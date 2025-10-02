local uv = vim.loop
local json_encode = vim.json.encode
local json_decode = vim.json.decode

local msg_utils = require("synaps.utils.message_utils")

local M = {}
local clients = {}
local server_handle = nil

-- Broadcast a message to all SSE clients
local function broadcast(msg)
    local data = "data: " .. json_encode(msg) .. "\n\n"
    for _, client in ipairs(clients) do
        client:write(data)
    end
end

-- Write SSE response headers
local function write_sse_headers(sock)
    sock:write("HTTP/1.1 200 OK\r\n")
    sock:write("Content-Type: text/event-stream\r\n")
    sock:write("Cache-Control: no-cache\r\n\r\n")
end

-- Handle a new SSE client connection
local function handle_sse(sock, path)
    write_sse_headers(sock)
    table.insert(clients, sock)
    msg_utils.show_info("SSE client subscribed: " .. path)
end

-- Write JSON response back to the client
local function respond_json(sock, data)
    sock:write("HTTP/1.1 200 OK\r\n")
    sock:write("Content-Type: application/json\r\n")
    sock:write("Content-Length: " .. #data .. "\r\n\r\n")
    sock:write(data)
end

-- Try to parse Content-Length and body
local function parse_post_body(buffer)
    local len = tonumber(buffer:match("Content%-Length:%s*(%d+)") or "0")
    local body = buffer:match("\r\n\r\n(.*)")
    return len, body
end

-- Decode JSON safely
local function try_decode_json(body, len)
    if not body or #body < len then
        return nil
    end
    local cleaned = body:sub(1, len):gsub("[\r\n%z]", "")
    local ok, result = pcall(json_decode, cleaned)
    return ok and result or nil
end

-- Handle POST request
local function handle_post(buffer, handler, sock, path)
    local len, body = parse_post_body(buffer)
    local req = try_decode_json(body, len)
    if not req then
        msg_utils.show_error("Invalid JSON at " .. path)
        return true
    end
    msg_utils.show_debug("Parsed JSON: " .. vim.inspect(req))
    local resp = json_encode(handler(req))
    respond_json(sock, resp)
    broadcast(json_decode(resp))
    return true
end

-- Determine request type and route it
local function route_request(buffer, sock, handler)
    local path = buffer:match("%s(/%S*)") or "/"
    if buffer:find("GET /sse") or buffer:find("GET /events") or buffer:find("GET / ") then
        handle_sse(sock, path)
        return true
    end
    if buffer:find("POST /") then
        return handle_post(buffer, handler, sock, path)
    end
    return false
end

-- TCP connection callback
local function on_client(sock, handler)
    local buffer = ""
    sock:read_start(function(err, chunk)
        if err then
            return msg_utils.show_error("Read error: " .. err)
        end
        if not chunk then
            return
        end
        buffer = buffer .. chunk
        local line = buffer:match("^(.-)\r\n")
        if line then
            msg_utils.show_debug("Request: " .. line)
        end
        if route_request(buffer, sock, handler) then
            buffer = ""
        end
    end)
end

-- Start SSE server
function M.start(handler)
    local cfg = require("synaps.config.config").get()
    server_handle = uv.new_tcp()
    server_handle:bind(cfg.host, cfg.port)
    server_handle:listen(128, function(err)
        if err then
            return msg_utils.show_error("Failed to start: " .. err)
        end
        local sock = uv.new_tcp()
        server_handle:accept(sock)
        on_client(sock, handler)
    end)
    msg_utils.show_info(("SSE server listening at http://%s:%d"):format(cfg.host, cfg.port))
end

-- Stop SSE server and close clients
function M.stop()
    if server_handle then
        server_handle:close()
        server_handle = nil
    end
    for _, c in ipairs(clients) do
        c:close()
    end
    clients = {}
    msg_utils.show_info("SSE server stopped")
end

return M

local config = require("synaps.config.config")

local transports = {
    sse = require("synaps.transports.sse"),
    stdio = require("synaps.transports.stdio"),
}

--- JSON-RPC error codes
local ERROR_CODES = {
    PARSE_ERROR = -32700,
    INVALID_REQUEST = -32600,
    METHOD_NOT_FOUND = -32601,
    INVALID_PARAMS = -32602,
    INTERNAL_ERROR = -32603,
}

--- JSON-RPC method names
local METHODS = {
    INITIALIZE = "initialize",
    TOOLS_LIST = "tools/list",
    TOOLS_CALL = "tools/call",
}

---@class MCPServer
---@field active_transport table|nil
---@field tools table
local MCPServer = {}
MCPServer.__index = MCPServer

--- Create a new server instance
function MCPServer:new()
    return setmetatable({
        active_transport = nil,
        tools = {},
    }, self)
end

--- Register a tool
function MCPServer:register_tool(name, description, handler)
    self.tools[name] = { description = description, handler = handler }
end

--- Return list of tools
function MCPServer:list_tools()
    local result = {}
    for name, tool in pairs(self.tools) do
        table.insert(result, { name = name, description = tool.description })
    end
    return result
end

--- Dispatch request
function MCPServer:handle_request(req)
    local handlers = {
        [METHODS.INITIALIZE] = function()
            return self:handle_initialize(req)
        end,
        [METHODS.TOOLS_LIST] = function()
            return self:handle_tools_list(req)
        end,
        [METHODS.TOOLS_CALL] = function()
            return self:handle_tool_call(req)
        end,
    }

    local handler = handlers[req.method]
    return handler and handler() or self:handle_unknown_method(req)
end

function MCPServer:handle_initialize(req)
    return self:ok_response(req.id, {
        protocolVersion = "2024-11-05",
        serverInfo = { name = "synaps.nvim", version = "0.1.0" },
    })
end

function MCPServer:handle_tools_list(req)
    return self:ok_response(req.id, { tools = self:list_tools() })
end

function MCPServer:handle_tool_call(req)
    local tool = self.tools[req.params.name]
    if not tool then
        return self:error_response(req.id, ERROR_CODES.METHOD_NOT_FOUND, "Unknown tool")
    end

    local result = tool.handler(req.params.arguments or {})
    return self:ok_response(req.id, result)
end

function MCPServer:handle_unknown_method(req)
    return self:error_response(req.id, ERROR_CODES.METHOD_NOT_FOUND, "Unknown method")
end

function MCPServer:ok_response(id, result)
    return {
        jsonrpc = "2.0",
        id = id,
        result = result,
    }
end

function MCPServer:error_response(id, code, message)
    return {
        jsonrpc = "2.0",
        id = id,
        error = {
            code = code,
            message = message,
        },
    }
end

--- Start transport
function MCPServer:start(transport_name)
    if self.active_transport then
        return vim.notify("[synaps] Server already running", vim.log.levels.WARN)
    end

    local transport = transports[transport_name]
    if not transport then
        return vim.notify("[synaps] Invalid transport: " .. transport_name, vim.log.levels.ERROR)
    end

    self.active_transport = transport
    transport.start(function(req)
        return self:handle_request(req)
    end)
end

--- Stop transport
function MCPServer:stop()
    if not self.active_transport then
        return vim.notify("[synaps] Server not running", vim.log.levels.WARN)
    end

    self.active_transport.stop()
    self.active_transport = nil
end

local server_instance = MCPServer:new()

return {
    instance = server_instance,
    ERROR_CODES = ERROR_CODES,
    METHODS = METHODS,
}

local M = {
    transport = "sse",
    host = "127.0.0.1",
    port = 8765,
    autostart = false,
}

function M.setup(opts)
    M = vim.tbl_extend("force", M, opts or {})
end

function M.get()
    return M
end

return M

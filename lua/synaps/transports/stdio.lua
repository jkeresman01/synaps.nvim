local M = {}

function M.start()
    vim.notify("[synaps] Starting stdio MCP server (not yet implemented)", vim.log.levels.INFO)
end

function M.stop()
    vim.notify("[synaps] Stopping stdio MCP server", vim.log.levels.INFO)
end

return M

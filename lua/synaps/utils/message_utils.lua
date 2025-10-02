local M = {}

function M.show_error(msg)
    vim.notify("[synaps] " .. msg, vim.log.levels.ERROR)
end

function M.show_warn(msg)
    vim.notify("[synaps] " .. msg, vim.log.levels.WARN)
end

function M.show_info(msg)
    vim.notify("[synaps] " .. msg, vim.log.levels.INFO)
end

function M.show_debug(msg)
    vim.notify("[synaps] " .. msg, vim.log.levels.DEBUG)
end

return M

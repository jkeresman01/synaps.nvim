local server = require("synaps.mcp.server").instance
local config = require("synaps.config.config")

local M = {}

function M.register()
    vim.api.nvim_create_user_command("SynapsStart", function()
        server:start(config.get().transport)
    end, {})

    vim.api.nvim_create_user_command("SynapsStop", function()
        server:stop()
    end, {})
end

return M

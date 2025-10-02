local config = require("synaps.config.config")
local commands = require("synaps.commands.commands")
local tools = require("synaps.tools")
local server = require("synaps.mcp.server").instance

local M = {}

function M.setup(opts)
    config.setup(opts)
    tools.register_all()
    commands.register()
    if config.get().autostart then
        server:start(config.get().transport)
    end
end

return M

local server = require("synaps.mcp.server").instance
local lsp_utils = require("synaps.utils.lsp_utils")
local fs_utils = require("synaps.utils.fs_utils")
local preview = require("synaps.view.preview")

local M = {}

function M.register_all()
    server:register_tool("get_buffer", "Get current buffer contents", function()
        return { contents = lsp_utils.get_current_buffer() }
    end)

    server:register_tool("get_diagnostics", "Get diagnostics for current buffer", function()
        return { diagnostics = lsp_utils.get_diagnostics(0) }
    end)

    server:register_tool("get_project_context", "Get multi-file project context", function(args)
        return { files = fs_utils.scan_project(args.max_files or 20) }
    end)

    server:register_tool("apply_edits", "Apply text edits to current buffer", function(args)
        return preview.apply_edits(args.edits or {})
    end)
end

return M

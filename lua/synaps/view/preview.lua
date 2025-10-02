local msg_utils = require("synaps.utils.message_utils")

local M = {}

function M.apply_edits(edits)
    if not edits or #edits == 0 then
        msg_utils.show_warn("No edits to apply")
        return { applied = false }
    end

    for _, e in ipairs(edits) do
        vim.api.nvim_buf_set_text(0, e.start[1], e.start[2], e["end"][1], e["end"][2], { e.text })
    end

    msg_utils.show_info(("Applied %d edits"):format(#edits))
    return { applied = true }
end

return M

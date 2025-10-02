local M = {}

function M.get_current_buffer()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    return table.concat(lines, "\n")
end

function M.get_diagnostics(bufnr)
    return vim.diagnostic.get(bufnr or 0)
end

local function make_params(bufnr)
    return { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
end

local function request_symbols(bufnr)
    return vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", make_params(bufnr), 2000)
end

function M.get_document_symbols(bufnr)
    local result = request_symbols(bufnr or 0)
    local out = {}
    if result then
        for _, res in pairs(result) do
            if res.result then
                vim.list_extend(out, res.result)
            end
        end
    end
    return out
end

return M

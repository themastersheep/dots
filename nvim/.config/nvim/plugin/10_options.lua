-- ============================================================================
-- Editor options + autocmds (auto-sourced after init.lua)
--
-- vim.g.* settings stay in init.lua because they must run before $VIMRUNTIME's
-- plugin/ files source bundled plugins (gzip, netrw, providers).
-- Plugin-specific autocmds (e.g. mini.files window centering) live with their
-- plugin's setup block in plugin/30_mini.lua.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Options
-- ----------------------------------------------------------------------------

vim.opt.swapfile       = false
vim.opt.termguicolors  = true

vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.cursorline     = true
vim.opt.cursorlineopt  = "number"
vim.opt.guicursor      = {
    "n:block-CursorNormal",
    "v:block-CursorVisual",
    "i-ci:block-CursorInsert",
    "r-cr:block-CursorReplace",
    "c:block-CursorCommand",
}

vim.opt.showtabline    = 0
vim.opt.tabstop        = 4
vim.opt.softtabstop    = 4
vim.opt.shiftwidth     = 4
vim.opt.expandtab      = true
vim.opt.autoindent     = true
vim.opt.smartindent    = true
vim.opt.wrap           = false
vim.opt.signcolumn     = "yes"
vim.opt.scrolloff      = 1
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.more           = false
vim.o.showmode         = false
vim.o.winborder        = "rounded"
vim.opt.shortmess:append("WIF")

vim.o.complete        = ".,w,b,kspell"
vim.o.completeopt     = "menuone,noselect,fuzzy,nosort"
vim.o.completetimeout = 100
vim.o.pumborder       = "rounded"
vim.o.pumheight       = 10
vim.o.pummaxwidth     = 100

-- ----------------------------------------------------------------------------
-- Autocmds (single shared augroup, helper trims boilerplate)
-- ----------------------------------------------------------------------------

local group           = vim.api.nvim_create_augroup("user", { clear = true })
local function au(event, opts)
    opts.group = group
    vim.api.nvim_create_autocmd(event, opts)
end

au("TextYankPost", {
    desc = "Highlight selection on yank",
    callback = function()
        vim.hl.on_yank({ higroup = "IncSearch", timeout = 500 })
    end,
})

au("BufWritePre", {
    desc    = "Remove trailing whitespace",
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

au("LspAttach", {
    desc = "Per-buffer LSP setup",
    callback = function(e)
        local client = vim.lsp.get_client_by_id(e.data.client_id)

        vim.bo[e.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"

        local function format_with_imports()
            local clients = vim.lsp.get_clients({ bufnr = e.buf, method = "textDocument/codeAction" })
            for _, c in ipairs(clients) do
                local enc = c.offset_encoding or "utf-16"
                local params = vim.lsp.util.make_range_params(0, enc)
                params.context = {
                    only        = { "source.organizeImports" },
                    diagnostics = {},
                }

                local result = c:request_sync("textDocument/codeAction", params, 2000, e.buf)
                for _, action in ipairs((result and result.result) or {}) do
                    local resolves = c.server_capabilities.codeActionProvider
                        and c.server_capabilities.codeActionProvider.resolveProvider
                    if not action.edit and resolves then
                        local resolved = c:request_sync("codeAction/resolve", action, 2000, e.buf)
                        if resolved and resolved.result then action = resolved.result end
                    end
                    if action.edit then
                        vim.lsp.util.apply_workspace_edit(action.edit, enc)
                    end
                    if action.command then
                        c:exec_cmd(action.command)
                    end
                end
            end

            vim.lsp.buf.format({ async = false, timeout_ms = 2000 })
        end

        vim.keymap.set("n", "ff", format_with_imports, { buffer = e.buf, desc = "Organize imports + format" })

        vim.o.updatetime = 300

        if client and client.server_capabilities.documentHighlightProvider then
            local hl_group = vim.api.nvim_create_augroup("user_lsp_doc_highlight", { clear = false })
            vim.api.nvim_clear_autocmds({ buffer = e.buf, group = hl_group })

            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                group    = hl_group,
                buffer   = e.buf,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                group    = hl_group,
                buffer   = e.buf,
                callback = vim.lsp.buf.clear_references,
            })
        end
    end,
})

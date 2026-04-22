-- ============================================================================
-- mini.* plugins (auto-sourced after init.lua)
-- ============================================================================

local later, now_if_args = Config.later, Config.now_if_args

-- ----------------------------------------------------------------------------
-- mini.icons — depended on by other mini.* modules; sync only when first paint
-- needs them (no splash).
-- ----------------------------------------------------------------------------

now_if_args(function()
    vim.pack.add({ "https://github.com/nvim-mini/mini.icons" })
    local icons = require("mini.icons")
    icons.setup()
    icons.tweak_lsp_kind()
end)

-- ----------------------------------------------------------------------------
-- mini.statusline — visible from first paint when a file is open; covered by
-- the splash otherwise.
-- ----------------------------------------------------------------------------

now_if_args(function()
    vim.pack.add({ "https://github.com/nvim-mini/mini.statusline" })
    require("mini.statusline").setup({
        content = {
            active = function()
                local git_branch = ""
                if vim.fn.exists("*FugitiveHead") == 1 then
                    local branch = vim.fn.FugitiveHead()
                    if branch ~= "" then
                        git_branch = "\xee\x82\xa0 " .. branch
                    end
                end

                local statusline    = require("mini.statusline")
                local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
                local diff          = statusline.section_diff({ trunc_width = 75, icon = "" })
                local diagnostics   = statusline.section_diagnostics({
                    trunc_width = 75,
                    icon        = "",
                    signs       = {
                        ERROR = "\xef\x81\x97 ",
                        WARN  = "\xef\x81\xb1 ",
                        INFO  = "\xf3\xb0\x8c\xb5 ",
                        HINT  = "\xef\x91\x89  ",
                    },
                })

                local lsp           = statusline.section_lsp({ trunc_width = 75 })
                return statusline.combine_groups({
                    { hl = mode_hl,                 strings = { mode } },
                    { hl = "MiniStatuslineDevinfo", strings = { git_branch, diff } },
                    "%<",
                    { hl = "MiniStatuslineFilename", strings = { "%f%m%r" } },
                    "%=",
                    { hl = "MiniStatuslineFileinfo", strings = { diagnostics } },
                    { hl = mode_hl,                  strings = { lsp } },
                })
            end,
        },
    })
end)

-- ----------------------------------------------------------------------------
-- mini.notify
-- ----------------------------------------------------------------------------

later(function()
    vim.pack.add({ "https://github.com/nvim-mini/mini.notify" })

    local win_config = function()
        local has_statusline = vim.o.laststatus > 0
        local pad = vim.o.cmdheight + (has_statusline and 1 or 0)
        return { anchor = "SE", col = vim.o.columns, row = vim.o.lines - pad }
    end
    local notify = require("mini.notify")
    notify.setup({
        lsp_progress = { enable = false },
        window       = { config = win_config() },
    })
    vim.notify = notify.make_notify()
end)

-- ----------------------------------------------------------------------------
-- mini.diff
-- ----------------------------------------------------------------------------

later(function()
    vim.pack.add({ "https://github.com/nvim-mini/mini.diff" })
    local diff = require("mini.diff")
    diff.setup({
        view = { style = "number" },
        mappings = {
            apply      = "gs",
            reset      = "gS",
            textobject = "gh",
        },
    })
    vim.keymap.set("n", "g=", diff.toggle_overlay, { desc = "Diff overlay" })
end)

-- ----------------------------------------------------------------------------
-- mini.hipatterns
-- ----------------------------------------------------------------------------

later(function()
    vim.pack.add({ "https://github.com/nvim-mini/mini.hipatterns" })
    require("mini.hipatterns").setup({
        highlighters = {
            fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
            hack  = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
            todo  = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
            note  = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
        },
    })
end)

-- ----------------------------------------------------------------------------
-- mini.pick
-- ----------------------------------------------------------------------------

later(function()
    vim.pack.add({ "https://github.com/nvim-mini/mini.pick" })
    local pick = require("mini.pick")

    local opts = {
        mappings = {
            move_down     = "<C-j>",
            move_up       = "<C-k>",
            scroll_down   = "<pagedown>",
            scroll_up     = "<pageup>",
            refine_marked = "<C-Enter>",
            choose_marked = "<C-q>",
        },
    }

    -- mini.pick.setup overrides vim.ui.select; restore the snipe trampoline
    local ui_select_orig = vim.ui.select
    pick.setup(opts)
    vim.ui.select = ui_select_orig

    vim.keymap.set("n", "<c-p>", function() pick.builtin.files() end, { desc = "Find files" })
    vim.keymap.set("n", "<leader>sg", function() pick.builtin.grep_live() end, { desc = "Live grep" })
    vim.keymap.set("n", "<leader>sG", function()
        pick.builtin.grep({ pattern = vim.fn.expand("<cword>") })
    end, { desc = "Grep <cword>" })
    vim.keymap.set("n", "<leader>sr", function() pick.builtin.resume() end, { desc = "Resume search" })
    vim.keymap.set("n", "<leader>sh", function() pick.builtin.help() end, { desc = "Search Help" })
end)

-- ----------------------------------------------------------------------------
-- mini.files
-- ----------------------------------------------------------------------------

later(function()
    vim.pack.add({ "https://github.com/nvim-mini/mini.files" })
    local files = require("mini.files")
    files.setup()

    vim.keymap.set("n", "-", function()
        if not files.close() then files.open(vim.api.nvim_buf_get_name(0)) end
    end, { desc = "Explore files" })

    -- Keep mini.files explorer windows centered on the screen
    local function ensure_center_layout(ev)
        local widths = { 60, 20, 10 }
        local state = files.get_explorer_state()
        if state == nil then return end

        local path_this = vim.api.nvim_buf_get_name(ev.data.buf_id):match("^minifiles://%d+/(.*)$")
        local depth_this
        for i, path in ipairs(state.branch) do
            if path == path_this then depth_this = i end
        end
        if depth_this == nil then return end
        local depth_offset = depth_this - state.depth_focus

        local i            = math.abs(depth_offset) + 1

        local win_config   = vim.api.nvim_win_get_config(ev.data.win_id)
        win_config.width   = i <= #widths and widths[i] or widths[#widths]
        win_config.zindex  = 99
        win_config.col     = math.floor(0.5 * (vim.o.columns - widths[1]))

        for j = 1, math.abs(depth_offset) do
            local sign = depth_offset == 0 and 0 or (depth_offset > 0 and 1 or -1)
            local prev_win_width = (sign == -1 and widths[j + 1]) or widths[j] or widths[#widths]
            local new_col = win_config.col + sign * (prev_win_width + 2)
            if (new_col < 0) or (new_col + win_config.width > vim.o.columns) then
                win_config.zindex = win_config.zindex - 1
                break
            end
            win_config.col = new_col
        end

        win_config.height = depth_offset == 0 and 25 or 20
        win_config.row    = math.floor(0.5 * (vim.o.lines - win_config.height))
        vim.api.nvim_win_set_config(ev.data.win_id, win_config)
    end

    vim.api.nvim_create_autocmd("User", {
        pattern  = "MiniFilesWindowUpdate",
        group    = vim.api.nvim_create_augroup("user_minifiles", { clear = true }),
        callback = ensure_center_layout,
    })
end)

-- ----------------------------------------------------------------------------
-- mini.completion — now_if_args so capabilities are set before the first LSP
-- attach (file on cmdline → loads sync; otherwise → next event-loop tick,
-- still before any later file open triggers an LSP attach).
-- ----------------------------------------------------------------------------

now_if_args(function()
    vim.pack.add({ "https://github.com/nvim-mini/mini.completion" })
    local completion = require("mini.completion")

    local process_items_opts = { kind_priority = { Text = -1, Snippet = 99 } }
    local process_items = function(items, base)
        return completion.default_process_items(items, base, process_items_opts)
    end

    completion.setup({
        lsp_completion = {
            source_func    = "omnifunc",
            auto_setup     = false,
            process_items  = process_items,
            snippet_insert = function(snippet) vim.snippet.expand(snippet) end,
        },
        mappings = {
            force_twostep = "<C-/>",
        },
    })

    vim.lsp.config("*", { capabilities = completion.get_lsp_capabilities() })
end)

-- ----------------------------------------------------------------------------
-- LSP servers — colocated with mini.completion above so capabilities are
-- guaranteed to be applied before any client starts. Both blocks share the
-- now_if_args tier and fire in declaration order.
-- ----------------------------------------------------------------------------

now_if_args(function()
    vim.lsp.enable("gopls")
    vim.lsp.enable("lua_ls")
end)

-- ----------------------------------------------------------------------------
-- mini.snippets
-- ----------------------------------------------------------------------------

later(function()
    vim.pack.add({ "https://github.com/nvim-mini/mini.snippets" })
    local snippets = require("mini.snippets")
    snippets.setup({
        snippets = { snippets.gen_loader.from_lang() },
        mappings = {
            expand    = "",
            jump_next = "",
            jump_prev = "",
            stop      = "",
        },
    })
    snippets.start_lsp_server()
end)

-- ----------------------------------------------------------------------------
-- mini.keymap
-- ----------------------------------------------------------------------------

later(function()
    vim.pack.add({ "https://github.com/nvim-mini/mini.keymap" })
    local keymap = require("mini.keymap")
    keymap.setup()
    keymap.map_multistep("i", "<C-j>", { "pmenu_next" })
    keymap.map_multistep("i", "<C-k>", { "pmenu_prev" })
    keymap.map_multistep("i", "<CR>", { "pmenu_accept" })
end)

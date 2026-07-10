-- ============================================================================
-- Plugins outside of mini.* (auto-sourced after init.lua)
-- ============================================================================

local now, later, now_if_args = Config.now, Config.later, Config.now_if_args

-- ----------------------------------------------------------------------------
-- rose-pine — colorscheme; must load before first paint
-- (repo dir is "neovim", so set name="rose-pine" for a sensible on-disk name)
-- ----------------------------------------------------------------------------

now(function()
    vim.pack.add({ { src = "https://github.com/rose-pine/neovim", name = "rose-pine" } })

    require("rose-pine").setup({
        styles = { transparency = true },
    })
    vim.cmd("colorscheme rose-pine")

    local palette = require("rose-pine.palette")

    vim.api.nvim_set_hl(0, "CursorNormal", { fg = "NONE", bg = palette.love })
    vim.api.nvim_set_hl(0, "CursorInsert", { fg = "NONE", bg = palette.foam })
    vim.api.nvim_set_hl(0, "CursorReplace", { fg = "NONE", bg = palette.gold })
    vim.api.nvim_set_hl(0, "CursorVisual", { fg = "NONE", bg = palette.iris })
    vim.api.nvim_set_hl(0, "CursorCommand", { fg = "NONE", bg = palette.text })

    vim.cmd("highlight linenr guifg=#423F51")
    vim.cmd("highlight comment guifg=#6e6a86")
    vim.cmd("highlight WinSeparator guifg=#21202e")

    vim.api.nvim_set_hl(0, "@variable.declaration", { bg = "#225164" })
    vim.api.nvim_set_hl(0, "@variable.redeclaration", { fg = "#eb6f92" })

    vim.api.nvim_set_hl(0, "MiniPickMatchCurrent", { fg = palette.text, bg = palette.highlight_med })
    vim.api.nvim_set_hl(0, "MiniPickMatchMarked", { fg = palette.foam })

    vim.api.nvim_set_hl(0, "MiniDiffOverAdd", { link = "DiffAdd" })
    vim.api.nvim_set_hl(0, "MiniDiffOverDelete", { link = "DiffDelete" })
    vim.api.nvim_set_hl(0, "MiniDiffOverChange", { link = "DiffText" })
    vim.api.nvim_set_hl(0, "MiniDiffOverContext", { link = "DiffChange" })
end)

-- ----------------------------------------------------------------------------
-- nvim-treesitter (+ textobjects) — load early if started with file arg
-- Uses the `main` branch (lua-only). PackChanged hook replaces lazy `build=`.
-- ----------------------------------------------------------------------------

now_if_args(function()
    -- Hook MUST be registered before the matching add() call (see :h vim.pack-events)
    Config.on_packchanged("nvim-treesitter", { "update" }, function()
        vim.cmd("TSUpdate")
    end)

    vim.pack.add({
        { src = "https://github.com/nvim-treesitter/nvim-treesitter",             version = "main" },
        { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
    })

    local parsers = {
        "bash", "c", "html", "lua", "markdown", "markdown_inline",
        "vim", "vimdoc", "go", "json", "yaml",
    }

    -- Install only missing parsers (idempotent — :TSUpdate handles upgrades)
    local function isnt_installed(lang)
        return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
    end
    local to_install = vim.tbl_filter(isnt_installed, parsers)
    if #to_install > 0 then require("nvim-treesitter").install(to_install) end

    -- Auto-start tree-sitter for the listed filetypes
    local filetypes = {}
    for _, lang in ipairs(parsers) do
        for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
            table.insert(filetypes, ft)
        end
    end
    vim.api.nvim_create_autocmd("FileType", {
        pattern = filetypes,
        callback = function(ev) vim.treesitter.start(ev.buf) end,
    })

    -- "Center on enclosing function" helper
    vim.keymap.set("n", "zf", function()
        local original_line = vim.fn.line(".")
        local node = vim.treesitter.get_node()
        if not node then return end

        while node and not (node:type():find("function") or node:type():find("method")) do
            node = node:parent()
        end

        if node then
            local start_row, _, end_row, _ = node:range()
            local center_row = math.floor((start_row + end_row) / 2) + 1
            vim.cmd("normal! " .. center_row .. "Gzz")
            vim.cmd("normal! " .. original_line .. "G")
        end
    end, { noremap = true, silent = true })

    -- textobjects setup + keymaps
    require("nvim-treesitter-textobjects").setup({
        select = {
            lookahead = true,
            selection_modes = {
                ["@parameter.outer"] = "v",
                ["@function.outer"]  = "V",
                ["@class.outer"]     = "<c-v>",
            },
            include_surrounding_whitespace = false,
        },
        move = { set_jumps = true },
    })

    local select = require("nvim-treesitter-textobjects.select")
    local move   = require("nvim-treesitter-textobjects.move")

    vim.keymap.set({ "n", "x", "o" }, "af", function() select.select_textobject("@function.outer", "textobjects") end)
    vim.keymap.set({ "n", "x", "o" }, "if", function() select.select_textobject("@function.inner", "textobjects") end)
    vim.keymap.set({ "n", "x", "o" }, "ar", function() select.select_textobject("@return.outer", "textobjects") end)
    vim.keymap.set({ "n", "x", "o" }, "ir", function() select.select_textobject("@return.inner", "textobjects") end)

    vim.keymap.set({ "n", "x", "o" }, "]f", function()
        move.goto_next_start("@pkgfunc.name", "textobjects")
        vim.cmd.normal({ "zz", bang = true })
    end)
    vim.keymap.set({ "n", "x", "o" }, "[f", function()
        move.goto_previous_start("@pkgfunc.name", "textobjects")
        vim.cmd.normal({ "zz", bang = true })
    end)
    vim.keymap.set({ "n", "x", "o" }, "]F", function()
        move.goto_next_end("@pkgfunc.outer", "textobjects")
        vim.cmd.normal({ "zz", bang = true })
    end)
    vim.keymap.set({ "n", "x", "o" }, "[F", function()
        move.goto_previous_end("@pkgfunc.outer", "textobjects")
        vim.cmd.normal({ "zz", bang = true })
    end)
    vim.keymap.set({ "n", "x", "o" }, "]r", function()
        move.goto_next_start("@return.outer", "textobjects")
        vim.cmd.normal({ "zz", bang = true })
    end)
    vim.keymap.set({ "n", "x", "o" }, "[r", function()
        move.goto_previous_start("@return.outer", "textobjects")
        vim.cmd.normal({ "zz", bang = true })
    end)
end)

-- ----------------------------------------------------------------------------
-- vim-fugitive (consumed by mini.statusline via FugitiveHead())
-- ----------------------------------------------------------------------------

later(function()
    vim.pack.add({ "https://github.com/tpope/vim-fugitive" })
    vim.keymap.set("n", "<leader>gg", "<cmd>G<cr>", { desc = "Git status" })
    vim.keymap.set("n", "<leader>gp", "<cmd>Git pull<cr>", { desc = "Git pull" })
    vim.keymap.set("n", "<leader>gw", "<cmd>Git blame<cr>", { desc = "Git blame" })
end)

-- ----------------------------------------------------------------------------
-- flash.nvim
-- ----------------------------------------------------------------------------

later(function()
    vim.pack.add({ "https://github.com/folke/flash.nvim" })
    local flash = require("flash")
    flash.setup({})

    vim.keymap.set({ "n", "x", "o" }, "<leader>J", function() flash.treesitter() end, { desc = "Flash Treesitter" })
    vim.keymap.set("o", "r", function() flash.remote() end, { desc = "Remote Flash" })
    vim.keymap.set({ "o", "x" }, "R", function() flash.treesitter_search() end, { desc = "Treesitter Search" })
    vim.keymap.set("c", "<c-s>", function() flash.toggle() end, { desc = "Toggle Flash Search" })
    vim.keymap.set({ "n", "x", "o" }, "<leader>j", function() flash.jump() end, { desc = "Flash" })
end)

-- ----------------------------------------------------------------------------
-- snipe.nvim — also backs the vim.ui.select trampoline in init.lua
-- ----------------------------------------------------------------------------

later(function()
    vim.pack.add({ "https://github.com/leath-dub/snipe.nvim" })
    local snipe = require("snipe")
    snipe.setup({
        ui = {
            position          = "cursor",
            open_win_override = { border = "rounded" },
            text_align        = "file-first",
        },
    })

    snipe.ui_select_menu = require("snipe.menu"):new({ position = "center" })
    snipe.ui_select_menu:add_new_buffer_callback(function(m)
        vim.keymap.set("n", "<esc>", function() m:close() end, { nowait = true, buffer = m.buf })
    end)

    vim.keymap.set("n", "<leader>b", function() snipe.open_buffer_menu() end, { desc = "Snipe a buffer" })
end)

-- ----------------------------------------------------------------------------
-- namu.nvim
-- ----------------------------------------------------------------------------

later(function()
    vim.pack.add({ "https://github.com/bassamsdata/namu.nvim" })
    require("namu").setup({
        global = {
            movement = {
                next     = { "<c-j>", "<c-n>", "<DOWN>" },
                previous = { "<c-k>", "<c-p>", "<UP>" },
            },
            multiselect = { keymaps = { toggle = "<c-x>" } },
        },
        namu_symbols = {
            enable  = true,
            options = { current_highlight = { enabled = true } },
        },
    })

    vim.keymap.set("n", "<leader>ls", "<cmd>Namu symbols<cr>", { desc = "Namu symbols" })
    vim.keymap.set("n", "<leader>lS", "<cmd>Namu workspace<cr>", { desc = "Namu workspace symbols" })
    vim.keymap.set("n", "<leader>ld", "<cmd>Namu diagnostics<cr>", { desc = "Namu diagnostics" })
    vim.keymap.set("n", "<leader>lD", "<cmd>Namu diagnostics workspace<cr>", { desc = "Namu workspace diagnostics" })
    vim.keymap.set("n", "<leader>lw", "<cmd>Namu watchtower<cr>", { desc = "Namu watchtower" })
end)

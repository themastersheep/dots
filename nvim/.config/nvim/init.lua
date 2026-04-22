-- ============================================================================
-- Bootstrap (vim.pack — built-in plugin manager, requires nvim 0.12+)
-- ============================================================================

vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

_G.Config            = {}

local function safely(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        vim.schedule(function()
            vim.notify(string.format("[Config.%s] %s", name, err), vim.log.levels.ERROR)
        end)
    end
end

-- now()         — run synchronously (use for first-paint critical things)
-- later()       — defer to first event-loop tick (most plugins)
-- now_if_args() — now() if nvim was started with a file arg, else later()
-- on_packchanged() — vim.pack install/update hook (replaces lazy `build=`)
Config.now            = function(f) safely("now", f) end
Config.later          = function(f) vim.schedule(function() safely("later", f) end) end
Config.now_if_args    = vim.fn.argc(-1) > 0 and Config.now or Config.later

Config.on_packchanged = function(plugin_name, kinds, callback)
    vim.api.nvim_create_autocmd("PackChanged", {
        callback = function(ev)
            local name, kind = ev.data.spec.name, ev.data.kind
            if name ~= plugin_name or not vim.tbl_contains(kinds, kind) then return end
            if not ev.data.active then vim.cmd.packadd(plugin_name) end
            callback(ev.data)
        end,
    })
end

-- ============================================================================
-- ui2 — experimental cmdline/messages redesign (nvim 0.12+)
-- See `:h ui2`. Disable by commenting this line if anything breaks.
-- ============================================================================
require("vim._core.ui2").enable()

-- ============================================================================
-- vim.pack user commands
-- ============================================================================

vim.api.nvim_create_user_command("PackList", function()
    vim.pack.update(nil, { offline = true })
end, { desc = "List installed plugins (offline view)" })

vim.api.nvim_create_user_command("PackUpdate", function()
    vim.pack.update()
end, { desc = "Fetch updates; :write to apply, :quit to abort" })

vim.api.nvim_create_user_command("PackDel", function(opts)
    vim.pack.del(opts.fargs, { force = opts.bang })
end, {
    nargs    = "+",
    bang     = true,
    desc     = "Remove plugins from disk (! to force-remove active plugins)",
    complete = function()
        return vim.iter(vim.pack.get()):map(function(p) return p.spec.name end):totable()
    end,
})

vim.api.nvim_create_user_command("PackOrphans", function()
    local orphans = vim.iter(vim.pack.get())
        :filter(function(p) return not p.active end)
        :map(function(p) return p.spec.name end)
        :totable()
    if #orphans == 0 then
        vim.notify("No orphan plugins")
    else
        vim.notify("Orphans (safe to PackDel):\n  " .. table.concat(orphans, "\n  "))
    end
end, { desc = "List installed plugins that are no longer in any vim.pack.add() call" })

-- ============================================================================
-- Globals that must be set before $VIMRUNTIME/plugin/* sources bundled plugins
-- ============================================================================

vim.g.clipboard               = {
    name = "wl-copy-primary",
    copy = {
        ["*"] = "wl-copy",
        ["+"] = "wl-copy",
    },
    paste = {
        ["+"] = "wl-paste",
        ["*"] = "wl-paste",
    },
    cache_enabled = 0,
}

vim.g.netrw_banner            = 0
vim.g.loaded_netrwPlugin      = 1
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider    = 0
vim.g.loaded_node_provider    = 0
vim.g.loaded_ruby_provider    = 0

-- vim.pack has no `performance.rtp.disabled_plugins` — disable bundled plugins here
vim.g.loaded_gzip             = 1
vim.g.loaded_matchit          = 1
vim.g.loaded_tarPlugin        = 1
vim.g.loaded_zipPlugin        = 1
vim.g.loaded_tohtml           = 1
vim.g.loaded_tutor            = 1
vim.g.loaded_2html_plugin     = 1

-- ============================================================================
-- vim.ui.select trampoline (lazily delegate to snipe.nvim on first call)
-- snipe is added in plugin/40_plugins.lua via later(), so it is in rtp by the
-- time the user can trigger a ui.select.
-- ============================================================================

vim.ui.select                 = function(...)
    local snipe = require("snipe")
    vim.ui.select = snipe.ui_select
    return vim.ui.select(...)
end

-- ============================================================================
-- Diagnostic display (deferred when no file — saves require('vim.diagnostic'))
-- ============================================================================

Config.now_if_args(function()
    vim.diagnostic.config({
        virtual_text = {
            prefix = "●",
        },
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = "\xf3\xb0\x85\x9a ",
                [vim.diagnostic.severity.WARN]  = "\xf3\xb0\x80\xaa ",
                [vim.diagnostic.severity.INFO]  = "\xef\x91\x89 ",
                [vim.diagnostic.severity.HINT]  = "\xf3\xb0\x8c\xb6 ",
            },
        },
        float = {
            focusable = true,
            source    = true,
            header    = "",
        },
    })
end)

-- ============================================================================
-- The rest is auto-sourced from `plugin/*.lua`:
--   plugin/10_options.lua    — editor options + generic autocmds
--   plugin/20_keymaps.lua    — global keymaps
--   plugin/30_mini.lua       — mini.* plugin specs + setup
--   plugin/40_plugins.lua    — non-mini plugin specs + setup
-- ============================================================================

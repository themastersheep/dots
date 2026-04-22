vim.keymap.set("n", "<leader>w", "<cmd>bd<CR>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>W", "<cmd>bd!<CR>", { desc = "Force delete buffer" })
vim.keymap.set("n", "<C-w>L", "<cmd>b#<CR>", { desc = "Switch to alternate buffer" })

vim.keymap.set({ "i", "s" }, "<C-l>", function()
    if vim.snippet.active({ direction = 1 }) then vim.snippet.jump(1) end
end, { desc = "Snippet jump next" })
vim.keymap.set({ "i", "s" }, "<C-h>", function()
    if vim.snippet.active({ direction = -1 }) then vim.snippet.jump(-1) end
end, { desc = "Snippet jump prev" })

vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank selection to clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank line to clipboard" })
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

--scroll navigate and center
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up (centered)" })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
vim.keymap.set("n", "n", "nzz", { desc = "Next match (centered)" })
vim.keymap.set("n", "N", "Nzz", { desc = "Prev match (centered)" })

vim.keymap.set("n", "<leader>q", function()
    local qf_exists = vim.fn.getqflist({ winid = 0 }).winid ~= 0
    if qf_exists then
        vim.cmd("cclose")
    else
        vim.cmd("copen")
    end
end, { desc = "Toggle Quickfix" })

vim.keymap.set("n", "<c-w>z", function()
    local zoomed = vim.w.zoomed or false

    if zoomed and vim.fn.tabpagenr('$') > 1 then
        vim.cmd("tabc") -- restore
        vim.w.zoomed = false
    elseif not zoomed and vim.fn.winnr('$') > 1 then
        vim.cmd("tab split") -- maximize
        vim.w.zoomed = true
    else
        print(zoomed and "No additional tab to close" or "Cannot maximize: only one window open")
        return
    end
end, { noremap = true, silent = true })

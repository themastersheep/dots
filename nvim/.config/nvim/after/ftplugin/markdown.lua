-- Enable spelling and wrap for window
vim.cmd('setlocal spell wrap')

-- Fold with tree-sitter
vim.cmd('setlocal nofoldenable foldmethod=expr foldexpr=v:lua.vim.treesitter.foldexpr()')

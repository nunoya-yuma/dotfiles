vim.g.mapleader = " "

-- Make a lone <Space> do nothing instead of moving the cursor right
vim.keymap.set('n', '<Space>', '<Nop>')
-- Collapse auto-repeated <Space> (from holding the key) into one leader press,
-- so "hold Space, then press d" behaves like "Space, d"
vim.keymap.set('n', '<Space><Space>', '<Space>', { remap = true })

if vim.g.vscode then
  -- remap = true so these go through vscode-neovim's own <C-d>/<C-u>
  -- overrides (VS Code-side scrolling) instead of Neovim's builtins.
  -- Trailing <leader> re-enters the leader-pending state after each scroll,
  -- so holding Space and tapping d/u repeatedly keeps scrolling
  vim.keymap.set('n', '<leader>d', '<C-d><leader>', { remap = true })
  vim.keymap.set('n', '<leader>u', '<C-u><leader>', { remap = true })
end

vim.keymap.set('n', '<leader>v', '<C-v>')
vim.keymap.set('n', '<leader>r', '<C-r>')

-- Increment/decrement; trailing <leader> allows repeating while Space is held
vim.keymap.set('n', '<leader>a', '<C-a><leader>', { remap = true })
vim.keymap.set('n', '<leader>x', '<C-x><leader>', { remap = true })
-- In visual mode, apply to every number in the selection
vim.keymap.set('x', '<leader>a', '<C-a>')
vim.keymap.set('x', '<leader>x', '<C-x>')

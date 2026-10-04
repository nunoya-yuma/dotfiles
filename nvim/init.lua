-- Alt stand-ins for the Ctrl keys handed back to VS Code. Alt is a real
-- modifier, so holding it and tapping a key repeats the action with no
-- timeout (unlike a Space leader, whose "held" state Neovim can't see).
-- In VS Code these arrive via vscode-neovim.send entries in
-- vscode/keybindings.json; in a terminal Neovim gets <M-x> directly.

-- remap = true so <C-d>/<C-u> go through vscode-neovim's own overrides
-- (VS Code-side scrolling) instead of Neovim's builtins
vim.keymap.set('n', '<M-d>', '<C-d>', { remap = true })
vim.keymap.set('n', '<M-u>', '<C-u>', { remap = true })

vim.keymap.set('n', '<M-v>', '<C-v>')
vim.keymap.set('n', '<M-r>', '<C-r>')

-- Increment/decrement; in visual mode, every number in the selection
vim.keymap.set({ 'n', 'x' }, '<M-a>', '<C-a>')
vim.keymap.set({ 'n', 'x' }, '<M-x>', '<C-x>')

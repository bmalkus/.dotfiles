local my_au_grp = vim.api.nvim_create_augroup('init-autocmds', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = my_au_grp,
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'When editing a file, always jump to the last know cursor position',
  group = my_au_grp,
  callback = function()
    vim.cmd('exe "normal! g`\\\""')
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { "markdown" },
  desc = 'Set spell check for markdown files',
  group = my_au_grp,
  callback = function()
    vim.opt_local.spell = true
  end,
})

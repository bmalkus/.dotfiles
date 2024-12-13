vim.api.nvim_create_user_command('CD', 'cd %:p:h', {})

local L = require"conf.local"

vim.api.nvim_create_user_command('Black', function()
  local line_length = L.def_python_line_length
  if vim.b.python_line_length ~= nil then
    line_length = vim.b.python_line_length
  end
  vim.cmd( '!black --line-length=' .. line_length .. ' %')
end, {})
vim.api.nvim_create_user_command('Isort', function()
  local line_length = L.def_python_line_length
  if vim.b.python_line_length ~= nil then
    line_length = vim.b.python_line_length
  end
  vim.cmd('!cd ' .. vim.lsp.get_clients({ bufnr = 0 })[1].config.root_dir .. ' && isort --profile=black --line-length=' .. line_length .. ' %:p')
end, {})

vim.api.nvim_create_user_command('CD', 'cd %:p:h', {})

vim.api.nvim_create_user_command('Black', '!black --line-length=120 %', {})
vim.api.nvim_create_user_command('Isort', function() vim.cmd('!cd ' .. vim.lsp.get_clients()[1].config.root_dir .. ' && isort --profile=black --line-length=120 %:p') end, {})

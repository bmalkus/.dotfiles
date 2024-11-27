vim.api.nvim_create_user_command('CD', 'cd %:p:h', {})

vim.api.nvim_create_user_command('Black', '!black --line-length=120 %', {})
vim.api.nvim_create_user_command('Isort', '!isort --line-length=120 %', {})

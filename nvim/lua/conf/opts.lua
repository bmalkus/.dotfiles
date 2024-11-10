vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.number = true
vim.opt.relativenumber = true

-- enable mouse support
vim.opt.mouse = 'a'

-- don't show mode, it's in the statusline
vim.opt.showmode = false

-- Enable break indent (indent broken lines with the same indent
vim.opt.breakindent = true

vim.opt.undofile = true
vim.opt.undolevels = 5000

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.smartcase = true

vim.opt.updatetime = 250

vim.opt.timeoutlen = 500 -- 0

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- list trailing whitespaces
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '\\u2022', nbsp = '␣'  }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- show at least 5 lines below/above cursor
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5
vim.opt.sidescroll = 1

vim.opt.completeopt = 'menu,menuone,preview'

vim.opt.foldmethod = 'marker'

vim.opt.wrap = false

vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

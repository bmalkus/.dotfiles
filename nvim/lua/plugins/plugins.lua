return {
  -- {{{ look & feel
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end,
  },
  {
    "rose-pine/neovim",
    lazy = false,
    priority = 1000,
    config = function()
      -- vim.cmd([[colorscheme rose-pine-moon]])
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    config = function()
      local lualine = require('lualine')
      lualine.setup {
        extensions = { "nvim-tree" },
        options = {
          refresh = {
            statusline = 999999999,
            tabline = 999999999,
            winbar = 999999999,
          }
        }
      }
      -- custom refreshing of lualine, heavy artillery, but avoids
      -- interference of lualine with NvimTree window picker
      local refresh_int_ms = 1000
      local timer = vim.uv.new_timer()
      timer:start(refresh_int_ms, refresh_int_ms, function()
        vim.schedule(function()
          lualine.refresh()
        end)
      end)

      local my_au_grp = vim.api.nvim_create_augroup('my-lualine-autocmds', { clear = true })
      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = { 'NvimTree*' },
        desc = 'Disable refreshes of lualine as it interferes with NvimTree window picker',
        group = my_au_grp,
        callback = function()
          timer:stop()
        end,
      })
      vim.api.nvim_create_autocmd('BufLeave', {
        pattern = { 'NvimTree*' },
        desc = 'Reenable refreshes of lualine after leaving NvimTree',
        group = my_au_grp,
        callback = function()
          timer:again()
        end,
      })
      vim.api.nvim_create_autocmd({'BufWritePost', 'BufEnter'}, {
        desc = 'Refresh lualine on various events',
        group = my_au_grp,
        callback = function()
          lualine.refresh()
        end,
      })
    end
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {},
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    }
  },
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    opts = {
      top_down = false,
      render = "wrapped-compact",
    }
  },
  {
    'stevearc/dressing.nvim',
    opts = {},
  },
  -- }}}
  -- {{{ nvim-tree, undotree
  -- mostly for auto cwd
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {},
    config = function()
      require("nvim-tree").setup {
        on_attach = function(bufnr)
          local api = require "nvim-tree.api"
          local function opts(desc)
            return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end

          api.config.mappings.default_on_attach(bufnr)

          vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
          vim.keymap.set('n', '<A-.>', api.node.run.cmd, opts('Run Command'))
          vim.keymap.set('n', '.', api.tree.toggle_hidden_filter, opts('Toggle Filter: Dotfiles'))
          vim.keymap.set('n', 'H', api.tree.change_root_to_parent, opts('Up'))
          vim.keymap.set('n', 'L', api.tree.change_root_to_node, opts('CD'))
          vim.keymap.set('n', 'l', api.node.open.edit, opts('Open'))
          vim.keymap.set('n', 'h', api.node.navigate.parent_close, opts('Close directory'))
          vim.keymap.set('n', 'cc', api.fs.copy.node, opts('Copy'))
          vim.keymap.set('n', 'cr', api.fs.copy.relative_path, opts('Copy Relative Path'))
          vim.keymap.set('n', 'cp', api.fs.copy.absolute_path, opts('Copy Absolute Path'))
          vim.keymap.set('n', 'cb', api.fs.copy.basename, opts('Copy Basename'))
          vim.keymap.set('n', 'cn', api.fs.copy.filename, opts('Copy Filename'))
        end
      }

      vim.keymap.set('n', '<C-n>', ":NvimTreeToggle<CR>", { desc = "nvim-tree: Open", noremap = true, silent = true, nowait = true })
      vim.keymap.set('n', '<A-n>', ":NvimTreeFindFileToggle<CR>", { desc = "nvim-tree: Open and find file", noremap = true, silent = true, nowait = true })
    end,
  },
  {
    'mbbill/undotree',
    opts = {},
    config = function()
      vim.keymap.set("n", "<A-u>", ":UndotreeToggle<CR>", { desc = "Toggle Undotree", noremap = true, nowait = true, silent = true })

      vim.g.undotree_SetFocusWhenToggle = 1
    end
  },
-- }}}
  -- {{{ lsp/completions
  {
    'neovim/nvim-lspconfig',
    opts = {},
    config = function()
      vim.keymap.set('n', '<A-CR>', vim.lsp.buf.code_action, { desc = 'Code action' })

      require('lspconfig').lua_ls.setup {
        on_init = function(client)
          if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if vim.uv.fs_stat(path..'/.luarc.json') or vim.uv.fs_stat(path..'/.luarc.jsonc') then
              return
            end
          end

          client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
              -- Tell the language server which version of Lua you're using
              -- (most likely LuaJIT in the case of Neovim)
              version = 'LuaJIT'
            },
            -- Make the server aware of Neovim runtime files
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME,
                -- Depending on the usage, you might want to add additional paths here.
                "~/.local/share/nvim/lazy/nvim-tree.lua",
                -- "${3rd}/busted/library",
              }
              -- or pull in all of 'runtimepath'. NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
              -- library = vim.api.nvim_get_runtime_file("", true)
            }
          })
        end,
        settings = {
          Lua = {}
        }
      }
      require'lspconfig'.pyright.setup{}
    end
  },
  {
    'hrsh7th/nvim-cmp',
    opts = {},
    dependencies = {
      'neovim/nvim-lspconfig',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline'
    },
    config = function()
      local cmp = require'cmp'

      cmp.setup({
        window = {
          -- completion = cmp.config.window.bordered(),
          -- documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-j>'] = cmp.mapping.select_next_item(),
          ['<C-k>'] = cmp.mapping.select_prev_item(),
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<CR>'] = cmp.mapping.confirm({ select = false }),
          ['<Tab>'] = cmp.mapping.confirm({ select = true }),
          ['<C-Space>'] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'path' },
        }, {
          { name = 'buffer' },
        })
      })

      vim.keymap.set({'i'}, '<C-e>', function()
        if cmp.visible() then
          cmp.abort()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-o>$', true, false, true), 'n', true)
        end
      end, { desc = 'Cancel completion or move to the end of line', silent = true })
    end
  },
-- }}}
-- {{{ treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function ()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = { "lua", "vim", "vimdoc", "python", "yaml", "fish", "markdown" },
        sync_install = false,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false
        },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<A-k>",
            node_incremental = "<A-k>",
            scope_incremental = false,
            node_decremental = "<A-j>",
          },
        }
      })
    end
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    config = function()
      require'nvim-treesitter.configs'.setup {
        textobjects = {
          select = {
            enable = true,
            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@call.outer",
              ["ic"] = "@call.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["ak"] = "@block.outer",
              ["ik"] = "@block.inner",
              -- ["as"] = "@statement.outer",
              -- ["is"] = "@statement.inner",
              -- ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
            },
            -- include_surrounding_whitespace = true,
          },
        },
      }
    end
  },
  -- autoclose end, fi, etc.
  {
    'RRethy/nvim-treesitter-endwise',
    config = function()
      require('nvim-treesitter.configs').setup {
        endwise = {
          enable = true,
        },
      }
    end,
  },
  -- commenting
  { 'numToStr/Comment.nvim' },
-- }}}
-- {{{ surround / autocomplete (, {, [
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = function()
      require'nvim-autopairs'.setup{}
      local npairs = require'nvim-autopairs'
      local Rule = require'nvim-autopairs.rule'
      local cond = require 'nvim-autopairs.conds'

      local brackets = { { '(', ')' }, { '[', ']' }, { '{', '}' } }
      npairs.add_rules {
        -- Rule for a pair with left-side ' ' and right side ' '
        Rule(' ', ' ')
          -- Pair will only occur if the conditional function returns true
          :with_pair(function(opts)
            -- We are checking if we are inserting a space in (), [], or {}
            local pair = opts.line:sub(opts.col - 1, opts.col)
            return vim.tbl_contains({
              brackets[1][1] .. brackets[1][2],
              brackets[2][1] .. brackets[2][2],
              brackets[3][1] .. brackets[3][2]
            }, pair)
          end)
          :with_move(cond.none())
          :with_cr(cond.none())
          -- We only want to delete the pair of spaces when the cursor is as such: ( | )
          :with_del(function(opts)
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local context = opts.line:sub(col - 1, col + 2)
            return vim.tbl_contains({
              brackets[1][1] .. '  ' .. brackets[1][2],
              brackets[2][1] .. '  ' .. brackets[2][2],
              brackets[3][1] .. '  ' .. brackets[3][2]
            }, context)
          end)
      }
      -- For each pair of brackets we will add another rule
      for _, bracket in pairs(brackets) do
        npairs.add_rules {
          -- Each of these rules is for a pair with left-side '( ' and right-side ' )' for each bracket type
          Rule(bracket[1] .. ' ', ' ' .. bracket[2])
            :with_pair(cond.none())
            :with_move(function(opts) return opts.char == bracket[2] end)
            :with_del(cond.none())
            :use_key(bracket[2])
            -- Removes the trailing whitespace that can occur without this
            :replace_map_cr(function(_) return '<C-c>2xi<CR><C-c>O' end)
        }
      end
    end
  },
  {
    'abecodes/tabout.nvim',
    lazy = false,
    config = function()
      require('tabout').setup {
        tabkey = '<Tab>', -- key to trigger tabout, set to an empty string to disable
        backwards_tabkey = '<S-Tab>', -- key to trigger backwards tabout, set to an empty string to disable
        act_as_tab = true, -- shift content if tab out is not possible
        act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
        default_tab = '<C-t>', -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
        default_shift_tab = '<C-d>', -- reverse shift default action,
        enable_backwards = true, -- well ...
        completion = false, -- if the tabkey is used in a completion pum
        tabouts = {
          { open = "'", close = "'" },
          { open = '"', close = '"' },
          { open = '`', close = '`' },
          { open = '(', close = ')' },
          { open = '[', close = ']' },
          { open = '{', close = '}' }
        },
        ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
        exclude = {} -- tabout will ignore these filetypes
      }
    end,
    opt = true,  -- Set this to true if the plugin is optional
    event = 'InsertCharPre', -- Set the event to 'InsertCharPre' for better compatibility
    priority = 1000,
  },
  {
    'Wansmer/treesj',
    keys = { '<leader><leader>m', '<leader><leader>j', '<leader><leader>s' },
    opts = {
    },
    config = function()
      local treesj = require('treesj')
      treesj.setup({
        use_default_keymaps = false,
      })
      vim.keymap.set('n', '<leader><leader>m', treesj.toggle)
      vim.keymap.set('n', '<leader><leader>s', treesj.split)
      vim.keymap.set('n', '<leader><leader>j', treesj.join)
    end
  },
  {
    'machakann/vim-sandwich',
    config = function()
      vim.api.nvim_command("runtime macros/sandwich/keymap/surround.vim")
      -- remove unneeded mappings which cause 's' command delay
      for _, mapping in ipairs({ 'sa', 'sr', 'srb', 'sd', 'sdb' }) do
        pcall(vim.keymap.del, 'n', mapping)
        pcall(vim.keymap.del, 'v', mapping)
      end
    end
  },
  -- }}}
-- {{{ easymotions
  {
    'smoka7/hop.nvim',
    config = function ()
      local hop = require('hop')
      local directions = require('hop.hint').HintDirection

      hop.setup({ keys = 'etovxqpdygfblzhckisuran' })

      vim.keymap.set('', 'f', function() hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true }) end, { desc = "Hop to letter", remap=true })
      vim.keymap.set('', 'F', function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true }) end, { desc = "Hop backwards to letter", remap=true })
      vim.keymap.set('', 't', function() hop.hint_char1({ direction = directions.AFTER_CURSOR, hint_offset = -1, current_line_only = true }) end, { desc = "Hop till letter", remap=true })
      vim.keymap.set('', 'T', function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, hint_offset = 1, current_line_only = true }) end, { desc = "Hop backwards till letter", remap=true })
      vim.keymap.set('', '<leader>s', function() hop.hint_char2() end, { desc = "Hop to 2-char sequence", remap=true })
      vim.keymap.set('', '<leader><leader>w', function() hop.hint_words({ direction = directions.AFTER_CURSOR }) end, { desc = "Hop to word", remap=true })
      vim.keymap.set('', '<leader><leader>b', function() hop.hint_words({ direction = directions.BEFORE_CURSOR }) end, { desc = "Hop backwards to word", remap=true })
      vim.keymap.set('', '<leader><leader>j', function() hop.hint_lines_skip_whitespace({ direction = directions.AFTER_CURSOR }) end, { desc = "Hop to line", remap=true })
      vim.keymap.set('', '<leader><leader>k', function() hop.hint_lines_skip_whitespace({ direction = directions.BEFORE_CURSOR }) end, { desc = "Hop backwards to line", remap=true })
    end
  },
-- }}}
-- {{{ tpope and similar
  -- auto-set shiftwidth, tabindent, etc
  { 'tpope/vim-sleuth', config = function() end },
  -- improved '.' repeating
  { 'tpope/vim-repeat', config = function() end },
  -- SudoWrite, etc.
  { 'tpope/vim-eunuch', config = function() end },
  -- change options with yo*, etc
  { 'tpope/vim-unimpaired', config = function()
    -- toggle all columns on the left to allow manual mulitline copy
    vim.keymap.set('n', 'yom', function()
      if vim.opt_local.number:get() then
        vim.opt_local.signcolumn = 'no'
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
      else
        vim.opt_local.signcolumn = 'yes'
        vim.opt_local.number = true
        vim.opt_local.relativenumber = true
      end
    end, { desc = "Toggle signcolumn" })
  end },
-- }}}
-- {{{ telescope
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-ui-select.nvim'
    },
    config = function ()
      require("telescope").setup({
        defaults = {
          vimgrep_arguments = {
            -- all required except `--smart-case`
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            -- add your options
            "--hidden",
          }
        }
      })
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
      vim.keymap.set('n', '<leader>fg', builtin.git_files, { desc = 'Telescope find git files' })
      vim.keymap.set('n', '<leader>g', builtin.live_grep, { desc = 'Telescope live grep' })
      vim.keymap.set('n', '<leader>b', builtin.buffers, { desc = 'Telescope buffers' })
      vim.keymap.set('n', '<leader>c', builtin.commands, { desc = 'Telescope commands' })
      vim.keymap.set('n', '<leader>fs', builtin.lsp_workspace_symbols, { desc = 'Telescope workspace symbols' })
      vim.keymap.set('n', '<leader>t', builtin.builtin, { desc = 'Telescope itself' })
      vim.keymap.set('n', '<leader>fp', require'telescope'.extensions.projects.projects, { desc = 'Telescope projects' })
      vim.keymap.set('n', '<C-p>', builtin.oldfiles, { desc = 'Telescope previous files' })
    end
  },
  {
    'ahmedkhalf/project.nvim',
    config = function ()
      require('telescope').load_extension('projects')
      require("project_nvim").setup {
        detection_methods = { "lsp", "pattern" },
      }
    end
  },
-- }}}
-- {{{ syntaxes
  {
    'neo4j-contrib/cypher-vim-syntax',
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'cypher' },
        desc = 'Set commentstring for cypher files',
        group = vim.api.nvim_create_augroup('my-cypher-autocmds', { clear = true }),
        callback = function()
          vim.opt_local.commentstring = '// %s'
        end,
      })
    end,
  },
-- }}}
  -- {
  --   "benlubas/molten-nvim",
  --   version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
  --   build = ":UpdateRemotePlugins",
  --   init = function()
  --     -- these are examples, not defaults. Please see the readme
  --     -- vim.g.molten_image_provider = "image.nvim"
  --     vim.g.molten_output_win_max_height = 20
  --     vim.g.molten_virt_text_output = true

  --     vim.keymap.set("v", "<leader>e", ":<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "evaluate visual selection" })
  --     vim.keymap.set("n", "<leader>e", ":MoltenEvaluateOperator<CR>", { silent = true, desc = "evaluate visual selection" })
  --     vim.keymap.set('n', '<leader>mo', ':noautocmd MoltenEnterOutput<CR>', { desc = 'Enter Molten output window', silent = true })
  --     vim.keymap.set('n', '<leader>r', ':MoltenReevaluateCell<CR>', { desc = 'Revaluate cell', silent = true })
  --   end,
  -- },
}
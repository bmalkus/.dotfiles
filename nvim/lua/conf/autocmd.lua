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
    local line, _ = unpack(vim.api.nvim_buf_get_mark(0, '"'))
    if line > 1 and line < vim.api.nvim_buf_line_count(0) then
      vim.cmd('exe "normal! g`\\\""')
    end
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { "markdown" },
  desc = 'Set spell check for markdown files',
  group = my_au_grp,
  callback = function()
    vim.wo.spell = true
    vim.wo.wrap = true
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { "json" },
  desc = 'Set formatprg for json files',
  group = my_au_grp,
  callback = function()
    vim.bo.formatprg = 'jq'
  end,
})

local L = require"conf.local"

-- autoformat python files

if L.autoformat_python then
  vim.api.nvim_create_autocmd({ 'BufWritePost' }, { pattern = { "*.py", "*.pyi" }, group = my_au_grp, command = 'Black' })
  vim.api.nvim_create_autocmd({ 'BufWritePost' }, { pattern = { "*.py", "*.pyi" }, group = my_au_grp, command = 'Isort' })
end

-- autosave

if L.autosave then
  local function get_save_buf_fn(buf)
    return function()
      vim.schedule(function()
        vim.api.nvim_buf_call(buf, function()
          vim.cmd("silent! noautocmd write")
          require('lualine').refresh()
        end)
      end)
    end
  end

  local delay_write_timers = {}
  local autosave_au_grp = vim.api.nvim_create_augroup('autosave-au', { clear = true })

  vim.api.nvim_create_autocmd({
    'BufEnter',
    'FocusGained',
  }, {
    desc = 'Automatically check files for external changes',
    group = autosave_au_grp,
    callback = function()
      vim.cmd('checktime')
    end,
  })

  vim.api.nvim_create_autocmd({
    'InsertLeave',
    'TextChanged',
  }, {
    desc = 'Autosave',
    group = autosave_au_grp,
    callback = function()
      if vim.bo.modifiable and vim.bo.buftype == '' then
        local buf = vim.api.nvim_get_current_buf()
        local timer = delay_write_timers[buf]
        if delay_write_timers[buf] == nil then
          delay_write_timers[buf] = vim.uv.new_timer()
          timer = delay_write_timers[buf]
        else
          timer:stop()
        end
        timer:start(L.autosave_delay, 0, get_save_buf_fn(buf))
      end
    end,
  })

  vim.api.nvim_create_autocmd({
    'BufLeave',
    'FocusLost',
  }, {
    desc = 'Autosave',
    group = autosave_au_grp,
    callback = function()
      if vim.bo.modifiable and vim.bo.buftype == '' then
        if vim.fn.getbufinfo(0)[1] ~= nil and vim.fn.getbufinfo(0)[1].changed == 1 then
          vim.cmd("silent! noautocmd write")
          require('lualine').refresh()
          local buf = vim.api.nvim_get_current_buf()
          local timer = delay_write_timers[buf]
          if timer ~= nil then
            timer:stop()
          end
        end
      end
    end,
  })
end

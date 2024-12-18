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

-- autosave {{{

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

-- }}}

-- golden-ratio {{{

local function find_vertical_parallels_smart(winnr)-- {{{
  if winnr == 0 then
    winnr = vim.api.nvim_get_current_win()
  end

  local conf = vim.api.nvim_win_get_config(winnr)
  if conf.relative ~= "" then
    return {}
  end

  -- Current window's position and size
  local crow, ccol = unpack(vim.api.nvim_win_get_position(winnr))
  local cwidth = vim.api.nvim_win_get_width(winnr)
  local cheight = vim.api.nvim_win_get_height(winnr)

  -- Current window edges
  local current_left   = ccol
  local current_right  = ccol + cwidth
  local current_top    = crow
  local current_bottom = crow + cheight

  local wins = vim.api.nvim_tabpage_list_wins(0)

  -- Find vertical parallels (either entirely above or below)
  local vertical_parallels = {}

  for _, w in ipairs(wins) do
    -- exclude current
    if w == winnr then
      goto continue
    end

    -- exclude floating windows
    local wconf = vim.api.nvim_win_get_config(w)
    if wconf.relative ~= "" then
      goto continue
    end

    -- exclude non-modifiable
    if not vim.bo[vim.api.nvim_win_get_buf(w)].modifiable then
      goto continue
    end

    local row, col = unpack(vim.api.nvim_win_get_position(w))
    local width = vim.api.nvim_win_get_width(w)
    local height = vim.api.nvim_win_get_height(w)

    local w_left   = col
    local w_right  = col + width
    local w_top    = row
    local w_bottom = row + height

    -- Check horizontal overlap
    local horizontal_overlap = not (w_right <= current_left or w_left >= current_right)

    if horizontal_overlap then
      -- Above if bottom <= current_top
      -- Below if top >= current_bottom
      if w_bottom <= current_top or w_top >= current_bottom then
        table.insert(vertical_parallels, {
          win = w,
          left = w_left,
          right = w_right,
          top = w_top,
          bottom = w_bottom
        })
      end
    end
    ::continue::
  end

  -- If no vertical parallels, just return empty
  if #vertical_parallels == 0 then
    return {}
  end

  -- Group these windows into columns based on horizontal overlap
  -- Sort by left coordinate for stable grouping
  table.sort(vertical_parallels, function(a, b)
    return (a.right - a.left) < (b.right - b.left)
  end)

  local columns = {}

  for _, info in ipairs(vertical_parallels) do
    local placed = false
    -- Try to place this window into an existing column if horizontally overlapping
    for _, col in ipairs(columns) do
      for _, cinfo in ipairs(col) do
        -- Check if horizontally they overlap at all
        local overlap = not (info.right <= cinfo.left or info.left >= cinfo.right)
        if overlap then
          table.insert(col, info)
          placed = true
          break
        end
      end
      if placed then break end
    end
    -- If not placed, start a new column
    if not placed then
      table.insert(columns, {info})
    end
  end

  -- Now we have one or more columns
  -- Decide which windows to return based on the heuristic:
  -- 1) If there's only one column, return all windows in it.
  -- 2) If multiple columns:
  --    - If any column has multiple vertically stacked windows, prefer that column and return all in it.
  --    - If all columns have a single window, return only the first column's single window.

  if #columns == 1 then
    -- Just one column, return all windows in it
    local res = {}
    for _, wininfo in ipairs(columns[1]) do
      table.insert(res, wininfo.win)
    end
    return res
  else
    -- Multiple columns
    -- Check for columns with vertical stacks:
    -- A vertical stack means more than one window that share a significant vertical alignment.
    -- For simplicity, if a column has more than one window, we consider it a vertical stack.
    local stacked_columns = {}
    for _, col in ipairs(columns) do
      if #col > 1 then
        table.insert(stacked_columns, col)
      end
    end

    if #stacked_columns > 0 then
      -- If there's at least one stacked column, return all windows from the first stacked column
      -- (assuming user wants the left-most stacked column if multiple).
      table.sort(stacked_columns, function(a, b)
        return #a > #b
      end)
      local res = {}
      for _, wininfo in ipairs(stacked_columns[1]) do
        table.insert(res, wininfo.win)
      end
      return res
    else
      -- No stacked columns; all columns have single windows side by side
      -- Return just one of them (the left-most one)
      -- If the user wants a single representative in this scenario, pick the first column's first window
      local first_column = columns[1]
      return { first_column[1].win }
    end
  end
end-- }}}

local function find_horizontal_parallels_smart(winnr)-- {{{
  if winnr == 0 then
    winnr = vim.api.nvim_get_current_win()
  end

  local conf = vim.api.nvim_win_get_config(winnr)
  if conf.relative ~= "" then
    return {}
  end

  -- Current window's position and size
  local crow, ccol = unpack(vim.api.nvim_win_get_position(winnr))
  local cwidth = vim.api.nvim_win_get_width(winnr)
  local cheight = vim.api.nvim_win_get_height(winnr)

  -- Current window edges
  local current_left   = ccol
  local current_right  = ccol + cwidth
  local current_top    = crow
  local current_bottom = crow + cheight

  local wins = vim.api.nvim_tabpage_list_wins(0)

  -- Find horizontal parallels (either entirely to the left or right)
  local horizontal_parallels = {}

  for _, w in ipairs(wins) do
    -- exclude current
    if w == winnr then
      goto continue
    end

    -- exclude floating windows
    local wconf = vim.api.nvim_win_get_config(w)
    if wconf.relative ~= "" then
      goto continue
    end

    -- exclude non-modifiable
    if not vim.bo[vim.api.nvim_win_get_buf(w)].modifiable then
      goto continue
    end

    local row, col = unpack(vim.api.nvim_win_get_position(w))
    local width = vim.api.nvim_win_get_width(w)
    local height = vim.api.nvim_win_get_height(w)

    local w_left   = col
    local w_right  = col + width
    local w_top    = row
    local w_bottom = row + height

    -- Check horizontal overlap
    local vertical_overlap = not (w_bottom <= current_top or w_top >= current_bottom)
    -- local horizontal_overlap = not (w_right <= current_left or w_left >= current_right)

    if vertical_overlap then
      -- Above if bottom <= current_top
      -- Below if top >= current_bottom
      if w_right <= current_left or w_left >= current_right then
        table.insert(horizontal_parallels, {
          win = w,
          left = w_left,
          right = w_right,
          top = w_top,
          bottom = w_bottom
        })
      end
    end
    ::continue::
  end

  -- If no vertical parallels, just return empty
  if #horizontal_parallels == 0 then
    return {}
  end

  -- Group these windows into columns based on horizontal overlap
  -- Sort by left coordinate for stable grouping
  table.sort(horizontal_parallels, function(a, b)
    return (a.bottom - a.top) < (b.bottom - b.top)
  end)

  local rows = {}

  for _, info in ipairs(horizontal_parallels) do
    local placed = false
    -- Try to place this window into an existing row if horizontally overlapping
    for _, row in ipairs(rows) do
      for _, rinfo in ipairs(row) do
        -- Check if vertically they overlap at all
        local overlap = not (info.bottom <= rinfo.top or info.top >= rinfo.bottom)
        if overlap then
          table.insert(row, info)
          placed = true
          break
        end
      end
      if placed then
        break
      end
    end
    -- If not placed, start a new column
    if not placed then
      table.insert(rows, {info})
    end
  end

  -- Now we have one or more columns
  -- Decide which windows to return based on the heuristic:
  -- 1) If there's only one column, return all windows in it.
  -- 2) If multiple columns:
  --    - If any column has multiple vertically stacked windows, prefer that column and return all in it.
  --    - If all columns have a single window, return only the first column's single window.

  if #rows == 1 then
    -- Just one column, return all windows in it
    local res = {}
    for _, wininfo in ipairs(rows[1]) do
      table.insert(res, wininfo.win)
    end
    return res
  else
    -- Multiple rows
    -- Check for columns with vertical stacks:
    -- A vertical stack means more than one window that share a significant vertical alignment.
    -- For simplicity, if a column has more than one window, we consider it a vertical stack.
    local stacked_rows = {}
    for _, row in ipairs(rows) do
      if #row > 1 then
        table.insert(stacked_rows, row)
      end
    end

    if #stacked_rows > 0 then
      -- If there's at least one stacked column, return all windows from the first stacked column
      -- (assuming user wants the left-most stacked column if multiple).
      table.sort(stacked_rows, function(a, b)
        return #a > #b
      end)
      local res = {}
      for _, wininfo in ipairs(stacked_rows[1]) do
        table.insert(res, wininfo.win)
      end
      return res
    else
      -- No stacked columns; all columns have single windows side by side
      -- Return just one of them (the left-most one)
      -- If the user wants a single representative in this scenario, pick the first column's first window
      local first_row = rows[1]
      return { first_row[1].win }
    end
  end
end-- }}}

local function resize_window_vertically(winnr, ratio)-- {{{
  if winnr == 0 then
    winnr = vim.api.nvim_get_current_win()
  end

  local parallels = find_vertical_parallels_smart(winnr)
  if #parallels == 0 then
    return
  end

  -- Get current window's height
  local cheight = vim.api.nvim_win_get_height(winnr)

  -- Calculate total height as sum of current window and parallel windows
  local total_height = cheight
  for _, win in ipairs(parallels) do
    total_height = total_height + vim.api.nvim_win_get_height(win) + 1
  end

  -- Calculate the new height for the current window
  local new_height = math.floor(total_height * ratio)

  -- Calculate remaining height
  local remaining_height = total_height - new_height
  if remaining_height <= 0 then
    print("Not enough space to resize other windows.")
    return
  end

  local heights_to_set = {}
  -- Evenly distribute the remaining height among parallel windows
  local per_window_height = math.floor(remaining_height / #parallels)
  for _, win in ipairs(parallels) do
    -- Ensure minimum width of 1
    local new_win_height = per_window_height > 0 and per_window_height or 1
    heights_to_set[win] = new_win_height
  end

  local all_wins = {winnr, unpack(parallels)}
  table.sort(all_wins, function(a, b)
    if vim.api.nvim_win_get_position(a)[2] < vim.api.nvim_win_get_position(b)[2] then
      return true
    elseif vim.api.nvim_win_get_position(a)[2] > vim.api.nvim_win_get_position(b)[2] then
      return false
    else
      return vim.api.nvim_win_get_position(a)[1] < vim.api.nvim_win_get_position(b)[1]
    end
  end)

  heights_to_set[winnr] = total_height - #parallels * per_window_height - 1

  for i = 1, #all_wins do
    vim.api.nvim_win_set_height(all_wins[i], heights_to_set[all_wins[i]])
  end
end-- }}}

local function resize_window_horizontally(winnr, ratio)-- {{{
  if winnr == 0 then
    winnr = vim.api.nvim_get_current_win()
  end

  local parallels = find_horizontal_parallels_smart(winnr)
  if #parallels == 0 then
    return
  end

  -- Get current window's width
  local cwidth = vim.api.nvim_win_get_width(winnr)

  -- Calculate total width as sum of current window and parallel windows
  local total_width = cwidth
  for _, win in ipairs(parallels) do
    total_width = total_width + vim.api.nvim_win_get_width(win) + 1
  end

  -- Calculate the new width for the current window
  local new_width = math.floor(total_width * ratio)

  -- Calculate remaining width
  local remaining_width = total_width - new_width
  if remaining_width <= 0 then
    print("Not enough space to resize other windows.")
    return
  end

  local widths_to_set = {}
  -- Evenly distribute the remaining width among parallel windows
  local per_window_width = math.floor(remaining_width / #parallels)
  for _, win in ipairs(parallels) do
    -- Ensure minimum width of 1
    local new_win_width = per_window_width > 0 and per_window_width or 1
    widths_to_set[win] = new_win_width
  end

  local all_wins = {winnr, unpack(parallels)}
  table.sort(all_wins, function(a, b)
    if vim.api.nvim_win_get_position(a)[1] < vim.api.nvim_win_get_position(b)[1] then
      return true
    elseif vim.api.nvim_win_get_position(a)[1] > vim.api.nvim_win_get_position(b)[1] then
      return false
    else
      return vim.api.nvim_win_get_position(a)[2] < vim.api.nvim_win_get_position(b)[2]
    end
  end)

  widths_to_set[winnr] = total_width - #parallels * per_window_width - 1

  for i = 1, #all_wins do
    vim.api.nvim_win_set_width(all_wins[i], widths_to_set[all_wins[i]])
  end
end-- }}}

local function resize_last_window()-- {{{
  -- not a perfect approach, but works pretty well, would require traversal of the layout tree
  local last_win = vim.fn.win_getid(vim.fn.winnr('#'))
  local vparallels = find_vertical_parallels_smart(last_win)
  resize_window_vertically(last_win, 1 / (#vparallels + 1))
  local hparallels = find_horizontal_parallels_smart(last_win)
  resize_window_horizontally(last_win, 1 / (#hparallels + 1))
end-- }}}

if L.golden_ratio then

  local golden_ratio_au = vim.api.nvim_create_augroup('golden_ratio_au', { clear = true })
  vim.api.nvim_create_autocmd({
    'BufEnter',
    'WinEnter',
  }, {
    desc = 'Automatically resize windows to golden ratio',
    group = golden_ratio_au,
    callback = function()
      if not vim.bo.modifiable then
        return
      end
      if vim.bo[vim.api.nvim_win_get_buf(vim.fn.win_getid(vim.fn.winnr('#')))].modifiable then
        local conf = vim.api.nvim_win_get_config(0)
        if conf.relative == "" then
          resize_last_window()
        end
      end
      resize_window_horizontally(0, 1 / 1.618)
      resize_window_vertically(0, 1 / 1.618)
    end,
  })

end

-- }}}

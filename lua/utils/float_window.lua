local M = {}

function M.create(opts)
  opts = opts or {}

  -- 配置
  local config = {
    width_percent = opts.width or 0.8,
    height_percent = opts.height or 0.8,
    border = opts.border or "rounded",
    title = opts.title,
    winblend = opts.winblend or 10,
    relative = opts.relative or "editor",
    focusable = opts.focusable ~= false,
    enter = opts.enter ~= false,
    filetype = opts.filetype,
    buftype = opts.buftype or "nofile",
    bufhidden = opts.bufhidden or "wipe",
    modifiable = opts.modifiable ~= false,
    readonly = opts.readonly or false,
    wrap = opts.wrap ~= false,
    linebreak = opts.linebreak or false,
    spell = opts.spell or false,
  }

  -- 获取尺寸
  local ui = vim.api.nvim_list_uis()[1]
  local editor_width, editor_height
  if ui then
    editor_width = ui.width
    editor_height = ui.height
  else
    editor_width = vim.o.columns
    editor_height = vim.o.lines
  end

  -- 计算窗口
  local win_width = math.floor(editor_width * config.width_percent)
  local win_height = math.floor(editor_height * config.height_percent)
  win_width = math.max(20, math.min(win_width, editor_width - 4))
  win_height = math.max(10, math.min(win_height, editor_height - 4))

  local col = math.floor((editor_width - win_width) / 2)
  local row = math.floor((editor_height - win_height) / 2)

  -- 创建缓冲区
  local buf = vim.api.nvim_create_buf(false, true)

  -- 设置缓冲区选项
  local bo = vim.bo[buf]
  bo.buftype = config.buftype
  bo.bufhidden = config.bufhidden
  bo.modifiable = config.modifiable
  bo.readonly = config.readonly

  if config.filetype then
    bo.filetype = config.filetype
  end

  -- 创建窗口
  local win = vim.api.nvim_open_win(buf, config.enter, {
    relative = config.relative,
    width = win_width,
    height = win_height,
    col = col,
    row = row,
    style = "minimal",
    border = config.border,
    title = config.title,
    zindex = opts.zindex or 50,
    focusable = config.focusable,
  })

  -- 设置窗口选项
  local wo = vim.wo[win]
  wo.winblend = config.winblend
  wo.winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"
  wo.number = opts.number or false
  wo.relativenumber = opts.relativenumber or false
  wo.cursorline = opts.cursorline or false
  wo.colorcolumn = opts.colorcolumn or ""
  wo.wrap = config.wrap
  wo.linebreak = config.linebreak
  wo.spell = config.spell

  -- 创建对象
  local obj = {
    win = win,
    buf = buf,
    width = win_width,
    height = win_height,
    col = col,
    row = row,
    config = config,
  }

  -- 方法定义
  function obj:close(force)
    force = force or false
    if vim.api.nvim_win_is_valid(self.win) then
      vim.api.nvim_win_close(self.win, force)
    end
    if vim.api.nvim_buf_is_valid(self.buf) then
      vim.api.nvim_buf_delete(self.buf, { force = force })
    end
  end

  function obj:set_content(content, opts)
    opts = opts or {}
    local start = opts.start or 0
    local end_ = opts.end_ or -1
    local clear_first = opts.clear_first or false

    -- 转换内容
    local lines
    if type(content) == "string" then
      lines = vim.split(content, "\n")
    elseif type(content) == "table" then
      lines = content
    else
      vim.notify("内容必须是字符串或行数组", vim.log.levels.ERROR)
      return false
    end

    -- 清空缓冲区
    if clear_first then
      self:clear()
    end

    -- 临时启用修改（如果被禁用）
    local was_modifiable = vim.bo[self.buf].modifiable
    local was_readonly = vim.bo[self.buf].readonly
    local should_restore = false

    if not was_modifiable then
      vim.bo[self.buf].modifiable = true
      should_restore = true
    end
    if was_readonly then
      vim.bo[self.buf].readonly = false
      should_restore = true
    end

    -- 设置内容
    local success, err = pcall(function()
      vim.api.nvim_buf_set_lines(self.buf, start, end_, false, lines)
    end)

    -- 恢复状态
    if should_restore then
      if not was_modifiable then
        vim.bo[self.buf].modifiable = false
      end
      if was_readonly then
        vim.bo[self.buf].readonly = true
      end
    end

    if not success then
      vim.notify("设置内容失败: " .. tostring(err), vim.log.levels.ERROR)
    end

    return success
  end

  function obj:append(content)
    local lines
    if type(content) == "string" then
      lines = vim.split(content, "\n")
    else
      lines = content
    end

    local current_lines = vim.api.nvim_buf_line_count(self.buf)
    return self:set_content(lines, { start = current_lines })
  end

  function obj:clear()
    local was_modifiable = vim.bo[self.buf].modifiable
    local was_readonly = vim.bo[self.buf].readonly

    if not was_modifiable then
      vim.bo[self.buf].modifiable = true
    end
    if was_readonly then
      vim.bo[self.buf].readonly = false
    end

    local success = pcall(vim.api.nvim_buf_set_lines, self.buf, 0, -1, false, {})

    if not was_modifiable then
      vim.bo[self.buf].modifiable = false
    end
    if was_readonly then
      vim.bo[self.buf].readonly = true
    end

    return success
  end

  function obj:set_buf_option(name, value)
    vim.bo[self.buf][name] = value
  end

  function obj:set_win_option(name, value)
    vim.wo[self.win][name] = value
  end

  function obj:get_buf_option(name)
    return vim.bo[self.buf][name]
  end

  function obj:get_win_option(name)
    return vim.wo[self.win][name]
  end

  function obj:set_keymap(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.buffer = self.buf
    vim.keymap.set(mode, lhs, rhs, opts)
  end

  function obj:set_autocmd(event, callback, opts)
    opts = opts or {}
    opts.buffer = self.buf
    vim.api.nvim_create_autocmd(event, opts)
  end

  -- 设置只读相关的方法
  function obj:make_readonly()
    vim.bo[self.buf].modifiable = false
    vim.bo[self.buf].readonly = true
  end

  function obj:make_writable()
    vim.bo[self.buf].modifiable = true
    vim.bo[self.buf].readonly = false
  end

  -- 别名
  obj.set_lines = obj.set_content

  obj:set_keymap("n", "q", function()
    obj:close()
  end)
  obj:set_keymap("n", "<ESC>", function()
    obj:close()
  end)

  return obj
end

-- 便利函数
function M.preview(content, opts)
  opts = opts or {}

  local float = M.create({
    width = opts.width or 0.8,
    height = opts.height or 0.8,
    title = opts.title or "预览",
    filetype = opts.filetype,
    modifiable = false,
    readonly = true,
    border = opts.border,
  })

  if content then
    float:set_content(content)
  end

  return float
end

function M.input(prompt, callback, opts)
  opts = opts or {}

  local float = M.create({
    width = opts.width or 0.6,
    height = opts.height or 0.2,
    title = prompt,
    modifiable = true,
    readonly = false,
    border = opts.border,
  })

  -- 添加提交快捷键
  float:set_keymap("n", "<CR>", function()
    local lines = vim.api.nvim_buf_get_lines(float.buf, 0, -1, false)
    callback(table.concat(lines, "\n"))
    float:close()
  end)

  -- 自动聚焦到输入
  vim.api.nvim_set_current_win(float.win)

  return float
end

return M

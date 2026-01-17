-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- 删除默认键绑定
local function remove_default_keymap()
  vim.keymap.del("n", "<C-h>")
  vim.keymap.del("n", "<C-j>")
  vim.keymap.del("n", "<C-k>")
  vim.keymap.del("n", "<C-l>")

  -- 也检查其他模式
  local modes = { "n", "x" }
  for _, mode in ipairs(modes) do
    local mappings = vim.api.nvim_get_keymap(mode) -- normal 模式

    for _, map in ipairs(mappings) do
      -- 检查是否以 <leader><Tab> 开头
      if map.lhs:match("^ <Tab>") or map.lhs:match("^ <tab>") then
        -- 删除这个映射
        vim.keymap.del("n", map.lhs)
        print("已删除: " .. map.lhs)
      end
    end
  end
end

remove_default_keymap()

-- 当前文件符号跳转
local function current_file_symbol_jump()
  -- 有 LSP 连接，尝试使用 LSP 符号跳转
  local lsp_clients = vim.lsp.get_clients({ bufnr = 0 })
  if #lsp_clients > 0 then
    local ok, _ = pcall(require("telescope.builtin").lsp_document_symbols)
    if ok then
      return -- LSP 符号跳转成功，直接返回
    end
  end

  -- 尝试使用 Treesitter 符号跳转
  local ok, treesitter_parser = pcall(vim.treesitter.get_parser)
  if ok and treesitter_parser ~= nil then
    require("telescope.builtin").treesitter()
    return -- Treesitter 跳转成功
  end

  --[[
-- 尝试使用内置的标签跳转 (ctags)
local has_tags = false
if vim.fn.expand("%") ~= "" then
  local tag_result = vim.fn.taglist(vim.fn.expand("<cword>"))
  has_tags = tag_result and #tag_result > 0
end

if has_tags then
  -- 使用内置的标签跳转
  vim.cmd("normal! g]")
  return
end
--]]

  -- 最后回退到当前缓冲区模糊查找
  local ok, _ = pcall(require("telescope.builtin").current_buffer_fuzzy_find)
  if ok then
    return
  end

  -- 连模糊查找都失败了，显示提示信息
  vim.notify("没有可用的符号跳转功能", vim.log.levels.WARN)
end

-- 当前文件所在目录文件浏览器
local function current_file_browser(opts)
  opts = opts or {}

  -- 获取当前缓冲区信息
  local buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(buf)
  local buftype = vim.bo[buf].buftype

  -- 确定基础路径
  local base_path

  -- 情况1: 特殊缓冲区类型
  if buftype == "terminal" or buftype == "nofile" or buftype == "prompt" then
    base_path = vim.loop.cwd()

  -- 情况2: 有文件名的缓冲区
  elseif buf_name and buf_name ~= "" then
    base_path = vim.fn.fnamemodify(buf_name, ":h")

    -- 验证路径是否存在
    local stat = vim.loop.fs_stat(base_path)
    if not stat then
      base_path = vim.loop.cwd()
    end

  -- 情况3: 其他情况（新缓冲区等）
  else
    base_path = vim.loop.cwd()
  end

  -- 合并用户选项
  local final_opts = vim.tbl_deep_extend("force", {
    path = base_path,
    cwd = base_path,
  }, opts)

  -- 打开文件浏览器
  require("telescope").extensions.file_browser.file_browser(final_opts)

  -- 返回使用的路径（可用于调试）
  return base_path
end

-- 工程最近
local function workspace_recently_files()
  require("telescope.builtin").oldfiles({
    cwd = vim.loop.cwd(),
    cwd_only = true,
  })
end

local function last_buffer()
  -- 获取缓冲区列表
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })

  if #buffers <= 1 then
    -- 只有一个或没有缓冲区，不做任何事情
    vim.notify("没有其他缓冲区可以切换", vim.log.levels.INFO, {
      title = "缓冲区切换",
      timeout = 1000,
    })
    return
  end

  -- 切换到上一个缓冲区
  vim.cmd("e #")
end

vim.keymap.set("n", "<leader><tab>", last_buffer, { desc = "上一个缓冲区" })
vim.keymap.set("n", "<leader>bb", "<cmd>Telescope buffers<cr>", { desc = "缓冲区列表" })
vim.keymap.set("n", "<leader>ff", current_file_browser, { desc = "查找文件(当前目录)" })
vim.keymap.set("n", "<leader>pf", workspace_recently_files, { desc = "查找文件(工程)" })
vim.keymap.set("n", "<leader>sj", current_file_symbol_jump, { desc = "智能符号跳转" })

vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "实时搜索" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "帮助" })

-- 通知历史（使用内置功能）
vim.keymap.set("n", "<leader>fn", "<cmd>Telescope notify<cr>", { desc = "通知历史" })

-- 其他
vim.keymap.set("n", "<leader>fo", "<cmd>Telescope oldfiles<cr>", { desc = "最近文件" })
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope registers<cr>", { desc = "寄存器" })
vim.keymap.set("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "快捷键" })

-- Git
vim.keymap.set("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", { desc = "提交记录" })
vim.keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<cr>", { desc = "Git 状态" })

-- LSP
vim.keymap.set("n", "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "文档符号" })
vim.keymap.set("n", "<leader>lS", "<cmd>Telescope lsp_workspace_symbols<cr>", { desc = "工作区符号" })

vim.keymap.set("n", "<leader>ats", "<cmd>Telescope lsp_workspace_symbols<cr>", { desc = "工作区符号" })

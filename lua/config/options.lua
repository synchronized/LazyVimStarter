-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

local float = require("utils.float_window")

local function show_plugin_config(name)
  local plugin = require("lazy.core.config").plugins[name]
  if plugin then
    local content = vim.inspect(plugin.opts, { depth = 4 })
    float.create({ title = "插件配置详细信息" }):set_content(content)
  else
    vim.notify("插件未找到: " .. name)
  end
end

_G.sunday_create_float_window = show_plugin_config

-- 使用
--vim.cmd("lua sunday_show_plugin_config('nvim-tree')")
--- 运行这个命令
vim.api.nvim_create_user_command("SundayListPlugin", function()
  -- 检查 lazy.nvim 管理的插件
  local lazy = require("lazy")
  local stats = lazy.stats()

  -- 查看 nvim-cmp 是否在插件列表中
  local plugins = lazy.plugins()

  local content = {}
  table.insert(content, "总插件数:" .. stats.count)
  for _, plugin in ipairs(plugins) do
    table.insert(content, "plugin.name:" .. plugin.name)
  end
  float.create({ title = "插件列表" }):set_content(content)
end, {})

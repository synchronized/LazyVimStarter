return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "rcarriga/nvim-notify",
      "BurntSushi/ripgrep", -- 需要安装 ripgrep
      "sharkdp/fd", -- 需要安装 fd
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    opts = function(_, opts)
      local actions = require("telescope.actions")

      opts.defaults = opts.defaults or {}
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        -- 映射配置
        mappings = {
          i = {
            ["<Esc>"] = actions.close,
            ["<C-g>"] = actions.close,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
          },
          n = {
            ["q"] = actions.close,
            ["<C-g>"] = actions.close,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
          },
        },

        file_ignore_patterns = {
          "node_modules",
          ".git",
          "target",
          "build",
          "dist",
          ".cache",
          "%.o",
          "%.a",
          "%.out",
          "%.class",
          "%.pdf",
          "%.mkv",
          "%.mp4",
          "%.zip",
          "%.log",
        },
      })

      return opts
    end,
    config = function(_, opts)
      local telescope = require("telescope")

      -- 加载扩展
      telescope.setup(opts)
      telescope.load_extension("fzf")
      telescope.load_extension("notify")
    end,
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },

    config = function(_, opts)
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local fb_actions = telescope.extensions.file_browser.actions

      opts = vim.tbl_deep_extend("force", opts or {}, {
        extensions = {
          file_browser = {
            -- theme = "ivy",
            hide_parent_dir = true, -- 这个选项在某些版本中可用
            -- disables netrw and use telescope-file-browser in its place
            -- hijack_netrw = true,
            mappings = {
              i = {
                -- Insert 模式下的 Ctrl+h/Ctrl+l
                ["<C-g>"] = actions.close,
                ["<C-h>"] = fb_actions.goto_parent_dir,
                ["<C-l>"] = actions.select_default,
              },
              n = {
                -- Normal 模式下的 Ctrl+h/Ctrl+l
                ["<C-g>"] = actions.close,
                ["<C-h>"] = fb_actions.goto_parent_dir,
                ["<C-l>"] = actions.select_default,

                -- 可选：保留 hjkl 基础导航
                ["h"] = fb_actions.goto_parent_dir,
                ["l"] = actions.select_default,
                ["j"] = actions.move_selection_next,
                ["k"] = actions.move_selection_previous,
              },
            },
          },
        },
      })
      telescope.setup(opts)

      telescope.load_extension("file_browser")
    end,
  },
  {
    "nvim-telescope/telescope-frecency.nvim",
    -- install the latest stable version
    version = "*",
    config = function()
      require("telescope").load_extension("frecency")
    end,
  },
}

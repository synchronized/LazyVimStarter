return {
  "saghen/blink.cmp",
  -- optional: provides snippets for the snippet source
  dependencies = { "rafamadriz/friendly-snippets" },

  opts = function(_, opts)
    opts = opts or {}
    opts.keymap = opts.keymap or {}

    opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
      ["<C-k>"] = { "select_prev", "fallback_to_mappings" },
      ["<C-j>"] = { "select_next", "fallback_to_mappings" },
    })

    opts.cmdline = opts.cmdline or {}
    opts.cmdline.keymap = vim.tbl_deep_extend("force", opts.cmdline.keymap or {}, {
      -- recommended, as the default keymap will only show and select the next item
      ["<C-k>"] = { "select_prev", "fallback_to_mappings" },
      ["<C-j>"] = { "select_next", "fallback_to_mappings" },
    })

    return opts
  end,
}

return {
  -- brighten comments: tokyonight's default comment color is too close to
  -- the background to read comfortably
  {
    "folke/tokyonight.nvim",
    opts = {
      on_highlights = function(hl, c)
        hl.Comment = { fg = c.fg_dark, italic = true }
        -- default WinSeparator/border color is too close to bg to see pane splits
        hl.WinSeparator = { fg = c.blue, bg = "NONE" }
        hl.FloatBorder = { fg = c.blue, bg = "NONE" }
      end,
    },
  },
}

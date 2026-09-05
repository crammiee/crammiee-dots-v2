-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Soft-wrap LaTeX.
--
-- LazyVim sets `wrap = false` globally (lazyvim/config/options.lua) and turns it
-- back on only for text, plaintex, typst, gitcommit and markdown. A LaTeX file
-- is filetype `tex`; `plaintex` is plain TeX, a different thing. So .tex falls
-- through the list, and since a LaTeX paragraph is one very long logical line,
-- reading it means scrolling sideways.
--
-- Deliberately no `textwidth` here: that would hard-wrap and write real newlines
-- into the .tex. This is visual only -- the bytes on disk are untouched.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("wrap_tex", { clear = true }),
  pattern = { "tex", "latex", "bib" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true -- break between words, never mid-word
    vim.opt_local.breakindent = true -- wrapped rows keep the line's indent
  end,
})

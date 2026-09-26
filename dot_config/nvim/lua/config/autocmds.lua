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

-- Keep chezmoi's copy of nvim-written state in sync.
--
-- lazy-lock.json (rewritten by :Lazy update/sync/...) and lazyvim.json
-- (rewritten by :LazyExtras) are chezmoi-managed, but nvim edits them in $HOME,
-- so the repo copy goes stale and the next `chezmoi apply` offers to overwrite
-- the newer file with the older one. `chezmoi re-add` copies them back into the
-- source repo; it's a no-op when nothing changed. Committing stays manual.
-- LazyExtras fires no event, hence the VimLeavePre catch-all.
if vim.fn.executable("chezmoi") == 1 then
  local config = vim.fn.stdpath("config")
  local files = { config .. "/lazy-lock.json", config .. "/lazyvim.json" }
  local function re_add()
    return vim.system(vim.list_extend({ "chezmoi", "re-add" }, files))
  end
  local group = vim.api.nvim_create_augroup("chezmoi_lazy_sync", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "LazyInstall", "LazyUpdate", "LazySync", "LazyClean", "LazyRestore" },
    callback = function() re_add() end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function() re_add():wait(3000) end,
  })
end

-- Dim comments except the one under the cursor (see config/comment_focus.lua).
require("config.comment_focus").setup()

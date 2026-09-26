-- Dim comments, except the one under the cursor.
--
-- A terminal can't draw text at partial opacity, so "dim" means a colour
-- blended from Comment's fg towards Normal's bg. It is painted as an extmark
-- over every treesitter comment capture (and docstrings, which treesitter
-- tags @string.documentation) in the visible lines, at a priority
-- above treesitter's (100) so injected highlights inside comments (JSDoc
-- `@param` tags, parameter names, code spans) dim too. The comment block the
-- cursor sits in -- a /** */ block, or a run of // lines on consecutive rows --
-- is left alone and shows the normal colours.
--
-- Toggle: <leader>uk, or :CommentFocusToggle.

local M = {}

local ns = vim.api.nvim_create_namespace("comment_focus")
local HL = "CommentDim"
local PRIORITY = 200
-- how much of Comment's colour survives; 0 = invisible, 1 = unchanged
local STRENGTH = 0.45

M.enabled = true

---@param a integer 0xRRGGBB foreground
---@param b integer 0xRRGGBB background
---@param t number weight of `a`, 0..1
---@return integer
local function blend(a, b, t)
  local function ch(c, shift) return bit.band(bit.rshift(c, shift), 0xff) end
  local out = 0
  for _, shift in ipairs({ 16, 8, 0 }) do
    local v = math.floor(ch(a, shift) * t + ch(b, shift) * (1 - t) + 0.5)
    out = bit.bor(out, bit.lshift(v, shift))
  end
  return out
end

local function define_hl()
  local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  if not comment.fg or not normal.bg then
    vim.api.nvim_set_hl(0, HL, { link = "NonText" })
    return
  end
  vim.api.nvim_set_hl(0, HL, { fg = blend(comment.fg, normal.bg, STRENGTH), italic = comment.italic })
end

--- Comment ranges in rows [top, bot), merged across trees and adjacent rows.
---@param buf integer
---@param top integer 0-based
---@param bot integer 0-based, exclusive
---@return {[1]: integer, [2]: integer, [3]: integer, [4]: integer}[] sr, sc, er, ec
local function comment_ranges(buf, top, bot)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok or not parser then return {} end
  local ranges = {}
  parser:for_each_tree(function(tree, ltree)
    local query = vim.treesitter.query.get(ltree:lang(), "highlights")
    if not query then return end
    for id, node in query:iter_captures(tree:root(), buf, top, bot) do
      local name = query.captures[id]
      if name == "comment" or name:find("^comment%.") or name == "string.documentation" then
        ranges[#ranges + 1] = { node:range() }
      end
    end
  end)
  table.sort(ranges, function(a, b) return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]) end)

  -- Merge overlapping ranges and comment lines on consecutive rows into blocks,
  -- so focusing one // line lights up the whole run.
  local merged = {}
  for _, r in ipairs(ranges) do
    local last = merged[#merged]
    if last and r[1] <= last[3] + 1 then
      if r[3] > last[3] or (r[3] == last[3] and r[4] > last[4]) then
        last[3], last[4] = r[3], r[4]
      end
    else
      merged[#merged + 1] = { r[1], r[2], r[3], r[4] }
    end
  end
  return merged
end

---@param buf integer
local function clear(buf) vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1) end

local function refresh()
  local buf = vim.api.nvim_get_current_buf()
  clear(buf)
  if not M.enabled or vim.bo[buf].buftype ~= "" then return end

  local win = vim.api.nvim_get_current_win()
  local top = vim.fn.line("w0", win) - 1
  local bot = vim.fn.line("w$", win)
  local cur = vim.api.nvim_win_get_cursor(win)
  local crow = cur[1] - 1

  for _, r in ipairs(comment_ranges(buf, top, bot)) do
    local sr, sc, er, ec = r[1], r[2], r[3], r[4]
    local under_cursor = crow >= sr and crow <= er
    if not under_cursor then
      vim.api.nvim_buf_set_extmark(buf, ns, sr, sc, {
        end_row = er,
        end_col = ec,
        hl_group = HL,
        priority = PRIORITY,
        strict = false,
      })
    end
  end
end

function M.toggle(state)
  if state == nil then state = not M.enabled end
  M.enabled = state
  refresh()
end

function M.setup()
  define_hl()
  local group = vim.api.nvim_create_augroup("comment_focus", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_hl })

  local pending = false
  local function schedule()
    if pending then return end
    pending = true
    vim.defer_fn(function()
      pending = false
      refresh()
    end, 30)
  end
  vim.api.nvim_create_autocmd(
    { "BufEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI", "WinScrolled" },
    { group = group, callback = schedule }
  )
  -- only the current window is painted; wipe it when leaving so a split
  -- showing the same buffer doesn't keep a stale "focused" comment
  vim.api.nvim_create_autocmd("BufLeave", { group = group, callback = function(ev) clear(ev.buf) end })

  vim.api.nvim_create_user_command("CommentFocusToggle", function() M.toggle() end, {})
  local ok, Snacks = pcall(require, "snacks")
  if ok and Snacks.toggle then
    Snacks.toggle
      .new({ name = "Comment Focus", get = function() return M.enabled end, set = M.toggle })
      :map("<leader>uk")
  else
    vim.keymap.set("n", "<leader>uk", M.toggle, { desc = "Toggle Comment Focus" })
  end
  schedule()
end

return M

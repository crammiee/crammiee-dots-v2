-- :Claude <query>  — ask `claude -p` for code and write it into the buffer.
-- No range: inserts below the cursor line. With a range (:'<,'>Claude ...): replaces those lines.
local M = {}

local function strip_fences(text)
  text = text:gsub("^%s*```[%w_+-]*\n", ""):gsub("\n?```%s*$", "")
  return text
end

function M.run(opts)
  local query = opts.args
  if query == "" then
    return vim.notify("Usage: :Claude <query>", vim.log.levels.WARN)
  end

  local buf = vim.api.nvim_get_current_buf()
  local file = vim.fn.expand("%:t")
  local ft = vim.bo[buf].filetype
  local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

  -- s, e: 0-indexed, end-exclusive line range to replace (s == e means insert)
  local s, e, prompt
  local base = ("You are a code generator running inside Neovim. Output ONLY the raw code to "
    .. "insert: no explanations, no markdown fences. File: %s (filetype: %s). "
    .. "The full file is on stdin. "):format(file, ft)

  if opts.range > 0 then
    s, e = opts.line1 - 1, opts.line2
    local sel = table.concat(vim.api.nvim_buf_get_lines(buf, s, e, false), "\n")
    prompt = base
      .. ("Rewrite lines %d-%d according to the task. Output only the replacement "
        .. "for those lines.\nLines:\n%s\n\nTask: %s"):format(opts.line1, opts.line2, sel, query)
  else
    local row = vim.api.nvim_win_get_cursor(0)[1]
    s, e = row, row
    prompt = base .. ("The code will be inserted after line %d.\nTask: %s"):format(row, query)
  end

  vim.notify("Claude is thinking…")
  vim.system(
    { "claude", "-p", prompt },
    { stdin = content, text = true },
    vim.schedule_wrap(function(res)
      if res.code ~= 0 then
        return vim.notify("claude failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
      end
      local out = strip_fences(vim.trim(res.stdout))
      vim.api.nvim_buf_set_lines(buf, s, e, false, vim.split(out, "\n"))
      vim.notify("Claude: done")
    end)
  )
end

vim.api.nvim_create_user_command("Claude", M.run, { nargs = "*", range = true })
-- <leader>ai opens the command line with :Claude ready (with '<,'> in visual mode)
vim.keymap.set({ "n", "x" }, "<leader>ai", ":Claude ", { desc = "Ask Claude to write code" })

return M

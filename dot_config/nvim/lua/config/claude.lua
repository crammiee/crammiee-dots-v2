-- Ask `claude -p` for code and write it into the buffer.
--   :Claude <query>          insert below the cursor line
--   :'<,'>Claude <query>     replace the selected lines
--   <C-g>c in insert mode    replace the current `claude: <query>` comment line
local M = {}

local function clean(text)
  text = text:gsub("^%s*```[%w_+-]*\n", ""):gsub("\n?```%s*$", "")
  -- drop blank lines at the ends but keep the first line's indentation
  return (text:gsub("^%s*\n", ""):gsub("%s+$", ""))
end

local function base_prompt(buf)
  return ("You are a code generator running inside Neovim. Output ONLY the raw code to "
    .. "insert: no explanations, no markdown fences. File: %s (filetype: %s). "
    .. "The full file is on stdin. "):format(vim.fn.expand("%:t"), vim.bo[buf].filetype)
end

-- Runs claude in the background; on_done(lines) is called on the main loop.
local function ask(buf, prompt, on_done)
  local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  vim.notify("Claude is thinking…")
  vim.system(
    { "claude", "-p", prompt },
    { stdin = content, text = true },
    vim.schedule_wrap(function(res)
      if res.code ~= 0 then
        return vim.notify("claude failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
      end
      on_done(vim.split(clean(res.stdout), "\n"))
      vim.notify("Claude: done")
    end)
  )
end

function M.run(opts)
  local query = opts.args
  if query == "" then
    return vim.notify("Usage: :Claude <query>", vim.log.levels.WARN)
  end

  local buf = vim.api.nvim_get_current_buf()
  -- s, e: 0-indexed, end-exclusive line range to replace (s == e means insert)
  local s, e, prompt
  if opts.range > 0 then
    s, e = opts.line1 - 1, opts.line2
    local sel = table.concat(vim.api.nvim_buf_get_lines(buf, s, e, false), "\n")
    prompt = base_prompt(buf)
      .. ("Rewrite lines %d-%d according to the task. Output only the replacement "
        .. "for those lines.\nLines:\n%s\n\nTask: %s"):format(opts.line1, opts.line2, sel, query)
  else
    local row = vim.api.nvim_win_get_cursor(0)[1]
    s, e = row, row
    prompt = base_prompt(buf) .. ("The code will be inserted after line %d.\nTask: %s"):format(row, query)
  end

  ask(buf, prompt, function(lines)
    vim.api.nvim_buf_set_lines(buf, s, e, false, lines)
  end)
end

-- Inline: the current line holds `<comment> claude: <query>`; replace it with the code.
function M.inline()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
  local query = line:match("[Cc]laude:%s*(.-)%s*$")
  if not query or query == "" then
    return vim.notify("No `claude: <request>` on this line", vim.log.levels.WARN)
  end

  local prompt = base_prompt(buf)
    .. ("Line %d is a request comment:\n%s\nYour output replaces that line. Write it with "
      .. "no base indentation (start at column 0); it will be re-indented for you.\nTask: %s")
      :format(row, line, query)

  ask(buf, prompt, function(lines)
    -- strip any common leading indent, then indent to the request line's level
    local indent = line:match("^%s*")
    local min
    for _, l in ipairs(lines) do
      if l:find("%S") then
        local n = #l:match("^%s*")
        min = (min and math.min(min, n)) or n
      end
    end
    for i, l in ipairs(lines) do
      lines[i] = l:find("%S") and indent .. l:sub((min or 0) + 1) or ""
    end

    -- the request line may have moved if lines were added above it while waiting
    local cur = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local at = cur[row] == line and row or nil
    if not at then
      for i, l in ipairs(cur) do
        if l == line then
          at = i
          break
        end
      end
    end
    if not at then
      return vim.notify("Claude: request line was changed, not inserting", vim.log.levels.WARN)
    end
    vim.api.nvim_buf_set_lines(buf, at - 1, at, false, lines)
  end)
end

vim.api.nvim_create_user_command("Claude", M.run, { nargs = "*", range = true })
-- <leader>ai opens the command line with :Claude ready (with '<,'> in visual mode)
vim.keymap.set({ "n", "x" }, "<leader>ai", ":Claude ", { desc = "Ask Claude to write code" })
vim.keymap.set("i", "<C-g>c", M.inline, { desc = "Claude: replace `claude:` line with code" })

return M

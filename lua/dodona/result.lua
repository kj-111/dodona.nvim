local M = {}

local last, buffer
local generation = 0

local function text(value)
  if type(value) == "string" then
    return value
  end
  if type(value) ~= "table" or type(value.description) ~= "string" then
    return nil
  end
  if value.permission and value.permission ~= "student" then
    return nil
  end
  local description = value.description
  if value.format == "html" then
    local entities = { lt = "<", gt = ">", amp = "&", quot = '"', apos = "'", nbsp = " " }
    description = description:gsub("<br%s*/?>", "\n"):gsub("</p>", "\n"):gsub("<[^>]+>", "")
    description = description:gsub("&(%a+);", entities)
  end
  return description
end

local function list(value)
  return type(value) == "table" and value or {}
end

-- Render judge feedback as plain text; preserve whitespace in test values as escapes.
function M.render(submission)
  local lines = { "Dodona result", "" }
  local function add(value)
    if type(value) == "string" and value ~= "" then
      vim.list_extend(lines, vim.split(value, "\n", { plain = true }))
    end
  end
  add("Status: " .. (type(submission.status) == "string" and submission.status or "unknown"))
  add(text(submission.summary))
  if type(submission.url) == "string" then
    add(submission.url:gsub("%.json$", ""))
  end
  add("\nq: close   r: refresh\n")
  if submission.status == "queued" or submission.status == "running" then
    add("Still evaluating. Press r to refresh.")
    return lines
  end

  local result = submission.result
  if type(result) == "string" then
    local ok, decoded = pcall(vim.json.decode, result)
    if not ok then
      add("Could not decode detailed feedback. Open the result URL in your browser.")
      return lines
    end
    result = decoded
  end
  if type(result) ~= "table" or vim.islist(result) then
    add("No detailed feedback available. Open the result URL in your browser.")
    return lines
  end

  local passed, total, details = 0, 0, {}
  local function detail(value)
    if type(value) == "string" and value ~= "" then
      details[#details + 1] = value
    end
  end
  local function messages(node)
    for _, message in ipairs(list(node.messages)) do
      detail(text(message))
    end
  end
  local function walk(node, input, context)
    if type(node) ~= "table" then
      return
    end
    local data = list(node.data)
    input = type(data.stdin) == "string" and data.stdin or input
    context = text(node.description) or context
    messages(node)
    for _, test in ipairs(list(node.tests)) do
      if type(test) == "table" then
        total = total + 1
        if test.accepted == true then
          passed = passed + 1
        else
          detail("\nTest " .. total .. ": " .. (type(test.status) == "string" and test.status or "not accepted"))
          detail(text(test.description) or context)
          if input then
            detail("Input:    " .. vim.inspect(input))
          end
          if test.expected ~= nil and test.expected ~= vim.NIL then
            detail("Expected: " .. vim.inspect(test.expected))
          end
          if test.generated ~= nil and test.generated ~= vim.NIL then
            detail("Actual:   " .. vim.inspect(test.generated))
          end
        end
        messages(test)
      end
    end
    for _, group in ipairs(list(node.groups)) do
      walk(group, input, context)
    end
  end
  walk(result)
  local description = text(result.description)
  if description ~= text(submission.summary) then
    add(description)
  end
  if total > 0 then
    add(string.format("Tests: %d/%d passed", passed, total))
  end
  if type(result.score) == "number" and type(result.maximal_score) == "number" then
    add(string.format("Score: %g/%g", result.score, result.maximal_score))
  end
  local duration = list(result.runtime_metrics).wall_time
  if type(duration) == "number" or type(duration) == "string" then
    duration = tonumber(duration)
    if duration then
      add(string.format("Runtime: %.3f ms", duration * 1000))
    end
  end
  for _, annotation in ipairs(list(result.annotations)) do
    if type(annotation) == "table" and type(annotation.text) == "string" then
      local row = type(annotation.row) == "number" and ("Line " .. (annotation.row + 1) .. ": ") or ""
      detail(row .. annotation.text)
    end
  end
  if #details > 0 then
    add("\nDetails")
    for _, value in ipairs(details) do
      add(value)
    end
  end
  return lines
end

function M.remember(url, config)
  last = { url = url, config = config }
end

local function write(buf, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
end

function M.show(id)
  local target = last
  if id and id ~= "" then
    if not id:match("^%d+$") then
      vim.notify("DodonaResult expects a numeric submission ID", vim.log.levels.ERROR)
      return
    end
    target = { url = "/submissions/" .. id .. ".json", config = require("dodona").config }
  end
  if not target then
    vim.notify("No submission yet this session - use :DodonaSubmit or :DodonaResult <id>", vim.log.levels.INFO)
    return
  end

  if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
    buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buffer, "dodona://result")
    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].filetype = "dodona-result"
    vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buffer, silent = true, desc = "Close Dodona result" })
  end
  local buf = buffer
  vim.keymap.set("n", "r", function()
    M.show(id)
  end, { buffer = buf, silent = true, desc = "Refresh Dodona result" })
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    vim.cmd("botright vsplit")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_win_set_width(win, math.max(20, math.min(80, math.floor(vim.o.columns * 0.45))))
  else
    vim.api.nvim_set_current_win(win)
  end
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = false
  vim.wo[win].spell = false
  vim.wo[win].foldenable = false
  write(buf, { "Dodona result", "", "Loading...", "", "q: close   r: refresh" })

  generation = generation + 1
  local current = generation
  require("dodona.api").request(target.url, { config = target.config }, function(submission, err)
    if current ~= generation or not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    if not submission then
      write(buf, vim.split("Dodona result\n\nCould not load result: " .. err .. "\n\nq: close   r: retry", "\n"))
      return
    end
    write(buf, M.render(submission))
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_win_set_cursor(win, { 1, 0 })
    end
  end)
end

return M

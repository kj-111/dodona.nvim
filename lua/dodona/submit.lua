local M = {}

local api = require("dodona.api")
local poll = require("dodona.poll")

-- Laatste submission URL opslaan
M.last_url = nil

function M.submit()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local first_line = lines[1] or ""

  -- Parse Dodona URL uit eerste regel
  local exercise_url = first_line:match("https://dodona%.be[^%s]+")
  if not exercise_url then
    vim.notify("Geen Dodona URL gevonden in eerste regel", vim.log.levels.ERROR)
    return
  end

  local course_id = exercise_url:match("/courses/(%d+)/")
  local exercise_id = exercise_url:match("/activities/(%d+)")
  if not exercise_id then
    vim.notify("Geen exercise ID gevonden in URL", vim.log.levels.ERROR)
    return
  end

  local response, err = api.post("/submissions.json", {
    submission = {
      code = table.concat(lines, "\n"),
      course_id = course_id,
      exercise_id = exercise_id,
    }
  })

  if not response then
    vim.notify("Submit mislukt: " .. (err or "unknown"), vim.log.levels.ERROR)
    return
  end

  if response.url then
    M.last_url = response.url
    vim.notify("Submitted, wachten op resultaat...", vim.log.levels.INFO)
    poll.start(response.url)
  else
    vim.notify("Submit mislukt: geen URL in response", vim.log.levels.ERROR)
  end
end

function M.result()
  if not M.last_url then
    vim.notify("Geen recente submission", vim.log.levels.WARN)
    return
  end

  local status, err = api.request(M.last_url)
  if not status then
    vim.notify("Kon resultaat niet ophalen: " .. (err or "unknown"), vim.log.levels.ERROR)
    return
  end

  local msg = status.status
  if status.summary then
    msg = msg .. " - " .. status.summary
  end

  local level = status.status == "correct" and vim.log.levels.INFO or vim.log.levels.WARN
  vim.notify(msg, level)
end

return M

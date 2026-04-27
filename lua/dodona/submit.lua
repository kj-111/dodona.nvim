local M = {}

local api = require("dodona.api")
local poll = require("dodona.poll")

function M.submit()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local first_line = lines[1] or ""

  local exercise_url = first_line:match("https://dodona%.be[^%s]+")
  if not exercise_url then
    vim.notify("No Dodona URL found on the first line", vim.log.levels.ERROR)
    return
  end

  local course_id = exercise_url:match("/courses/(%d+)/")
  local exercise_id = exercise_url:match("/activities/(%d+)")
  if not exercise_id then
    vim.notify("No exercise ID found in the Dodona URL", vim.log.levels.ERROR)
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
    vim.notify("Submission failed: " .. (err or "unknown"), vim.log.levels.ERROR)
    return
  end

  if response.url then
    vim.notify("Submitted, waiting for result...", vim.log.levels.INFO)
    poll.start(response.url)
  else
    vim.notify("Submission failed: response did not include a result URL", vim.log.levels.ERROR)
  end
end

return M

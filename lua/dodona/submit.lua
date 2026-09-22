local M = {}

local api = require("dodona.api")

function M.submit()
  local config = require("dodona").config
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local first_line = lines[1] or ""

  local exercise_url = first_line:match("https?://[^%s<>\"']+")
  if not exercise_url then
    vim.notify("No Dodona URL found on the first line", vim.log.levels.ERROR)
    return
  end

  local url, url_err = api.resolve_url(exercise_url, config.base_url)
  if not url then
    vim.notify("Invalid Dodona exercise URL: " .. url_err, vim.log.levels.ERROR)
    return
  end
  local path = url:sub(#config.base_url + 1):gsub("[?#].*$", ""):gsub("/$", ""):gsub("%.json$", "")
  path = path:gsub("^/%a%a/", "/")
  local course_id, exercise_id = path:match("^/courses/(%d+)/activities/(%d+)$")
  if not exercise_id then
    course_id, exercise_id = path:match("^/courses/(%d+)/series/%d+/activities/(%d+)$")
  end
  exercise_id = exercise_id or path:match("^/activities/(%d+)$")
  if not exercise_id then
    vim.notify("No exercise ID found in the Dodona URL", vim.log.levels.ERROR)
    return
  end

  api.request("/submissions.json", {
    config = config,
    body = {
      submission = {
        code = table.concat(lines, "\n"),
        course_id = course_id,
        exercise_id = exercise_id,
      },
    },
  }, function(response, err)
    if not response then
      vim.notify("Submission failed: " .. err, vim.log.levels.ERROR)
      return
    end
    local result_url, result_err = api.resolve_url(response.url, config.base_url)
    if not result_url then
      vim.notify("Submission accepted but result URL is invalid: " .. result_err, vim.log.levels.ERROR)
      return
    end
    require("dodona.result").remember(result_url, config)
    vim.notify("Submitted, waiting for result...", vim.log.levels.INFO)
    require("dodona.poll").start(result_url, config)
  end)
end

return M

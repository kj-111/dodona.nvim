local M = {}

local api = require("dodona.api")

local INITIAL_DELAY = 3000
local POLL_INTERVAL = 2000
local TIMEOUT = 60000

function M.start(url, config)
  local timer, deadline, request
  local finished = false

  local function finish(msg, level)
    if finished then
      return
    end
    finished = true
    for _, handle in pairs({ timer, deadline }) do
      if not handle:is_closing() then
        handle:stop()
        handle:close()
      end
    end
    if request and not request:is_closing() then
      request:kill(15)
    end
    vim.notify(msg, level)
  end

  local function poll()
    if finished then
      return
    end
    request = api.request(url, { config = config }, function(status, err)
      request = nil
      if finished then
        return
      end
      if not status then
        finish("Could not fetch status: " .. err, vim.log.levels.ERROR)
        return
      end
      if type(status.status) ~= "string" or status.status == "" then
        finish("Invalid Dodona response: missing submission status", vim.log.levels.ERROR)
        return
      end
      if status.status == "running" or status.status == "queued" then
        timer = vim.defer_fn(poll, POLL_INTERVAL)
        return
      end

      local correct = status.status == "correct"
      local summary = type(status.summary) == "string" and status.summary ~= "" and status.summary or status.status
      finish(correct and "Correct!" or summary, correct and vim.log.levels.INFO or vim.log.levels.WARN)
    end)
  end

  deadline = vim.defer_fn(function()
    finish("Timed out after 60 seconds", vim.log.levels.WARN)
  end, TIMEOUT)
  timer = vim.defer_fn(poll, INITIAL_DELAY)
end

return M

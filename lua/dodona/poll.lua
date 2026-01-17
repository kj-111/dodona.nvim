local M = {}

local api = require("dodona.api")

local INITIAL_DELAY = 3000   -- 3 seconden wachten voor eerste poll
local POLL_INTERVAL = 2000   -- 2 seconden tussen polls
local MAX_ATTEMPTS = 30      -- Max 30 pogingen (60 seconden totaal)

function M.start(url)
  local timer = vim.uv.new_timer()
  local attempts = 0
  local closed = false

  local function cleanup()
    if not closed then
      closed = true
      timer:stop()
      timer:close()
    end
  end

  local function poll()
    attempts = attempts + 1

    if attempts > MAX_ATTEMPTS then
      cleanup()
      vim.notify("Timeout na 60 seconden", vim.log.levels.WARN)
      return
    end

    local status, err = api.request(url)

    if not status then
      cleanup()
      vim.notify("Kon status niet ophalen: " .. (err or "unknown"), vim.log.levels.ERROR)
      return
    end

    if status.error then
      cleanup()
      vim.notify("API error: " .. tostring(status.error), vim.log.levels.ERROR)
      return
    end

    if status.status ~= "running" and status.status ~= "queued" then
      cleanup()
      local is_correct = status.status == "correct"
      local msg = is_correct and "Correct!" or (status.summary or status.status)
      local level = is_correct and vim.log.levels.INFO or vim.log.levels.WARN
      vim.notify(msg, level)
    end
  end

  -- Start met initiële delay, daarna poll elke POLL_INTERVAL
  timer:start(INITIAL_DELAY, POLL_INTERVAL, vim.schedule_wrap(poll))
end

return M

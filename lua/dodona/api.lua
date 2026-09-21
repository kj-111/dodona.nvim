local M = {}

-- Keep authenticated requests on the configured server, including result URLs.
function M.resolve_url(url, base_url)
  if type(url) ~= "string" or url == "" or url:find("[%s%c\\]") then
    return nil, "invalid API URL"
  end
  if url:sub(1, 1) == "/" and url:sub(1, 2) ~= "//" then
    return base_url .. url
  end
  if url:sub(1, #base_url + 1) == base_url .. "/" then
    return url
  end
  return nil, "API URL does not belong to " .. base_url
end

local function api_error(data)
  if type(data) ~= "table" then
    return nil
  end
  local err = data.error or data.errors
  if err and err ~= vim.NIL then
    return type(err) == "string" and err or vim.json.encode(err)
  end
end

local function decode(result)
  if result.code ~= 0 then
    if result.code == 28 or result.code == 124 then
      return nil, "request timed out"
    end
    return nil, "curl failed (exit " .. result.code .. "): " .. vim.trim(result.stderr or "")
  end

  local body, status = (result.stdout or ""):match("^(.*)\n(%d%d%d)$")
  if not status then
    return nil, "missing HTTP status in curl response"
  end
  status = tonumber(status)
  local ok, data = pcall(vim.json.decode, body)
  if status < 200 or status >= 300 then
    local detail = ok and api_error(data)
    if status == 401 then
      detail = "unauthorized - check your API token"
    end
    return nil, "HTTP " .. status .. (detail and ": " .. detail or "")
  end
  if not ok or type(data) ~= "table" or vim.islist(data) then
    return nil, "expected a JSON object from Dodona"
  end
  local err = api_error(data)
  if err then
    return nil, "API error: " .. err
  end
  return data
end

local function quote(value)
  return '"' .. value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r") .. '"'
end

-- With a callback this is asynchronous; health checks use the synchronous form.
function M.request(url, opts, callback)
  opts = opts or {}
  local function finish(data, err)
    if callback then
      callback(data, err)
    end
    return data, err
  end

  local dodona = require("dodona")
  local config = opts.config or dodona.config
  local full_url, url_err = M.resolve_url(url, config.base_url)
  if not full_url then
    return finish(nil, url_err)
  end
  local token, token_err = dodona.get_token(config)
  if not token then
    return finish(nil, token_err)
  end

  local timeout = opts.timeout or 30000
  local args = {
    "curl", "-q", "-sS",
    "--max-time", tostring(timeout / 1000),
    "--proto", "=http,https",
    "--proto-redir", config.base_url:match("^https:") and "=https" or "=http,https",
    "-H", "Accept: application/json",
    "--write-out", "\n%{http_code}",
    "--config", "-",
    "--url", full_url,
  }
  -- Do not put the token or submitted code in process arguments.
  local stdin = "header = " .. quote("Authorization: " .. token) .. "\n"
  if opts.body then
    local ok, body = pcall(vim.json.encode, opts.body)
    if not ok then
      return finish(nil, "could not encode submission as JSON")
    end
    vim.list_extend(args, { "-H", "Content-Type: application/json" })
    stdin = stdin .. "data-binary = " .. quote(body) .. "\n"
  elseif opts.follow_redirects then
    -- /profile.json redirects; curl restricts Authorization to the original origin.
    vim.list_extend(args, { "--location", "--max-redirs", "5" })
  end

  local on_exit = callback and vim.schedule_wrap(function(result)
    finish(decode(result))
  end) or nil
  local ok, process = pcall(vim.system, args, { text = true, stdin = stdin, timeout = timeout }, on_exit)
  if not ok then
    return finish(nil, "could not start curl - check that it is installed")
  end
  if callback then
    return process
  end
  return decode(process:wait())
end

return M

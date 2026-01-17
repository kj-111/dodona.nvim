local M = {}

local config = nil

function M.init(cfg)
  config = cfg
end

-- Voegt base_url toe als path relatief is
local function resolve_url(url)
  if url:match("^https?://") then
    return url
  end
  return config.base_url .. url
end

function M.request(url)
  if not config.token then
    return nil, "geen API token - gebruik :DodonaSetToken"
  end

  local full_url = resolve_url(url)

  local args = {
    "curl", "-s",
    "--max-time", "30",
    "-H", "Authorization: " .. config.token,
    "-H", "Accept: application/json",
    full_url,
  }

  local result = vim.fn.system(args)
  if vim.v.shell_error ~= 0 then
    return nil, "request mislukt - check internetverbinding"
  end

  local ok, data = pcall(vim.json.decode, result)
  if not ok then
    return nil, "onverwacht antwoord - check of token geldig is"
  end

  return data
end

function M.post(path, body)
  if not config.token then
    return nil, "geen API token - gebruik :DodonaSetToken"
  end

  local full_url = resolve_url(path)

  local args = {
    "curl", "-s",
    "--max-time", "30",
    "-X", "POST",
    "-H", "Authorization: " .. config.token,
    "-H", "Content-Type: application/json",
    "-H", "Accept: application/json",
    "-d", vim.json.encode(body),
    full_url,
  }

  local result = vim.fn.system(args)
  if vim.v.shell_error ~= 0 then
    return nil, "request mislukt - check internetverbinding"
  end

  local ok, data = pcall(vim.json.decode, result)
  if not ok then
    return nil, "onverwacht antwoord - check of token geldig is"
  end

  return data
end

return M

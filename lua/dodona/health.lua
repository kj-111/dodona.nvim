local M = {}

function M.check()
  local health = vim.health
  local config = require("dodona").config

  health.start("Neovim version")
  if vim.fn.has("nvim-0.10") == 1 then
    health.ok("Neovim >= 0.10 (" .. tostring(vim.version()) .. ")")
  else
    health.warn("Neovim >= 0.10 is required, current version: " .. tostring(vim.version()))
  end

  health.start("Dependencies")
  if vim.fn.executable("curl") == 1 then
    health.ok("curl found")
  else
    health.error("curl not found", { "Install curl to use dodona.nvim" })
  end

  health.start("API token")
  local token_path = config.token_path
  local stat = vim.uv.fs_stat(token_path)

  if stat then
    health.ok("Token file found: " .. token_path)

    local perm = vim.fn.getfperm(token_path)
    if perm == "rw-------" then
      health.ok("Token file permissions are safe (rw-------)")
    else
      health.warn(
        "Token file permissions are " .. perm .. " (expected rw-------)",
        { "Fix with: chmod 600 " .. token_path }
      )
    end
  else
    health.warn("Token file not found: " .. token_path, {
      "Run :DodonaSetToken to set a token",
      "Or pass a token via require('dodona').setup({ token = '...' })",
    })
  end

  local token = config.token
  if not token or token == "" then
    health.error("No API token loaded", {
      "Run :DodonaSetToken to set a token",
      "Or pass a token via require('dodona').setup({ token = '...' })",
    })
    return
  end

  health.ok("API token loaded")

  health.start("Dodona API connection")

  -- /profile.json redirects to /nl/users/<id>.json, so curl needs -L.
  local result = vim.fn.system({
    "curl", "-s", "-L",
    "--max-time", "10",
    "-H", "Authorization: " .. token,
    "-H", "Accept: application/json",
    config.base_url .. "/profile.json",
  })

  if vim.v.shell_error ~= 0 then
    health.error("Could not reach Dodona", {
      "Check your internet connection",
      "Check whether " .. config.base_url .. " is reachable",
    })
  else
    local ok, data = pcall(vim.json.decode, result)
    if ok and data and data.first_name then
      health.ok("Connection succeeded - logged in as " .. data.first_name .. " " .. (data.last_name or ""))
    elseif ok and data and data.error then
      health.error("API error: " .. data.error, {
        "Check whether your token is valid at " .. config.base_url,
      })
    else
      health.error("Unexpected API response", {
        "Check whether your token is valid at " .. config.base_url,
      })
    end
  end
end

return M

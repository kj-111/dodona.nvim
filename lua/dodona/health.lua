local M = {}

function M.check()
  local health = vim.health

  health.start("Neovim version")
  if vim.fn.has("nvim-0.10") == 1 then
    health.ok("Neovim >= 0.10 (" .. tostring(vim.version()) .. ")")
  else
    health.error("Neovim >= 0.10 is required, current version: " .. tostring(vim.version()))
    return
  end

  health.start("Dependencies")
  if vim.fn.executable("curl") == 1 then
    health.ok("curl found")
  else
    health.error("curl not found", { "Install curl to use dodona.nvim" })
    return
  end

  local dodona = require("dodona")
  local config = dodona.config
  health.start("API token")
  if config.token then
    health.ok("API token supplied through setup()")
  else
    local token_path = config.token_path
    local stat = vim.uv.fs_stat(token_path)
    if stat and stat.type == "file" then
      health.ok("Token file found: " .. token_path)
      local perm = vim.fn.getfperm(token_path)
      if perm == "rw-------" then
        health.ok("Token file permissions are safe (rw-------)")
      else
        health.warn("Token file permissions are " .. perm .. " (expected rw-------)", {
          "Fix with: chmod 600 " .. vim.fn.shellescape(token_path),
        })
      end
    end
  end

  local token, err = dodona.get_token()
  if not token then
    health.error(err, { "Run :DodonaSetToken or provide a token through setup()" })
    return
  end
  health.ok("API token loaded")

  health.start("Dodona API connection")
  local data, request_err = require("dodona.api").request("/profile.json", {
    timeout = 10000,
    follow_redirects = true,
  })
  if not data then
    health.error("Could not connect to Dodona: " .. request_err)
  elseif type(data.first_name) == "string" and (data.last_name == nil or data.last_name == vim.NIL
    or type(data.last_name) == "string") then
    local last_name = type(data.last_name) == "string" and data.last_name or ""
    health.ok("Connection succeeded - logged in as " .. data.first_name .. " " .. last_name)
  else
    health.error("Unexpected API response: missing or invalid profile name")
  end
end

return M

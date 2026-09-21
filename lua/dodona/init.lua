local M = {}

local defaults = {
  base_url = "https://dodona.be",
  token_path = vim.fs.joinpath(vim.fn.stdpath("data"), "dodona_token"),
  token = nil,
}

M.config = vim.tbl_extend("force", {}, defaults)

local function valid_token(token)
  return type(token) == "string" and token ~= "" and not token:find("[%s%c]")
end

function M.get_token(config)
  config = config or M.config
  if config.token then
    if not valid_token(config.token) then
      return nil, "invalid API token in setup()"
    end
    return config.token
  end

  local f, err = io.open(config.token_path, "r")
  if not f then
    return nil, "could not read API token: " .. err .. " - run :DodonaSetToken"
  end
  local token, read_err = f:read("*a")
  local closed, close_err = f:close()
  if not token or not closed then
    return nil, "could not read API token: " .. (read_err or close_err)
  end
  token = vim.trim(token)
  if not valid_token(token) then
    return nil, "empty or invalid API token - run :DodonaSetToken"
  end
  return token
end

local function set_token()
  local ok, token = pcall(vim.fn.inputsecret, { prompt = "Dodona API Token: ", cancelreturn = vim.NIL })
  if not ok or token == vim.NIL then
    return
  end

  local path = M.config.token_path
  if token == "" then
    local removed, err, code = vim.uv.fs_unlink(path)
    if not removed and code ~= "ENOENT" then
      vim.notify("Failed to remove Dodona token: " .. err, vim.log.levels.ERROR)
      return
    end
    M.config.token = nil
    vim.notify("Dodona token removed", vim.log.levels.INFO)
    return
  end

  token = vim.trim(token)
  if not valid_token(token) then
    vim.notify("Invalid Dodona token: expected a nonempty token without whitespace", vim.log.levels.ERROR)
    return
  end

  local made_dir, dir_err = pcall(vim.fn.mkdir, vim.fs.dirname(path), "p", 448)
  if not made_dir then
    vim.notify("Failed to save Dodona token: " .. dir_err, vim.log.levels.ERROR)
    return
  end

  -- mkstemp creates a 0600 file; rename preserves the old token if writing fails.
  local fd, temp = vim.uv.fs_mkstemp(path .. ".XXXXXX")
  if not fd then
    vim.notify("Failed to save Dodona token: " .. temp, vim.log.levels.ERROR)
    return
  end
  local written, err = vim.uv.fs_write(fd, token, 0)
  local closed, close_err = vim.uv.fs_close(fd)
  local saved
  if written == #token and closed then
    saved, err = vim.uv.fs_rename(temp, path)
  end
  if not saved then
    vim.uv.fs_unlink(temp)
    vim.notify("Failed to save Dodona token: " .. (err or close_err or "incomplete write"), vim.log.levels.ERROR)
    return
  end
  M.config.token = nil
  vim.notify("Dodona token saved", vim.log.levels.INFO)
end

function M.setup(opts)
  assert(opts == nil or type(opts) == "table", "dodona: setup options must be a table")
  local config = vim.tbl_extend("force", defaults, opts or {})
  assert(type(config.base_url) == "string", "dodona: base_url must be a string")
  config.base_url = config.base_url:gsub("/+$", "")
  local authority = config.base_url:match("^https?://([^/]+)$")
  local host = authority and authority:gsub(":%d+$", "")
  assert(
    host and (host:match("^[%w%.%-]+$") or host:match("^%[[%x:%.]+%]$")),
    "dodona: base_url must be an HTTP(S) origin"
  )
  assert(
    type(config.token_path) == "string" and config.token_path ~= "",
    "dodona: token_path must be a nonempty string"
  )
  config.token_path = vim.fs.normalize(config.token_path)
  assert(config.token == nil or valid_token(config.token), "dodona: token must be a nonempty string without whitespace")
  M.config = config

  -- Register user commands.
  vim.api.nvim_create_user_command("DodonaSubmit", function()
    require("dodona.submit").submit()
  end, { desc = "Submit the current buffer to Dodona" })
  vim.api.nvim_create_user_command("DodonaSetToken", set_token, { desc = "Set or remove the Dodona API token" })
  vim.api.nvim_create_user_command("DodonaHealth", function()
    vim.cmd("checkhealth dodona")
  end, { desc = "Check Dodona configuration and API access" })
end

return M

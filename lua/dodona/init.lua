local M = {}

M.config = {
  base_url = "https://dodona.be",
  token_path = vim.fs.joinpath(vim.fn.stdpath("data"), "dodona_token"),
  token = nil,
}

local function set_token()
  vim.ui.input({ prompt = "Dodona API Token: " }, function(token)
    if not token then
      return
    end

    if token == "" then
      os.remove(M.config.token_path)
      M.config.token = nil
      vim.notify("Dodona token removed", vim.log.levels.INFO)
      return
    end

    local f, err = io.open(M.config.token_path, "w")
    if not f then
      vim.notify("Failed to save Dodona token: " .. err, vim.log.levels.ERROR)
      return
    end

    f:write(token)
    f:close()
    vim.fn.setfperm(M.config.token_path, "rw-------")
    M.config.token = token
    vim.notify("Dodona token saved", vim.log.levels.INFO)
  end)
end

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})

  -- Load token from disk unless it was provided in setup().
  if not M.config.token then
    local f = io.open(M.config.token_path, "r")
    if f then
      M.config.token = f:read("*l")
      f:close()
    end
  end

  -- Initialize API module with the final config.
  require("dodona.api").init(M.config)

  -- Register user commands.
  local submit = require("dodona.submit")
  vim.api.nvim_create_user_command("DodonaSubmit", submit.submit, {})
  vim.api.nvim_create_user_command("DodonaSetToken", set_token, {})
  vim.api.nvim_create_user_command("DodonaHealth", function()
    vim.cmd("checkhealth dodona")
  end, {})
end

return M

local M = {}

M.config = {
  base_url = "https://dodona.be",
  token_path = vim.fs.joinpath(vim.fn.stdpath("data"), "dodona_token"),
  token = nil,
}

local function set_token()
  vim.ui.input({ prompt = "Dodona API Token: " }, function(token)
    if not token or token == "" then
      return
    end

    local f, err = io.open(M.config.token_path, "w")
    if not f then
      vim.notify("Token opslaan mislukt: " .. err, vim.log.levels.ERROR)
      return
    end

    f:write(token)
    f:close()
    vim.fn.setfperm(M.config.token_path, "rw-------")
    M.config.token = token
    vim.notify("Token opgeslagen", vim.log.levels.INFO)
  end)
end

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})

  -- Laad token uit bestand als niet meegegeven
  if not M.config.token then
    local f = io.open(M.config.token_path, "r")
    if f then
      M.config.token = f:read("*l")
      f:close()
    end
  end

  -- Initialiseer api module met config
  require("dodona.api").init(M.config)

  -- Registreer commands
  local submit = require("dodona.submit")
  vim.api.nvim_create_user_command("DodonaSubmit", submit.submit, {})
  vim.api.nvim_create_user_command("DodonaResult", submit.result, {})
  vim.api.nvim_create_user_command("DodonaSetToken", set_token, {})
end

return M

# dodona.nvim

Minimal Neovim plugin for [Dodona](https://dodona.be) - submit code directly from your editor.

Inspired by [xerbalind/dodona.nvim](https://github.com/xerbalind/dodona.nvim).

## Requirements

- Neovim 0.10+
- curl

## Installation

```lua
-- lazy.nvim
{
  "kj-111/dodona.nvim",
  config = function()
    require("dodona").setup()
  end,
}
```

## Setup

1. Get your API token: [dodona.be/profile](https://dodona.be/profile)
2. In Neovim: `:DodonaSetToken`

Optional configuration (each call to `setup()` replaces the previous configuration):

```lua
require("dodona").setup({
  base_url = "https://dodona.be", -- HTTP(S) origin, without a path
  token_path = vim.fs.joinpath(vim.fn.stdpath("data"), "dodona_token"),
  -- token = "...", -- optional; overrides the token file
})
```

## Usage

Put the Dodona URL in the first line of your file:

```python
# https://dodona.be/courses/123/activities/456

def solution():
    return 42
```

Submit with `:DodonaSubmit`.

Submission and polling run asynchronously. Polling stops after 60 seconds;
Dodona may still finish evaluating the submission after that. Exercise URLs
must belong to the configured server.

## Commands

| Command | Description |
|---------|-------------|
| `:DodonaSubmit` | Submit current buffer to Dodona |
| `:DodonaSetToken` | Set your API token |
| `:DodonaHealth` | Run `:checkhealth dodona` |

## Data Storage

Your API token is stored in Neovim's data directory:

```text
~/.local/share/nvim/dodona_token
```

The file has permissions `600` (only you can read/write). The token is not encrypted.
Token input is hidden and excluded from input history. Tokens and submitted code
are passed to curl through stdin rather than process arguments.

To remove your token, delete the file or run `:DodonaSetToken` with an empty value.

## Health Check

Run `:DodonaHealth` to verify your Neovim version, `curl` availability, token file permissions, and Dodona API access.
This explicit check waits for the API response for up to 10 seconds.

## License

MIT

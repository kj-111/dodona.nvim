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

## Usage

Put the Dodona URL in the first line of your file:

```python
# https://dodona.be/courses/123/activities/456

def solution():
    return 42
```

Submit with `:DodonaSubmit`.

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

To remove your token, delete the file or run `:DodonaSetToken` with an empty value.

## Health Check

Run `:DodonaHealth` to verify your Neovim version, `curl` availability, token file permissions, and Dodona API access.

## License

MIT

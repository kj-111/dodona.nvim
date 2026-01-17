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
| `:DodonaResult` | Check result of last submission |
| `:DodonaSetToken` | Set your API token |

## License

MIT

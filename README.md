# learner.nvim

`learner.nvim` helps track study topics and tasks while integrating a simple spaced repetition system and LLM suggestions.

## Installation

### lazy.nvim
```lua
{
  'gavinw2143/learner.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('learner').setup()
  end
}
```

### packer.nvim
```lua
use {
  'gavinw2143/learner.nvim',
  requires = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('learner').setup()
  end
}
```

## Configuration

Call `require('learner').setup()` with an optional table. Available fields are:

```lua
require('learner').setup({
  storage = {
    adapter = 'file',         -- 'file' (default) or 'neo4j'
    path = nil,               -- path for the file adapter
    uri  = nil,               -- neo4j URI if using neo4j adapter
    user = nil,               -- neo4j user
    pass = nil,               -- neo4j password
  },
  llm = {
    api_url = 'https://openrouter.ai/api/v1/chat/completions',
    model   = 'gpt-3.5-turbo',
    api_key = vim.env.OPENROUTER_API_KEY,
  },
  tasks = {},                 -- task module options
  ui = {},                    -- ui module options
})
```

## Usage

- `:LearnerReview` lists all topics that are due and lets you record a review.
- `<leader>a` in visual mode: start an interactive query with the selected text as context.
- `:LearnerSuggest [prompt]` sends `prompt` to the configured LLM (defaults to *"Give me a learning suggestion"*).

## Commands

| Command | Description |
| --- | --- |
| `:LearnerReview` | Review due topics via a picker. |
| `:LearnerSuggest [prompt]` | Ask the LLM for a suggestion or answer. |
| `:LearnerAddTask {desc}` | Add a new learning task. |
| `:LearnerRemoveTask {id}` | Remove a task by ID. |
| `:LearnerDoneTask {id}` | Mark a task as completed. |
| `:LearnerUpdateTask {id} {desc}` | Update a task's description. |

## Prerequisites

- Neovim 0.8 or newer.
- `nvim-lua/plenary.nvim`.
- `curl` and `OPENROUTER_API_KEY` set for LLM features.
- Optional: `neo4j-lua` if the Neo4j storage adapter is used.

## Development Setup

Run `./setup.sh` to install dependencies on Debian/Ubuntu or macOS.
The script uses `sudo` for `apt-get` and `luarocks` installs, so review it
before running. Pass `--no-root` to skip these privileged steps. It installs
Neovim, LuaRocks, Git, Curl, and fetches the `plenary.nvim` plugin.

If you are on Windows or another platform, install these tools manually:

1. Install **Neovim** and **LuaRocks** using your package manager or from
   [neovim.io](https://neovim.io/) and [luarocks.org](https://luarocks.org/).
2. Install the Lua testing framework:
   ```sh
   luarocks install --lua-version=5.1 busted
   ```
3. (Optional) Install the Neo4j adapter:
   ```sh
   luarocks install --lua-version=5.1 neo4j
   ```
4. Ensure `nvim-lua/plenary.nvim` is available. Either clone it into
   `~/.local/share/nvim/site/pack/deps/start` or use your plugin manager.

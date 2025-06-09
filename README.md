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
  srs = {
    base_interval = 1,        -- days between first reviews
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
- `:LearnerSuggest [prompt]` sends `prompt` to the configured LLM (defaults to *"Give me a learning suggestion"*).

## Commands

| Command | Description |
| --- | --- |
| `:LearnerReview` | Review due topics via a picker. |
| `:LearnerSuggest [prompt]` | Ask the LLM for a suggestion or answer. |

## Prerequisites

- Neovim 0.8 or newer.
- `nvim-lua/plenary.nvim`.
- `curl` and `OPENROUTER_API_KEY` set for LLM features.
- Optional: `neo4j-lua` if the Neo4j storage adapter is used.

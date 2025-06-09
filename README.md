# learner.nvim

A Neovim plugin that helps you track learning topics, tasks and progress. It combines spaced repetition scheduling with lightweight task management and optional LLM suggestions.

## Installation

Use your favourite plugin manager. With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "path/to/learner.nvim", -- replace with repository URL
  config = function()
    require("learner").setup()
  end,
}
```

## Usage

After calling `require("learner").setup()` the plugin will:

1. Connect to the configured storage backend (see `lua/learner/storage/`).
2. Initialise spaced repetition via `lua/learner/srs.lua`.
3. Provide commands like `:LearnerReview` and `:LearnerSuggest` from `lua/learner/ui.lua`.

Storage backends include a flat-file adapter as well as a Neo4j connector. LLM integration through `lua/learner/llm.lua` can be configured with an API key.

## Further Reading

Detailed design discussions and notes live in the [docs/](docs/) directory.

Major modules to explore:

- `learner.storage` – pluggable storage backends.
- `learner.llm` – wrapper around OpenRouter or other LLM providers.
- `learner.srs` – simple spaced repetition scheduler.
- `learner.tasks` – task tracking.
- `learner.ui` – user commands and basic interface.



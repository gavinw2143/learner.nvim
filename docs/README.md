# learner.nvim Documentation

## 1. Project Overview and Goals

`learner.nvim` aims to help you retain knowledge and manage study tasks right from Neovim. The plugin stores topics you want to review, schedules them with a basic spaced‑repetition system (SRS), and lets you ask an LLM for learning suggestions. It is designed to be lightweight while allowing different storage backends and future integrations.

## 2. Storage Adapters

Data persistence is provided by pluggable adapters under `lua/learner/storage`.

### `file` adapter (default)
Stores everything in a local JSON file. Configure the path and connect:

```lua
require('learner').setup({
  storage = {
    adapter = 'file',
    path = vim.fn.stdpath('data') .. '/learner/db.json',
  },
})
```

### `neo4j` adapter
Persists topics and tasks to a Neo4j database via the Bolt protocol:

```lua
require('learner').setup({
  storage = {
    adapter = 'neo4j',
    uri  = 'bolt://localhost:7687',
    user = 'neo4j',
    pass = 'secret',
  },
})
```

Each adapter implements `connect`, `query`, `execute`, `migrate`, and `close` so the rest of the plugin can remain agnostic to the backend.

## 3. Events

Modules communicate through a small dispatcher in `learner.events`.
Handlers subscribe with `events.subscribe(name, fn)` and are invoked when `events.emit` is called.

Current events:

- `llm_request` – fired when the user sends a prompt to the LLM.
- `llm_response` – emitted after an LLM reply is received.
- `topic_reviewed` – triggered when a topic has been reviewed.

Example:

```lua
local events = require('learner.events')

events.subscribe('llm_response', function(info)
  print(info.text)
end)
```

## 4. Planned Features

The project is still experimental. Planned work includes:

- **Neo4j integration** – richer graph queries and migrations beyond the basic adapter.
- **FSRS scheduling** – replace the simple SM‑2 style algorithm with [FSRS](https://github.com/open-spaced-repetition/fsrs) for better review intervals.
- **History view** – expose conversation and review history (see `HISTORY.md`).

Contributions and ideas are welcome as the plugin evolves.

# learner.nvim

A small experimental plugin for tracking learning topics and tasks. It provides a
simple spaced repetition scheduler and basic persistence through pluggable
storage backends.

## Running tests

The test suite lives in the `tests/` directory and uses plenary's busted
helpers. With Neovim and `plenary.nvim` installed, execute:

```bash
nvim --headless -c "PlenaryBustedDirectory tests { minimal = true }"
```

This will run all specifications under `tests/`.

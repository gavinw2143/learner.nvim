#!/usr/bin/env bash
set -euo pipefail

# Ensure we have package manager tools available
if command -v apt-get >/dev/null; then
    sudo apt-get update
    sudo apt-get install -y neovim luarocks git curl
fi

# Install Lua testing dependencies
if command -v luarocks >/dev/null; then
    sudo luarocks install --lua-version=5.1 busted || true
fi

# Fetch Neovim dependency for the plugin
PLUGIN_PATH="$HOME/.local/share/nvim/site/pack/deps/start"
mkdir -p "$PLUGIN_PATH"
if [ ! -d "$PLUGIN_PATH/plenary.nvim" ]; then
    git clone --depth 1 https://github.com/nvim-lua/plenary.nvim.git "$PLUGIN_PATH/plenary.nvim" || true
fi

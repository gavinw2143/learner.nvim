#!/usr/bin/env bash
set -euo pipefail

# Install OS level dependencies
if command -v apt-get >/dev/null; then
    echo "Detected apt based system"
    sudo apt-get update
    sudo apt-get install -y neovim luarocks git curl
elif command -v brew >/dev/null; then
    echo "Detected macOS with Homebrew"
    brew update
    brew install neovim luarocks git curl
else
    echo "Please install neovim, luarocks, git and curl using your OS package manager." >&2
fi

# Install Lua testing dependencies
if command -v luarocks >/dev/null; then
    sudo luarocks install --lua-version=5.1 busted || true
    # Required for the Neo4j storage adapter
    sudo luarocks install --lua-version=5.1 neo4j || true
fi

# Fetch Neovim dependency for the plugin
PLUGIN_PATH="$HOME/.local/share/nvim/site/pack/deps/start"
mkdir -p "$PLUGIN_PATH"
if [ ! -d "$PLUGIN_PATH/plenary.nvim" ]; then
    git clone --depth 1 https://github.com/nvim-lua/plenary.nvim.git "$PLUGIN_PATH/plenary.nvim" || true
fi

-- File: lua/learner/storage/init.lua
-- Abstract storage interface and loader

local config = require("learner.config")
local M = {}

local adapter

local function load_adapter()
    local adapter_name = config.get().storage.adapter or "file"
    local ok, mod = pcall(require, "learner.storage." .. adapter_name)
    if not ok then
        error("[learner.nvim] Could not load storage adapter: " .. adapter_name)
    end
    adapter = mod
end

---Connect to the underlying storage backend
function M.connect(opts)
    if not adapter then
        load_adapter()
    end
    adapter.connect(opts or config.get().storage)
end

---Proxy functions to the loaded adapter
for _, fn in ipairs({ "query", "execute", "migrate", "close" }) do
    M[fn] = function(...)
        if not adapter then
            load_adapter()
        end
        return adapter[fn](...)
    end
end

return M

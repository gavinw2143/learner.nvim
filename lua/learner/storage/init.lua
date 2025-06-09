-- File: lua/learner/storage/init.lua
-- Abstract storage interface and loader

local config = require("learner.config")
local M = {}

-- Load the configured adapter ("neo4j" or "file")
local adapter_name = config.storage.adapter or "file"
local ok, adapter = pcall(require, "learner.storage." .. adapter_name)
if not ok then
	error("[learner.nvim] Could not load storage adapter: " .. adapter_name)
end

-- Proxy API
M.connect = adapter.connect
M.query   = adapter.query
M.execute = adapter.execute
M.migrate = adapter.migrate
M.close   = adapter.close

return M

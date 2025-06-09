-- File: lua/learner/storage/file.lua
-- Flat-file (JSON) adapter for offline/local fallback

local uv = vim.loop
local json = vim.fn.json_encode and vim.fn.json_decode or error("No JSON support")
local Path = require("plenary.path")

local M = {}
local db_file

function M.connect(opts)
	db_file = Path:new(opts.path or vim.fn.stdpath("data") .. "/learner/db.json")
	if not db_file:exists() then
		db_file:write(json({ nodes = {}, relations = {} }), "w")
	end
end

function M.query(cypher, params)
	-- Simple in-memory stub or use a JSON search
	error("Flat-file adapter: query not implemented yet")
end

function M.execute(cypher, params)
	-- Append to a CRUD log, or apply to JSON
	error("Flat-file adapter: execute not implemented yet")
end

function M.migrate()
	-- No migrations needed for flat-file
end

function M.close()
	-- Nothing to clean up
end

return M

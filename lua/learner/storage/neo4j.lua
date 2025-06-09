-- File: lua/learner/storage/neo4j.lua
-- Neo4j adapter using Bolt protocol

local neo4j = require("neo4j") -- e.g. https://github.com/Anaminus/neo4j-lua
local M = {}
local session

function M.connect(opts)
	local uri      = opts.uri or "bolt://localhost:7687"
	local user     = opts.user or "neo4j"
	local password = opts.pass or ""
	local driver   = neo4j.new({
		url      = uri,
		user     = user,
		password = password,
	})
	session        = driver:session()
end

function M.query(cypher, params)
	local res = session:run(cypher, params or {})
	return res:to_table()
end

function M.execute(cypher, params)
	session:run(cypher, params or {})
end

function M.migrate()
	-- e.g. ensure indexes/constraints exist
	session:run([[
    CREATE CONSTRAINT IF NOT EXISTS ON (t:Topic) ASSERT t.id IS UNIQUE;
  ]])
end

function M.close()
	session:close()
end

return M

-- File: lua/learner/storage/neo4j.lua
-- Neo4j adapter using Bolt protocol

local neo4j = require("neo4j") -- e.g. https://github.com/Anaminus/neo4j-lua
local M = {}
local session

-- Helper --------------------------------------------------------------------

---Build a CREATE query for a label with parameterized properties.
---@param label string
---@param data table
---@return string cypher
---@return table params
local function build_create(label, data)
  local parts = {}
  for k, _ in pairs(data or {}) do
    table.insert(parts, string.format('%s: $%s', k, k))
  end
  local cypher = string.format('CREATE (n:%s { %s }) RETURN n', label, table.concat(parts, ', '))
  return cypher, data
end

---Build a MATCH query with optional equality filters.
---@param label string
---@param filters table|nil
---@return string cypher
---@return table params
local function build_match(label, filters)
  filters = filters or {}
  local conds = {}
  for k, _ in pairs(filters) do
    table.insert(conds, string.format('n.%s = $%s', k, k))
  end
  local where = ''
  if #conds > 0 then
    where = ' WHERE ' .. table.concat(conds, ' AND ')
  end
  local cypher = string.format('MATCH (n:%s)%s RETURN n', label, where)
  return cypher, filters
end

---Build an UPDATE query setting new property values.
---@param label string
---@param filters table
---@param updates table
---@return string cypher
---@return table params
local function build_update(label, filters, updates)
  local match_q, match_params = build_match(label, filters)
  match_q = match_q:gsub(' RETURN n$', '')
  local set_parts = {}
  local params = vim.tbl_extend('force', match_params, {})
  for k, v in pairs(updates or {}) do
    table.insert(set_parts, string.format('n.%s = $update_%s', k, k))
    params['update_' .. k] = v
  end
  local cypher = match_q .. ' SET ' .. table.concat(set_parts, ', ') .. ' RETURN n'
  return cypher, params
end

M.build_create = build_create
M.build_match = build_match
M.build_update = build_update

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

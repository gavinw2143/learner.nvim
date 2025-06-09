-- File: lua/learner/storage/file.lua
-- Flat-file (JSON) adapter for offline/local fallback

local encode = vim.fn.json_encode
local decode = vim.fn.json_decode
local Path = require("plenary.path")

local M = {}
local db_file

local data

local function load()
    local ok, decoded = pcall(decode, db_file:read())
    if ok and type(decoded) == "table" then
        data = decoded
    else
        data = { topics = {}, tasks = {} }
    end
end

local function save()
    db_file:write(encode(data), "w")
end

function M.connect(opts)
    db_file = Path:new(opts.path or vim.fn.stdpath("data") .. "/learner/db.json")
    if not db_file:exists() then
        data = { topics = {}, tasks = {} }
        db_file:parent():mkdir({ parents = true })
        save()
    else
        load()
    end
end

---Retrieve a value by key from the JSON store
function M.query(key)
    return data[key]
end

---Write a value for a given key back to the JSON store
function M.execute(key, value)
    data[key] = value
    save()
end

function M.migrate()
	-- No migrations needed for flat-file
end

function M.close()
	-- Nothing to clean up
end

return M

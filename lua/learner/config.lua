local M = {}

-- Default configuration used before user calls setup()
M.options = {
	storage = { adapter = "file" },
	llm = {},
	tasks = {},
	ui = {},
}

---Setup global configuration
---@param opts table|nil user options
function M.setup(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", M.options, opts)
end

---Retrieve the current configuration
---@return table
function M.get()
	return M.options
end

return M

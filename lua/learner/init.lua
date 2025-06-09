local M = {}

function M.setup(opts)
	opts = opts or {}
	require("learner.srs").setup(opts.srs)
	require("learner.llm").setup(opts.llm)
	require("learner.tasks").setup(opts.tasks)
	require("learner.ui").setup(opts.ui)
end

return M

local config = require("learner.config")
local M = {}

---Entry point for plugin setup
---@param opts table|nil user configuration table
function M.setup(opts)
    opts = opts or {}

    -- Persist configuration for other modules
    config.setup(opts)

    -- Initialize submodules with their respective configs
    require("learner.srs").setup(config.get().srs)
    require("learner.llm").setup(config.get().llm)
    require("learner.tasks").setup(config.get().tasks)
    require("learner.ui").setup(config.get().ui)
end

return M

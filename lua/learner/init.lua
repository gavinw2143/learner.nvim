local config = require("learner.config")
local M = {}

---Entry point for plugin setup
---@param opts table|nil user configuration table
function M.setup(opts)
    opts = opts or {}

    -- Persist configuration for other modules
    config.setup(opts)

    -- Establish storage connection early so other modules can persist data
    local storage = require("learner.storage")
    storage.connect(config.get().storage)

    -- Initialize submodules with their respective configs
    require("learner.srs").setup(config.get().srs, storage)
    require("learner.llm").setup(config.get().llm)
    require("learner.tasks").setup(config.get().tasks, storage)
    require("learner.ui").setup(config.get().ui)
end

return M

local UI = {}

function UI.setup(config)
	-- create commands and keymaps
	UI.register_commands()
end

function UI.register_commands()
	vim.api.nvim_create_user_command("LearnerReview", function()
		local due = require("learner.srs").due_topics()
		-- open a picker to choose a topic to review
	end, {})

	vim.api.nvim_create_user_command("LearnerSuggest", function()
		-- on-demand LLM suggestion
	end, {})
end

return UI

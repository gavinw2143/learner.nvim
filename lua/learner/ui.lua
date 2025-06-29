local UI = {}
local events = require("learner.events")
local tasks = require("learner.tasks")

local DEFAULT_MAX_PREVIEW_CHARS = 4000

---Sanitize text for display by stripping control characters and
---truncating overly long output.
---@param text string
---@return string
function UI.sanitize_text(text)
	text = tostring(text or "")
	text = text:gsub('[%z\1-\8\11\12\14-\31\127]', '')
	local max_len = (UI.config and UI.config.max_preview_chars) or DEFAULT_MAX_PREVIEW_CHARS
	if #text > max_len then
		text = text:sub(1, max_len) .. "..."
	end
	return text
end

---Open a scrollable floating window showing the given text
---@param text string content to display
---@return boolean success
function UI.show_llm(text)
	text = UI.sanitize_text(text)
	local buf = vim.api.nvim_create_buf(false, true)
	if not buf then
		return false
	end
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	local lines = vim.split(text, "\n", { plain = true })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local width = math.floor(vim.o.columns * 0.6)
	local height = math.min(#lines, math.floor(vim.o.lines * 0.6))
	local row = math.floor((vim.o.lines - height) / 2 - 1)
	local col = math.floor((vim.o.columns - width) / 2)

	local ok, win = pcall(vim.api.nvim_open_win, buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		style = "minimal",
		border = "single",
	})
	if not ok or not win then
		return false
	end

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end, { buffer = buf, nowait = true })

	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	return true
end

---Setup UI components (commands and keymaps)
function UI.setup(config)
	UI.config = config or {}
	events.subscribe("llm_response", function(info)
		if type(info) == "table" and info.text then
			local ok, success = pcall(function()
				success = UI.show_llm(info.text)
			end)
			if not ok or not success then
				vim.notify(UI.sanitize_text(info.text), vim.log.levels.INFO)
			end
		end
	end)
	events.subscribe("topic_reviewed", function(info)
		if type(info) == "table" and info.topic then
			local title = info.topic.data and info.topic.data.title or info.topic.id
			vim.notify("Reviewed " .. title)
		end
	end)
	UI.register_commands()
	vim.keymap.set({ "v", "x" }, "<space><space>g", UI.open_conversation)
	events.subscribe("llm_response", function(info)
		if type(info) ~= "table" or not info.text then
			return
		end
		UI._on_conversation_response(info.text)
	end)
end

---Create user commands for interacting with the plugin
function UI.register_commands()
	-- Simple LLM prompt helper
	vim.api.nvim_create_user_command("LearnerSuggest", function(opts)
		local prompt = table.concat(opts.fargs, " ")
		if prompt == "" then
			prompt = "Give me a learning suggestion"
		end
		events.emit("llm_request", prompt)
	end, { nargs = "*" })

	-- Task management helpers
	vim.api.nvim_create_user_command("LearnerAddTask", function(opts)
		local desc = table.concat(opts.fargs, " ")
		if desc == "" then
			vim.notify("Task description required", vim.log.levels.ERROR)
			return
		end
		local id = tasks.add({ desc = desc })
		vim.notify("Added task " .. id)
	end, { nargs = "+" })

	vim.api.nvim_create_user_command("LearnerRemoveTask", function(opts)
		local id = tonumber(opts.args)
		if not id then
			vim.notify("Task id required", vim.log.levels.ERROR)
			return
		end
		tasks.remove(id)
		vim.notify("Removed task " .. id)
	end, { nargs = 1 })

	vim.api.nvim_create_user_command("LearnerDoneTask", function(opts)
		local id = tonumber(opts.args)
		if not id then
			vim.notify("Task id required", vim.log.levels.ERROR)
			return
		end
		tasks.mark_done(id)
		vim.notify("Marked task " .. id .. " done")
	end, { nargs = 1 })

	vim.api.nvim_create_user_command("LearnerUpdateTask", function(opts)
		local id = tonumber(opts.fargs[1])
		if not id then
			vim.notify("Task id required", vim.log.levels.ERROR)
			return
		end
		local desc = table.concat(opts.fargs, " ", 2)
		if desc == "" then
			vim.notify("New description required", vim.log.levels.ERROR)
			return
		end
		tasks.update(id, { desc = desc })
		vim.notify("Updated task " .. id)
	end, { nargs = "+" })
end

local function _get_visual_selection()
	-- Save the unnamed register (") so we can restore it:
	local saved_reg     = vim.fn.getreg('"')
	local saved_regtype = vim.fn.getregtype('"')

	-- Yank the visual selection (assumes you’ve already got a visual range):
	vim.cmd('silent! normal! "vy')

	-- Grab the yanked text:
	local text = vim.fn.getreg('"')

	-- Restore the unnamed register so we didn’t clobber it:
	vim.fn.setreg('"', saved_reg, saved_regtype)

	return text
end

function UI._update_conversation_buf()
	if not UI.conv_buf then
		return
	end
	local lines = { "[" }
	for i, entry in ipairs(UI.conv_data) do
		local json = vim.fn.json_encode(entry)
		lines[#lines + 1] = "  " .. json .. (i < #UI.conv_data and "," or "")
	end
	lines[#lines + 1] = "]"
	vim.api.nvim_set_option_value("modifiable", true, { buf = UI.conv_buf })
	vim.api.nvim_buf_set_lines(UI.conv_buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = UI.conv_buf })
end

function UI._on_conversation_response(text)
	table.insert(UI.conv_data, { role = "assistant", text = text })
	UI._update_conversation_buf()
end

function UI._submit_input()
	if not UI.input_buf then
		return
	end
	local input_lines = vim.api.nvim_buf_get_lines(UI.input_buf, 0, -1, false)
	local user_text = table.concat(input_lines, "\n")
	if user_text == "" then
		return
	end
	table.insert(UI.conv_data, { role = "user", text = user_text })
	UI._update_conversation_buf()
	vim.api.nvim_buf_set_lines(UI.input_buf, 0, -1, false, {})
	local prompt = UI.current_context .. "\n\n" .. user_text
	events.emit("llm_request", prompt)
end

function UI._close_conversation()
	if UI.win_ids then
		for _, win in ipairs(UI.win_ids) do
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end
	end
	if UI.prev_win and vim.api.nvim_win_is_valid(UI.prev_win) then
		vim.api.nvim_set_current_win(UI.prev_win)
	end
end

function UI.open_conversation()
	UI.prev_win = vim.api.nvim_get_current_win()
	UI.current_context = UI._get_visual_selection()
	UI.conv_data = { { role = "context", text = UI.current_context } }

	local cols = vim.o.columns
	local lines = vim.o.lines
	local left_w = math.floor(cols / 2)
	local right_w = cols - left_w
	local top_h = math.floor(lines / 2)
	local bottom_h = lines - top_h

	UI.conv_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = UI.conv_buf })
	vim.api.nvim_set_option_value("modifiable", false, { buf = UI.conv_buf })

	UI.context_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = UI.context_buf })
	vim.api.nvim_set_option_value("modifiable", false, { buf = UI.context_buf })
	vim.api.nvim_buf_set_lines(UI.context_buf, 0, -1, false, vim.split(UI.current_context, "\n", { plain = true }))

	UI.input_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = UI.input_buf })
	vim.api.nvim_set_option_value("modifiable", true, { buf = UI.input_buf })

	local conv_win = vim.api.nvim_open_win(UI.conv_buf, true, {
		relative = "editor",
		row = 0,
		col = 0,
		width = left_w,
		height = lines,
		style = "minimal",
		border = "single",
	})
	local ctx_win = vim.api.nvim_open_win(UI.context_buf, true, {
		relative = "editor",
		row = 0,
		col = left_w,
		width = right_w,
		height = top_h,
		style = "minimal",
		border = "single",
	})
	local input_win = vim.api.nvim_open_win(UI.input_buf, true, {
		relative = "editor",
		row = top_h,
		col = left_w,
		width = right_w,
		height = bottom_h,
		style = "minimal",
		border = "single",
	})

	UI.win_ids = { conv_win, ctx_win, input_win }

	vim.keymap.set("n", "q", UI._close_conversation, { buffer = UI.input_buf, nowait = true })
	vim.keymap.set("n", "q", UI._close_conversation, { buffer = UI.context_buf, nowait = true })
	vim.keymap.set("n", "q", UI._close_conversation, { buffer = UI.conv_buf, nowait = true })
	vim.keymap.set("n", "<C-s>", UI._submit_input, { buffer = UI.input_buf, nowait = true, desc = "Learner: submit input" })
	vim.keymap.set("i", "<C-s>", function()
		vim.cmd("stopinsert")
		UI._submit_input()
	end, { buffer = UI.input_buf, nowait = true, desc = "Learner: submit input" })

	UI._update_conversation_buf()
end

return UI

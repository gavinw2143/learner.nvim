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
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
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

    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    return true
end

---Setup UI components (commands and keymaps)
function UI.setup(config)
    UI.config = config or {}
    events.subscribe("llm_response", function(info)
        if type(info) == "table" and info.text then
            local ok = false
            local status = pcall(function()
                ok = UI.show_llm(info.text)
            end)
            if not status or not ok then
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
end

---Create user commands for interacting with the plugin
function UI.register_commands()
    -- Review due topics
    vim.api.nvim_create_user_command("LearnerReview", function()
        local srs = require("learner.srs")
        local due = srs.due_topics()

        if #due == 0 then
            vim.notify("No topics due for review", vim.log.levels.INFO)
            return
        end

        vim.ui.select(due, {
            prompt = "Select topic to review",
            format_item = function(item)
                return item.data and item.data.title or ("Topic " .. item.id)
            end,
        }, function(choice)
            if not choice then
                return
            end

            vim.ui.input({
                prompt = "Score 0-5",
                default = "5",
            }, function(input)
                if input == nil then
                    return
                end
                local score = tonumber(input)
                if not score or score < 0 or score > 5 then
                    score = 5
                end
                events.emit("topic_reviewed", { id = choice.id, topic = choice, quality = score })
            end)
        end)
    end, {})

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
        local desc = table.concat(vim.list_slice(opts.fargs, 2), " ")
        if desc == "" then
            vim.notify("New description required", vim.log.levels.ERROR)
            return
        end
        tasks.update(id, { desc = desc })
        vim.notify("Updated task " .. id)
    end, { nargs = "+" })
end

return UI

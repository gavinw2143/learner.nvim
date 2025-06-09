local UI = {}
local events = require("learner.events")
local tasks = require("learner.tasks")

---Setup UI components (commands and keymaps)
function UI.setup(config)
    UI.config = config or {}
    events.subscribe("llm_response", function(info)
        if type(info) == "table" and info.text then
            vim.notify(info.text, vim.log.levels.INFO)
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

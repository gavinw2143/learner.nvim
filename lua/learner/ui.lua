local UI = {}

---Setup UI components (commands and keymaps)
function UI.setup(config)
    UI.config = config or {}
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
            -- After user picks a topic we record a successful review by default
            srs.record_review(choice.id, 5)
            vim.notify("Reviewed " .. (choice.data.title or choice.id))
        end)
    end, {})

    -- Simple LLM prompt helper
    vim.api.nvim_create_user_command("LearnerSuggest", function(opts)
        local llm = require("learner.llm")
        local prompt = table.concat(opts.fargs, " ")
        if prompt == "" then
            prompt = "Give me a learning suggestion"
        end
        llm.complete(prompt, function(resp)
            vim.notify(resp, vim.log.levels.INFO)
        end)
    end, { nargs = "*" })
end

return UI

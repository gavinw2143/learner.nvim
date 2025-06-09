local M = {}
local events = require("learner.events")

-- Default options for LLM integration
M.config = {
    api_url = "https://openrouter.ai/api/v1/chat/completions",
    model = "gpt-3.5-turbo",
    api_key = vim.env.OPENROUTER_API_KEY or "",
}

---Setup LLM configuration
function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    events.subscribe("llm_request", function(prompt)
        M.complete(prompt, function(resp)
            events.emit("llm_response", { prompt = prompt, text = resp })
        end)
    end)
end

---Send a prompt to the configured LLM provider
---@param prompt string user prompt
---@param callback fun(text:string)|nil called with the completion text
---@return userdata|nil handle of the spawned job
function M.complete(prompt, callback)
    local uv = vim.loop
    local body = vim.fn.json_encode({
        model = M.config.model,
        messages = {
            { role = "user", content = prompt },
        },
    })

    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local chunks = {}

    local args = {
        "-s",
        "-X", "POST",
        "-H", "Authorization: Bearer " .. M.config.api_key,
        "-H", "Content-Type: application/json",
        "-d", body,
        M.config.api_url,
    }

    local handle
    handle = uv.spawn("curl", {
        args = args,
        stdio = { nil, stdout, stderr },
    }, function(code)
        stdout:read_stop()
        stderr:read_stop()
        stdout:close()
        stderr:close()
        handle:close()

        local result = ""
        if code == 0 then
            local resp = table.concat(chunks)
            local data = vim.fn.json_decode(resp)
            result = data and data.choices and data.choices[1].message.content or ""
        else
            vim.schedule(function()
                vim.notify("LLM request failed (code " .. code .. ")", vim.log.levels.ERROR)
            end)
        end

        if callback then
            vim.schedule(function()
                callback(result)
            end)
        end
    end)

    stdout:read_start(function(err, data)
        if err then return end
        if data then table.insert(chunks, data) end
    end)

    stderr:read_start(function(err, data)
        if err or not data then return end
        vim.schedule(function()
            vim.notify(data, vim.log.levels.ERROR)
        end)
    end)

    return handle
end

return M

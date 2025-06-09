local M = {}

-- Default options for LLM integration
M.config = {
    api_url = "https://openrouter.ai/api/v1/chat/completions",
    model = "gpt-3.5-turbo",
    api_key = vim.env.OPENROUTER_API_KEY or "",
}

---Setup LLM configuration
function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

---Send a prompt to the configured LLM provider
---@param prompt string user prompt
---@return string result
function M.complete(prompt)
    local curl = require("plenary.curl")

    local res = curl.post(M.config.api_url, {
        headers = {
            ["Authorization"] = "Bearer " .. M.config.api_key,
            ["Content-Type"] = "application/json",
        },
        body = vim.fn.json_encode({
            model = M.config.model,
            messages = {
                { role = "user", content = prompt },
            },
        }),
    })

    if res.status ~= 200 then
        vim.notify("LLM request failed: " .. (res.status or ""), vim.log.levels.ERROR)
        return ""
    end

    local data = vim.fn.json_decode(res.body)
    return data and data.choices and data.choices[1].message.content or ""
end

return M

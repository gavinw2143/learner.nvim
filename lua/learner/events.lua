local M = {}

-- Table storing event name -> list of handlers
M._handlers = {}

---Subscribe to an event
---@param name string
---@param fn fun(...)
function M.subscribe(name, fn)
    if not M._handlers[name] then
        M._handlers[name] = {}
    end
    table.insert(M._handlers[name], fn)
end

---Emit an event, invoking all registered handlers
---@param name string
function M.emit(name, ...)
    local handlers = M._handlers[name]
    if not handlers then
        return
    end
    for _, h in ipairs(handlers) do
        local ok, err = pcall(h, ...)
        if not ok then
            vim.schedule(function()
                vim.notify(err, vim.log.levels.ERROR)
            end)
        end
    end
end

return M

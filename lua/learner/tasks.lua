local Tasks = {}
local storage = require("learner.storage")

-- In-memory table of all tasks
Tasks.list = {}

---Setup task module
function Tasks.setup(config, store)
    Tasks.config = config or {}
    if store then
        storage = store
    end
    Tasks.list = storage.query("tasks") or {}
end

---Add a new learning task
---@param task table expects `desc` and optional `goal_id`
---@return number id of the inserted task
function Tasks.add(task)
    local id = #Tasks.list + 1
    task.id = id
    task.done = false
    table.insert(Tasks.list, task)
    storage.execute("tasks", Tasks.list)
    return id
end

---Mark a task as completed
---@param task_id number
function Tasks.mark_done(task_id)
    for _, t in ipairs(Tasks.list) do
        if t.id == task_id then
            t.done = true
            break
        end
    end
    storage.execute("tasks", Tasks.list)
end

---Remove a task completely
---@param task_id number
function Tasks.remove(task_id)
    for i, t in ipairs(Tasks.list) do
        if t.id == task_id then
            table.remove(Tasks.list, i)
            break
        end
    end
    storage.execute("tasks", Tasks.list)
end

---Update fields on a task
---@param task_id number
---@param fields table
function Tasks.update(task_id, fields)
    for _, t in ipairs(Tasks.list) do
        if t.id == task_id then
            for k, v in pairs(fields) do
                if k ~= "id" then
                    t[k] = v
                end
            end
            break
        end
    end
    storage.execute("tasks", Tasks.list)
end

---List tasks associated with a specific goal
---@param goal_id number
---@return table[]
function Tasks.list_by_goal(goal_id)
    local results = {}
    for _, t in ipairs(Tasks.list) do
        if t.goal_id == goal_id then
            table.insert(results, t)
        end
    end
    return results
end

---Initialize storage data for tasks
function Tasks.migrate()
    if not storage.query("tasks") then
        storage.execute("tasks", {})
    end
end

return Tasks

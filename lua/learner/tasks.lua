local Tasks = {}

function Tasks.setup(config)
	-- initialize task storage, link to goals
	Tasks.config = config or {}
end

function Tasks.add(task)
	-- insert a new learning task
end

function Tasks.mark_done(task_id)
	-- mark a task as completed
end

function Tasks.list_by_goal(goal_id)
	-- return tasks associated with a goal
	return {}
end

return Tasks

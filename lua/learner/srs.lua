local SRS = {}

function SRS.setup(config)
	-- initialize FSRS or other algorithm
	SRS.config = config or {}
end

function SRS.due_topics()
	-- return list of topics due for review
	return {}
end

function SRS.record_review(topic_id, result)
	-- update review history
end

return SRS

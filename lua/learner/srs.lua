local SRS = {}

-- Table storing topic state indexed by id
SRS.topics = {}

-- Default configuration for the scheduler
SRS.config = { base_interval = 1 }

---Setup SRS options
---@param config table|nil
function SRS.setup(config)
    SRS.config = vim.tbl_deep_extend("force", SRS.config, config or {})
end

---Add a new topic to the scheduler
---@param topic table plain table with at least an `id` field
function SRS.add_topic(topic)
    topic.interval = topic.interval or SRS.config.base_interval
    topic.due = topic.due or os.time()
    topic.ease = topic.ease or 2.5
    SRS.topics[topic.id] = topic
end

---Return a list of topics that are due for review
---@return table[]
function SRS.due_topics()
    local now = os.time()
    local due = {}
    for _, t in pairs(SRS.topics) do
        if t.due <= now then
            table.insert(due, t)
        end
    end
    return due
end

---Record the result of a review using a simplified SM-2 formula
---@param topic_id number
---@param quality number score 0-5
function SRS.record_review(topic_id, quality)
    local t = SRS.topics[topic_id]
    if not t then
        return
    end
    quality = tonumber(quality) or 0

    -- Update ease factor
    t.ease = t.ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    if t.ease < 1.3 then
        t.ease = 1.3
    end

    -- Calculate next interval in days
    t.interval = math.max(1, (t.interval * t.ease))
    t.due = os.time() + math.floor(t.interval * 24 * 60 * 60)
    t.last_review = os.time()
end

return SRS

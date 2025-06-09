local srs = require('learner.srs')

local function stub_storage()
  local data = {}
  return {
    query = function(key)
      return data[key]
    end,
    execute = function(key, value)
      data[key] = value
    end,
  }
end

describe('SRS calculations', function()
  local store

  before_each(function()
    store = stub_storage()
    srs.topics = {}
    srs.setup({ base_interval = 1 }, store)
  end)

  it('adds topics that are due immediately', function()
    srs.add_topic({ id = 1, data = { title = 'Lua' } })
    local due = srs.due_topics()
    assert.equals(1, #due)
    assert.equals(1, due[1].id)
  end)

  it('records reviews and schedules next interval', function()
    srs.add_topic({ id = 1 })
    srs.record_review(1, 5)
    local topic = srs.topics[1]
    assert.truthy(topic.interval > 1)
    assert.truthy(topic.due > os.time())
    assert.truthy(topic.last_review)
  end)
end)

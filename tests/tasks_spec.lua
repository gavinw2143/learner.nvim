local tasks = require('learner.tasks')
local storage = require('learner.storage')

local function stub_storage()
  local data = { tasks = {} }
  return {
    data = data,
    query = function(key)
      return data[key]
    end,
    execute = function(key, value)
      data[key] = value
    end,
  }
end

describe('Task persistence', function()
  local store

  before_each(function()
    store = stub_storage()
    tasks.list = {}
    tasks.setup({}, store)
  end)

  it('adds tasks and persists them', function()
    local id = tasks.add({ desc = 'read docs', goal_id = 2 })
    assert.equals(1, id)
    assert.equals(1, #store.data.tasks)
    assert.is_false(store.data.tasks[1].done)
  end)

  it('marks tasks as done', function()
    local id = tasks.add({ desc = 'test' })
    tasks.mark_done(id)
    assert.is_true(store.data.tasks[1].done)
  end)

  it('filters tasks by goal', function()
    tasks.add({ desc = 'a', goal_id = 1 })
    tasks.add({ desc = 'b', goal_id = 2 })
    local res = tasks.list_by_goal(1)
    assert.equals(1, #res)
    assert.equals('a', res[1].desc)
  end)
end)

describe('LLM setup', function()
  local llm
  local events = require('learner.events')

  local function reload()
    package.loaded['learner.llm'] = nil
    llm = require('learner.llm')
  end

  local function stub_schedule()
    local orig = vim.schedule
    vim.schedule = function(fn) fn() end
    return function() vim.schedule = orig end
  end

  local function stub_notify(calls)
    local orig = vim.notify
    vim.notify = function(msg, level) table.insert(calls, {msg = msg, level = level}) end
    return function() vim.notify = orig end
  end

  before_each(function()
    events._handlers = {}
    reload()
  end)

  it('warns when api key missing', function()
    local notes = {}
    local undo_notify = stub_notify(notes)
    local undo_sched = stub_schedule()
    llm.setup({ api_key = '' })
    undo_sched()
    undo_notify()
    assert.is_true(#notes > 0)
    assert.matches('API key', notes[1].msg)
  end)
end)

describe('LLM completion', function()
  local llm
  local events = require('learner.events')
  local uv_orig
  local stdout_pipe
  local stderr_pipe
  local spawn_cb

  local function reload()
    package.loaded['learner.llm'] = nil
    llm = require('learner.llm')
  end

  local function pipe()
    local obj = {}
    function obj:read_start(cb) self.cb = cb end
    function obj:read_stop() end
    function obj:close() end
    function obj:send(data) if self.cb then self.cb(nil, data) end end
    return obj
  end

  local function stub_schedule()
    local orig = vim.schedule
    vim.schedule = function(fn) fn() end
    return function() vim.schedule = orig end
  end

  local function stub_notify(calls)
    local orig = vim.notify
    vim.notify = function(msg, level) table.insert(calls, {msg = msg, level = level}) end
    return function() vim.notify = orig end
  end

  before_each(function()
    events._handlers = {}
    reload()
    local uv = {}
    stdout_pipe = pipe()
    stderr_pipe = pipe()
    function uv.new_pipe()
      if not uv._called then uv._called = true return stdout_pipe else return stderr_pipe end
    end
    function uv.spawn(cmd, opts, cb)
      spawn_cb = cb
      return { close = function() end }
    end
    uv_orig = vim.loop
    vim.loop = uv
  end)

  after_each(function()
    vim.loop = uv_orig
  end)

  it('notifies on non-200 response', function()
    local notes = {}
    local undo_notify = stub_notify(notes)
    local undo_sched = stub_schedule()
    llm.config.api_key = 'test'
    llm.complete('hi')
    stdout_pipe:send('{"error":"bad"}500')
    spawn_cb(0)
    undo_sched()
    undo_notify()
    assert.is_true(#notes > 0)
    assert.matches('bad', notes[1].msg)
  end)
end)

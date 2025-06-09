local storage = require('learner.storage')
local Path = require('plenary.path')

local tmp_dir = Path:new(vim.loop.os_tmpdir()):joinpath('learner_spec')
local db_file = tmp_dir:joinpath('db.json')

describe('File storage initialization', function()
  before_each(function()
    if tmp_dir:exists() then
      tmp_dir:rm({ recursive = true })
    end
  end)

  after_each(function()
    storage.close()
    if tmp_dir:exists() then
      tmp_dir:rm({ recursive = true })
    end
  end)

  it('creates missing directories', function()
    assert.is_false(db_file:exists())
    storage.connect({ path = db_file:absolute() })
    assert.is_true(db_file:exists())
  end)
end)

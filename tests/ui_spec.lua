local ui = require('learner.ui')

describe('UI text sanitization', function()
  before_each(function()
    ui.config = { max_preview_chars = 5 }
  end)

  it('strips control characters', function()
    local txt = ui.sanitize_text('a\031b\n')
    assert.equals('ab\n', txt)
  end)

  it('truncates long text', function()
    local txt = ui.sanitize_text('abcdefg')
    assert.equals('abcde...', txt)
  end)
end)

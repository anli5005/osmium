function create(x, y, w, h)
  local self = {x = x, y = y, w = w, h = h, focused = false, screen = nil, needsRedraw = true}

  function self.draw()
  end

  function self.click()
  end

  function self.drag()
  end

  function self.scroll()
  end

  function self.mouseUp()
  end

  function self.key()
  end

  function self.char()
  end

  function self.keyUp()
  end

  function self.paste()
  end
end

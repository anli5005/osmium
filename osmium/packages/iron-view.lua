function create(x, y, w, h)
  local self = {x = x, y = y, w = w, h = h, focused = false, screen = nil, needsRedraw = true, acceptsFocus = true}

  function self.redraw()
    self.needsRedraw = true
    if self.screen and self.screen.window then
      self.screen.draw()
    end
  end

  function self.forceRedraw()
    self.needsRedraw = true
    if self.screen and self.screen.window then
      self.screen.forceDraw()
    end
  end

  function self.draw(window)
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

  function self.focus()
  end

  function self.blur()
  end

  function self.restoreCursor()
  end

  return self
end

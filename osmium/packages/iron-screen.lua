function create(window)
  local self = {window = window, focusView = nil, views = {}, _callbacks = {}, needsRedraw = false, needsForceRedraw = false}

  function self._callbacks.mouse_click(button, globalX, globalY)
    local wx, wy = self.window.getPosition()
    local x = globalX - wx + 1
    local y = globalY - wy + 1

    self.blur()
    for n = #self.views, 1, -1 do
      local view = self.views[n]
      if view and x >= view.x and x < view.x + view.w and y >= view.y and y < view.y + view.h then
        if view.acceptsFocus and not self.focusView then
          self.focus(view)
        end
        if view.click({
          button = button,
          x = x,
          y = y,
          globalX = globalX,
          globalY = globalY
        }) then
          break
        end
      end
    end
  end

  function self._callbacks.mouse_up(button, globalX, globalY)
    local wx, wy = self.window.getPosition()
    local x = globalX - wx + 1
    local y = globalY - wy + 1
    for n = #self.views, 1, -1 do
      local view = self.views[n]
      if x >= view.x and x < view.x + view.w and y >= view.y and y < view.y + view.h then
        if view.mouseUp({
          button = button,
          x = x,
          y = y
        }) then
          break
        end
      end
    end
  end

  function self._callbacks.mouse_drag(button, x, y)
    for n = #self.views, 1, -1 do
      local view = self.views[n]
      if x >= view.x and x < view.x + view.w and y >= view.y and y < view.y + view.h then
        if view.drag({
          button = button,
          x = x,
          y = y
        }) then
          break
        end
      end
    end
  end

  function self._callbacks.mouse_scroll(direction, x, y)
    for n = #self.views, 1, -1 do
      local view = self.views[n]
      if x >= view.x and x < view.x + view.w and y >= view.y and y < view.y + view.h then
        if view.scroll({
          direction = direction,
          x = x,
          y = y
        }) then
          break
        end
      end
    end
  end

  function self._callbacks.key(code, hold)
    if self.focusView then
      self.focusView.key({
        keyCode = code,
        isBeingHeld = hold
      })
    end
  end

  function self._callbacks.char(char)
    if self.focusView then
      self.focusView.char({
        char = char
      })
    end
  end

  function self._callbacks.key_up(code)
    if self.focusView then
      self.focusView.keyUp({
        keyCode = code
      })
    end
  end

  function self._callbacks.paste(clipboard)
    if self.focusView then
      self.focusView.paste({
        clipboard = clipboard
      })
    end
  end

  function self.addView(view)
    table.insert(self.views, view)
    view.screen = self
    self.requestDraw()
  end

  function self.removeView(view)
    for n,v in ipairs(self.views) do
      if v == view then
        v.screen = nil
        table.remove(self.views, n)
      end
    end
    self.requestForceDraw()
  end

  function self.focus(view)
    self.blur()
    self.focusView = view
    self.focusView.focused = true
    self.focusView.focus()
  end

  function self.blur()
    if self.focusView then
      self.focusView.focused = false
      self.focusView.blur()
    end
    self.focusView = nil
  end

  function self.draw()
    if self.window then
      local didDraw = false
      for i,view in ipairs(self.views) do
        if view.needsRedraw or didDraw then
          view.draw(self.window)
          didDraw = true
          view.needsRedraw = false
        end
      end
      term.setCursorBlink(false)
      if didDraw and self.focusView then
        self.focusView.restoreCursor(self.window)
      end
    end
  end

  function self.forceDraw()
    if self.window then
      self.window.setBackgroundColor(colors.black)
      self.window.clear()
      for i,view in ipairs(self.views) do
        view.draw(self.window)
        view.needsRedraw = false
      end
      term.setCursorBlink(false)
      if self.focusView then
        self.focusView.restoreCursor(self.window)
      end
    end
  end

  function self.requestDraw()
    if self.loop and self.loop.running then
      self.needsRedraw = true
    else
      self.draw()
    end
  end

  function self.requestForceDraw()
    if self.loop and self.loop.running then
      self.needsForceRedraw = true
    else
      self.forceDraw()
    end
  end

  function self._lastHandler()
    if self.needsForceRedraw then
      self.forceDraw()
    elseif self.needsRedraw then
      self.draw()
    end
    self.needsRedraw = false
    self.needsForceRedraw = false
  end

  function self.attach(loop)
    if self.loop == nil then
      self.loop = loop
      for k,v in pairs(self._callbacks) do
        loop.on(k, v)
      end
      loop.last(self._lastHandler)
    end
  end

  function self.detach()
    for k,v in pairs(self._callbacks) do
      self.loop.off(v)
    end
    self.loop.off(self._lastHandler)
    self.loop = nil
  end

  return self
end

function create(window, loop)
  local self = {window = window, loop = loop, focus = nil, views = {}}

  function addView(view)
    table.insert(self.views, view)
    view.screen = self
    self.draw()
  end

  function removeView(view)
    for n,v in ipairs(self.views) do
      if v == view then
        v.screen = nil
        table.remove(self.views, n)
      end
    end
    self.forceDraw()
  end

  function focus(view)
    if self.focus then
      self.focus.focused = false
    end
    self.focus = view
    self.focus.focused = true
    self.draw()
  end

  function blur(view)
    if self.focus then
      self.focus.focused = false
    end
    self.focus = nil
    self.draw()
  end

  function draw()
    for i,view in ipairs(self.views) do
      if view.needsRedraw then
        view.draw()
        view.needsRedraw = false
      end
    end
  end

  function forceDraw()
    for i,view in ipairs(self.views) do
      view.draw()
      view.needsRedraw = false
    end
  end

  return self
end

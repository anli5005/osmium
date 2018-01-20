local IronView = opm.require("iron-view")

box = {}
function box.create(x, y, w, h, color)
  local self = IronView.create(x, y, w, h)
  self.color = color

  function self.draw(window)
    window.setBackgroundColor(self.color)
    for y = self.y,self.y + self.h - 1 do
      window.setCursorPos(self.x, y)
      for i = 1,self.w do
        window.write(" ")
      end
    end
  end

  return self
end

text = {}
function text.create(x, y, w, h, text)
  local self = IronView.create(x, y, w, h)
  self.text = text
  self.backgroundColor = colors.black
  self.textColor = colors.white

  function self.draw(window)
    window.setBackgroundColor(self.backgroundColor)
    window.setTextColor(self.textColor)
    window.setCursorPos(self.x, self.y)
    window.write(self.text)
  end

  return self
end

button = {}
function button.create(x, y, w, h, text, action)
  local self = IronView.create(x, y, w, h)
  self.text = text
  self.action = action
  self.backgroundColor = colors.lightGray
  self.textColor = colors.black
  self.activeBackgroundColor = colors.gray
  self.activeTextColor = colors.lightGray
  self.disabledBackgroundColor = colors.lightGray
  self.disabledTextColor = colors.gray
  self.isActive = false
  self._disabled = false

  function self.draw(window)
    if self._disabled then
      window.setBackgroundColor(self.disabledBackgroundColor)
      window.setTextColor(self.disabledTextColor)
    elseif self.isActive then
      window.setBackgroundColor(self.activeBackgroundColor)
      window.setTextColor(self.activeTextColor)
    else
      window.setBackgroundColor(self.backgroundColor)
      window.setTextColor(self.textColor)
    end

    for y = self.y,self.y + self.h - 1 do
      window.setCursorPos(self.x, y)
      for i = 1,self.w do
        window.write(" ")
      end
    end

    local writeX = self.x + math.floor((self.w - string.len(self.text)) / 2) - 1
    local writeY = self.y + math.floor((self.h - 1) / 2)
    window.setCursorPos(writeX, writeY)
    window.write(self.text)
  end

  function self.click(event)
    if event.button == 1 and not self._disabled then
      self.isActive = true
      self.redraw()
    end
  end

  function self.mouseUp(event)
    if event.button == 1 and self.isActive and not self._disabled then
      self.isActive = false
      self.redraw()
      if self.action then
        self.action()
      end
      return true
    end
  end

  function self.getDisabled()
    return self._disabled
  end

  function self.setDisabled(disabled)
    self._disabled = disabled
    self.isActive = false
    self.redraw()
  end

  return self
end

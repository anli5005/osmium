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
function button.create(x, y, w, h, text)
  local self = IronView.create(x, y, w, h)
  self.text = text
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
      self.emit("press")
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

input = {}
function input.create(x, y, w, h, value, replaceChar)
  local self = IronView.create(x, y, w, h)
  self.backgroundColor = colors.lightGray
  self.textColor = colors.black
  self.placeholderColor = colors.gray
  self.disabledBackgroundColor = colors.white
  self.disabledTextColor = colors.gray
  self.disabledPlaceholderColor = colors.lightGray
  self._disabled = false
  self.value = ""
  self.placeholder = ""
  self.leftMargin = 1
  self.replaceChar = replaceChar
  if value then
    self.value = value
  else
    self.value = ""
  end
  self.cursorPos = 0

  function self.draw(window)
    if self._disabled then
      window.setBackgroundColor(self.disabledBackgroundColor)
    else
      window.setBackgroundColor(self.backgroundColor)
    end

    for y = self.y,self.y + self.h - 1 do
      window.setCursorPos(self.x, y)
      for i = 1,self.w do
        window.write(" ")
      end
    end

    local scroll = math.max(self.leftMargin + self.cursorPos + 1 - self.w, 0)
    local toWrite = string.rep(" ", self.leftMargin)
    if string.len(self.value) > 0 then
      if self._disabled then
        window.setTextColor(self.disabledTextColor)
      else
        window.setTextColor(self.textColor)
      end
      if self.replaceChar then
        toWrite = toWrite .. string.rep(self.replaceChar, string.len(self.value))
      else
        toWrite = toWrite .. self.value
      end
    else
      if self._disabled then
        window.setTextColor(self.disabledPlaceholderColor)
      else
        window.setTextColor(self.placeholderColor)
      end
      toWrite = toWrite .. self.placeholder
    end

    local textY = self.y + math.floor(self.h / 2)
    window.setCursorPos(self.x, textY)
    window.write(string.sub(toWrite, scroll + 1, scroll + self.w))
  end

  function self.restoreCursor(window)
    if self.focused then
      window.setTextColor(self.textColor)
      window.setCursorPos(self.x + math.min(self.w - 1, self.leftMargin + self.cursorPos), self.y + math.floor(self.h / 2))
      window.setCursorBlink(true)
    end
  end

  function self.blur()
    self.redraw()
  end

  function self.focus()
    self.redraw()
  end

  function self.char(event)
    self.value = string.sub(self.value, 1, self.cursorPos + 1) .. event.char .. string.sub(self.value, self.cursorPos + 2)
    self.cursorPos = self.cursorPos + 1
    self.redraw()
  end

  function self.paste(event)
    self.value = string.sub(self.value, 1, self.cursorPos + 1) .. event.clipboard .. string.sub(self.value, self.cursorPos + 2)
    self.cursorPos = self.cursorPos + string.len(event.clipboard)
    self.redraw()
  end

  function self.key(event)
    if event.keyCode == keys.backspace or event.keyCode == keys.delete then
      if self.cursorPos > 0 then
        self.cursorPos = self.cursorPos - 1
      end
      self.value = string.sub(self.value, 1, self.cursorPos) .. string.sub(self.value, self.cursorPos + 2)
      self.redraw()
    end
    if event.keyCode == keys.left then
      if self.cursorPos > 0 then
        self.cursorPos = self.cursorPos - 1
        self.redraw()
      end
    end
    if event.keyCode == keys.right then
      if self.cursorPos < string.len(self.value) then
        self.cursorPos = self.cursorPos + 1
        self.redraw()
      end
    end
    if event.keyCode == keys.enter then
      self.emit("enter")
    end
  end

  function self.getDisabled()
    return self._disabled
  end

  function self.setDisabled(disabled)
    self._disabled = disabled
    self.acceptsFocus = not self._disabled
    self.redraw()
  end

  return self
end

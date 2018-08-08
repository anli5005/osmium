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
    window.write(string.rep(" ", self.w))
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

    local writeX = self.x + math.floor((self.w - string.len(self.text)) / 2)
    local writeY = self.y + math.floor((self.h - 1) / 2)
    window.setCursorPos(writeX, writeY)
    window.write(self.text)
  end

  function self.click(event)
    if event.button == 1 and not self._disabled then
      self.isActive = true
      self.redraw()
    end
    return true
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
    self.emit("change", self.value)
    self.redraw()
  end

  function self.paste(event)
    self.value = string.sub(self.value, 1, self.cursorPos + 1) .. event.clipboard .. string.sub(self.value, self.cursorPos + 2)
    self.cursorPos = self.cursorPos + string.len(event.clipboard)
    self.emit("change", self.value)
    self.redraw()
  end

  function self.key(event)
    if event.keyCode == keys.backspace or event.keyCode == keys.delete then
      self.value = string.sub(self.value, 1, self.cursorPos - 1) .. string.sub(self.value, self.cursorPos + 1)
      if self.cursorPos > 0 then
        self.cursorPos = self.cursorPos - 1
        self.emit("change", self.value)
      else
        self.emit("ding")
      end
      self.redraw()
    end
    if event.keyCode == keys.left then
      if self.cursorPos > 0 then
        self.cursorPos = self.cursorPos - 1
        self.redraw()
      else
        self.emit("ding")
      end
    end
    if event.keyCode == keys.right then
      if self.cursorPos < string.len(self.value) then
        self.cursorPos = self.cursorPos + 1
        self.redraw()
      else
        self.emit("ding")
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

checkbox = {}
function checkbox.create(x, y, w, h, text, checked)
  local self = IronView.create(x, y, w, h)
  self.text = text
  self.backgroundColor = colors.black
  self.textColor = colors.white
  self.boxBackgroundColor = colors.lightGray
  self.checkedBackgroundColor = colors.blue
  self.checkedTextColor = colors.lightBlue
  self.disabledBackgroundColor = colors.white
  self.disabledTextColor = colors.lightGray
  self.isChecked = checked or false
  self._disabled = false

  function self.draw(window)
    if self._disabled then
      window.setBackgroundColor(self.disabledBackgroundColor)
      window.setTextColor(self.disabledTextColor)
    elseif self.isChecked then
      window.setBackgroundColor(self.checkedBackgroundColor)
      window.setTextColor(self.checkedTextColor)
    else
      window.setBackgroundColor(self.boxBackgroundColor)
    end

    window.setCursorPos(self.x, self.y)
    if self.isChecked then
      window.write("X")
    else
      window.write(" ")
    end

    if self.text then
      window.setCursorPos(self.x + 2, self.y)
      window.setBackgroundColor(self.backgroundColor)
      window.setTextColor(self.textColor)
      window.write(self.text)
    end
  end

  function self.click(event)
    if event.button == 1 and not self._disabled then
      self.isChecked = not self.isChecked
      self.emit("change", self.isChecked)
      self.redraw()
    end
  end

  function self.getDisabled()
    return self._disabled
  end

  function self.setDisabled(disabled)
    self._disabled = disabled
    self.redraw()
  end

  return self
end

scroller = {}
function scroller.create(view, contentHeight, color)
  local self = {contentHeight = contentHeight, view = view, color = color or colors.lightGray, pos = 0, isScrolling = false, isVisible = (contentHeight > view.h)}
  view.scroller = self

  function self.updateVisible()
    self.isVisible = (self.contentHeight > self.view.h) or self.isScrolling
  end

  function self.draw(window)
    self.updateVisible()
    if self.isVisible then
      local x = self.view.x + self.view.w - 1
      local y = math.min(math.ceil((math.max(1, self.pos + 1) / self.contentHeight) * self.view.h) + self.view.y - 1, self.view.y + self.view.h - 1)
      local h = math.min(math.ceil((self.view.h / self.contentHeight) * self.view.h), self.view.h + 2 - y)
      window.setBackgroundColor(self.color)
      for i = 0,h - 1 do
        window.setCursorPos(x, y + i)
        window.write(" ")
      end
    end
  end

  function self.scroll(event)
    if event.direction < 0 then
      if self.pos > 0 then
        self.pos = self.pos - 1
        self.view.redraw()
      end
    elseif event.direction > 0 then
      if (self.pos + self.view.h) < self.contentHeight then
        self.pos = self.pos + 1
        self.view.redraw()
      end
    end
  end

  function self.click(event)
    local x = self.view.x + self.view.w - 1
    if event.x == x and event.button == 1 and self.isVisible then
      self.isScrolling = true
      local y = event.y - self.view.y + 1
      local h = math.ceil((self.view.h / self.contentHeight) * self.view.h)
      if y < math.floor((self.pos / self.contentHeight) * self.view.h) or y >= math.ceil((self.pos / self.contentHeight) * self.view.h) + h then
        self._dragPos = 0
        self.drag(event)
        return true
      else
        self._dragPos = y - math.ceil((self.pos / self.contentHeight) * self.view.h)
        self.view.redraw()
        return true
      end
    end
  end

  function self.drag(event)
    if self.isScrolling then
      local y = event.y - self.view.y
      self.pos = math.ceil(math.min(((y + (self._dragPos or 0)) / (self.view.h - 1)) * self.contentHeight, self.contentHeight - self.view.h))
      self.view.redraw()
      return true
    end
  end

  function self.mouseUp()
    if self.isScrolling then
      self.isScrolling = false
      self.view.redraw()
      return true
    end
    return false
  end

  return self
end

list = {rows = {}}
function list.rows.default(height)
  local self = {height = height or 1, padding = 1, selectable = true}

  function self.drawLine(window, row, num, isSelected, x, y, w, view)
    if isSelected then
      window.setBackgroundColor(view.selectedBackgroundColor)
      window.setTextColor(view.selectedTextColor or colors.white)
    else
      window.setBackgroundColor(view.backgroundColor)
      window.setTextColor(view.textColor or colors.black)
    end
    window.setCursorPos(x, y)
    if num ~= math.ceil(self.height / 2) then
      window.write(string.rep(" ", w))
    else
      window.write(string.rep(" ", self.padding) .. row.text .. string.rep(" ", math.max(0, w - (self.padding + string.len(row.text)))))
    end
  end

  return self
end

function list.create(x, y, w, h, rows, row)
  local self = IronView.create(x, y, w, h)
  self.backgroundColor = colors.white
  self.selectedBackgroundColor = colors.blue
  self.textColor = colors.black
  self.selectedTextColor = colors.white
  self.row = row or list.rows.default()
  self._rows = rows or {}
  self._padding = 1
  self.selectedRow = nil

  local scroller = scroller.create(self, 0)

  function self.update()
    scroller.contentHeight = (2 * self._padding) + (#self._rows * self.row.height)
    self.redraw()
  end

  function self.addRow(row)
    table.insert(self._rows, row)
    self.update()
  end

  function self.modifyRow(row, index)
    self._rows[index] = row
    self.redraw()
  end

  function self.removeRow(index)
    scroller.pos = 0
    table.remove(self._rows, index)
    self.update()
  end

  function self.removeAllRows()
    scroller.pos = 0
    self._rows = {}
    self.update()
  end

  function self.countRows()
    return #self._rows
  end

  function self.getPadding()
    return self._padding
  end

  function self.setPadding(padding)
    self._padding = padding
    self.update()
  end

  function self.draw(window)
    local y = self.y
    local h = (2 * self._padding) + (#self._rows * self.row.height)
    for line = scroller.pos + 1, scroller.pos + self.h do
      if line > self._padding and line <= h - self._padding then
        local listY = line - self._padding
        local index = math.ceil(listY / self.row.height)
        local row = self._rows[index]
        self.row.drawLine(window, row, ((listY - 1) % self.row.height) + 1, self.selectedRow == index, self.x, y, self.w, self)
      else
        window.setCursorPos(self.x, y)
        window.setBackgroundColor(self.backgroundColor)
        window.write(string.rep(" ", self.w))
      end
      y = y + 1
    end
    scroller.draw(window)
  end

  function self.scroll(event)
    scroller.scroll(event)
  end

  function self.click(event)
    if not scroller.click(event) then
      local line = scroller.pos + 1 + event.y - self.y
      local h = (2 * self._padding) + (#self._rows * self.row.height)
      if line > self._padding and line <= h - self._padding then
        local listY = line - self._padding
        local index = math.ceil(listY / self.row.height)
        local row = self._rows[index]
        self.emit("click", row)
        if self.selectedRow ~= index then
          if self.selectedRow then
            self.emit("deselect", row)
          end
          if self.row.selectable then
            self.selectedRow = index
            self.emit("select", row)
          else
            self.selectedRow = nil
          end
          self.redraw()
        end
      else
        self.emit("paddingClick")
      end
    end
  end

  function self.drag(event)
    scroller.drag(event)
  end

  function self.mouseUp(event)
    scroller.mouseUp(event)
  end

  self.update()
  return self
end

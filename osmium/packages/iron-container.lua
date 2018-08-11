local IronView = opm.require("iron-view")
local imageutils = opm.require("imageutils")

function create(x, y, w, h)
  local self = IronView.create(x, y, w, h)
  self.cursorBlink = false
  self.buffer = {{bg = {}, fg = {}, text = {}}}
  self.backgroundColor = colors.black
  self.textColor = colors.white
  self.cursorPos = {1, 1}
  local i = 1
  while i <= h do
    self.buffer[1].bg[i] = {}
    self.buffer[1].fg[i] = {}
    self.buffer[1].text[i] = {}
    local j = 1
    while j <= w do
      self.buffer[1].bg[i][j] = self.backgroundColor
      self.buffer[1].fg[i][j] = self.textColor
      self.buffer[1].text[i][j] = " "
      j = j + 1
    end
    i = i + 1
  end

  function self.draw(window)
    local curr = term.current()
    term.redirect(window)
    term.setCursorPos(x, y)
    imageutils.drawImage(self.buffer, colors.black)
    term.redirect(curr)
  end

  function self.click(event)
    self.emit("mouse_click", event.button, event.x, event.y)
  end

  function self.mouseUp(event)
    self.emit("mouse_up", event.button, event.x, event.y)
  end

  function self.drag(event)
    self.emit("mouse_drag", event.button, event.x, event.y)
  end

  function self.scroll(event)
    self.emit("mouse_scroll", event.direction, event.x, event.y)
  end

  function self.key(event)
    self.emit("key", event.keyCode, event.isBeingHeld)
  end

  function self.char(event)
    self.emit("char", event.char)
  end

  function self.keyUp(event)
    self.emit("key_up", event.keyCode)
  end

  function self.paste(event)
    self.emit("paste", event.clipboard)
  end

  function self.write(text)
    local i = 0
    while i < math.min(#text, self.w - self.cursorPos[1] + 1) do
      self.buffer[1].bg[self.cursorPos[2]][self.cursorPos[1] + i] = self.backgroundColor
      self.buffer[1].fg[self.cursorPos[2]][self.cursorPos[1] + i] = self.textColor
      self.buffer[1].text[self.cursorPos[2]][self.cursorPos[1] + i] = string.sub(text, i + 1, i + 1)
      i = i + 1
    end
    self.cursorPos[1] = self.cursorPos[1] + #text
    self.redraw()
  end

  local paintColors = {
    ["0"] = colors.white,
    ["1"] = colors.orange,
    ["2"] = colors.magenta,
    ["3"] = colors.lightBlue,
    ["4"] = colors.yellow,
    ["5"] = colors.lime,
    ["6"] = colors.pink,
    ["7"] = colors.gray,
    ["8"] = colors.lightGray,
    ["9"] = colors.cyan,
    ["a"] = colors.purple,
    ["b"] = colors.blue,
    ["c"] = colors.brown,
    ["d"] = colors.green,
    ["e"] = colors.red,
    ["f"] = colors.black
  }

  function self.blit(text, bg, fg)
    local i = 0
    while i < math.min(#text, self.w - self.cursorPos[1] + 1) do
      self.buffer[1].bg[self.cursorPos[2]][self.cursorPos[1] + i] = paintColors[string.sub(bg, i + 1, i + 1)]
      self.buffer[1].fg[self.cursorPos[2]][self.cursorPos[1] + i] = paintColors[string.sub(fg, i + 1, i + 1)]
      self.buffer[1].text[self.cursorPos[2]][self.cursorPos[1] + i] = string.sub(text, i + 1, i + 1)
      i = i + 1
    end
    self.cursorPos[1] = self.cursorPos[1] + #text
    self.redraw()
  end

  function self.clear()
    local i = 1
    while i <= h do
      local j = 1
      while j <= w do
        self.buffer[1].bg[i][j] = self.backgroundColor
        self.buffer[1].fg[i][j] = self.textColor
        self.buffer[1].text[i][j] = " "
        j = j + 1
      end
      i = i + 1
    end
    self.cursorPos = {1, self.cursorPos[2] + 1}
    self.redraw()
  end

  function self.clearLine()
    local i = self.cursorPos[2]
    local j = 1
    while j <= w do
      self.buffer[1].bg[i][j] = self.backgroundColor
      self.buffer[1].fg[i][j] = self.textColor
      self.buffer[1].text[i][j] = " "
      j = j + 1
    end
    self.cursorPos = {1, self.cursorPos[2] + 1}
    self.redraw()
  end

  function self.scroll(lines)
    local i = 1
    while i <= self.h - lines do
      self.buffer[1].bg[i] = self.buffer[1].bg[i + lines]
      self.buffer[1].fg[i] = self.buffer[1].fg[i + lines]
      self.buffer[1].text[i] = self.buffer[1].text[i + lines]
      i = i + 1
    end
    while i <= self.h do
      local j = 1
      while j <= w do
        self.buffer[1].bg[i][j] = self.backgroundColor
        self.buffer[1].fg[i][j] = self.textColor
        self.buffer[1].text[i][j] = " "
        j = j + 1
      end
    end
    self.cursorPos = {1, self.h}
    self.redraw()
  end

  function self.getCursorPos()
    return self.cursorPos[1], self.cursorPos[2]
  end

  function self.setCursorPos(x, y)
    self.cursorPos = {x, y}
  end

  function self.setCursorBlink(blink)
    self.cursorBlink = blink
  end

  function self.getBackgroundColor()
    return self.backgroundColor
  end

  function self.getTextColor()
    return self.textColor
  end

  function self.setBackgroundColor(color)
    self.backgroundColor = color
  end

  function self.setTextColor(color)
    self.textColor = color
  end

  function self.isColor(color)
    if self.screen and self.screen.window then
      return self.screen.window.isColor()
    else
      return true
    end
  end

  function self.getSize()
    return self.w, self.h
  end

  function self.getPosition()
    return self.x, self.y
  end

  self.getBackgroundColour = self.getBackgroundColor
  self.getTextColour = self.getTextColor
  self.setBackgroundColour = self.setBackgroundColor
  self.setTextColour = self.setTextColor
  self.isColour = self.isColor

  function self.restoreCursor(win)
    win.setCursorPos(self.x + self.cursorPos[1] - 1, self.y + self.cursorPos[2] - 1)
    win.setCursorBlink(self.cursorBlink)
  end

  return self
end

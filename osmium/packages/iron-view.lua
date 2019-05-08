local events = opm.require("iron-events")

---@class IronView: IronEventEmitter
---@field public x number
---@field public y number
---@field public w number
---@field public h number
---@field public focused boolean
---@field public screen IronScreen
---@field public needsRedraw boolean
---@field public acceptsFocus boolean

function create(x, y, w, h)
  ---@type IronView
  local self = events.create()
  self.x = x
  self.y = y
  self.w = w
  self.h = h
  self.focused = false
  self.screen = nil
  self.needsRedraw = true
  self.acceptsFocus = true

  function self.redraw()
    self.needsRedraw = true
    if self.screen and self.screen.window then
      self.screen.requestDraw()
    end
  end

  function self.forceRedraw()
    self.needsRedraw = true
    if self.screen and self.screen.window then
      self.screen.requestForceDraw()
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

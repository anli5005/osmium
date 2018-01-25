if _HOST then
  local IronView = opm.require("iron-view")
  local bigfont = opm.require("wojbie-bigfont")

  supportsTeletext = true
  text = {}
  function text.create(x, y, w, h, text, size)
    local self = IronView.create(x, y, w, h)
    self.text = text
    self.backgroundColor = colors.black
    self.textColor = colors.white
    self.size = size or 1

    function self.draw(window)
      window.setBackgroundColor(self.backgroundColor)
      window.setTextColor(self.textColor)
      bigfont.writeOn(window, self.size, string.rep(" ", self.w), self.x, self.y)
      bigfont.writeOn(window, self.size, self.text, self.x, self.y)
    end

    return self
  end
else
  local UI = opm.require("osmium-ui")
  supportsTeletext = false
  text = UI.text
end

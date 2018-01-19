local events = opm.require("iron-events")

function create()
  local self = events.create()

  self.running = false
  self._isStopping = false

  function self.run()
    self.running = true
    self._isStopping = false
    while true do
      if self._isStopping then
        break
      end

      local event, p1, p2, p3, p4, p5 = os.pullEvent()
      self.emit(event, p1, p2, p3, p4, p5)
    end
    self._isStopping = false
    self.running = false
  end

  function self.oneEvent()
    local event, p1, p2, p3, p4, p5 = os.pullEvent()
    self.emit(event, p1, p2, p3, p4, p5)
  end

  function self.stop()
    self._isStopping = true
  end

  return self
end

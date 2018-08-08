function create()
  local self = {_callbacks = {}, _onceCallbacks = {}, _allCallbacks = {}, _lastCallbacks = {}}

  function self.on(name, callback)
    if not self._callbacks[name] then
      self._callbacks[name] = {}
    end
    table.insert(self._callbacks[name], callback)
  end

  function self.once(name, callback)
    if not self._onceCallbacks[name] then
      self._onceCallbacks[name] = {}
    end
    table.insert(self._onceCallbacks[name], callback)
  end

  function self.all(callback)
    table.insert(self._allCallbacks, callback)
  end

  function self.last(callback)
    table.insert(self._lastCallbacks, callback)
  end

  function self.off(callback)
    for k,v in pairs(self._callbacks) do
      for n,c in ipairs(v) do
        if c == callback then
          table.remove(v, n)
        end
      end
    end
    for k,v in pairs(self._onceCallbacks) do
      for n,c in ipairs(v) do
        if c == callback then
          table.remove(v, n)
        end
      end
    end
    for n,c in ipairs(self._allCallbacks) do
      if c == callback then
        table.remove(self._allCallbacks, n)
      end
    end
    for n,c in ipairs(self._lastCallbacks) do
      if c == callback then
        table.remove(self._lastCallbacks, n)
      end
    end
  end

  function self.emit(name, ...)
    if self._callbacks[name] then
      for n,callback in ipairs(self._callbacks[name]) do
        callback(unpack(arg))
      end
    end

    if self._onceCallbacks[name] then
      for n,callback in ipairs(self._onceCallbacks[name]) do
        callback(unpack(arg))
      end
      self._onceCallbacks[name] = {}
    end

    for n,callback in ipairs(self._allCallbacks) do
      callback(name, unpack(arg))
    end

    for n,callback in ipairs(self._lastCallbacks) do
      callback(name, unpack(arg))
    end
  end

  return self
end

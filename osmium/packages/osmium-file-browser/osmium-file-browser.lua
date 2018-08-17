local IronScreen = opm.require("iron-screen")
local UI = opm.require("osmium-ui")
local events = opm.require("iron-events")
local filesize = opm.require("osmium-filesize")
local filetypes = opm.require("osmium-filetype-registry")

function create(window, options)
  local self = events.create()
  self.screen = IronScreen.create(window)
  self.back = {}
  self.forward = {}

  self.extensions = filetypes.getAll()

  local home = fs.combine("home", osmium.user.username)
  local apps = "apps"
  local system = "osmium"
  self.dir = options.dir or home

  function self.getPathDescription(dir, skipReadOnly)
    local desc
    if dir == home or dir == "/" .. home then
      desc = osmium.user.username
    elseif dir == system or dir == "/" .. system then
      desc = "Osmium System"
    elseif dir == apps or dir == "/" .. apps then
      desc = "Applications"
    elseif dir == "/" or dir == "" then
      desc = os.getComputerLabel() or "Computer"
    elseif dir == "/rom" or dir == "rom" then
      desc = "ROM"
    else
      desc = fs.getName(dir)
    end
    if not skipReadOnly and fs.isReadOnly(dir) then
      desc = desc .. " (read-only)"
    end
    return desc
  end

  function self.getAppsFor(path)
    local ext = path:match("^.+(%..+)$")
    local type = ".file"
    if ext then
      type = ext:sub(2)
    end
    local extdata = self.extensions[type]
    if not (extdata and extdata.preferred) then
      extdata = self.extensions[".file"]
    end
    local apps = {}
    local l = #extdata.preferred
    for k,v in ipairs(extdata.preferred) do
      apps[k] = v
    end
    for k,v in ipairs(extdata.canOpen) do
      apps[l + k] = v
    end
    return apps
  end

  function self.openFile(path)
    local app = self.getAppsFor(path)[1]
    local args = app.args or {}
    local slashPath = path
    if slashPath:sub(1,1) ~= "/" then
      slashPath = "/" .. slashPath
    end
    local tabID
    if app.execute then
      tabID = osmium.run(path, unpack(args))
    else
      local runtimeArgs = {}
      for k,v in ipairs(args) do
        runtimeArgs[k] = v
      end
      table.insert(runtimeArgs, slashPath)
      tabID = osmium.run(app.exec, unpack(runtimeArgs))
    end
    osmium.switchTo(tabID)
  end

  local w, h = window.getSize()

  local toolbar = UI.box.create(1, 1, w, 3, colors.lightGray)
  self.screen.addView(toolbar)

  local back = UI.button.create(2, 2, 3, 1, "<")
  back.backgroundColor = colors.white
  back.disabledBackgroundColor = colors.white
  back.disabledTextColor = colors.lightGray
  back.setDisabled(true)
  self.screen.addView(back)

  local forward = UI.button.create(6, 2, 3, 1, ">")
  forward.backgroundColor = colors.white
  forward.disabledBackgroundColor = colors.white
  forward.disabledTextColor = colors.lightGray
  forward.setDisabled(true)
  self.screen.addView(forward)

  back.on("press", function()
    table.insert(self.forward, self.dir)
    forward.setDisabled(false)
    self.go(self.back[#self.back])
    table.remove(self.back)
    back.setDisabled(#self.back < 1)
  end)
  forward.on("press", function()
    table.insert(self.back, self.dir)
    back.setDisabled(false)
    self.go(self.forward[#self.forward])
    table.remove(self.forward)
    forward.setDisabled(#self.forward < 1)
  end)

  local path = UI.button.create(10, 2, w - 21, 1, self.getPathDescription(self.dir) .. " v")
  path.backgroundColor = colors.white
  self.screen.addView(path)

  local addFolder = UI.button.create(w - 10, 2, 10, 1, "+ Folder")
  addFolder.backgroundColor = colors.white
  addFolder.disabledBackgroundColor = colors.white
  addFolder.disabledTextColor = colors.lightGray
  addFolder.textColor = colors.black
  self.screen.addView(addFolder)
  addFolder.on("press", function()
    local x = math.floor((w - 25) / 2)
    local y = math.floor((h - 5) / 2)
    local dialog = UI.box.create(x, y, 25, 5, colors.lightGray)
    function dialog.click()
      return true
    end
    self.screen.addView(dialog)

    local folderName = UI.input.create(x + 1, y + 1, 23, 1)
    folderName.backgroundColor = colors.white
    folderName.placeholderColor = colors.lightGray
    folderName.placeholder = "New Folder Name"
    self.screen.addView(folderName)

    local cancel = UI.button.create(x + 9, y + 3, 8, 1, "Cancel")
    cancel.backgroundColor = colors.white
    self.screen.addView(cancel)

    local save = UI.button.create(x + 18, y + 3, 6, 1, "Save")
    save.backgroundColor = colors.blue
    save.textColor = colors.white
    save.activeBackgroundColor = colors.cyan
    save.activeTextColor = colors.white
    save.disabledBackgroundColor = colors.lightGray
    save.disabledTextColor = colors.gray
    save.setDisabled(true)
    self.screen.addView(save)

    folderName.on("change", function(value)
      save.setDisabled(not (value and #value > 0 and not value:find("/")))
    end)

    cancel.on("press", function()
      self.screen.removeView(dialog)
      self.screen.removeView(folderName)
      self.screen.removeView(cancel)
      self.screen.removeView(save)
    end)

    save.on("press", function()
      local path = fs.combine(self.dir, folderName.value)
      if not fs.exists(path) then
        fs.makeDir(path)
      end
      self.navigate(path)
      self.screen.removeView(dialog)
      self.screen.removeView(folderName)
      self.screen.removeView(cancel)
      self.screen.removeView(save)
    end)
  end)

  local menu = nil

  path.on("press", function()
    if menu then
      self.screen.removeView(menu)
      menu = nil
    else
      local rows = {
        {isDir = true, text = self.getPathDescription("/", true), path = "/"}
      }
      local currentPath = ""
      for str in string.gmatch(self.dir, "([^/]+)") do -- from Stack Overflow
        currentPath = currentPath .. "/" .. str
        table.insert(rows, {isDir = true, text = self.getPathDescription(currentPath, true), path = currentPath})
      end

      table.insert(rows, {subheader = true, text = ""})
      table.insert(rows, {subheader = true, text = "Favorites"})
      table.insert(rows, {isDir = true, text = self.getPathDescription(home, true), path = home})
      table.insert(rows, {isDir = true, text = self.getPathDescription(apps, true), path = apps})
      table.insert(rows, {isDir = true, text = self.getPathDescription(system, true), path = system})

      menu = UI.list.create(10, 3, w - 10, h - 3, rows)
      menu.backgroundColor = colors.gray
      menu.textColor = colors.white
      menu.setPadding(1)
      menu.row = {selectable = false, height = 1}
      function menu.row.drawLine(window, row, num, isSelected, x, y, w, view)
        window.setCursorPos(x, y)
        if row.subheader then
          window.setBackgroundColor(view.backgroundColor)
          window.setTextColor(colors.lightGray)
          window.write("  " .. row.text .. string.rep(" ", math.max(0, (w - 2) - string.len(row.text))))
        else
          if row.path == "/" or row.path == "" then
            window.setBackgroundColor(colors.lightGray)
            window.setTextColor(colors.gray)
            window.write("C")
          elseif row.path == home or row.path == "/" .. home then
            window.setBackgroundColor(colors.brown)
            window.setTextColor(colors.orange)
            window.write("H")
          elseif row.path == system or row.path == "/" .. system then
            window.setBackgroundColor(colors.lightBlue)
            window.setTextColor(colors.cyan)
            window.write("S")
          elseif row.path == apps or row.path == "/" .. apps then
            window.setBackgroundColor(colors.lightBlue)
            window.setTextColor(colors.cyan)
            window.write("A")
          elseif row.path == "rom" or row.path == "/rom" then
            window.setBackgroundColor(colors.lightGray)
            window.setTextColor(colors.gray)
            window.write("R")
          elseif row.isDir then
            window.setBackgroundColor(colors.lightBlue)
            window.setTextColor(colors.cyan)
            window.write("/")
          elseif row.type and self.extensions[string.sub(row.type, 2)] then
            local ext = self.extensions[string.sub(row.type, 2)]
            window.setBackgroundColor(ext.bg)
            window.setTextColor(ext.fg)
            window.write(ext.text)
          else
            window.setBackgroundColor(colors.gray)
            window.setTextColor(colors.lightGray)
            window.write("-")
          end
          window.setBackgroundColor(view.backgroundColor or colors.white)
          window.setTextColor(view.textColor or colors.black)
          window.write(" " .. row.text .. string.rep(" ", math.max(0, (w - 2) - string.len(row.text))))
        end
      end
      menu.on("click", function(row)
        if row and not row.subheader then
          self.navigate(row.path)
          self.screen.removeView(menu)
          menu = nil
        end
      end)

      self.screen.addView(menu)
    end
  end)

  local selectedFile
  if options.action then
    local bottomBar = UI.box.create(1, h - 2, w, 3, colors.lightGray)
    self.screen.addView(bottomBar)

    local cancel = UI.button.create(2, h - 1, 8, 1, "Cancel")
    cancel.backgroundColor = colors.white
    cancel.on("press", function()
      self.emit("cancel")
    end)
    self.screen.addView(cancel)

    local done = UI.button.create(w - 7, h - 1, 6, 1)
    done.backgroundColor = colors.blue
    done.activeBackgroundColor = colors.cyan
    done.textColor = colors.white
    done.activeTextColor = colors.white
    if options.action == "save" then
      done.text = "Save"
    else
      done.text = "Open"
      done.on("press", function()
        if selectedFile then
          self.emit("open", selectedFile)
        end
      end)
    end
    self.screen.addView(done)

    if options.action == "save" then
      local filename = UI.input.create(11, h - 1, w - 19, 1)
      filename.backgroundColor = colors.white
      filename.placeholderColor = colors.lightGray
      filename.placeholder = "Name"
      self.screen.addView(filename)
    end
  end

  local list
  if options.action then
    list = UI.list.create(1, 4, w, h - 6)
  else
    list = UI.list.create(1, 4, w, h - 3)
  end
  list.setPadding(0)
  list.backgroundColor = colors.white
  list.row = {selectable = true, height = 1}
  function list.row.drawIcon(window, type)
    if type and self.extensions[type] then
      window.setBackgroundColor(self.extensions[type].bg)
      window.setTextColor(self.extensions[type].fg)
      window.write(self.extensions[type].text)
    else
      list.row.drawIcon(window, ".file")
    end
  end
  function list.row.drawLine(window, row, num, isSelected, x, y, w, view)
    window.setCursorPos(x, y)
    if row.path == "/" or row.path == "" then
      window.setBackgroundColor(colors.lightGray)
      window.setTextColor(colors.gray)
      window.write("C")
    elseif row.path == home or row.path == "/" .. home then
      window.setBackgroundColor(colors.brown)
      window.setTextColor(colors.orange)
      window.write("H")
    elseif row.path == system or row.path == "/" .. system then
      window.setBackgroundColor(colors.lightBlue)
      window.setTextColor(colors.cyan)
      window.write("S")
    elseif row.path == apps or row.path == "/" .. apps then
      window.setBackgroundColor(colors.lightBlue)
      window.setTextColor(colors.cyan)
      window.write("A")
    elseif row.path == "rom" or row.path == "/rom" then
      window.setBackgroundColor(colors.lightGray)
      window.setTextColor(colors.gray)
      window.write("R")
    elseif row.isDir then
      list.row.drawIcon(window, ".dir")
    else
      list.row.drawIcon(window, row.type and row.type:sub(2))
    end
    if isSelected then
      window.setBackgroundColor(view.selectedBackgroundColor or colors.blue)
      window.setTextColor(view.selectedTextColor or colors.white)
    else
      window.setBackgroundColor(view.backgroundColor or colors.white)
      if row.isDir then
        window.setTextColor(colors.green)
      else
        window.setTextColor(view.textColor or colors.black)
      end
    end
    local size = ""
    if row.size ~= nil and row.size ~= false then
      size = filesize.formatDiskSize(row.size)
    end
    window.write(" " .. row.text .. string.rep(" ", math.max(0, w - (11 + string.len(row.text)))) .. size .. string.rep(" ", math.max(0, w - (11 + string.len(row.text) + string.len(size)))))
  end

  function self.handleDoubleClick(row)
    if row.isDir then
      self.navigate(row.path)
    elseif not options.action then
      self.openFile(row.path)
    end
  end

  local lastRowClicked = nil
  list.on("click", function(row)
    if lastRowClicked == row then
      lastRowClicked = nil
      self.handleDoubleClick(row)
    else
      lastRowClicked = row
      self.screen.loop.timeout(function()
        if lastRowClicked == row then
          lastRowClicked = nil
        end
      end, 0.4)
    end
  end)
  list.on("select", function(row)
    if row then
      selectedFile = row.path
    else
      selectedFile = nil
    end
  end)

  self.screen.addView(list)

  function self.refresh()
    addFolder.setDisabled(fs.isReadOnly(self.dir))

    local files = fs.list(self.dir)
    local rows = {}
    for k,v in ipairs(files) do
      rows[k] = {text = v, type = v:match("^.+(%..+)$"), isDir = fs.isDir(fs.combine(self.dir, v)), path = fs.combine(self.dir, v)}
      if not rows[k].isDir then
        rows[k].size = fs.getSize(fs.combine(self.dir, v))
      end
    end
    table.sort(rows, function(a, b)
      if a.isDir and not b.isDir then
        return true
      elseif b.isDir and not a.isDir then
        return false
      else
        return a.text < b.text
      end
    end)
    list.removeAllRows()
    for k,v in ipairs(rows) do
      list.addRow(v)
    end
  end

  function self.go(dir)
    selectedFile = nil
    self.dir = dir
    path.text = self.getPathDescription(dir) .. " v"
    path.redraw()
    self.refresh()
  end

  function self.navigate(dir)
    table.insert(self.back, self.dir)
    back.setDisabled(false)
    self.forward = {}
    forward.setDisabled(true)
    self.go(dir)
  end

  self.refresh()

  return self
end

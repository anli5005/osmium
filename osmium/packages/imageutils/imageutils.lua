local magiclines = opm.require("magiclines")

local function getColourOf(hex)
  -- Code taken from getColourOf in NPaintPro by NitrogenFingers
  local value = tonumber(hex, 16)
  if not value then return nil end
  value = math.pow(2,value)
  return value
end

local getColorOf = getColourOf

loaders = {
  {
    name = "NFT Loader",
    canHandleExtension = function(extension)
      return extension == "nft"
    end,
    canHandleData = function(data)
      return string.find(data, string.char(30)) or string.find(data, string.char(31))
    end,
    loadFromData = function(data)
      -- Code taken from loadNFT in NPaintPro by NitrogenFingers
      local frames = {{}}
      local sFrame = 1
      frames[sFrame].bg = { }
      frames[sFrame].text = { }
      frames[sFrame].fg = { }

      local num = 1
      for sLine in magiclines.magiclines(data) do
        table.insert(frames[sFrame].bg, num, {})
        table.insert(frames[sFrame].text, num, {})
        table.insert(frames[sFrame].fg, num, {})

        --As we're no longer 1-1, we keep track of what index to write to
        local writeIndex = 1
        --Tells us if we've hit a 30 or 31 (BG and FG respectively)- next char specifies the curr colour
        local bgNext, fgNext = false, false
        --The current background and foreground colours
        local currBG, currFG = nil,nil
        for i=1,#sLine do
          local nextChar = string.sub(sLine, i, i)
          if nextChar:byte() == 30 then
            bgNext = true
          elseif nextChar:byte() == 31 then
            fgNext = true
          elseif bgNext then
            currBG = getColourOf(nextChar)
            bgNext = false
          elseif fgNext then
            currFG = getColourOf(nextChar)
            fgNext = false
          else
            if nextChar ~= " " and currFG == nil then
              currFG = colours.white
            end
            frames[sFrame].bg[num][writeIndex] = currBG or 0
            frames[sFrame].fg[num][writeIndex] = currFG
            frames[sFrame].text[num][writeIndex] = nextChar
            writeIndex = writeIndex + 1
          end
        end
        num = num+1
      end
      return frames
    end
  },
  {
    name = "NFP Loader",
    canHandleExtension = function(extension)
      return extension == "nfp"
    end,
    canHandleData = function() return true end,
    loadFromData = function(data)
      local image = paintutils.parseImage(data)
      return {{bg = image}}
    end
  }
}

function loadFromData(data, extension)
  for i,loader in ipairs(loaders) do
    if loader.canHandleExtension(extension) then
      return loader.loadFromData(data)
    end
  end

  for j,loader in ipairs(loaders) do
    if loader.canHandleData(data) then
      return loader.loadFromData(data)
    end
  end
end

function loadFromFile(file)
  local extension = file:match("^.+(%..+)$")
  if extension then
    extension = extension:sub(2)
  end
  local stream = fs.open(file, "r")
  local data = stream.readAll()
  stream.close()

  return loadFromData(data, extension)
end

function drawImage(image, alpha)
  local x, y = term.getCursorPos()
  local frame = image[1]
  for i,row in ipairs(frame.bg) do
    for j,col in ipairs(row) do
      local color
      if col > 0 then
        color = col
      else
        if alpha then
          color = alpha
        end
      end
      if color then
        term.setBackgroundColor(color)
        term.setCursorPos(x + j - 1, y + i - 1)
        if frame.text and frame.fg and frame.text[i][j] and frame.text[i][j] ~= "" and frame.fg[i][j] then
          term.setTextColor(frame.fg[i][j])
          term.write(frame.text[i][j]:sub(1,1))
        else
          term.write(" ")
        end
      end
    end
  end
end

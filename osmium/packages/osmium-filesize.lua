local suffixes = {"MB", "KB", "b"}

function formatDiskSize(bytes)
  for k,v in ipairs(suffixes) do
    if bytes >= 1000 ^ (#suffixes - k) then
      local main = math.floor(bytes / (1000 ^ (#suffixes - k)))
      local decimal = (bytes - (main * (1000 ^ (#suffixes - k))))
      return main .. "." .. string.sub(tostring(decimal), 1, 2) .. " " .. v
    end
  end
end

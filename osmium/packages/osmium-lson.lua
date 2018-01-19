function parse(lson)
  return textutils.unserialize(lson)
end

function stringify(object)
  return textutils.serialize(object)
end

function read(file)
  local stream = fs.open(file, "r")
  local lson = stream.readAll()
  stream.close()
  return parse(lson)
end

function save(file, object)
  local lson = stringify(object)
  local stream = fs.open(file, "w")
  stream.write(lson)
  stream.close()
  return lson
end

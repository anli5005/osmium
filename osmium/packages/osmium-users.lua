local base64 = opm.require("base64")
local lson = opm.require("osmium-lson")
local sha = opm.require("sha256")

local function _getUsers()
  if fs.exists("/osmium/settings/users.lson") then
    return lson.read("/osmium/settings/users.lson")
  else
    return {users = {}, nextID = 1}
  end
end

function getUsers()
  return _getUsers().users
end

function getUser(id)
  return _getUsers().users[id]
end

function insertUser(data)
  local users = _getUsers()
  local id = users.nextID
  users.users[id] = data
  users.nextID = users.nextID + 1
  lson.save("/osmium/settings/users.lson", users)
  return id
end

function updateUser(id, data)
  local users = _getUsers()
  if users.users[id] then
    users.users[id] = data
    lson.save("/osmium/settings/users.lson", users)
  else
    error("User not found")
  end
end

function removeUser(id)
  local users = _getUsers()
  if users.users[id] then
    users.users[id] = nil
    lson.save("/osmium/settings/users.lson", users)
  else
    error("User not found")
  end
end

function auth(id, password)
  local user = getUser(id)
  if user then
    if user.password and user.salt then
      local hash = sha.hash256(password .. ":" .. user.salt)
      return hash == user.password
    else
      error("User does not have a password")
    end
  else
    error("User not found")
  end
end

function setPassword(id, password)
  local users = _getUsers()
  if users.users[id] then
    -- Generate a salt
    local salt = base64.encnumber(math.random(0, 2 ^ 30 - 1))
    local hash = sha.hash256(password .. ":" .. salt)
    users.users[id].password = hash
    users.users[id].salt = salt
    lson.save("/osmium/settings/users.lson", users)
    return {
      hash = hash,
      salt = salt
    }
  else
    error("User not found")
  end
end

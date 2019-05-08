-- https://stackoverflow.com/questions/19326368/iterate-over-lines-including-blank-lines
---@param s string
---@return string[]
function magiclines(s)
        if s:sub(-1)~="\n" then s=s.."\n" end
        return s:gmatch("(.-)\n")
end

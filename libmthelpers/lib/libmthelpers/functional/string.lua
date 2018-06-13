--[[
List generators etc. for working with strings.
]]

local i = {}

-- iterate over a string one character at a time.
local char_iterator = function(s)
	assert(type(s) == "string")
	local limit = #s
	local i = 0

	return function()
		if i == limit then return nil end
		i = i + 1
		return string.sub(s, i, i)
	end
end
i.char_iterator = char_iterator



return i


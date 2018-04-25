--[[
actual error formatter.
in it's own module so to not cause circular dependency problems with stdcodes.
]]

local i = {}

local format_error = function(e)
	return "<error type=\""..e.."\" />"
end
i.format_error = format_error

return i


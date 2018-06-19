--[[
The counterpart to unwrap.lua,
effectively vector.new with some sanity checks on types.
]]
local assert_num = function(v)
	assert(type(v) == "number")
	return v
end
local wrap = function(_x, _y, _z)
	return {
		x = assert_num(_x),
		y = assert_num(_y),
		z = assert_num(_z),
	}
end

return wrap


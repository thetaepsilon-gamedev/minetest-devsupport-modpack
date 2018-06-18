--[[
Subtract one vector from another;
can also be used to calculate a difference vector between two points in space.
Note that like normal subtraction, order of operation is significant.
]]
local unwrap = mtrequire("ds2.minetest.vectorextras.unwrap")
local wrap = mtrequire("ds2.minetest.vectorextras.wrap")

local i = {}

local subtract_raw = function(ax, ay, az, bx, by, bz)
	return ax - bx, ay - by, az - bz
end
i.raw = subtract_raw

local subtract_wrapped = function(a, b)
	local ax, ay, az = unwrap(a)
	local bx, by, bz = unwrap(b)
	return wrap(subtract_raw(ax, ay, az, bx, by, bz))
end
i.wrapped = subtract_wrapped

return i


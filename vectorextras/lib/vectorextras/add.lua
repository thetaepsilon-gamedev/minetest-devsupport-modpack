--[[
Simpler version of vector.add,
also with bare and wrapped variants.
]]
local unwrap = mtrequire("ds2.minetest.vectorextras.unwrap")
local wrap = mtrequire("ds2.minetest.vectorextras.wrap")

local i = {}

local add_raw = function(ax, ay, az, bx, by, bz)
	return ax + bx, ay + by, az + bz
end
i.raw = add_raw

local add_wrapped = function(a, b)
	local ax, ay, az = unwrap(a)
	local bx, by, bz = unwrap(b)
	return wrap(add_raw(ax, ay, az, bx, by, bz))
end
i.wrapped = add_wrapped

return i


--[[
Vector *element-wise* product,
unlike scalar multiply which is multiplying all components by one value.
]]

local unwrap = mtrequire("ds2.minetest.vectorextras.unwrap")
local wrap = mtrequire("ds2.minetest.vectorextras.wrap")

local i = {}

local mul_raw = function(ax, ay, az, bx, by, bz)
	return ax * bx, ay * by, az * bz
end
i.raw = mul_raw

local mul_wrapped = function(a, b)
	local ax, ay, az = unwrap(a)
	local bx, by, bz = unwrap(b)
	return wrap(mul_raw(ax, ay, az, bx, by, bz))
end
i.wrapped = mul_wrapped

return i


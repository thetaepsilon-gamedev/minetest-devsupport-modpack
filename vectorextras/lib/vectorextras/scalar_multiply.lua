--[[
Simpler version of vector.multiply's scalar behaviour,
also with bare and wrapped variants.
Arguments are ordered with scalar first followed by vector.
]]
local unwrap = mtrequire("ds2.minetest.vectorextras.unwrap")
local wrap = mtrequire("ds2.minetest.vectorextras.wrap")

local i = {}

local scalar_multiply_raw = function(scale, x, y, z)
	return scale * x, scale * y, scale * z
end
i.raw = scalar_multiply_raw

local scalar_multiply_wrapped = function(scale, vec)
	local x, y, z = unwrap(vec)
	return wrap(scalar_multiply_raw(scale, x, y, z))
end
i.wrapped = scalar_multiply_wrapped

return i


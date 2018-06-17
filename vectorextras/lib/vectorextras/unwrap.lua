--[[
An unwrap helper that is used in various other routines in vectorextras.
Performs some sanity checks on an MT XYZ vector table,
then returns the three individual components of the vector, like so:
local x, y, z = unwrap(vec)
If the types were wrong for whatever reason, unwrap throws an assertion.
]]
local assert_num = function(v)
	assert(type(v) == "number")
	return v
end
local unwrap = function(vec)
	assert(type(vec) == "table")
	local x = assert_num(vec.x)
	local y = assert_num(vec.y)
	local z = assert_num(vec.z)
	return x, y, z
end

return unwrap


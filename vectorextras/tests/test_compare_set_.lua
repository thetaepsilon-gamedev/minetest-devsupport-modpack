local compare_set_ = mtrequire("ds2.minetest.vectorextras.compare_set_")

-- test helper: replica of minetest's vector.new()
local vec3 = function(x, y, z)
	assert(type(x) == "number")
	assert(type(y) == "number")
	assert(type(y) == "number")
	return {x=x,y=y,z=z}
end

local s1 = {
	a = vec3(23, 45, 46),
	b = vec3(56, 45, 8),
	c = vec3(83, 783, 3),
}
local eq = compare_set_({})
assert(eq(s1, s1))
-- check by-value comparison
assert(eq(s1, {
	a = vec3(23, 45, 46),
	b = vec3(56, 45, 8),
	c = vec3(83, 783, 3),
}))

-- reject if we change one of the values.
assert(not eq(s1, {
	a = vec3(23, 45, 46),
	b = vec3(56, 45, 111111),
	c = vec3(83, 783, 3),
}))

-- reject if key missing.
assert(not eq(s1, {
	a = vec3(23, 45, 46),
	b = vec3(56, 45, 8),
	-- now you "c" me, now you don't... /badpun
}))

-- extra keys in the *input* are normally fine...
local se = {
	a = vec3(23, 45, 46),
	b = vec3(56, 45, 8),
	c = vec3(83, 783, 3),
	d = vec3(345, 56, 34),
}
assert(eq(s1, se))
-- but are not in set member strict mode
assert(not compare_set_({setstrict=true})(s1, se))


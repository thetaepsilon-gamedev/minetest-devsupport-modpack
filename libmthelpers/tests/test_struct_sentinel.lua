local sentinel =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.datastructs.sentinel")
local errors =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.errors")
local expect_error = errors.expect_error

local mk = sentinel.mk
assert(type(mk) == "function")

local differ = function(a, b)
	assert(a ~= b)
end
eq = function(a, b)
	assert(a == b)
end

-- get some sentinels, separate ones never compare equal even with the same label.
local s1 = mk("test.foo")
local s2 = mk("test.bar")
local s3 = mk("test.bar")
differ(s1, s2)
differ(s1, s3)
differ(s2, s3)

-- a sentinel should always compare equal to itself, even if passed around.
local f = function() return s1 end
eq(s1, s1)
eq(s1, f())
eq(s2, s2)
eq(s3, s3)



-- operator abuse: these operators should all raise some form of error.
local badop = "err.struct.bad_operator"
local bang = function(f)
	expect_error(badop, f)
end
bang(function() return s1 + 1 end)
bang(function() return s1 - 1 end)
bang(function() return s1 * s2 end)
bang(function() return s1 / 1 end)
bang(function() return s1 % 2 end)
bang(function() return s1 ^ 3 end)
bang(function() return s1 .. "wat" end)
bang(function() return s1 < s2 end)
bang(function() return s1 <= s2 end)
bang(function() return s1 > s2 end)
bang(function() return s1 >= s2 end)
bang(function() return -s1 end)
bang(function() return s1() end)

expect_error("err.struct.bad_key_access", function() return s1.x end)
expect_error("err.struct.bad_key_write", function() s1.x = 1 end)

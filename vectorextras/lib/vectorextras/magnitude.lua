--[[
Work out the euclidian length of a vector:
length = sqrt(x^2 + y^2 + z^2).
]]

--[[
-- in some cases, it can be useful to leave out the square root part,
-- if only to save on a call to a relatively complex operation in some cases.
-- the absolute value will then obviously be incorrect,
-- but for comparing lengths it still holds -
-- assuming a and b are >= 0, if a < b then sqrt(a) < sqrt(a),
-- for all values of a and b which are positive real numbers.
-- so we can check whether the length exceeds a limit even if both values are squared.
-- (mathy types [UNICODE WARNING]:
--	(a < b) → √a < √b ∀ a, b; a, b ∈ (R+ ∪ {0}).
-- will someone please explain why zero isn't in the reals...)
]]
local sqrt = math.sqrt
local i = {}
local magnitude_squared_raw = function(x, y, z)
	return (x*x) + (y*y) + (z*z)
end
i.squared_raw = magnitude_squared_raw

local magnitude_raw = function(x, y, z)
	return sqrt(magnitude_squared_raw(x, y, z))
end
i.raw = magnitude_raw



local unwrap = mtrequire("ds2.minetest.vectorextras.unwrap")
local magnitude_squared_wrapped = function(vec)
	return magnitude_squared_raw(unwrap(vec))
end
i.squared_wrapped = magnitude_squared_wrapped

i.wrapped = function(vec)
	return sqrt(magnitude_squared_wrapped(vec))
end

return i


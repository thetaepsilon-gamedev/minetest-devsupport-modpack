--[[
Various ways of printing out a vector's xyz components.
See also coords.format() in libmthelpers.
]]
local unwrap = mtrequire("ds2.minetest.vectorextras.unwrap")

-- hmm, this is starting to be a bit copy-and-paste,
-- but sometimes it's not worth the effort to type the import line!
local assert_num = function(v)
	assert(type(v) == "number")
	return v
end

local i = {}
local column = {}
i.column = column
local column_vec_raw_ = function(print)
	assert(type(print) == "function")

	return function(_x, _y, _z)
		local x = assert_num(_x)
		local y = assert_num(_y)
		local z = assert_num(_z)
		print(x)
		print(y)
		print(z)
	end
end
column.raw_ = column_vec_raw_

local column_vec_wrapped_ = function(print)
	local base = column_vec_raw_(print)
	return function(vec)
		return base(unwrap(vec))
	end
end
column.wrapped_ = column_vec_wrapped_

return i


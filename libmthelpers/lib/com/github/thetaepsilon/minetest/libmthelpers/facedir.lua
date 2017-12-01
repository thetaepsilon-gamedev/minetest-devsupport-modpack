local facedir = {}

-- functions to deal with param2 facedir values

-- for some reason the values that minetest.facedir_to_dir() were returning made bugger-all sense.
-- after sanity checking with the docs,
-- at least the docs matched the param2 values I got,
-- so I decided to re-implement this here.
local check = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.check")
local rangecheck = check.range
local param2_facedir_split = function(param2)
	local caller="param2_facedir_split"
	-- integercheck(param2, "param2", caller)
	rangecheck(param2, 0, 23, true, "param2", caller)
	local axis = math.floor(param2 / 4)
	local rotation = param2 % 4
	return { axis=axis, rotation=rotation }
end
facedir.param2_split = param2_facedir_split

return facedir

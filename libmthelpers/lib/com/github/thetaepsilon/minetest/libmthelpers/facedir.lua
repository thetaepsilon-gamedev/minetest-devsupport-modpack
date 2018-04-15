local facedir = {}

-- functions to deal with param2 facedir values

-- for some reason the values that minetest.facedir_to_dir() were returning made bugger-all sense.
-- after sanity checking with the docs,
-- at least the docs matched the param2 values I got,
-- so I decided to re-implement this here.
local check = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.check")
local rangecheck = check.range
local param2check = function(caller, v)
	return rangecheck(v, 0, 23, true, "param2", caller)
end

local getaxis = function(param2)
	local axis = math.floor(param2 / 4)
	return axis
end
local getrotation = function(param2)
	local rotation = param2 % 4
	return rotation
end

-- split into axis and rotation values.
local param2_facedir_split = function(param2)
	local caller="param2_facedir_split"
	-- integercheck(param2, "param2", caller)
	param2check(caller, param2)
	local axis = getaxis(param2)
	local rotation = getrotation(param2)
	return { axis=axis, rotation=rotation }
end
facedir.param2_split = param2_facedir_split



-- get facing direction vector dependent on axis.
-- again, the values returned by the MT api make zero sense.
-- the direction is coming towards you when you place a facedir node on a surface.
local axes = {
	-- note 1-indexed!
	{ x = 0, y = 1, z = 0 },
	{ x = 0, y = 0, z = 1 },
	{ x = 0, y = 0, z =-1 },
	{ x = 1, y = 0, z = 0 },
	{ x =-1, y = 0, z = 0 },
	{ x = 0, y =-1, z = 0 },
}
local to_vec = function(param2)
	param2check("facedir.to_dir()", param2)
	local axis = getaxis(param2)
	return axes[axis+1]
end
facedir.to_dir = to_vec



-- the opposite: get the direction going away
local reverse = {
	{ x = 0, y =-1, z = 0 },
	{ x = 0, y = 0, z =-1 },
	{ x = 0, y = 0, z = 1 },
	{ x =-1, y = 0, z = 0 },
	{ x = 1, y = 0, z = 0 },
	{ x = 0, y = 1, z = 0 },
}
local reverse_vec = function(param2)
	param2check("facedir.to_reverse_dir()", param2)
	local axis = getaxis(param2)
	return reverse[axis+1]
end
facedir.to_reverse_dir = reverse_vec



return facedir

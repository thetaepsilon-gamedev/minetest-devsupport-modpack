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



-- rotate a vector based on node param2 data,
-- where the base vector is sat at param2 = 0 (facing up, zero rotation)
local matrix =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.datastructs.matrix")
local m = function(vs) return matrix.new(3, 3, vs) end
local identity = m({
	1,  0,  0,
	0,  1,  0,
	0,  0,  1,
})
local rotation_m = {
	[0] = identity,
	m({
		0,  0,  1,
		0,  1,  0,
		-1, 0,  0,
	}),	-- 90 degrees CW
	m({
		-1, 0,  0,
		0,  1,  0,
		0,  0, -1,
	}),	-- 180 degrees
	m({
		0,  0, -1,
		0,  1,  0,
		1,  0,  0,
	})	-- 90 degrees CCW
}
local axis_m = {
	[0] = identity,
	m({
		1,  0,  0,
		0,  0, -1,
		0,  1,  0,
	}),
	m({
		1,  0,  0,
		0,  0,  1,
		0, -1,  0,
	}),
	m({
		0,  1,  0,
		-1, 0,  0,
		0,  0,  1,
	}),
	m({
		0,  -1, 0,
		1,  0,  0,
		0,  0,  1,
	}),
	m({
		-1, 0,  0,
		0, -1,  0,
		0,  0,  1,
	}),
}
local matrices = {}
for axis = 0, 5, 1 do
	for rotation = 0, 3, 1 do
		matrices[(axis * 4) + rotation] =
			axis_m[axis]:multiply_m(rotation_m[rotation])
	end
end
local get_rotation_matrix = function(param2)
	param2check("get_rotation_matrix()", param2)
	return matrices[param2]:clone()
end
facedir.get_rotation_matrix = get_rotation_matrix

-- optimised function variants of the above to avoid matrix multiplies all the time.
local optimised_rotations =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.facedir.optimised_rotations")
facedir.get_rotation_function = function(param2)
	param2check("get_rotation_function()", param2)
	return optimised_rotations.funcs[param2]
end



-- get an array of rotation vectors indexed by param2 rotation bits,
-- by taking an initial base vector for when the node is at param2 = 0,
-- and applying the rotation function for all possible param2 values.
-- returns a function of param2 which will in turn return the appropriate vector.
-- label is just used for error messages (not in the below type signature)
-- mk_rotated_vector_set :: Vec3 -> (NodeParam2 -> Vec3)
local rotfuncs = optimised_rotations.funcs
local deflabel = "mk_rotated_vector_set() closure"
local mk_rotated_vector_set = function(basevec, label)
	label = label or deflabel
	local rotations = {}
	for i = 0, 23, 1 do
		rotations[i] = rotfuncs[i](basevec)
	end
	return function(param2)
		param2check(label, param2)
		return rotations[param2]
	end
end
facedir.mk_rotated_vector_set = mk_rotated_vector_set



return facedir

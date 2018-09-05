--[[
Attempt to solve where a look vector from a given point intersects a cuboid.
This is of interest because the MT engine currently doesn't offer
the position on the hitbox that was clicked by the user.
(This is possibly because the client simply doesn't send this?)

To do this, we have to consider up to three faces of the cube,
and see if the vector intersects with any of them.
]]

local pre = "ds2.minetest.vectorextras."
local vmult = mtrequire(pre.."scalar_multiply").raw
local vadd = mtrequire(pre.."add").raw
local vsub = mtrequire(pre.."subtract").raw



local i = {}
--[[
Solve for the plane of intersection for the indicated face.
Note that the returned multiple of the look vector may lie outside the face bounds.
args:
px, py, pz - point of click origin relative to cube origin
lx, ly, lz - look vector (doesn't have to be normalised)
cxf - coordinate extractor function, to tell the function which axis to use.
ct - coordinate target, value on said axis to solve for.
returns: scalar multiple of the look vector which satisfies the coordinate target,
	i.e. cxf(point + (scalar * look)) == ct.
	may return infinity if the component of the look vector is zero.

data AxisExtract n = (Vec3 n -> n)
solve_target_axis :: Num n => Vec3 n -> Vec3 n-> AxisExtract n -> n -> n
]]
local solve_target_axis = function(px, py, pz, lx, ly, lz, cxf, ct)
	-- get the appropriate axis out of the point
	local cp = cxf(px, py, pz)
	-- determine how much of the chosen axis remains before reaching ct
	local cr = cp - ct
	-- determine how much of that axis is moved by 1x of the look vector
	local cl = cxf(lx, ly, lz)

	-- note, that we assume the look vector is moving inwards towards the origin.
	-- so, relative to the sign of cr, the sign of cl should be negated.
	local scalar_moved = cr / -cl
	return scalar_moved
end

-- same arguments as the above, but returns a vector;
-- takes care of adding scalar_moved * look to the origin point.
-- returns Nothing if the scalar_moved value is +- infinity.
-- solve_target_coordinates :: Num n => Vec3 n -> Vec3 n-> AxisExtract n -> n -> Maybe Vec3 n
local inf = 1 / 0
local isinf = function(v)
	return (v == inf) or (v == -inf)
end
local solve_target_coordinates = function(px, py, pz, lx, ly, lz, cxf, ct)
	local scalar_moved = solve_target_axis(px, py, pz, lx, ly, lz, cxf, ct)
	if isinf(scalar_moved) then return nil, nil, nil end

	local mx, my, mz = vmult(scalar_moved, lx, ly, lz)
	return vadd(px, py, pz, mx, my, mz)
end




-- extractor functions for various faces.
-- cxf_x, cxf_y, cxf_z :: AxisExtract n
local cxf_x = function(x, y, z) return x end
local cxf_y = function(x, y, z) return y end
local cxf_z = function(x, y, z) return z end

-- other two axis extractors, b for "bounds" used below
local bxf_x = function(x, y, z) return y, z end
local bxf_y = function(x, y, z) return z, x end
local bxf_z = function(x, y, z) return x, y end

local dims = {
	{cxf_x, bxf_x, "x"},
	{cxf_y, bxf_y, "y"},
	{cxf_z, bxf_z, "z"},
}



--[[
Test a single face for intersection, given point, look, and dimensions of the cuboid.
If there cannot be an intersection on this face, returns Nothing;
otherwise returns the point of intersect.
args:
px, py, pz; lx, ly, lz; point and look vectors again
wx, wy, wz: *half* widths in each dimension, must be positive.
cxf: extractor for axis again.
bxf: a function which extracts the *other two* of the axes.
	this is used to check whether the solved coordinates lie on the face.
	ordering of the axes isn't important, as long as it is consistent.
returns: found coordinates and the sign of the face;
	or nil if no intersection is possible.

data BoundsExtract n :: Vec3 n -> (n, n)
-- note enums indicated by strings
data Sign :: "+" | "-"
find_face_intersection :: Num n => Vec3 n -> Vec3 n -> Vec3 n -> \
			AxisExtract n -> BoundsExtract n -> Maybe (Vec3 n, Sign)
]]
local abs = math.abs
local sign = function(v) return v < 0 and -1 or 1 end
local signe = function(v) return v < 0 and "-" or "+" end
local find_face_intersection = function(px, py, pz, lx, ly, lz, wx, wy, wz, cxf, bxf)
	-- get the current width and origin position in this axis.
	local cp = cxf(px, py, pz)
	local cw = cxf(wx, wy, wz)
	-- check whether position is *inside* the width of the cuboid.
	-- if we're e.g. level with the cube in Y,
	-- which is to say -wy <= py <= +wy,
	-- then it is impossible for the player to reach that face.
	if abs(cp) <= cw then return nil, nil, nil end

	-- make sure that ct gets the correct sign based on our position.
	local ct = sign(cp) * cw
	local enum_sign = signe(cp)
	local rx, ry, rz =
		solve_target_coordinates(px, py, pz, lx, ly, lz, cxf, ct)

	-- check the ranges to ensure they lie on the face.
	local ur, vr = bxf(rx, ry, rz)
	local uw, vw = bxf(wx, wy, wz)
	if (ur < -uw) or (ur > uw) then return nil, nil, nil end
	if (vr < -vw) or (vr > vw) then return nil, nil, nil end

	-- otherwise we should be good to go
	return rx, ry, rz, enum_sign
end



-- now try all three axes and return the first successful one;
-- if none are found, returns nil.
-- data Face = "x" | "y" | "z"
-- test_all_faces_centered :: Num n => \
--	Vec3 n -> Vec3 n -> Vec3 n -> Maybe (Vec3 n, Sign, Face)
local test_all_faces_centered = function(px, py, pz, lx, ly, lz, wx, wy, wz)
	for _, dim in ipairs(dims) do
		local cxf, bxf = dim[1], dim[2]
		local rx, ry, rz, es =
			find_face_intersection(
				px, py, pz, lx, ly, lz, wx, wy, wz, cxf, bxf)

		if rx then return rx, ry, rz, es, dim[3] end
	end
	return nil, nil, nil, nil, nil
end
i.test_all_faces_centered_raw = test_all_faces_centered



--[[
now we take care of rebasing the coordinate system,
given the *world* position of the entity and click origin.
the returned coordinates (if any) will also be in world space.
args:
cx, cy, cz: clicker origin
lx, ly, lz: look vector from clicker origin
ex, ey, ez: center of the cuboid
wx, wy, wz: dimensions of cuboid
returns: surface position in world space, or nil.
]]
-- solve_ws :: Num n => Vec3 n -> Vec3 n -> Vec3 n -> Vec3 n -> Maybe Vec3 n
local solve_ws = function(cx, cy, cz, lx, ly, lz, ex, ey, ez, wx, wy, wz)
	-- the entity is already at zero relative to itself
	-- (ex - ex = 0), so just rebase clicker
	local px, py, pz = vsub(cx, cy, cz, ex, ey, ez)
	local rx, ry, rz, es, ef =
		test_all_faces_centered(px, py, pz, lx, ly, lz, wx, wy, wz)

	if rx == nil then return nil, nil, nil end

	-- rebase to be relative to entity in world space again
	local fx, fy, fz = vadd(rx, ry, rz, ex, ey, ez)
	return fx, fy, fz, es, ef
end
i.solve_ws_raw = solve_ws



-- the enums for sign and axis are just strings;
-- if we concat them we end up with a unique face string, e.g. "+y".
-- this table contains unit vectors in those directions.
local offsets = {
	["+x"] = {	x=1,	y=0,	z=0 	},
	["-x"] = {	x=-1,	y=0,	z=0	},
	["+y"] = {	x=0,	y=1,	z=0	},
	["-y"] = {	x=0,	y=-1,	z=0	},
	["+z"] = {	x=0,	y=0,	z=1	},
	["-z"] = {	x=0,	y=0,	z=-1	},
}
i.enum_offsets = offsets



return i


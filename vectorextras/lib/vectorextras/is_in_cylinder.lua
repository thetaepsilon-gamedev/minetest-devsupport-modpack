--[[
Work out whether a given point P lies within a specified cylinder.
This cylinder is specified as two points A and B,
indicating the centre points of the two circular ends,
and a radius of the cross section.
The leaf functions (after partial application) below return a boolean value,
where true indicates inside the cylinder and false is not so.
]]

local bp = "ds2.minetest.vectorextras."
local m_reflect = mtrequire(bp.."reflect")
local m_sub = mtrequire(bp.."subtract")
local sub = m_sub.raw
local m_unit = mtrequire(bp.."unit")
local normal = m_unit.raw
local m_len = mtrequire(bp.."magnitude")
local dist2 = m_len.squared_raw

-- we use the reflect routine to "flatten" points
-- into a plane perpendicular to vector AB.
-- we need this as the circular end of the cylinder lies in this plane;
-- we can then use this to work out distance from A to this projected point,
-- and therefore determine if it lies within the radius
-- of the cross-sectional circle (I really need some diagrams...)
local flatten = m_reflect.mk_reflect_raw_({getdot=true,reflectivity=-1})

local i = {}
-- core version which uses an offset from the base point A.
local cylinder_test_offset = function(ax, ay, az, dx, dy, dz, radius, _px, _py, _pz)
	-- firstly, we rebase the coordinates to be relative to A.
	local px, py, pz = sub(_px, _py, _pz, ax, ay, az)

	-- next, get normalised vector and length for use in reflect.
	-- the length represents the max height of the cylinder,
	-- which we will need later.
	local nx, ny, nz, maxh = normal(dx, dy, dz)

	-- shove the point into the plane and get it's "height" above the plane.
	local fx, fy, fz, height = flatten(px, py, pz, nx, ny, nz)
	-- y = 0 of the cylinder is implicitly height = 0 due to rebasing.
	-- height is below cylinder or above max height? fail
	if height < 0 or height > maxh then return false end

	-- work out the distance from the flattened point to the origin (A).
	-- if this is greater than the cylinder's radius, fail
	local r2 = radius * radius
	-- if a < b then sqrt(a) < sqrt(b), sqrt is redundant
	if dist2(fx, fy, fz) > r2 then return false end

	-- otherwise we should be good
	return true
end
i.raw_offset = cylinder_test_offset

-- variant which uses an absolute secondary position -
-- this takes care of computing the offset.
local cylinder_test_abs = function(ax, ay, az, _bx, _by, _bz, radius, _px, _py, _pz)
	local dx, dy, dz = sub(_bx, _by, _bz, ax, ay, az)
	return cylinder_test_offset(ax, ay, az, dx, dy, dz, radius, _px, _py, _pz)
end
i.raw = cylinder_test_abs



return i


--[[
Work out the point along a line defined by two points (A and B)
that is closest to a third reference point S.
]]
local m_add = mtrequire("ds2.minetest.vectorextras.add")
local m_subtract = mtrequire("ds2.minetest.vectorextras.subtract")
local m_magnitude = mtrequire("ds2.minetest.vectorextras.magnitude")
local m_scalar_mult = mtrequire("ds2.minetest.vectorextras.scalar_multiply")
local m_dot = mtrequire("ds2.minetest.vectorextras.dotproduct")
local add = m_add.raw
local sub = m_subtract.raw
local length = m_magnitude.raw
local scalar_mult = m_scalar_mult.raw
local dot = m_dot.raw

local clamp_to_range = function(lower, v, higher)
	if v < lower then return lower end
	if v > higher then return higher end
	return v
end

local i = {}
-- retdiff flag:
-- if true, additionally return the difference between the closest point and B
-- (such that closestp + diff = B).
-- may be useful if a calculation transforms the closest point but wants to keep P -> B.
local null = function() end
local closest_point_on_segment_raw = function(ax, ay, az, bx, by, bz, sx, sy, sz, retdiff)
	-- to begin, we need the difference vectors going from A to B, and A to S.
	-- A is considered the starting point of movement,
	-- B the end point,
	-- and S the anchor point to work out the closest point on the line to.
	local asx, asy, asz = sub(sx, sy, sz, ax, ay, az)
	local abx, aby, abz = sub(bx, by, bz, ax, ay, az)

	-- next, we need a unit vector in the direction of AB,
	-- to enable working with the dot product operation.
	-- to get that, we take the magnitude separately
	-- (because we'll need |AB| later on)
	-- then multiply by it's reciprocal to normalise it.
	local len_ab = length(abx, aby, abz)
	local nx, ny, nz = scalar_mult(1 / len_ab, abx, aby, abz)

	-- the dot product m = AS · N (where N is the normalised AB vector)
	-- can be thought of as "projecting" AS onto N;
	-- specifically, here it gives us a scalar multiple of N,
	-- where if we take the point A + (m * N),
	-- and then draw a plane perpendicular to N at that point,
	-- the point S will be a point on that plane:
	--[[
	* S
       /|
      / |
     /  |  <-- the perpendicular plane
    /   |
   /    |
A *--N->* m*N
	Perpendicular is important,
	as the point on the original line which is perpendicular to S
	*is the closest point*.
	]]
	local m = dot(asx, asy, asz, nx, ny, nz)

	-- however, at this point, this is multiples of the *normalised* vector.
	-- we want a multiple of the original vector;
	-- the normal vector is shrunk in proportion to the original,
	-- so we must shrink the result correspondingly.
	local t = m / len_ab

	-- now, this gives us a value in terms of the parametric equation:
	-- P(t) = A + t(B - A)
	-- t being either < 0 or > 1 is off the line, so clamp.
	t = clamp_to_range(0, t, 1)
	local diff = 1 - t

	-- finally, convert back to a point on the line and return
	local dx, dy, dz = scalar_mult(t, abx, aby, abz)
	local extra
	if retdiff then
		extra = function() return scalar_mult(diff, abx, aby, abz) end
	else
		extra = null
	end
	
	local rx, ry, rz = add(ax, ay, az, dx, dy, dz)
	return rx, ry, rz, extra()
end
i.raw = closest_point_on_segment_raw

return i

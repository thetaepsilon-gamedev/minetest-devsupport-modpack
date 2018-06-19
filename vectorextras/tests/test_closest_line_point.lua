local m_closest = mtrequire("ds2.minetest.vectorextras.closest_line_point")
local closest = m_closest.raw

-- the calculations involved in the algorithm has a tendency to run afoul of rounding errors.
-- for the most part, it stays within less than the machine epsilon
-- (2^-52 or so on most targets), so we need equals with tolerance here.
local p16 = 65536
local pow = p16 * p16 * p16 * 16
local epsilon = 1 / pow
local eq = function(expected, actual)
	if actual < (expected - epsilon) then return false end
	if actual > (expected + epsilon) then return false end
	return true
end



local assertc = function(ax, ay, az, bx, by, bz, sx, sy, sz, ex, ey, ez)
	local rx, ry, rz = closest(ax, ay, az, bx, by, bz, sx, sy, sz)
	assert(eq(ex, rx))
	assert(eq(ey, ry))
	assert(eq(ez, rz))
end

-- I encourage you to draw these coordinates out on a graph to see what is meant.
-- mid point on vertical line centered on y = 0, source point also y = 0
assertc(
	0, -1,  0,
	0,  1,  0,
	1,  0,  0,
	0,  0,  0)

-- diagonal line starting at origin,
-- closest point relative to various positions along the X-axis.
assertc(
	0, 0, 0,
	2, 2, 0,
	1, 0, 0,
	0.5, 0.5, 0)
assertc(
	0, 0, 0, 
	2, 2, 0,
	2, 0, 0,
	1, 1, 0)
assertc(
	0, 0, 0,
	2, 2, 0,
	4, 0, 0,
	2, 2, 0)
-- for the above examples one can visualise a diagonal line
-- going from the closest point to the point on the X-axis.
-- if we move beyond X = 4, the connecting line rolls off the original line,
-- however the closest point should remain being the highest point on the line.
assertc(
	0, 0, 0,
	2, 2, 0,
	8, 0, 0,
	2, 2, 0)

-- we can request the remainder of the vector from the closest point to B
-- (note the final true parameter).
-- again, working out these values on graph paper is left as an exercise.
-- this is the one from above where we expect x=0.5, y=0.5, z=0,
-- so the remainder to the point (2, 2, 0) will be (1.5, 1.5, 0).
local rx, ry, rz, dx, dy, dz = closest(0, 0, 0, 2, 2, 0, 1, 0, 0, true)
assert(eq(rx, 0.5))
assert(eq(ry, 0.5))
assert(eq(rz, 0))
assert(eq(dx, 1.5))
assert(eq(dy, 1.5))
assert(eq(dz, 0))


local m_cyl = mtrequire("ds2.minetest.vectorextras.is_in_cylinder")
local is_in_cylinder = m_cyl.raw

local test_bounds = function(...)
	assert(is_in_cylinder(...))
end
local mkbounds = function(ax, ay, az, bx, by, bz, radius)
	local test = function(px, py, pz)
		return is_in_cylinder(ax, ay, az, bx, by, bz, radius, px, py, pz)
	end
	local accept = function(...)
		assert(test(...))
	end
	local reject = function(...)
		assert(not test(...))
	end
	return accept, reject
end

-- a simple cylinder of height and radius one.
-- the origin ought to lie inside this point
local r = 1
local accept, reject = mkbounds(0, 0, 0, 0, 1, 0, r)
accept(0, 0, 0)
-- as should the top point
accept(0, 1, 0)
-- and the mid-point
accept(0, 0.5, 0)
-- points just outside this height range should NOT work
reject(0, -0.1, 0)
reject(0, -1, 0)
reject(0, 1.1, 0)
reject(0, 2.0, 0)

-- point that will lie off-centre but within the circle should work.
accept(1.0, 0, 0)
accept(0, 0, 1.0)
accept(-0.5, 0, -0.5)
-- however, points outside that circle should NOT work
reject(1.0, 0, 1.0)
reject(-1, 0, -1)
-- circular cross section should not change with height
accept(1.0, 1, 0)
accept(0, 1, 1.0)
accept(-0.5, 1, -0.5)
reject(1.0, 1, 1.0)
reject(-1, 1, -1)



-- now test some more diagonal pointing cylinders, offset from origin.
local accept, reject = mkbounds(1, 1, 1, 2, 2, 2, 1)
accept(1, 1, 1)
-- argh, rounding errors strike again
accept(1.99, 1.99, 1.99)
accept(1.5, 1.5, 1.5)
reject(2.1, 2.1, 2.1)
-- just to show this isn't the same as above...
reject(0, 0, 0)
reject(0, 1, 0)

accept(2, 1.5, 1.5)
reject(3, 1.5, 1.5)


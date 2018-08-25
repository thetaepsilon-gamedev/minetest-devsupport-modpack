local m_prod = mtrequire("ds2.minetest.vectorextras.product")

-- deduce the side of a cube that a unit vector from it's center intersects.
-- we can determine which face was passed by looking at the largest component
-- (in terms of absolute value).
-- we indicate this as a vector pointing out the detected face;
-- in the event that two or more components were equal,
-- the resulting vector will be a diagonal that passes through the boundary,
-- whether that boundary be an edge or a vertex.


-- returns the maximum component of a vector.
-- we're not interested in *which* one because we deal with that later.
-- Vec3 Number -> Number
local max = math.max
local max_component = function(vx, vy, vz)
	return max(vx, max(vy, vz))
end

-- Apply a function to the xyz components of a vector.
-- Note, the resulting vector may not have numerical components!
-- (a -> b) -> Vec3 a -> Vec3 b
local fmap_vector_ = function(f)
	assert(type(f) == "function")
	return function (ix, iy, iz)
		local rx = f(ix)
		local ry = f(iy)
		local rz = f(iz)
		return rx, ry, rz
	end
end

-- to this day.. no math.sign. sigh...
-- sign :: Number -> Number
local sign = function(v)
	return ((v == 0) and 0 or ((v > 0) and 1 or -1))
end
local vsigns = fmap_vector_(sign)
local vabs = fmap_vector_(math.abs)



-- partially applied equals because we don't have that in lua...
-- eq :: Eq a -> a -> a -> Bool
local eq = function(a)
	return function(b)
		return (a == b)
	end
end
-- map bool to one or zero.
-- toBit :: (a -> Bool) -> a -> Number
local toBit = function(f)
	return function(v)
		return f(v) and 1 or 0
	end
end


-- returns the vector and count of faces that were crossed.
-- in the case of the zero vector, returns 0 and the zero vector.
-- Vec3 Number -> (Vec3 Number, Int)
local vmult = m_prod.raw
local z = function(v) return v == 0 end

local i = {}
local get_traversed_faces = function(vx, vy, vz)
	if z(vx) and z(vy) and z(vz) then
		return 0, 0, 0, 0
	end

	local mx, my, mz = vabs(vx, vy, vz)
	local sx, sy, sz = vsigns(vx, vy, vz)
	local max = max_component(mx, my, mz)

	-- this representation works because (unless the cube is zero sized)
	-- it's not possible for a vector to cross e.g. +Y and -Y at the same time.
	-- touched_axes (without signs)
	local tax, tay, taz = fmap_vector_(toBit(eq(max)))(mx, my, mz)
	-- touched_sides (re-attach signs for correct faces)
	local tsx, tsy, tsz = vmult(tax, tay, taz, sx, sy, sz)

	-- touched axes are 0/1 flags, so just add them.
	local total = tax + tay + taz
	return tsx, tsy, tsz, total
end
i.raw = get_traversed_faces



local unwrap = mtrequire("ds2.minetest.vectorextras.unwrap")
local wrap = mtrequire("ds2.minetest.vectorextras.wrap")
local wrapped = function(v)
	local vx, vy, vz = unwrap(v)
	local tsx, tsy, tsz, total = get_traversed_faces(vx, vy, vz)
	local wrapped = wrap(tsx, tsy, tsz)
	return wrapped, total
end
i.wrapped = wrapped



return i


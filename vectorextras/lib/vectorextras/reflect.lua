--[[
Given a ray hitting a surface with a known normal vector
(i.e. pointed straight out perpendicular to the surface, and normalised),
we can work out what direction the ray will go after hitting the surface;
useful for modelling reflections or perfect collisions off of an object.

reflected = original + (-2 * normal * dot(original, normal))

This function supports partial application of certain parameters,
passed via an options table:
reflectivity: the -2 in the above equation, and defaults to -2 if not set.
	specifying other values can lead to some interesting results.
	For instance, setting it to -1 precisely cancels out the normal vector,
	so the resulting vector will end up going perpendicular to the normal.
	Setting it between -1 and 0 can model a sort of refraction,
	like when light passes into water - it slows down and bends.
]]
local m_dot = mtrequire("ds2.minetest.vectorextras.dotproduct")
local dotproduct = m_dot.raw
local m_mult = mtrequire("ds2.minetest.vectorextras.scalar_multiply")
local scalar_mult = m_mult.raw
local m_add = mtrequire("ds2.minetest.vectorextras.add")
local vector_add = m_add.raw

local i = {}
-- note: the surface normal, funnily enough, must be normalised!
-- typically it is pre-computed ahead of time, but bear the above in mind.
local retn = function(x, y, z, a) return x, y, z end
local reta = function(x, y, z, a) return x, y, z, a end
local mk_reflect_raw_ = function(opts)
	opts = opts or {}
	assert(type(opts) == "table")
	local rv = opts.reflectivity or -2
	assert(type(rv) == "number")
	-- allow requesting that the amount of the normal vector in input is returned.
	-- this can be useful as e.g. a height in terms of the normal vector.
	local ret = opts.getdot and reta or retn

	return function(ox, oy, oz, nx, ny, nz)
		local amount = dotproduct(ox, oy, oz, nx, ny, nz)
		local scale = rv * amount
		local bx, by, bz = scalar_mult(scale, nx, ny, nz)
		local rx, ry, rz = vector_add(ox, oy, oz, bx, by, bz)
		return ret(rx, ry, rz, amount)
	end
end
i.mk_reflect_raw_ = mk_reflect_raw_

-- provide an instance with default settings.
i.default_reflect_raw = mk_reflect_raw_()

local mk_reflect_wrapped_ = function(opts)
	local reflect_raw = mk_reflect_raw_(opts)

	return function(original, normal)
		local ox, oy, oz = unwrap(original)
		local nx, ny, nz = unwrap(normal)
		return wrap(reflect_raw(ox, oy, oz, nx, ny, nz))
	end
end
i.mk_reflect_wrapped_ = mk_reflect_wrapped_
i.default_reflect_wrapped = mk_reflect_wrapped_()



return i


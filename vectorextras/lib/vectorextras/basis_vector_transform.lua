--[[
Basis vector transformation:
Given a point to be translated, and three basis vector points
(relative to the origin and should be unit vectors),
this function will "rotate" the point into the coordinate space
represented by the basis vectors.
The basis vectors represent the new X, Y, and Z axes
with which to measure the position of the input point,
and the function will return the point (from the original coordinate space)
as measured using these new X, Y, and Z axes.

This function uses partial application,
to support the use case of potentially rotating several positions:
First pass the basis vectors, and you will get back a closure,
which can then be applied to the positions you wish to rotate.
]]

-- used to work out the values along the new axes.
local m_dot = mtrequire("ds2.minetest.vectorextras.dotproduct")
local dotproduct = m_dot.raw

local function inner(n, v, ...)
	if (type(v) ~= "number") then
		error("assert_args_all_numbers(): argument #"..n.." was not a number!")
	else
		local count = select("#", ...)
		if count > 0 then
			inner(n+1, ...)
		end
	end
end

local assert_all_args_numbers = function(...)
	return inner(1, ...)
end

local i = {}
local basis_transform_raw_ = function(ax, ay, az, bx, by, bz, cx, cy, cz)
	assert_all_args_numbers(ax, ay, az, bx, by, bz, cx, cy, cz)

	return function(px, py, pz)
		local al = dotproduct(px, py, pz, ax, ay, az)
		local bl = dotproduct(px, py, pz, bx, by, bz)
		local cl = dotproduct(px, py, pz, cx, cy, cz)

		return al, bl, cl
	end
end
i.raw_ = basis_transform_raw_



return i


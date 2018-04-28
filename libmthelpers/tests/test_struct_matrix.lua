#!/usr/bin/env lua5.1

local sep = function() print("--------") end

local matrix =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.datastructs.matrix")

local m1 = matrix.new(4, 2, {1, 2, 3, 4, 5, 6, 7, 8})
assert(m1:equals(m1), "matrix should compare equal to itself")
local m2 = matrix.new(4, 2, {1, 2, 3, 4, 5, 6, 7, 8})
assert(m1:equals(m2), "matrix should compare equal to same-sized matrix with same values")
assert(m2:equals(m1:clone()), "matrix should compare equal to an equivalent clone")

local height, width = m1:get_size()
assert((height == 4) and (width == 2), "expected 4x2 matrix reported from get_size()")

assert(m1:index(2, 1) == 3, "unexpected value in 2nd row 1st column")

--[[
      1  2
      3  4

1 2   7  10 
3 4   15 22
5 6   23 34
7 8   31 46
]]
local m3 = matrix.new(2, 2, {1, 2, 3, 4})
local result = m1:multiply_m(m3)
local expected = matrix.new(4, 2, {
	7, 10,
	15, 22,
	23, 34,
	31, 46,
})
if not result:equals(expected) then
	print("---- expected:")
	matrix.primitive_print(expected, print)
	print("---- actual:")
	matrix.primitive_print(result, print)
	error("matrix multiplication mis-match")
end

local equal_xyz = function(vec1, vec2)
	return (vec1.x == vec2.x) and
		(vec1.y == vec2.y) and 
		(vec1.z == vec2.z) and
		true
end



assert(equal_xyz({x=3,y=1,z=0}, {x=3,y=1,z=0}),
	"same-valued XYZ vectors should compare equal")
assert(not equal_xyz({x=3,y=1,z=0}, {x=3,y=2,z=0}),
	"different-valued XYZ vectors should NOT compare equal")

local m4 = matrix.from_xyz({x=1,y=42,z=3})
local pos1 = matrix.to_xyz(m4)
assert(equal_xyz(pos1, {x=1,y=42,z=3}),
	"vector should be equal after round-tripping through matrix conversion")

local m5 = matrix.new(3, 1, {5, 6, 7})
local pos2 = matrix.to_xyz(m5)
assert(equal_xyz(pos2, {x=5,y=6,z=7}),
	"unexpected values from matrix converted to vector")

local pos3 = {x=7,y=8,z=9}
local m6 = matrix.from_xyz(pos3)
local expected = matrix.new(3, 1, {7, 8, 9})
assert(expected:equals(m6), "unexpected values for vector -> matrix conversion")




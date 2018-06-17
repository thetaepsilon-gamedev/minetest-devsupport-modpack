--[[
vector dot product, usually written 𝐚 · 𝐛
(rip users with poor unicode...).
Intuitively, assuming b is a unit vector,
we can use the dot product to tell us how much magnitude of b is present in a.
For instance, suppose we're reflecting something off a surface [monospace warning]:
I   N   R
 \  |  /
  \ | /
   \|/
---------
Assume also that N is a unit vector,
then I · N gives us a value containing the magnitude of N in I.
If we them times that by I, and subtract that from I,
we would get a vector moving parallel to N.
Subtract again and we get a vector R
which is reflected off the plane parallel to N.

There are various other uses for the dot product
which are too lengthy to explain here.
One should be prepared to deal with a lot of algebra and vectors when it is found...
]]
local unwrap = mtrequire("ds2.minetest.vectorextras.unwrap")

-- note: one of the vectors (preferably b)
-- should be normalised, otherwise the answer will very likely be incorrect.
-- that said about preference, the operation can be seen below to be commutitive:
-- a dot b will always equal b dot a.
local dot_raw = function(ax, ay, az, bx, by, bz)
	return (ax * bx) + (ay * by) + (az * bz)
end

local dot_wrapped = function(a, b)
	local ax, ay, az = unwrap(a)
	local bx, by, bz = unwrap(b)
	return dot_raw(ax, ay, az, bx, by, bz)
end

local i = {}
i.wrapped = dot_wrapped
i.raw = dot_raw
return i


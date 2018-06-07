local eq = mtrequire("ds2.minetest.vectorextras.equality")

-- same values.
local same = {x=1,y=45,z=34}
assert(eq(same, same))
-- should compare equal by component values, not by table values
assert(eq(same, {x=1,y=45,z=34}))

assert(not eq(same, {x=445,y=454,z=456}))
-- check what happens when at least one component is wrong.
assert(not eq(same, {x=451,y=45,z=34}))
assert(not eq(same, {x=1,y=455,z=34}))
assert(not eq(same, {x=1,y=45,z=3564}))
assert(not eq(same, {x=674,y=23,z=34}))
assert(not eq(same, {x=1,y=675,z=234}))
assert(not eq(same, {x=4546,y=45,z=674}))

-- extra keys should be ignored in non-strict mode.
assert(eq(same, {x=1,y=45,z=34,foo="wat"}))

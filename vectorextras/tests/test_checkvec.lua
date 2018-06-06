local checkvec = mtrequire("ds2.minetest.vectorextras.checkvec")
local sep = function()
	--print("---")
end
local accept = function(v)
	sep()
	assert(checkvec(v), "checkvec() rejected but expected true")
end
local reject = function(v)
	sep()
	assert(not checkvec(v), "checkvec() accepted but expected false")
end

-- wrong argument types or forgot to pass
assert(not checkvec())
reject(1)

-- wrong kinds of tables
reject({})
reject({"a","list","that_shouldn't_be_here"})

-- incomplete tables - possibly bugs in source code
reject({x=86})
reject({y=365})
reject({z=123})
reject({x=142, y=31 })
reject({y=45,  z=654})
reject({z=3445,x=87 })

-- one of the x/y/z components was not a number
reject({x="foo",y=124,z=66})
reject({x=1,y={}, z=765})
reject({x=1,y=656,z=false})

-- regular vector should work
accept({x=45,y=34,z=67})
-- a vector with extra keys should work unless strict mode is on.
local extra = {x=45,y=45,z=77,w=2}
accept(extra)
assert(not checkvec(extra, true))



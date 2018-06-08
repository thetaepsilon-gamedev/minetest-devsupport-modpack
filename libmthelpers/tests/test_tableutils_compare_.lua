local compare_ =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.tableutils.compare_")

-- test helper:
-- compare equal by specific keys in tables
local kex = function(t)
	assert(type(t) == "table")
	local v = t[1]
	assert(v ~= nil)
	return v
end
local kcomp = function(a, b)
	return kex(a) == kex(b)
end
local key = function(v) return {v} end

-- obvious things: called with no arguments, not enough, or wrong types
local plain_eq = compare_()
local reject = function(t1, t2)
	assert(not plain_eq(t1, t2))
end
reject()
reject({})
reject(1)
reject(nil, {})
reject(nil, "wat")
reject({}, false)
reject({}, 42)
reject(34, "wat2")

local keq = compare_({comparator=kcomp})
-- empty tables should compare equal regardless of comparator used,
-- as there are no keys to invoke on in the first place.
assert(plain_eq({}, {}))
assert(keq({}, {}))

-- plain comparison operator should work as you'd expect on keys.
local mk_plain_test = function()
	return {
		d = 1,
		e = 5,
		f = 2,
	}
end
local t1 = mk_plain_test()
local t2 = mk_plain_test()
assert(plain_eq(t1, t2))

-- the plain comparison operator will do by-value examination of keys,
-- so if those sub-keys are tables it should think they are different.
local mk_subtable_test = function()
	return {
		a = key(1),
		b = key(2),
		c = key(3),
	}
end
local t1 = mk_subtable_test()
local t2 = mk_subtable_test()
reject(t1, t2)

-- whereas equipped with the correct comparator it will look more closely.
assert(keq(t1, t2))



-- check handling of missing keys.
-- input missing some of reference's keys is always a failure.
local t2 = {
	a = key(1),
	-- look ma, no b!
	c = key(3),
}
reject(t1, t2)
-- by default, input having keys that the *reference* doesn't is not a failure.
local t2 = {
	a = key(1),
	b = key(2),
	c = key(3),
	d = key(4),
}
assert(keq(t1, t2))
-- however, this is not allowed in strict mode
assert(not compare_({comparator=kcomp,strict=true})(t1, t2))


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

-- likewise check what happens if the key is present but different.
local t2 = {
	a = key(1),
	b = key(42),
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
local c2 = compare_({comparator=kcomp,strict=true})
assert(not c2(t1, t2))



-- we can ask for an extra return value describing an error, if any.
-- as it is possible that this would change behaviour if one did e.g.
-- f(comparef(...)) (in other words, f() would see an extra argument),
-- it is not enabled by default - here we verify this default behaviour.
local countargs = function(...)
	return select("#", ...)
end
assert(countargs(c2(t1, t2)) == 1)

-- now we enable the error object by adjusting properties of the partially applied function.
local c3 = compare_({comparator=kcomp,strict=true,verbose=true})
local result, ex = c3(t1, t2)
-- truth value should not differ.
assert(not result)
-- let's examine the object shall we...
local err =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.errors.stdcodes")
assert(ex.reason == err.table.unknown_key)

-- please note that further testing of error codes is not done here on purpose;
-- the error code object is intrinsically tightly coupled
-- to the internals of compare_.
-- it is more intended to provide the ability to localise error descriptions
-- to the user's language preferences (as opposed to hard-coded strings),
-- as well as providing a more structured way to pass errors along
-- (a la java's caused by: in stack traces).




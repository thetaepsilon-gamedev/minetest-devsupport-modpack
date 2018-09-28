#!/usr/bin/env lua5.1

local lib = "com.github.thetaepsilon.minetest.libmthelpers"
local stack =
	mtrequire(lib..".datastructs.stack")
local n = stack.new





-- bad behaviour testing:
-- ensure errors are thrown when the constructor values are invalid.
local e = "err.args.expected_t.numeric.natural_or_zero"
local expect = mtrequire(lib..".errors").expect_error
expect(e, n, -1)	-- negative length? what
expect(e, n, 1.5)	-- you can't have half an index!
expect(e, n, -4.5)
expect(e, n, false)	-- just wrong types now, perhaps from wrong variable
expect(e, n, {})
expect(e, n, "BLARGH")





-- test that an empty stack returns empty.
local check_empty = function(empty)
	for i, v in empty.ipairs() do
		-- won't be called if the iterator runs zero times
		error("empty stack should not have any iterator elements")
	end
	assert(empty.size() == 0, "empty stack should have size zero")
end
check_empty(n())
check_empty(n(0))





-- new stacks with a certain size requested should return n nils when iterated.
local msg_size = "number of iterations vs requested size didn't match: "
local check_size = function(size)
	local vec = n(size)
	assert(
		vec.size() == size,
		"stack(n) should have size() == n after construction")

	local c = 0
	for i, v in vec.ipairs() do
		c = c + 1
		if i ~= c then
			error("iterator index didn't match count at count = "..c)
		end
		if v ~= nil then
			error("item at index "..i.." wasn't nil in new stack")
		end
	end
	if c ~= size then
		error(msg_size.."count="..c.." vs size="..size)
	end
	return vec
end

check_size(1)
check_size(2)
check_size(42)
check_size(678)
check_size(4536)





-- now try pushing some elements.
local check_push = function(base_elements)
	local vec = n()
	check_empty(vec)

	for i, bv in ipairs(base_elements) do
		vec.push(bv)

		-- the ordering shouldn't really change during pushing.
		local expected_size = i
		local c = 0
		for j, pv in vec.ipairs() do
			c = c + 1
			assert(
				c <= expected_size,
				"stack iteration longer than inserted elements!?")
			assert(j == c, "iterator count/index mismatch")
			assert(
				pv == base_elements[j],
				"mis-match between original and retrieved element")
		end
	end
	return vec
end

check_push({43,6,4,7,3,45,565,3464,6572})
check_push({4,6,33,878,347,58,578,127})





-- similar to the above, but constructs the stack with a given size first;
-- this should have the effect of having n nils in the vector first.
local check_push_presize = function(base_elements, size)
	local vec = n(size)

	for i, bv in ipairs(base_elements) do
		vec.push(bv)

		local expected_size = i + size
		local c = 0
		for j, pv in vec.ipairs() do
			c = c + 1
			assert(
				c <= expected_size,
				"stack iteration longer than existing elements!?")
			assert(j == c, "iterator count/index mismatch")

			-- first `size` elements nil...
			local expected
			if c > size then
				expected = base_elements[c - size]
			end
			assert(pv == expected, "mismatch in expected element")
		end
	end
end
check_push_presize({43,6,4,7,3,45,565,3464,6572}, 64)
check_push_presize({4,6,33,878,347,58,578,127}, 12)





-- other random things...
-- try pushing a function onto one then iterating and calling it.
-- should work exactly as expected;
-- the stack is not expected to distinguish types of pushed elements.
local sub = function(a, b) return a - b end
local fstack = n()
fstack.push(sub)
for i, f in fstack.ipairs() do
	local r = f(10, 4)
	assert(r == 6)
end





-- test popping.
local empty = stack.empty()
local check_empty = function(s)
	assert(s.pop() == empty, "stack was expected to be empty")
end
check_empty(n())

local msg = "popped element didn't match expected"
local check_pop = function(base_elements)
	local s = check_push(base_elements)
	local n = #base_elements
	for i = n, 1, -1 do
		assert(s.pop() == base_elements[i], msg)
	end
end
check_pop({34,56,false,{},"abc"})




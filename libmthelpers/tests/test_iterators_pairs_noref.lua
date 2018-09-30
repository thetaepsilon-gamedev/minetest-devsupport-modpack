--[[
The standard lua pairs() gives no ordering guarantees of keys,
and pairs_noref() doesn't say *on it's interface*
that it gives any particular order either,
nor does it state that it's ordering matches that of in-built pairs()
(regardless of implementation, which isn't what black box testing is for).
Hence, to test this routine, it is sufficient to form a "checklist" of keys,
and ensure that pairs_noref() "ticks" them all and that the values match.
]]

local p = "com.github.thetaepsilon.minetest.libmthelpers.iterators.pairs_noref"
local pairs_noref = mtrequire(p)

-- create the "checklist" of table keys using standard pairs().
local opairs = pairs
local create_checklist = function(t)
	local checklist = {}
	for k, _ in opairs(t) do
		checklist[k] = true
	end
	return checklist
end	



local msg_unknown = "a key appeared during iteration not in the original table:"
local msg_mismatch = "value didn't match original during iteration:"
local q = function(v)
	local t = type(v)
	local s = (t == "string")
	return s and string.format("%q", v) or tostring(v)
end
local test = function(t)
	-- make a note of which keys need testing.
	-- we compare from the original table during iteration
	-- (so we know the keys have the right values),
	-- however we also need to check at the end that
	-- *all keys* present in the original table went through the iterator.
	local checklist = create_checklist(t)

	for k, v in pairs_noref(t) do
		assert(k ~= nil, "nil key appeared!?")
		-- nil values are treated as non-existant,
		-- so they should never appear.
		local original = t[k]
		local qk = " key="..q(k)
		local qv = " iterator value="..q(v)
		if original == nil then
			error(msg_unknown..qk..qv)
		end

		if original ~= v then
			local qo = " original value="..q(original)
			error(msg_mismatch..qk..qv..qo)
		end

		-- so at this point we know the value for this key is matched;
		-- clear it from the checklist
		checklist[k] = nil
	end

	-- now check that no keys remained unaccounted for from the checklist.
	local missing = 0
	for k, _ in opairs(checklist) do
		missing = missing + 1
	end
	assert(missing == 0, "some keys did not make it through the iterator")
end



-- now, just test with as many different tables as you like...

test({1,56,false,"","abc","wtf",{}})
test({a=1,b=42,xyz="wat",t={}})



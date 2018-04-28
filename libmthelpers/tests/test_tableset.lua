#!/usr/bin/env lua5.1
local collect_iterator = function(it)
	local results = {}
	for v in it do table.insert(results, v) end
	return results
end

local collect_set = function(set)
	return collect_iterator(set.iterator())
end

local notexists = "object should not be considered present if not previously inserted"
local not_exists_trans = "object should not be inserted by failed transaction"
local exists_trans = "object expected to be present after completing transaction"
local expected_committable = "expected to get commit handle for should-be unique values"
local test = function(constructor)
	local set = constructor()
	local t = {}
	local collected = nil

	assert(set.size() == 0, "new set should have size zero")
	assert(#collect_set(set) == 0, "new set should return zero elements")

	assert(not set.ismember(t), notexists)
	assert(not set.remove(t), notexists)

	assert(set.add(t), "object should be newly inserted")
	assert(set.ismember(t), "object should be member after being inserted")
	collected = collect_set(set)
	assert(#collected == 1, "set should return one element after insertion")
	assert(set.size() == 1, "set should have size one after insertion")
	assert(collected[1] == t, "sole item of set should be the inserted element")

	assert(set.remove(t), "object should have been removed after being inserted")
	assert(set.size() == 0, "set size should be zero after removal")
	assert(#collect_set(set) == 0, "set should return zero elements after removal")
	local oldelement = "item should not be present if added then removed"
	assert(not set.remove(t), oldelement)
	assert(not set.ismember(t), oldelement)

	local a = { 1 }
	local b = { 2 }
	local c = { 3 }
	local newelement = "set should be able to accept a new element"
	assert(set.add(a), newelement)
	assert(set.add(b), newelement)
	assert(set.add(c), newelement)
	assert(set.size() == 3, "set should have size 3 after three insertions")
	assert(#collect_set(set) == 3, "set should contain three elements after three insertions")

	assert(set.remove(b), "object should have been removed")
	assert(set.size() == 2, "set should have size 2 after three insertions and one removal")
	assert(#collect_set(set) == 2, "set should contain two elements after three insertions and one removal")

	local na = { 4 }
	assert(not set.remove(na), notexists)
	assert(not set.ismember(na), notexists)

	-- transactionality tests.
	-- transaction should NOT succeed for an already-added value.
	local d = { 4 }
	local e = { 5 }
	assert(set.batch_add({d, e, a}) == nil, "transaction should fail with already-existing value")
	-- and should not touch the set's contents
	local expect_trans_noeffect = function()
		assert(not set.remove(d), not_exists_trans)
		assert(not set.remove(e), not_exists_trans)
		assert(not set.ismember(e), not_exists_trans)
		assert(not set.ismember(d), not_exists_trans)
	end
	expect_trans_noeffect()

	-- but should succeed with unique values.
	local commit = set.batch_add({d, e})
	assert(type(commit) == "function", expected_committable)
	-- don't call the commit, *still* values should not be there
	-- same behaviour as dropping the commit as the committer function is just thrown away.
	expect_trans_noeffect()
	-- *then* commit and check the values are in there
	commit()
	assert(set.ismember(d), exists_trans)
	assert(set.ismember(e), exists_trans)
	-- transaction should be defused after calling once.
	set.remove(e)
	commit()
	assert(not set.ismember(e), "duplicate commits should have been defused and not re-insert values")

	local f = { 6 }
	local g = { 7 }
	set.merge({f, g})
	local postmerge = "object should be present after merge operation"
	assert(set.ismember(f), postmerge)
	assert(set.ismember(g), postmerge)

	return "self-tests completed"
end

local intkeytests = function(constructor)
	local set = constructor()

	local newelement = "set should be able to accept a new element"
	assert(set.add(1), newelement)
	assert(set.add(2), newelement)
	assert(set.add(3), newelement)
	assert(set.size() == 3, "set should have size 3 after three insertions")
	assert(#collect_set(set) == 3, "set should contain three elements after three insertions")

	assert(set.remove(2), "object should have been removed")
	assert(set.size() == 2, "set should have size 2 after three insertions and one removal")
	assert(#collect_set(set) == 2, "set should contain two elements after three insertions and one removal")

	assert(not set.remove(4), notexists)
	assert(not set.ismember(4), notexists)

	return "integer tests completed"
end



local tableset = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.datastructs.tableset")

test(tableset.new)
test(tableset.mk_unique)
intkeytests(tableset.mk_unique)




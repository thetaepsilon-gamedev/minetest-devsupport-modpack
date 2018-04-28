#!/usr/bin/env lua5.1
local qi = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.datastructs.queue")

local queue = qi.new()
assert(queue.size() == 0, "queue should have size zero when new")

local pushnil = function()
	local msg_nonil = "queue should not accept nil elements"
	assert(not queue.enqueue(nil), msg_nonil)
end
pushnil()

local checksamesize = function(expected)
	local msg_nosizechange = "queue should not change size after inserting a nil element"
	assert(queue.size() == expected, msg_nosizechange)
end
checksamesize(0)

-- check that all non-nil items are successfully inserted.
local checkpush = function(item)
	assert(queue.enqueue(item), "queue should be able to accept non-nil item")
end

local items = { 1, 34, 453, 6 }

local testordering = function(items)
	local total = #items
	for index, item in ipairs(items) do
		checkpush(item)
		assert(queue.size() == index, "queue should have size "..tostring(index).." after inserting that many items")
		pushnil()
		checksamesize(index)
	end
	for index, expected in ipairs(items) do
		local actual = queue.next()
		assert(expected == actual, "queue should return objects in order of insertion")
		local expectedsize = (total - index)
		assert(queue.size() == expectedsize, "queue should have size "..tostring(expectedsize).." after "..tostring(total).." removals and "..tostring(index).."removals")
		pushnil()
		checksamesize(expectedsize)
	end
end
testordering(items)

-- can't hurt to spam it... right?
for i = 1, 100, 1 do
	local result = queue.next()
	assert(result == nil, "empty run #"..tostring(i)..": empty queue should return nil")
	assert(queue.size() == 0, "empty queue should have zero size")
	pushnil()
	checksamesize(0)
end

testordering({45, 5656, 4, 567, 564})



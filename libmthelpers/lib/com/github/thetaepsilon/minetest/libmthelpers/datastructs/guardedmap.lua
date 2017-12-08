local i = {}

--[[
A "guarded map".
Essentially a structure wrapping a table that (by default)
blocks duplicate insertions via add(), invoking callbacks to handle this case.
When the key is unique, it is inserted as normal.

An extra remove() operation is also supplied,
to allow removal without invoking the duplicate mechanism.
This removal mechanism will invoke callbacks if the key doesn't exist;
intended to help cases where the key is expected to exist already.
On success, the old value is returned.

Finally there is the get() operation which behaves as expected;
nil indicates "doesn't exist" like normal tables.

Any operation that may invokes a callback returns a boolean success value.
On (initial) failure, additional return values from the callback are passed through.
The callbacks are allowed to throw errors if so desired in a "shouldn't happen" situation.
]]
local checkers = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.check")

--[[
callback interface, all of these are optional:
+ callbacks:on_collision(e, k, oldv, newv):
	called with access to the inner entries table, the colliding key,
	the current value for that key, and the value that was trying to be inserted.
	the callback may decide to overwrite anyway by doing e[k] = newv.
+ callbacks:on_remove_missing(e, k):
	called when tried to remove a key that didn't exist in the table.
	e is the entries table, k is the key that was attempted to be removed.
]]
local ifdesc = { "on_collision", "on_remove_missing" }
local prefix = "guardedmap.new() callbacks table was invalid:"
-- default to doing nothing for any missing callbacks.
local checki = checkers.mk_interface_defaulter(prefix, ifdesc, nil)



local add = function(self, k, v)
	local e = self.entries
	local oldv = e[k]
	if oldv ~= nil then
		return false, self.handler:on_collision(e, k, oldv, v)
	else
		e[k] = v
		self.count = self.count + 1
		return true
	end
end

local remove = function(self, k)
	local e = self.entries
	local oldv = e[k]
	if oldv == nil then
		return nil, self.handler:on_remove_missing(e, k)
	else
		e[k] = nil
		self.count = self.count - 1
		return oldv
	end
end

local get = function(self, k) return self.entries[k] end

local size = function(self) return self.count end

-- get a single arbitary entry from the table.
-- intended for use cases where other operations clear entries from this map,
-- until none remain.
-- returns key and value of the selected entry.
local getsingle = function(self)
	local k, v = next(self.entries)
	return k, v
end

-- get a copy of the internal entries table.
local copyentries = function(self)
	local ret = {}
	for k, v in pairs(self.entries) do ret[k] = v end
	return ret
end

local iterator = function(self) return pairs(self.entries) end

local construct = function(callbacks)
	local self = {
		add = add,
		remove = remove,
		get = get,
		size = size,
		next = getsingle,
		copyentries = copyentries,
		iterator = iterator,
	}
	self.entries = {}
	self.count = 0
	self.handler = checki(callbacks)

	return self
end
i.new = construct

-- construct the map from a provided table, copying it's keys.
local copytable = function(callbacks, existing)
	local self = construct(callbacks)
	local count = 0
	-- the map is new, so don't bother running callback checks.
	local e = self.entries
	for k, v in pairs(existing) do
		e[k] = v
		count = count + 1
	end
	self.count = count
	return self
end
i.from_table = copytable



return i

local interface = {}

local iterators = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.iterators")
local curry = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.readonly.curry")
local curryobject = curry.object
local mk_value_iterator = iterators.mk_value_iterator

-- argh, why could I not just "from package import function..."
local check = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.check")
local mkfnexploder = check.mkfnexploder

-- generic table which takes a "hash function" to calculate keys.
-- the hash function is expected to produce a "compare equal" quality:
-- for the same value, the hash result must be the same.
-- two values which are considered equal for this hasher
-- (but do not compare directly, e.g. coordinate tables with the same values but different addresses)
-- must also map to the same hash value.

-- check if an entry is present without inserting it; returns true if so.
local test = function(self, v)
	local exists = (self.entries[self.hasher(v)] ~= nil)
	return exists
end

-- internal assignment operation, takes care of adjusting the count.
-- should not be called without checking the key doesn't already exist.
local overwrite = function(self, v, hash)
	self.entries[hash] = v
	self.size = self.size + 1
end

-- internal insertion operation when hash is already calculated.
local tryinsert = function(self, v, hash)
	local isnew = (self.entries[hash] == nil)
	if isnew then
		overwrite(self, v, hash)
	end
	return isnew
end



-- externally visible operations follow
-- external add operation
local add = function(self, v)
	return tryinsert(self, v, self.hasher(v))
end

-- returns true if item was removed, false if it didn't exist
local remove = function(self, v)
	local hash = self.hasher(v)
	local e = self.entries
	local didexist = (e[hash] ~= nil)
	if didexist then
		e[hash] = nil
		self.size = self.size - 1
	end
	return didexist
end

-- obtain an iterator over the items of a set
local iterator = function(self)
	return mk_value_iterator(self.entries)
end

-- transactional insert operation:
-- either adds the entire provided set of values, expecting them to be new,
-- or performs no changes.
-- returns a "commit" function that can be called to complete the operation,
-- or nil if no changes took place.
-- onus is on caller not to modify the set in the meantime.
local batch_add = function(self, values)
	local mergeset = {}
	local hasher = self.hasher
	local e = self.entries
	for _, v in ipairs(values) do
		local hash = hasher(v)
		if (e[hash] ~= nil) then
			return nil
		else
			mergeset[hash] = v
		end
	end
	-- if we get this far, it's all unique
	local breaker = false
	return function()
		if breaker then return end
		breaker = true
		for hash, v in pairs(mergeset) do
			overwrite(self, v, hash)
		end
	end
end

-- batch insert operation where it is not cared about whether some are not inserted.
local merge = function(self, values)
	local hasher = self.hasher
	for _, value in pairs(values) do
		tryinsert(self, value, hasher(value))
	end
end



-- constructor functions.
-- offer a method table form without closuring to help reduce memory.
local dname_constructor = "mk_generic_raw()"
local check_constructor = mkfnexploder(dname_constructor)
local mk_generic_raw = function(hasher)
	check_constructor(hasher, "hasher")
	local self = {
		add = add,
		remove = remove,
		ismember = test,
		iterator = iterator,
		batch_add = batch_add,
		merge = merge,
	}

	self.size = 0
	self.entries = {}
	self.hasher = hasher

	return self
end
interface.mk_generic_raw = mk_generic_raw

-- currified version to preserve existing API
local mk_generic = function(hasher)
	local self = mk_generic_raw(hasher)
	local curried = curryobject(self, {"add", "remove", "iterator", "ismember", "batch_add", "merge"})
	curried.size = function() return self.size end
	return curried
end
interface.mk_generic = mk_generic

-- simplified version of the set data structure for working with table or userdata handles;
-- it is assumed that inserted values do not alias inside the table (think 0 and "0").
-- hasher is a no-op and passes keys directly to the table to let it do hashing on values internally.
local noop = function(v) return v end
interface.new_raw = function()
	return mk_generic_raw(noop)
end
interface.new = function()
	return mk_generic(noop)
end

-- existing set for backwards compat.
-- ensures all keys can be unique by tagging them with their type.
local unique = function(val) return type(val).."!"..tostring(val) end
interface.mk_unique = function()
	return mk_generic(unique)
end



return interface

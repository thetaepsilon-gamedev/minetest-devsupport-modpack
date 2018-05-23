-- libmthelpers.readonly:
-- defensive protection of objects to prevent modifications to shared objects,
-- so that users of the protected object cannot modify it,
-- and therefore affect other users.

local readonly = {}

-- used to be here, now aliased from tableutils for compatibilty
local tableutils = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.tableutils")
readonly.shallowcopy = tableutils.shallowcopy

readonly.curry = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.readonly.curry")

--[[
create a "read-only" table.
note that this breaks pairs and ipairs operation.
this may be useful for a constants table or such which shouldn't be edited.
uses the __metatable meta field to prevent retrieval or replacement after.
this is only 100% if one excludes the debug library
( debug.{get,set}metatable() ),
which really ought to be considered dangerous anyway.
]]
local ro = function(...)
	error("attempt to modify to a read-only table")
end
local mk_ro_reader = function(t)
	return function(outer, key)
		return t[key]
	end
end
local mk_ro_table = function(t)
	-- as the outer table is technically blank,
	-- any assignments always trigger newindex.
	local meta = {
		__newindex = ro,
		__index = mk_ro_reader(t),
		__metatable = false,
	}
	return setmetatable({}, meta)
end
readonly.mk_ro_table = mk_ro_table

--[[
A somewhat simpler solution if one doesn't have API compat concerns:
just have a function which returns the keys from a captured table.
This can only be breached via the likes of debug.getupvalue.
]]
local mk_ro_accessor = function(t)
	return function(k)
		return t[k]
	end
end
readonly.mk_ro_accessor = mk_ro_accessor

return readonly


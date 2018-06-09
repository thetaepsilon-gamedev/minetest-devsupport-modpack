--[[
vector set comparison:
compare a table of vectors against a reference one.
Mostly a wrapper around libmthelpers.tableutils.compare_,
baking in the vector equality operator (see equality.lua).

Options:
+ vecstrict: strict mode flag for equality test.
	vectors with "extras" in their tables
	will be treated as a type error.
+ setstrict: strict mode flag as for libmthelpers.tableutils.compare_():
	if the input table has a vector that reference does not, reject it.
+ verbose: return an error object as well as boolean predicate upon match failure
]]

-- base table compare wrapper
local compare_ =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.tableutils.compare_")
-- equality operator... should have made this a partial applicative
local vecequal = mtrequire("ds2.minetest.vectorextras.equality")

local coercebool = function(v) return v and true or false end
local compare_set_ = function(opts)
	local opts = opts or {}
	local vecstrict = coercebool(opts.vecstrict)
	local setstrict = coercebool(opts.setstrict)
	local v = coercebool(opts.verbose)

	local eq = function(a, b)
		return vecequal(a, b, vecstrict, false)
	end

	return compare_({comparator=eq,strict=setstrict,verbose=v})
end

return compare_set_


--[[
Standard error "codes" (strings) for use in formatted errors.
This is to establish a convention on the formatted errors that can be expected.

Functions using these should document which ones they can throw,
ideally by referring to their object path as it appears below,
e.g. err.logic.register.duplicate and so on.
]]
local err = {}
local format =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.errors.format")
local format_error = format.format_error

local e = function(path, code)
	local root = err
	local current = root
	for _, sub in ipairs(path) do
		current = current[sub]
	end

	local sep = "."
	local str = table.concat(path, sep) .. sep .. code
	current[code] = format_error("err." .. str)
end

-- argument type errors:
-- calling something with a string where it expected a number.
err.args = {}
err.args.expected_t = {}
e({"args", "expected_t"}, "number")
-- be a bit careful here as function is a keyword,
-- so attempting to call it that would cause client problems.
e({"args", "expected_t"}, "func")
e({"args", "expected_t"}, "table")



--[[
Generic table data type errors - wrong keys, missing values etc.
Note that more specific use cases should probably have more relevant codes,
e.g. for when a table is used as a poor man's keyword arguments.
]]
err.table = {}
-- unknown key in table?
e({"table"}, "unknown_key")
-- a required key was missing.
e({"table"}, "missing_key")
-- key was expected to be a certain value due to other conditions.
-- may be accompanied with more information elaborating on this.
e({"table"}, "bad_key_value")



--[[
Errors associated with user-defined types (typically represented as tables).
Mostly some sense of "tried to call an operation not supported by this type";
in other words what would have been caught at compile time in static typed langs.
]]
err.struct = {}
-- tried to call a primitive operator on a type that didn't make sense
-- (e.g. metatable overriden but say adding isn't logical for this type)
e({"struct"}, "bad_operator")
-- unallowed accesses or modifications of keys (usually trapped by metatables)
e({"struct"}, "bad_key_access")
e({"struct"}, "bad_key_write")



--[[
Registration errors.
Many mods have some sort of mechanism to register callbacks or handlers
which are called in response to certain classes of events.
In these cases, things like e.g. duplicate registrations should be a hard error;
this is because it is a condition that should never arise in correct code,
or there is a mod conflict that needs resolving
(and trying to register handlers from two different,
mutually unaware mods is probably a recipe for weird things to happen).
]]
err.register = {}
-- duplicate registration error as described above.
e({"register"}, "duplicate")



--[[
Errors related to number type arguments.
Because of lua's insistance on a single number type,
we often can get a float when we only wanted an int;
other times negative numbers don't make sense.
]]
err.numeric = {}
e({"numeric"}, "expected_integer")
e({"numeric"}, "expected_positive_or_zero")
-- one could also argue this is a type property of sorts;
-- in that the *type* of the numbers are supposed to be e.g. integer, natural etc.
-- for instance: the type of natural numbers (with or without zero, as needed).
-- the distinction doesn't matter all that much in a dynamic language
-- (if you excuse the fact that type() won't tell apart these categories).
err.args.expected_t.numeric = {}
e({"args", "expected_t", "numeric"}, "integer")
-- please, mathematicians, no arguments!
-- I'm not here to decide whether 0 ∈ ℕ or not,
-- I just need labels for these things
e({"args", "expected_t", "numeric"}, "natural_nz")	-- ℕ*, "non-zero"
e({"args", "expected_t", "numeric"}, "natural_or_zero")	-- ℕ⁰



return err


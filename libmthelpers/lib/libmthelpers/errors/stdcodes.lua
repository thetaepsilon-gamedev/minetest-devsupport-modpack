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



return err


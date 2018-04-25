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



-- logic errors:


return err


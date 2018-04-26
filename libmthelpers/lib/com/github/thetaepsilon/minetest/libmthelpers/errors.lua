--[[
Modules for catching and throwing errors in a predictable way.
Produces error strings with a known prefix pattern of the form:
"<error type="ESOMETHINGBLEWUP" /> this thing blew up because..."
(NB: this is NOT XML)
In other words, still human readable but with a machine-checkable prefix.
Useful in tests where an error is *expected* to be thrown for invalid usage,
where it is likely that the caller can't really deal with a failure;
e.g. registration functions which error() if a duplicate exists.
]]

local i = {}

local esc = function(v)
	local is_str = (type(v) == "string")
	return is_str and string.format("%q", v) or tostring(v)
end

local format =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.errors.format")
i.format = format
local format_error = format.format_error

-- compatibility alias
i.format_error = format_error

local str_or_empty = function(m) return m and (" " .. msg) or "" end
i.ferror = function(e, msg)
	error( format_error(e) .. str_or_empty(msg) )
end

i.expect_error = function(expected, ...)
	local n = "expect_error(): "
	local ok, err = pcall(...)
	if (ok) then
		error(n.."no exception occured? expected error " .. 
			esc(expected) .. ", function returned " .. esc(err) ..
			" (type: "..type(err)..")")
	else
		local e = tostring(err)
		local x = format_error(expected)
		local start, last = string.find(e, x, 1, true)
		-- lua unfortunately mangles the error string with source code information if it can,
		-- so we must look for some special tags.
		if (start == nil) then
			-- re-raise error if it's not the expected one.
			error(n.."unexpected exception: (expected " .. expected ..") " .. e)
		end
	end
end

-- link in standard error codes.
i.stdcodes =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.errors.stdcodes")

return i


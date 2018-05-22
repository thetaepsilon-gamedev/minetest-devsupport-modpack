--[[
Not all characters are valid in a filename in all operating systems.
Furthermore, case insensitivity can mean that certain paths alias when they should not.
The functions in this file take an arbitary path string
and escape it using known safe characters.
]]

local strutil = dofile(_modpath.."strutil.lua")

local interface = {}

-- work out the safe representation of a parsed path.
-- see naming-conventions.md for details;
-- characters are "escaped" as needed to produce a path that is unambiguous and valid on all relevant OSes.
-- namely windows, linux-based, osx and the other unix-likes.
local encode_safe_filename = function(path)
	local result = ""
	local first = true
	for index, element in ipairs(path) do
		-- ternaries in lua make my head hurt.
		local sep = first and "" or "."
		result = result..sep..strutil.escape(element, "[0-9a-z_-]", "+")
		first = false
	end
	return result
end
interface.encode_safe_filename = encode_safe_filename

-- counterpart of the above which is used when treating each component as a sub-directory.
-- the dot "." is allowed to be used unescaped in this case.
-- this makes URI-style paths more readable in that case,
-- instead of "github.com" becoming something like "github+2ecom".
local encode_safe_path_component = function(element)
	return strutil.escape(element, "[0-9a-z_.-]", "+")
end
interface.encode_safe_path_component = encode_safe_path_component

return interface


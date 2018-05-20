--[[
When a mod has mod_reservations.lua present in it's mod directory,
it is opened and treated as an (isolated!) lua script.
Said script is expected to return a table of the following form:
{
	["com.mymod.mynamespace"] = {
		...
	},
	...
}
The keys are reserved namespaces, and the value is either a table
(containing certain allowed properties, see below)
or it is a boolean true value, which simply indicates no extra properties.

In this file you will find the code which performs validation on these tables.
]]



local allowed_keys = {
}
local check_table_keys = function(props)
	local ret = {}
	-- no extra props currently supported,
	-- so just raise error on *any* key.
	for k, v in pairs(props) do
		error("No extra reservation properties currently supported")
	end
	return ret
end



local i = {}
local emsg = "validate_reserve_properties(): " ..
	"reservation properties was unexpected type/value, " ..
	"expected nil, true or table, got "
local amsg = "skip a reservation by not setting it, don't use false for that"

local validate_reserve_properties = function(props)
	local t = type(props)
	local empty = {}
	if t == "nil" then
		-- the old reserved-namespaces.txt mechanism passes nil here
		return empty
	elseif t == "boolean" then
		-- just let it say "true" to reserve this namespace with defaults
		assert(props, amsg)
		return empty
	elseif t == "table" then
		return check_table_keys(props)
	else
		error(emsg .. t)
	end
end
i.validate_reserve_properties = validate_reserve_properties

return i


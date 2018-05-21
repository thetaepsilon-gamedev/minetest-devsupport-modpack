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



-- list of property key validation functions.
local msg_searchdir_type =
	"property search_dirs expected to be a table or string, got "

local allowed_keys = {
	-- alternative (shorter?) paths to look for relative to libs or natives.
	-- does not need directory separators, can just be plain dir name.
	search_dirs = function(cfg)
		local t = type(cfg)

		-- if it's a single string, just return that as length one list.
		if t == "string" then return { cfg } end
		assert(t == "table", msg_searchdir_type .. t)

		-- actual lists are a bit more complex, needs checking of keys
		local count = 0
		for k, v in pairs(cfg) do
			if type(k) ~= "number" then
				error("non-numeric key found in search_dirs list")
			end
			assert(
				type(v) == "string",
				"non-string value found in search_dirs list")
			count = count + 1
		end
		assert(count > 0, "at least one directory required in search_dir list")

		-- we can't really do any more validation than this portably.
		return cfg
	end,
}



local check_table_keys = function(props)
	local ret = {}
	-- no extra props currently supported,
	-- so just raise error on *any* key.
	for k, v in pairs(props) do
		assert(type(k) == "string", "non-string property name encountered")

		local validate = allowed_keys[k]
		if not validate then
			error("unrecognised reservation property " .. k)
		end
		ret[k] = validate(v)
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


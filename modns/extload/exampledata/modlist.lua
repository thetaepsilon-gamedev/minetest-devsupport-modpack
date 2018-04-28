--[[
We currently don't rely on any kind of filesystem module,
so we have to list out mods that we wish to make visible outside of MT by hand,
as standard lua provides no directory list mechanism.
This example is for unix-like targets;
work hasn't been done on windows, patches welcome.
]]

--[[
The intent of this file is to return a table
mapping known mods to absolute file system paths.
This is used to provide an implementation of mod path look-up to the core code
(see the mp() function and the loader_impl definition in extload/init.lua),
and to provide a list of mods to the reservation manager
(see the function populate_reservations() in reservations.lua)
so that the loader knows
a) which mod name provides a given namespace or component, and
b) the path to that mod so that the lua files can be loaded on demand.

In other words, this script should return a table like the following:
{
	["mymod"] = "/home/user/.minetest/mods/mymod",
	...
}
This script could be adapted locally to do something more sophisticated,
such as load a config file enabling or disabling certain mods,
and require()'ing a filesystem module to do probing of installed mods.
Patches are welcome for this.
]]

local getenv_or_bang = function(var)
	local v = os.getenv(var)
	if v == nil then error("environment variable "..var.." not set") end
	return v
end

mods = getenv_or_bang("MINETEST_MOD_HOME") .. "/"
return {
	["modns"] = mods .. "devsupport-modpack/modns",
	["libmthelpers"] = mods .. "devsupport-modpack/libmthelpers",
	["libmt_node_network"] = mods.."libmt_node_network",
}


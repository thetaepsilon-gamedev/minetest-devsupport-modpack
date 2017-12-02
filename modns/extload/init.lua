-- standalone loader that can be loaded by the lua cli interpreter.
-- to use, set MODNS_PATH to this mod's top directory,
-- OSDIRSEP to the appropriate dir separator string for your OS,
-- LUA_INIT to the full path of this script (so the interpreter runs it automatically),
-- and MODNS_LOADER_DATA to a directory containing modlist.txt,
-- which should have on each line a mod name and it's directory path.

-- the method to look up mod directories varies between OSes,
-- and the user may even want to use an alternate installation path,
-- hence the need to provide a path list.

local getenv_or_bang = function(var)
	local v = os.getenv(var)
	if v == nil then error("environment variable "..var.." not set") end
end

_modpath = getenv_or_bang("MODNS_PATH")
local pathsep = getenv_or_bang("OSDIRSEP")
local datadir = getenv_or_bang("MODNS_LOADER_DATA")



-- standalone loader that can be loaded by the lua cli interpreter.
-- to use, set MODNS_PATH to this mod's top directory,
-- OSDIRSEP to the appropriate dir separator string for your OS,
-- LUA_INIT to the full path of this script (so the interpreter runs it automatically),
-- and MODNS_LOADER_DATA to a directory containing modlist.lua,
-- which will be sourced to return a table mapping mods to paths
-- (with _datadir set to the above env var).

-- the method to look up mod directories varies between OSes,
-- and the user may even want to use an alternate installation path,
-- hence the need to provide a path list.

local getenv_or_bang = function(var)
	local v = os.getenv(var)
	if v == nil then error("environment variable "..var.." not set") end
	return v
end

_common = {}

local sep = getenv_or_bang("OSDIRSEP")
_modpath = getenv_or_bang("MODNS_PATH")..sep
local datadir = getenv_or_bang("MODNS_LOADER_DATA")
datadir = datadir..sep

_datadir = datadir
local modmap = dofile(datadir.."modlist.lua")
_datadir = nil
if type(modmap) ~= "table" then error("modlist script expected to return a table") end
local modlist = {}
for k, _ in pairs(modmap) do table.insert(modlist, k) end

-- mod path lookup function: just looks it up in the table.
local mp = function(modname) return modmap[modname] end

local m_loaddefs = dofile(_modpath.."loader-defaults.lua")
local d = m_loaddefs.mk_debugger(print, "[loader] ")
-- quieten the debugger so as to not flood stdout
local filterlist = dofile(_modpath.."log-filter-list.lua")
if not os.getenv("MODNS_VERBOSE") then d = m_loaddefs.mk_debug_filter(d, filterlist) end

local m_reservations = dofile(_modpath.."reservations.lua")
-- reservation manager ioimpl
-- use the example one in reservations.lua
local revio = m_reservations.mk_extio(modmap, sep)
-- load mod namespace reservations
local reservations = m_reservations.new({debugger=d})
m_reservations.populate(reservations, modlist, revio)



-- impl objects for the main loader.
local modcache = {}
local modfinder = { get=function(self, modname) return mp(modname) end }
local loader_impl = {
	fileloader = m_loaddefs.mk_fileloader(),
	filetester = m_loaddefs.mk_filetester(),
	-- only load portable components outside of MT.
	targetlist = { "lib" },
	modpathfinder = modfinder,
	reservations = reservations,
	dirpathsep = sep,
}
local opts = { debugger = d }

local m_loader = dofile(_modpath.."loader.lua")
local loader = m_loader.new(loader_impl, modcache, opts)

modns = dofile(_modpath.."construct_interface.lua")(loader)
mtrequire = modns.get

_modpath = nil
_common = nil


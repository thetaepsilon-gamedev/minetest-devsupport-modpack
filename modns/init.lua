if minetest.global_exists("modns") then error("modns should not already be defined") end
local registered = {}

local modname = minetest.get_current_modname()
local dirsep = "/"
local modpath = minetest.get_modpath(modname)..dirsep

local debugmode = false



-- I'm thinking of putting this in it's own mod.
local log_trace = "trace"
local log_error = "error"
local log_warning = "warning"
local logaction = function(severity, msg)
	print("[modns] ["..severity.."] "..msg)
end
-- simplified form of the logging system found in libmtlog.
local debugger = function(ev)
	local args = ""
	if ev.args then
		for k, v in pairs(ev.args) do
			args = args.." "..k.."="..string.format("%q", v)
		end
	end
	logaction(log_trace, ev.n..args)
end



_common = {}
_modpath = modpath
local reservations = dofile(modpath.."reservations.lua")
local loader_defaults = dofile(modpath.."loader-defaults.lua")
local modpathioimpl, modfinder = dofile(modpath.."impl-mt.lua")
local loaderlib = dofile(modpath.."loader.lua")
_modpath = nil

local debugger = loader_defaults.mk_debugger(print, "[modns] ")
local filterlist = dofile(modpath.."log-filter-list.lua")
if not debugmode then debugger = loader_defaults.mk_debug_filter(debugger, filterlist) end

local prefixes = reservations.new({debugger=debugger})
reservations.populate(prefixes, minetest.get_modnames(), modpathioimpl)

local mt_target_list = {
	"lib",
	"natives/minetest",
}
local loader_impl = {
	fileloader = loader_defaults.mk_fileloader(),
	reservations = prefixes,
	filetester = loader_defaults.mk_filetester(),
	modpathfinder = modfinder,
	dirpathsep = dirsep,
	targetlist = mt_target_list,
}
local loader = loaderlib.new(loader_impl, registered, {debugger=debugger})

_modpath = modpath
modns = dofile(modpath.."construct_interface.lua")(loader)
-- modns.register() is only really intended for use inside MT.
modns.register = function(...)
	return loader:register(...)
end
_modpath = nil
_common = nil
mtrequire = modns.get

minetest.log("info", "modns interface now exported")

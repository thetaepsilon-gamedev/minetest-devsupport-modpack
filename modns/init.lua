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

local deepcopy = dofile(modpath.."deepcopy.lua")

local tvisit = dofile(modpath.."tvisit.lua")

local checkexists = function(path)
	return (registered[path] ~= nil) or (compat[path] ~= nil)
end

local handledeprecated = function(path, isdeprecated)
	if isdeprecated then
		deprecated[path] = true
	end
end



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



-- check a path's validity and return the mod name that reserves it, if any.
-- returns the same as reservations:locate(),
-- namely found mod if any, closest prefix length, and parse result.
-- TODO: enable this when issues with automatic sub-component traversal are fixed.
local checkpath = function(path)
	if type(path) ~= "string" then error("component path must be a string") end
	return prefixes:locate(path)
end



-- internal single-component registration.
local register = function(path, component, isdeprecated, invoker)
	checkpath(path)
	if checkexists(path) then error("duplicate component registration for "..path.." by "..invoker) end
	registered[path] = component
	handledeprecated(path, isdeprecated)
end



function mtrequire(path)
	checkpath(path)
	local result

	local obj = loader:get(path)
	if obj then
		result = deepcopy(obj)
	else
		error("component "..path.." does not exist")
	end

	return result
end


_modpath = modpath
local nsauto = (dofile(modpath.."nsauto.lua"))(loader)
_modpath = nil

modns = {
	get = mtrequire,
	mk_parent_ns = nsauto.ns,
	mk_parent_ns_noauto = nsauto.ns_noauto,
}

minetest.log("info", "modns interface now exported")

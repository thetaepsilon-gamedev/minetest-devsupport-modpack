if minetest.global_exists("modns") then error("modns should not already be defined") end
local registered = {}
local compat = {}
local deprecated = {}

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

-- "require" equivalent for MT mods, performs lookup and retreival.
-- lint note: intentional global assigmnent
function mtrequire(path)
	checkpath(path)
	local invoker = tostring(minetest.get_current_modname())
	local result
	local compat_alias = compat[path]

	-- woo, nested functions!
	local logaccess = function(msg)
		logaction(log_trace, "component "..path.." requested by "..invoker..": "..msg)
	end

	if deprecated[path] then
		logaction(log_warning, "component "..path.." has been marked deprecated!")
	end

	if compat_alias then
		return mtrequire(compat_alias)
	end

	local obj = loader:get(path)
	if obj then
		result = deepcopy(obj)
	else
		logaction(log_error, "mod "..invoker.." tried to retrieve non-existant component "..path)
		error("component "..path.." does not exist")
	end

	return result
end



-- helpers to create a parent namespace which is simply a table housing sub-namespaces.
local dname = "mk_parent_ns_noauto() "
local mk_parent_ns_noauto = function(list, base, sep)
	local result = {}
	for _, sub in ipairs(list) do
		local subpath = base..sep..sub
		result[sub] = mtrequire(subpath)
	end
	return result
end

local dname = "mk_parent_ns() "
local mk_parent_ns = function(list)
	local inflight, ptype = loader:get_current_inflight()
	if not inflight then error(dname.."must be invoked via dynamic loading of another file") end
	local sep = ptype.pathsep
	if not sep then error(dname.."auto path deduction failure: path type "..ptype.label.." doesn't support separator concatenation") end
	return mk_parent_ns_noauto(list, inflight, sep)
end




modns = {
	register = function(path, component, isdeprecated, opts)
		if not opts then opts = {} end
		local sep = opts.pathsep
		if not sep then
			sep = "."
		else
			if type(sep) ~= "string" then error("path separator not a string!") end
		end

		local owner, prefixlength, parsed = checkpath(path)
		if checkexists(path) then error("duplicate component registration for "..path) end
		local comptype = type(component)
		local invoker = tostring(minetest.get_current_modname())
		if owner ~= nil and owner ~= invoker then
			error("mod "..invoker.." tried to register "..path.." but that path is reserved by "..owner)
		end
		if comptype == "table" then
			register(path, component, isdeprecated, invoker)
			logaction(log_trace, "mod object registered for component "..path.." by mod "..invoker)
		else
			logaction(log_error, "mod "..invoker.." tried to register an unknown object of type "..comptype)
			error("modns.register(): unrecognised object type "..comptype)
		end
		handledeprecated(path, isdeprecated)
	end,
	register_compat_alias = function(path, totarget, isdeprecated)
		local aliaserror = function(msg)
			error("compatability alias from "..path.." to real target "..totarget.." "..msg)
		end
		checkpath(path)
		checkpath(totarget)
		if checkexists(path) then aliaserror("conflicts with an existing component") end
		if not checkexists(totarget) then aliaserror("does not reference an existing component!") end
		local invoker = tostring(minetest.get_current_modname())
		logaction(log_trace, invoker.." registered a compatability alias making "..totarget.." appear as "..path)
		compat[path] = totarget
		handledeprecated(path, isdeprecated)
	end,
	get = mtrequire,
	check = function(path)
		checkpath(path)
		return checkexists(path)
	end,
	deepcopy = deepcopy,
	mk_parent_ns = mk_parent_ns,
	mk_parent_ns_noauto = mk_parent_ns_noauto,
}

minetest.log("info", "modns interface now exported")

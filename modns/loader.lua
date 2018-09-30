-- dynamic loader for registered components
-- given a reservation object (see reservations.lua),
-- a modpath lookup implementation,
-- a "does this file exist?" implementation,
-- a list of platform target directores*,
-- a script loader implementation**,
-- and a loaded component cache implementation,
-- this object will take care of loading components as needed.
-- it supports those component scripts requesting others in turn
-- (detected cycles cause a hard error).
-- for the interfaces needed of these impl dependencies,
-- scroll down to the "Documentation for dependencies" comment block.

--[[
* Where possible, it is encouraged that mods split apart portable code and code which accesses MT apis.
For portable code for a component com.foo, where the mod to look up the path is known,
the file could be in any of the following:
modname/lib/com.foo.lua
modname/lib/com/foo.lua
modname/lib/com/foo/init.lua

However, minetest "natives" would be searched like so:
modname/natives/minetest/com.foo.lua
...
The reason for this split is so that components that would do something different in MT vs an external test script can be separate.
E.g. some components that use the MT api or other MT-specific globals would be in natives,
but "pure" components and algorithms can go in lib.
The first found match is always the winner;
the target directory order for this elsewhere in this mod prefers portable code first.

** This is used instead of directly calling dofile() to make using a testing harness somewhat easier.
]]



local paths = dofile(_modpath.."paths.lua")
local deepcopy = dofile(_modpath.."deepcopy.lua")
local lift_revdata_to_modname = _common.lift_revdata_to_modname
local search_dirs = dofile(_modpath.."search_dirs.lua")
local calculate_relative_paths = search_dirs.relative_to_mod_d
local interface = {}

local evprefix = "modns.loader."
local entirelen = function(t) return t, #t end



-- object allocation/initialisation steps
local init_loadstate = function(self)
	self.loadstate = {}
	self.loadstate.inflight = {}
end

local allocself = function()
	local self = {}
	init_loadstate(self)
	return self
end



-- find the mod diretory that should own a given path string.
local ev_modfail = evprefix.."mod_lookup_failed"
local ev_modfound = evprefix.."owning_mod_located"
local ev_modnexist = evprefix.."mod_path_failed"
local ev_modpathfound = evprefix.."mod_path_found"
local get_modpath = function(self, pathresult, original)
	local modpathfinder = self.modpathfinder
	local reservations = self.reservations
	local debugger = self.debugger

	local result = pathresult
	local path = result.tokens

	local revdata, closest = reservations:locateparsed(path)
	-- convert the closest match prefix back to a string for tracing/error messages
	local longest = result.type.tostring(path, closest)
	if revdata == nil then
		debugger({n=ev_modfail, args={path=original, closest=longest}})
		return nil
	end
	local props = revdata.properties
	assert(props ~= nil)
	local modname = lift_revdata_to_modname(revdata)
	debugger({n=ev_modfound, args={path=original, modname=modname, parent_ns=longest}})

	-- this is basically equivalent to minetest.get_modpath(modname),
	-- but is wrapped up so that it can be mimicked outside of MT.
	local modpath = modpathfinder:get(modname)
	local ev
	if modpath == nil then
		ev = {n=ev_modnexist, args={modname=modname}}
	else
		ev = {n=ev_modpathfound, args={modname=modname, modpath=modpath}}
	end
	debugger(ev)

	-- save the part of the path that is "inside" the reservation.
	-- this is used in the case that the mod specified an alias path.
	local tail, err = paths.tail(path, closest)
	if tail == nil then error("WTF condition: tail path was nil!? "..err) end

	return {
		modbasedir = modpath,
		modname = modname,
		revproperties = props,
		path_suffix = tail,
	}
end



-- try to locate the file that should be loaded for a given component.
local ev_testpath = evprefix.."attempt_load_component"
local ev_located = evprefix.."component_file_found"
local ev_notfound = evprefix.."component_file_not_found"
local find_component_file = function(self, pathresult, original)
	local debugger = self.debugger
	local filetester = self.filetester
	local dirsep = self.dirsep

	-- work out relative paths, and which mod directory should contain them.
	local ownerdata = get_modpath(self, pathresult, original)
	if ownerdata == nil then return nil, "no mod claims that namespace" end

	local props = ownerdata.revproperties
	assert(props ~= nil)
	local tail = ownerdata.path_suffix
	assert(tail ~= nil)
	local relatives = calculate_relative_paths(
		self.targetlist,
		dirsep,
		pathresult.tokens,
		props,
		tail)

	local attempts = 0
	local modpath_base = ownerdata.modbasedir
	for index, relpath in ipairs(relatives) do
		attempts = attempts + 1
		-- construct the full path and ask if it exists.
		local fullpath = modpath_base..dirsep..relpath
		debugger({n=ev_testpath, args={component=original, fullpath=fullpath, attempt=index}})
		if filetester:exists(fullpath) then
			debugger({n=ev_located, args={component=original, at=fullpath}})
			return fullpath
		end
	end
	debugger({n=ev_notfound, args={component=original, attempts=attempts}})
	return nil, "mod " .. ownerdata.modname ..
		" registered that namespace but did not have that component"
end



-- loads a component from file when it is not already in the cache in getcomponent() below.
local load_component_from_file = function(self, pathresult, original)
	local filepath, reason = find_component_file(self, pathresult, original)
	if not reason then reason = "" end
	if filepath == nil then error("unable to locate source file for component "..original..": "..reason) end
	return self.fileloader:load(filepath)
end



-- actual component retrieval.
-- takes the path string to use.
local ev_cachehit = evprefix.."cache_hit"
local ev_cachemiss = evprefix.."cache_miss"
local getcomponent_nocopy = function(self, pathstring)
	--print("# path", pathstring)
	--print("# inflight", self.loadstate.current)

	-- objects are only added to the array when completely loaded.
	-- however, if two files circularly depend on each other via mtrequire(),
	-- an infinite recursion will occur.
	-- prevent this by marking the currently loading component so that re-entrancy is detected.
	-- circular references result in an error.
	local loadstate = self.loadstate
	local caches = self.cache
	local debugger = self.debugger

	-- first check that we're being asked to load something valid.
	-- note: this throws on parse failure
	local pathresult = paths.parse(pathstring)
	-- re-serialise the string to get the normalised path.
	local original = pathresult.type.tostring(entirelen(pathresult.tokens))
	pathstring = original

	-- if we're already in-flight loading this same component,
	-- something somewhere is causing a dependency cycle.
	if loadstate.inflight[pathstring] then
		-- TODO: print out the chain of components causing the cycle
		error("dependency cycle!")
	end

	-- check whether we have the component already cached.
	-- if so, return that directly.
	local cached = caches[pathstring]
	local ev_args = { component=pathstring }
	local hit = cached ~= nil
	local evn = hit and ev_cachehit or ev_cachemiss
	debugger({n=evn, args=ev_args})
	if hit then return cached end

	-- else we need to go out to a file.
	-- mark this path as in-flight to catch circular errors.
	loadstate.inflight[pathstring] = true
	-- we may be currently loading another component up a dependency chain,
	-- so we must save any previous current loadstate to avoid clobbering.
	local oc = loadstate.current
	local oct = loadstate.current_type
	loadstate.current = pathstring
	loadstate.current_type = pathresult.type

	-- catch any errors so we can unwind the inflight state first.
	local success, result = pcall(load_component_from_file, self, pathresult, original)

	-- clean up at the end.
	loadstate.inflight[pathstring] = nil
	loadstate.current = oc
	loadstate.current_type = oct

	-- throw any error if not success;
	-- else insert object into cache and return component to caller
	if success then
		caches[pathstring] = result
		return result
	else
		--print("# re-throwing error now, offending component was "..pathstring)
		error(result)
	end
end



-- we make a copy of a component object each time it is retrieved.
-- historically this was to prevent problems due to mods clobbering component tables.
local getcomponent = function(...)
	return deepcopy(getcomponent_nocopy(...))
end



-- get the currently-being-loaded mod, if any.
-- used by calls to the modns object while inside another file;
-- see mk_parent_ns() in init.lua.
local get_current_inflight = function(self)
	return self.loadstate.current, self.loadstate.current_type
end

-- explicit registration mechanism (see relevant file)
local registerself = dofile(_modpath.."loader_explicit_register.lua")


--[[
Documentation for dependencies and their interfaces needed in the constructor's impl table

impl.fileloader: used to load script files from an absolute path.
	:load(filename)
		essentially dofile(), returns the result of executing the given file name.

impl.filetester: used to determine if a file exists -
	search moves onto other possibilities if not.
	:exists(filename)
		returns true if filename can be loaded by fileloader, false otherwise.

impl.reservations: expected to be an instance of the files created in reservations.lua.
	used to check which mod should contain the file for a given component.

impl.modpathfinder: gets the full directory path for a given mod.
	:get(modname)	returns full path or nil if the given mod didn't exist.

impl.dirpathsep: a string which must contain the character the current OS uses for directory separators in file paths.

Other dependencies and optional components:
* The cache argument should be a table where component paths are mapped to objects.
	Other parts of modns allow explicit registration,
	so this table is exposed to let that happen.
* opts table:
	+ "debugger" is a debug tracing function in the style of libmtlog.
	It is expected to take a single argument when called,
	a table with the following keys:
		+ "n", an event name, and
		+ "args", a table of key-value pairs containing extra data about the event.
	See loader-defaults.lua for an example implementation.

Again, the reason for all this is to allow mock implementations during testing.
The loader is a reasonably complex object, so being able to see into it is imperative.
]]
local check_impl_deps = function(impl, label, signatures)
	if type(impl) ~= "table" then error("expected table for: "..label) end
	for name, signature in pairs(signatures) do
		local dep = impl[name]
		if type(dep) ~= "table" then error("expected impl dependency to be a table: "..name) end
		for index, method in pairs(signature) do
			if type(dep[method]) ~= "function" then
				error("expected dependency to have method: "..method.." in "..name)
			end
		end
	end
	return impl
end
local signatures = {
	fileloader = { "load" },
	filetester = { "exists" },
	-- FIXME: ask reservations.lua to declare some kind of expected interface here
	reservations = {},
	modpathfinder = { "get" },
	targetlist = {},
}
local desc = "loader implementation dependencies"
local check_impl = function(impl)
	check_impl_deps(impl, desc, signatures)
	if type(impl.dirpathsep) ~= "string" then
		error(desc.." needed to contain a dirpathsep string")
	end
	return impl
end

local construct_inner = function(impl, cache, opts)
	local self = allocself()
	local debugger = opts.debugger or function() end
	self.cache = cache
	self.debugger = debugger
	self.dirsep = impl.dirpathsep
	-- link to module for use by loader:register(),
	-- see loader_explicit_register.lua
	self.paths = paths

	for objname, _ in pairs(signatures) do
		self[objname] = impl[objname]
	end
	self.get = getcomponent
	self.get_current_inflight = get_current_inflight
	self.register = registerself
	return self
end
local construct = function(impl, cache, opts)
	impl = check_impl(impl)
	if type(cache) ~= "table" then error("component cache expected to be a table") end
	local wasnil = (opts == nil)
	if not wasnil and type(opts) ~= "table" then
		error("options expected to be a table or not set")
	end
	if wasnil then opts = {} end
	return construct_inner(impl, cache, opts)
end
interface.new = construct



return interface

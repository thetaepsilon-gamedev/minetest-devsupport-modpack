local interface = {}

local paths = dofile(_modpath.."paths.lua")

-- reservation manager.
-- given a list of all mods and a IO implementation,
-- this object reads in a list of paths from their reservation configurations.
-- the IO impl's open method is passed a modname and a (top-level only) filename.
-- it must return a file object that at least supports the lua io file:lines() iterator operation,
-- or nil if the file name does not exist.

-- when reserving a hierachial path (such as java-style com.foo.bar...),
-- the fully-qualified path gets reserved by the owning mod,
-- but the paths "above" it (e.g. com, com.foo) become shared.
-- other mods can still reserve sibling paths.
-- but cannot reserve an existing reserved path or it's descendants
-- (e.g. other mods can still reserve com.foo.anotherbar,
-- but not com.foo.bar again or com.foo.bar.sub).
-- similarly, a shared path or it's parents (e.g. the above com.foo)
-- also cannot be exclusively reserved.

-- In the internal tables, shared paths and reservations are two different table structures.
-- sub-paths are members of a shared path's subentries table.
--[[
toplevel = {
	com = {
		type = shared,
		subentries = {
			foo = {
				type = shared,
				subentries = {
					...
				},
			},
			bar =  {
				type = reservation,
				modname = "mymod",
				cfg = { ... },
			}
		},
	},
}
]]



-- internal tree elements as discussed above.
local shared = {}
local reservation = {}
local mk_shared = function() return { type = shared, subentries = {} } end
local mk_reservation = function(owner, props)
	return {
		type = reservation,
		data = {
			owner = owner,
			properties = props,
		},
	}
end

-- this is needed due to historical reasons, for refactoring purposes.
local lift_revdata_to_modname = function(revdata)
	local tr = type(revdata)
	assert(tr == "table", "revdata was not a table!? "..tr)
	local n = revdata.owner
	local tn = type(n)
	assert(tn == "string", "owner was not a string!? "..tn)
	return n
end
_common.lift_revdata_to_modname = lift_revdata_to_modname



-- takes the top-level table as described above and an array of path components.
-- pathtostring depends on the path type and is used to turn the path back into a string for error messages;
-- it is passed a component array and a length, and returns the concatenated path.
local dname = "try_reserve() "
local try_reserve = function(toplevel, path, pathtostring, modname)
	assert(modname, "why is this even nil")
	if type(toplevel) ~= "table" then error(dname.."top level was not a table") end
	local depth = #path
	if depth < 1 then error(dname.."was passed a zero-sized path") end

	local index = 1
	local current = toplevel
	local isexact = function() return (index == depth) end

	while true do
		local key = path[index]
		local sub = current[key]
		-- if we have not yet reached further into the path,
		-- check that either a shared path exists or does not.
		-- if it is reserved, trigger an error.
		-- otherwise, create the sub-entry as needed and recurse into it.
		local t = sub and sub.type or nil
		local errpath = pathtostring(path, index)
		if not isexact() then
			if t == shared then
				-- recurse into this sub-path and continue.
				current = sub.subentries
			elseif t == nil then
				-- create new shared path, save it, then continue
				local new = mk_shared()
				current[key] = new
				current = new.subentries
			else
				-- probably a reservation.
				assert(t == reservation)
				error(modname.."tried to reserve a taken prefix ("..errpath.." taken by "..sub.owner..")")
			end
		else
			-- if this is an exact match, check we're not reserving a shared path.
			if t == shared then
				error(modname.."tried to reserve an in-use shared prefix "..errpath)
			elseif t == nil then
				-- path not taken, grant it to this mod
				current[key] = mk_reservation(modname)
			else
				assert(t == reservation)
				error(modname.."tried to reserve a taken namespace "..errpath.." reserved by "..sub.owner)
			end
			-- exact path reached match so we can't proceed any further anyway
			break
		end

		index = index + 1
	end
end
interface.try_reserve = try_reserve



-- look up the mod that should contain a given path.
-- tries to find the first mod that has reserved the longest prefix of the given path.
-- returns the mod name or nil for not found.
-- also returns a second argument, number of matched path components:
-- on success, the number of components matched in path;
-- on failure, the number of components that did match before one component didn't.
local locate_mod = function(toplevel, path)
	local dname = "locate_mod() "
	local depth = #path
	if depth < 1 then error(dname.."was passed a zero-sized path") end

	local index = 1
	local current = toplevel
	local isexact = function() return (index == depth) end

	local result = nil
	while true do
		local key = path[index]
		local sub = current[key]
		local t = sub and sub.type or nil
		-- encountered a reservation - this mod should own everything under it
		if t == reservation then
			return sub.data, index
		elseif t == nil then
			-- reached "end of the thread" in the tree, we can't continue.
			return nil, index-1
		end
		assert(t == shared)

		-- at this point, we are at a shared path.
		-- if this is the end of the given path string, then return failure.
		if index == depth then return nil, index end

		-- note that if we reach here and no error but not yet found,
		-- we found a sub-level to go into.
		current = sub.subentries
		index = index + 1
	end
end
interface.locate_mod = locate_mod



local locatemodself = function(self, pathstr)
	local result = paths.parse(pathstr, "mod lookup path")
	return locate_mod(self.entries, result.tokens)
end
-- same but allow the caller to parse it already
local locatemodparsed = function(self, path)
	return locate_mod(self.entries, path)
end

local reserveself = function(self, pathstring, modname)
	local label = "namespace reservation [in mod "..modname.."]"
	-- this throws on a bad component path so no need to nil check.
	-- mods really should make sure these are valid and correct.
	local result = paths.parse(pathstring, label)
	-- try to reserve this path or fail
	try_reserve(self.entries, result.tokens, result.type.tostring, modname)
	self.debugger({n="modns.reservation", args={mod=modname, path=pathstring}})
	return true
end

local construct = function(opts)
	if not opts then opts = {} end
	local debugger = opts.debugger
	if not debugger then debugger = function() end end
	
	local self = {}
	local entries = {}
	self.entries = entries
	self.locate = locatemodself
	self.locateparsed = locatemodparsed
	self.reserve = reserveself
	self.debugger = debugger

	return self
end
interface.new = construct

local populate_reservations = function(reservations, modlist, ioimpl)
	for index, modname in ipairs(modlist) do
		local file = ioimpl:open(modname, "reserved-namespaces.txt")
		if file ~= nil then for entry in file:lines() do
			reservations:reserve(entry, modname)
		end end
	end
end
interface.populate = populate_reservations



-- an example ioimpl for the above which attempts loads from a table of directories.
-- the lua built-in io operations are used to do this.
-- this should not be used within minetest itself;
-- see init.lua for a version which uses minetest get_modpath() operations to do the same.
-- in particular, this on it's own does no auto-detection of mods and modpack directories,
-- as unfortunately the common denominator of lua lacks the facility to list directories.
local extio_try_load = function(self, modname, filename)
	local sep = self.dirsep
	local entry = self.paths[modname]
	if entry then return io.open(entry..sep..filename, "r") end
end
local mk_extio = function(paths, osdirsep)
	local self = { paths=paths, dirsep=osdirsep}
	self.open = extio_try_load
	return self
end
interface.mk_extio = mk_extio



return interface

--[[
This file contains the code to determine relative filesystem paths inside a mod,
for a given requested component path.
The end result is a list of paths that point to candidate lua scripts to load.
These scripts are tested in order to see if they exist,
and the first one found is run to load the component
(see find_component_file() in loader.lua).
]]

local sf = dofile(_modpath.."safe_filenames.lua")
local encode_safe_filename = sf.encode_safe_filename
local encode_safe_path_component = sf.encode_safe_path_component

local filter = function(table, f)
	local ret = {}
	for key, value in pairs(table) do
		ret[key] = f(value)
	end
	return ret
end

local initfile = "init"
local ext = ".lua"



local interface = {}
-- handle the shorter paths inside mod writer-supplied alias directories.
-- say the mod writer only wanted to create e.g.
-- short_mod_dir/foomodule/... (leading part of namespace chopped)
local paths_relative_to_alias_d = function(dirsep, pathtail)
	-- note that the suffix tail has the potential to be zero elements here,
	-- so in that case we skip the "all-in-one" and "just filename" paths,
	-- otherwise we'd end up with subdir/.lua which would
	-- a) look strange and b) cause problems on unix and windows alike if it existed.
	local ret = {}
	local safepath = filter(pathtail, encode_safe_path_component)
	-- myaliasdir/sub/foo
	-- may become either sub/foo.lua or sub/foo/init.lua
	local basepath = table.concat(safepath, dirsep)

	local alias_aio = nil
	local zero = (#pathtail == 0)
	if not zero then
		-- myaliasdir/sub.foo.lua
		alias_aio = encode_safe_filename(pathtail) .. ext
		table.insert(ret, alias_aio)

		-- myaliasdir/sub/foo.lua
		-- note that if #pathtail = 1, would just be /sub.lua,
		-- which would end up the same as the all-in-one path.
		-- hence, skip this if turns out to be the same.
		local alias_justname = basepath .. ext
		if alias_justname ~= alias_aio then
			table.insert(ret, alias_justname)
		end
	end

	-- myaliasdir/sub/foo/init.lua
	-- or, if tail is zero size, just myaliasdir/init.lua
	basepath = (basepath ~= "") and (basepath .. "/") or ""
	table.insert(ret, basepath .. initfile .. ext)

	return ret
end
interface.relative_to_alias_d = paths_relative_to_alias_d



-- constructs the list of modpath-relative files to attempt loading.
local paths_relative_to_mod_d =
	function(
		targetlist,
		dirsep,
		path,
		extraprops,
		pathtail
	)

	assert(type(extraprops) == "table")
	assert(type(pathtail) == "table")
	local result = {}
	local ipos = 0
	local add = function(v)
		ipos = ipos + 1
		result[ipos] = v
	end
	-- possible paths for a component,
	-- given the path "com.github.user.myawesomemod.foomodule"
	-- com.github.user.myawesomemod.foomodule.lua
	local path_allinone = encode_safe_filename(path) .. ext

	local relatives = {}
	local safepath = filter(path, encode_safe_path_component)
	-- com/github/user/myawesomemod/foomodule
	local basepath = table.concat(safepath, dirsep)
	-- com/github/user/myawesomemod/foomodule.lua
	local path_justname = basepath .. ext
	-- com/github/user/myawesomemod/foomodule/init.lua
	local path_initfile = basepath .. dirsep .. initfile .. ext

	local search_dirs = extraprops.search_dirs
	local alias_relatives
	if search_dirs then
		alias_relatives = paths_relative_to_alias_d(dirsep, pathtail)
	end

	-- there can exist both portable and native lookup directories for each candidate.
	for _, target in ipairs(targetlist) do
		target = target..dirsep

		-- alias directories take higher precedence than default paths.
		if search_dirs then for i, aliasdir in ipairs(search_dirs) do
			-- yes, I'm shadowing the outer variable on purpose
			local target = target .. aliasdir .. dirsep
			for j, candidate in ipairs(alias_relatives) do
				add(target .. candidate)
			end
		end end

		add(target .. path_allinone)
		add(target .. path_justname)
		add(target .. path_initfile)
	end

	return result
end
interface.relative_to_mod_d = paths_relative_to_mod_d

return interface


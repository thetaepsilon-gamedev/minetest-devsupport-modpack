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



local interface = {}
-- handle the shorter paths inside mod writer-supplied alias directories.
-- say the mod writer only wanted to create e.g.
-- short_mod_dir/foomodule/... (leading part of namespace chopped)
local paths_relative_to_alias_d = function(dirsep, pathtail)
	error("not implemented")
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
	local initfile = "init"
	local ext = ".lua"
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

	-- there can exist both portable and native lookup directories for each candidate.
	for _, target in ipairs(targetlist) do
		target = target..dirsep
		table.insert(result, target .. path_allinone)
		table.insert(result, target .. path_justname)
		table.insert(result, target .. path_initfile)
	end

	return result
end
interface.relative_to_mod_d = paths_relative_to_mod_d

return interface


--[[
A subloader represents an abstraction of accessing sub-components of a given path.
You can pass it a list of sub-path segments
(e.g. {"some", "child"} as opposed to "some.child")
or a single segment string to load a component relative to a base path;
this base path is baked into the subloader at construction time.
]]




-- concat a path passed as a table of components,
-- or accept just a string to act as a list of length one.
-- data SubPath = Single Segment | Deep [Segment]
-- concat_path :: SubPath -> PathSep -> SubPathStr
local msg_concat = "path concatenation: expected a string or table, got "
local concat_path = function(path, sep)
	local t = type(path)
	if t == "string" then
		return path
	elseif t == "table" then
		return table.concat(path, sep)
	else
		error(msg_concat .. t)
	end
end





local checkstr = function(v) assert(type(v) == "string") end

-- it's closures all the way dooooooooown
local attach_loader = function(loader)
	local create_subloader = function(base, sep)
		checkstr(base)
		checkstr(sep)
		base = base .. sep

		return function(subpath)
			local subs = concat_path(subpath, sep)
			local fullpath = base..subs
			return loader:get(fullpath)
		end
	end
	return create_subloader
end



return attach_loader


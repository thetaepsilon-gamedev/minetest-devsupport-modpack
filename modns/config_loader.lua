--[[
Load a lua table from an already opened config source file.
This file must be a lua script which returns a table object.
The file will be loaded and executed in a contained environment,
where *no globals* are present whatsoever, not even normal lua builtins.
Furthermore, any attempts to read or set a global by the script are immediately fatal.
The script is intended only to contain the table structure itself.
]]

local bmsg = " lua binary code is not permitted in config files."
local create_file_load_iterator = function(file, label)
	local line = file:lines()
	local first = true
	return function()
		local l = line()
		if l then
			-- goddammnit lua 5.1
			if l:byte(1) == 27 then
				error(label..bmsg)
			end
			-- have to re-add line endings because :lines() strips them.
			-- lua single-line comments make the language line break sensitive
			return l.."\n"
		end
	end
end



-- meta event functions for confined environment
local cname = "load_config_file(): "
local err_get = cname .. "confined script attempted to access key in global environment: "
local err_set = cname .. "confined script attempted to set global key "
local desc = function(v)
	return "[" .. type(v) .. "] " .. ("%q"):format(v)
end

local metaget = function(table, key)
	error(err_get .. desc(key))
end
local metaset = function(table, key, value)
	error(err_set .. desc(key) .. " to value " .. desc(value))
end

local create_confined_environment = function()
	local env = {}
	local meta = {
		__index = metaget,
		__newindex = metaset,
	}
	setmetatable(env, meta)
	return env
end



-- lua's inbuilt load() is sensitive to the difference between no 2nd argument and nil
-- (the latter causes it to throw a type error).
-- create a wrapper around it to avoid this edge case
local loadl = function(loadfunc, label)
	if label == nil then
		return load(loadfunc)
	else
		return load(loadfunc, label)
	end
end



local n = "load_config_file():"
local load_config_file = function(file, label)
	local loader = create_file_load_iterator(file, n)

	local chunk, err = loadl(loader, label)
	if not chunk then
		error("parsing error occured while loading config file: "..err)
	end

	setfenv(chunk, create_confined_environment())
	local ok, r = pcall(chunk)
	if not ok then
		error("config file exec raised an exception: "..tostring(r))
	end

	local t = type(r)
	if t ~= "table" then
		error("config file script did not return a table, got "..t)
	end

	return r
end

return load_config_file


local interface = {}

-- default implementations of dependencies of the loader.
-- see init.lua for the mod finder wrapper which uses the MT API.

-- file loader: just wraps dofile()
local d = dofile
local mk_fileloader = function()
	return {
		load = function(self, f) return dofile(f) end,
	}
end
interface.mk_fileloader = mk_fileloader

-- file checker: tries to open a file in read-only mode to determine it's existance.
-- utilises the io functions which work in both the lua cli interpreter and MT.
local exists = function(self, filename)
	local found = false
	local f = io.open(filename, "r")
	if f then f:close() found = true end
	return found
end
local mk_filetester = function()
	return {
		exists = exists,
	}
end
interface.mk_filetester = mk_filetester

-- default debugger implementation.
-- takes a printer argument to print the serialised events with.
local flattenstr = function(v)
	if type(v) == "string" then
		return string.format("%q", v)
	else
		return tostring(v)
	end
end
local dumptable = function(t)
	local result = ""
	for k, v in pairs(t) do result = result.." "..k.."="..flattenstr(v) end
	return result
end
local mk_debugger = function(print, prefix)
	return function(ev)
		print(prefix..ev.n..dumptable(ev.args or {}))
	end
end
interface.mk_debugger = mk_debugger

-- debug filter:
-- blocks event names from an array, allows others.
interface.mk_debug_filter = function(lowerfunc, blocked)
	return function(ev)
		if not blocked[ev.n] then return lowerfunc(ev) end
	end
end

return interface

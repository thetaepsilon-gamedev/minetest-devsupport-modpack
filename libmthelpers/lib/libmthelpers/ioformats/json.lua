--[[
Stuff to handle writing out JSON for getting around some of MT's annoyances;
See the comments below for rationale.
]]
local i = {}





-- a primitive, recursive printer of json that utilises some base function for non-tables.
-- but descends into tables recursively itself and prints the necessary elements.
-- this routine arose out of an annoyance with minetest.write_json()
-- producing JSON null for empty tables.
-- if an error occurs, the data written to the sink should be considered incomplete,
-- so it is advised (if writing directly to file) to use rename-after-save;
-- this can be achieved in MT by using a string sink (see below),
-- then using minetest.safe_file_write().

-- this reimplementation of just the table recursion part allows a degree of code reuse;
-- minetest.write_json can be left to handle things like string escape sequences.
-- in theory, an alternative, portable implementation of minetest.write_json
-- would allow this module to become a free-standing JSON serialisation module.
local value_type = {
	string = true,
	number = true,
	boolean = true,
	["nil"] = true,
}
local msg_badtype = "JSON serialisation cannot handle values of type "
-- weee, mutually recursive calls
local json_object
local json_array

local recursive_json = function(opts, json_write, sink, v)
	local t = type(v)
	if value_type[t] then
		return json_write(opts.base, sink, v)
	end

	if t ~= "table" then
		error(msg_badtype..t)
	end
	-- so at this point we know we have a table.
	-- JSON only supports string-keyed objects or arrays,
	-- so here we need to figure out which form to use.

	local arraylike = (v[0] ~= nil)
	local f = arraylike and json_array or json_object
	return f(opts, json_write, sink, v)
end
i.recursive_json = recursive_json

local msg_badkey = "Table key type not supported by object or array: "
local msg_mixed = "Table keys must be either strings or numbers, " ..
		"mixing is not supported."





-- check used in the object iterator below
local write_string_key = function(opts, json_write, sink, v)
	local t = type(v)
	if t == "number" then error(msg_mixed) end
	if t ~= "string" then error(msg_badkey .. t) end
	json_write(opts.base, sink, v)
end





-- write json from the values of a iterator that yields key-value pairs.
-- the iterator is passed in as a function to be called in a generic for loop:
-- for k, v in iter_start() do --[[ JSON serialisation here ]] end
-- to pass a normal table ipairs(), one could do something like the following:
--[[
local t = {}
-- add stuff to t in-between
local start = function()
	return ipairs(t)
end
-- then pass start to the code below.
-- the rationale for this is to support guarded data structures,
-- which only expose an iterator via the interface instead of a private table.

-- WARNING: keys are expected to be strings only, JSON does not support mixing.
]]
local json_object_from_iterator = function(opts, json_write, sink, iter_start)
	local first = true
	sink("{ ")
	for key, value in iter_start() do
		if not first then
			-- reee json why can't you just accept trailing commas
			sink(", ")
		else	-- first = true, turn off after first object
			first = false
		end
		write_string_key(opts, json_write, sink, key)
		sink(": ")
		recursive_json(opts, json_write, sink, value)
	end
	sink(" }")
end
i.json_object_from_iterator = json_object_from_iterator





-- yeah yeah, I know, mutation... shhhh
local target = nil
local iter_start = function() return pairs(target) end
json_object = function(opts, json_write, sink, v)
	target = v
	json_object_from_iterator(opts, json_write, sink, iter_start)
end

local msg_nat = "Only non-zero, positive integers are supported for arrays"
json_array = function(opts, json_write, sink, v)
	sink("[ ")
	-- initial pass to ensure that all keys are numbers to avoid mistakes.
	for k, v in pairs(v) do
		assert(type(k) == "number", msg_mixed)
		assert(k > 0, msg_nat)
		assert((k % 1.0) == 0, msg_nat)
	end

	-- then same as in json_object(), except using ipairs, and keys implied
	local first = true
	for _, value in ipairs(v) do
		if not first then
			sink(", ")
		else
			first = false
		end
		recursive_json(opts, json_write, sink, v)
	end

	sink(" ]")
end





-- default json_write using minetest.write_json.
-- strips that pesky newline off the end as well.
-- in order to allow code to remain portable and not refer to minetest.*,
-- you must manually pass minetest.write_json to this partial applied constructor,
-- which will return the actual function suitable for use as json_write.
i.mk_mt_json_write = function(mwj)
	return function(opts, sink, v)
		local r = mwj(v, false)
		local l = #r
		if r:sub(l, l) == "\n" then
			r = r:sub(1, l-1)
		end
		sink(r)
	end
end

-- create a writer sink which updates the returned table with a "output" key,
-- which is the concatenated string result of all writes via this sink.
-- this could be considered analogous to C++'s std::string_stream.
local mk_string_sink = function()
	local r = { output="" }
	r.sink = function(str)
		local n = r.output .. str
		r.output = n
	end

	return r
end
i.mk_string_sink = mk_string_sink





return i


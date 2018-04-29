--[[
A "handler look-up table".

A common pattern that I came across during code for both pipeworks and libmt_node_network:
* I would have a table mapping node names to functions for some purpose.
	e.g. let's say it's a function to determine connectable sides.
* When examining a node, there would be a query operation which examines the node's name,
	and then tries to find a function in the above table for that node;
	if so, call it and return the result, else return an error status.
* Various parts of the mod code would install handlers into this table,
	as the various nodes came to be defined,
	with the handlers becoming associated with those nodes.

This data structure provides this pattern in a generic manner.
For instance, the look-up "key" which is associated with a handler does not have to be a node name,
instead it can be any function which will be given the data passed to the query operation.

The only oddity is how the interface is provided;
you get back two functions from the constructor, one for query and one for registration.
Part of the rationale for this is to allow these structures to compose;
you can use the query method of one as the handler for another,
to drill down into sub-details of the provided data if needed.
]]

local errors =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.errors")

local check = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.check")

local fncheck = check.mkfnexploder("neighbourtable:add_custom_hook()")
local eduplicate = errors.stdcodes.register.duplicate



local maybe_insert = function(entries, k, v)
	local new = (entries[k] == nil)
	if (new) then
		entries[k] = v
	end
	return new
end
local assert_insert = function(entries, label, k, v)
	if not maybe_insert(entries, k, v) then
		error(eduplicate.." "..label.." duplicate insertion for key "..tostring(k))
	end
end

--[[
Query routine:
attempt to look up an appropriate handler based on the provided data.
]]
local query_inner = function(entries, data, getkey, defaultv)
	local key = getkey(data)
	local handler = entries[key]
	local r, msg

	if handler then
		local result, err = handler(data)
		if (result == nil) then
			-- allow passing through explicit non-fatal "no data",
			-- otherwise default to hook fail to catch bugs like missing returns
			local is_nonfatal = (err == "ENODATA")
			msg = (is_nonfatal and "ENODATA" or "EHOOKFAIL")
			r = nil
		else
			r = result
			msg = nil
		end
	else
		r = nil
		msg = "ENODATA"
	end

	-- if defaultv is set, and we would otherwise return ENODATA,
	-- instead return the default value without error.
	if (msg == "ENODATA" and defaultv ~= nil) then
		msg = nil
		r = defaultv
	end
	return r, msg
end

-- check if a provided value is a string, or provide a default if nil.
local string_or_missing = function(caller, label, v, default)
	local t = type(v)
	if v ~= nil then
		assert(
			t == "string",
			caller.." "..label.." expected to be a string, got "..t)
		return v
	else
		return default
	end
end
-- similar to the above but retrieve from a table, and assume key == label
local string_from_table = function(caller, tbl, key, default)
	return string_or_missing(caller, key, tbl[key], default)
end


--[[
Construct a handler lookup table.
* getkey is a function used to extract the "primary key" from input data.
	This key is used to determine which handler to call.
* label is the "display name" string of this object in errors.
* opts should be a table consisting of:
	* [optional] hooklabel is a string used to refer to the handler functions,
		e.g. "neighbour set hook".
		May be nil, in which case a sane but not very descriptive string is used.
	* [optional] reglabel similarly refers to the "outer" register function if applicable,
		if this object is used as part of some larger interface.
	* [optional] opts.default can be any object.
		If it is non-nil, and query() would otherwise return ENODATA,
		return this object instead *without error*.

Returns *two functions*, query and register.
query should be called with an opaque data argument,
which will be passed to both getkey and the found handler, if any.
register should be called with a key (as returned by the getkey function)
and the handler function to associate with that key.
]]
local n_chl = "mk_handler_lut():"
local mk_handler_lut = function(getkey, label, opts)
	assert(type(label) == "string", n_chl.."label expected to be a string")
	local hooklabel = string_from_table(n_chl, opts, "hooklabel", "handler function")
	local reglabel = string_from_table(n_chl, opts, "reglabel", "register()")
	local defaultv = opts.default

	reglabel = label .. ":" .. reglabel
	local fncheck = check.mkfnexploder(reglabel)
	local entries = {}
	getkey = fncheck(getkey, n_chl)

	local query = function(data)
		return query_inner(entries, data, getkey, defaultv)
	end

	local register = function(key, handler)
		local f = fncheck(handler, hooklabel)
		return assert_insert(entries, reglabel, key, handler)
	end

	return query, register
end



local i = {}
i.mk_handler_lut = mk_handler_lut
return i


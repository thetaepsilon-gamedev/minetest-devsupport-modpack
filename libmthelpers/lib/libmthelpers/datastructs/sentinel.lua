--[[
READ THIS FIRST:
if exposing sentinels via modns,
please return it from an accessor function,
else modns will attempt to deep copy it.

There are times when we would like to return a special sentinel value from a function.
This sentinel should be considered distinct from other possible values;
let's say we want to return a special value indicating the end of a list,
or that a position is outside the allowed boundaries of some world object,
*but* we don't wish to use nil for whatever reason
(among other things: iterators don't like them).

We can use tables for this.
Tables (assuming there isn't some metatable.__eq override going on)
in lua are compared by their address;
a given table instance is equal to itself but not any other table.
Most notably, ({} == {}) will evaluate to false,
as that creates two independent tables by literal syntax.
Two distinct table entities will never compare equal (again sans metatable)
as they can't share the same address at the same time.

This means that we can use tables as a unique sentinel value,
distinct from other values (but see caveat below)
that we can return in place of a normal result in such a condition;
the client could then determine if this was the case
by comparing the return value with the sentinel object.
As tables are passed around by reference normally,
we can do this simply with "if result == somesentinel then ...";
it can even be placed into a dispatch/match table to save a long if/elseif chain.

However, this presents a mild problem in that it could potentially be error prone.
Take the example of a position above, say it returns node data like minetest.get_node() does.
In this case the normal result could be a table also.
If we use a regular plain table {}, if the client code has a bug in it,
*and* if on one occasion the called function returns a sentinel value,
then we could end up in a situation where the client tries to load a key from the sentinel,
gets nil but has forgotten to check that (i.e. that's the bug),
and then gets nil errors later on. Headaches will ensue.

To save such headaches, sentinel objects made here are a bit more elaborate.
They have metatables on them designed to make them immutable,
as well as catching the case of trying to load them.
The table used for the sentinel itself is (mostly*) empty
and trying to read or write them raises a loud and obvious error.
It doesn't necessarily make it any easier to avoid the mistake,
but it does make it easier to see what went wrong when it does;
For this reason, code which uses sentinels
is expected to document if/when it may return these potentially explosive values.

* For the sake of error messages ("oh, I forgot to handle possible XYZ sentinel value"),
the specified label for a sentinel is stored in a load-time randomised key.
This does potentially mean that a shallow copy loop like this:
local t = {}
for k, v in pairs(sentinel) do
	t[k] = v
end
could potentially slip past, but there's not much that can be done about this.
To discourage the use of this key directly for comparisons,
the key's value is also mangled with a random prefix.
]]

-- for said randomised key, and for mangling
local random = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.random")
local base64_ = random.base64_
local mangle = base64_(8)


-- a table of known sentinels.
-- when one is created, it is set true here.
-- this is only used internally for the meta ops
-- to determine which of it's arguments is a sentinels.
local is_sentinel = {}

-- internal-only type retrieval of a sentinel.
local sentinel_label_key = "__"..mangle().."_sentinel_label__"
local get_label = function(sentinel)
	local v = sentinel[sentinel_label_key]
	assert(type(v) == "string")
	return v
end

-- get the type of a an object which may or may not be a sentinel,
-- for the purposes of debugging messages.
local type_sentinel = function(v)
	return is_sentinel[v] and get_label(v) or type(v)
end

-- describe operands for binary operation errors.
local describe_binary = function(opr1, opr2)
	return "lhs " .. type_sentinel(opr1) ..
		" and rhs " .. type_sentinel(opr2)
end




-- the various meta behaviours.
-- most operations should raise an error;
-- some (like the .. concat operator) already do cause errors with tables,
-- but again we want as obvious as possible error messages wherever we can.
local err =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.errors.stdcodes")

local badop = err.struct.bad_operator
local mk_binary_op = function(label)
	local msg = badop .. " attempted to use binary " .. label ..
		" operator on sentinel object, argument types were "

	return function(opr1, opr2)
		error(msg .. describe_binary(opr1, opr2))
	end
end
local mk_unary_op = function(label)
	local msg = badop .. " attempted to use unary " .. label ..
		" operator on sentinel object, argument type was"

	return function(operand)
		error(msg .. type_sentinel(operand))
	end
end

local refuse_binary_ops = {
	"add",
	"sub",
	"mul",
	"div",
	"mod",
	"pow",
	"concat",
	-- __eq is fine, we want the default by-value behaviour
	"lt",
	"le",
	-- index and newindex have special operators defined below.
}
local refuse_unary_ops = {
	"unm",
	-- we can't override length it seems...
	-- call is somewhat special, it diagnoses # of arguments
}

local bug = "(did you accidentally use a sentinel as a table?)"
local msg_index = err.struct.bad_key_access ..
	" attempted to load key from sentinel value "..bug..", "
local msg_newindex = err.struct.bad_key_write ..
	" attempted to write key to sentinel value "..bug..", "
local msg_call = badop .. " attempted to call a sentinel value as a function, "

local extra_ops = {
	__index = function(sentinel, key)
		assert(is_sentinel[sentinel])
		error(msg_index .. "sentinel type was " .. get_label(sentinel) ..
			", key type was " .. type_sentinel(key))
	end,
	__newindex = function(sentinel, key, value)
		assert(is_sentinel[sentinel])
		error(msg_newindex .. "sentinel type was " .. get_label(sentinel) ..
			", key type was " .. type_sentinel(key) ..
			", assigned value type was " .. type_sentinel(value))
	end,
	__call = function(sentinel, ...)
		assert(is_sentinel[sentinel])
		error(msg_call .. "sentinel type was " .. get_label(sentinel) ..
			", number of args was " .. select("#", ...))
	end,
	__metatable = false,
	__tostring = function(sentinel)
		-- the tostring op is special in that we want this to work.
		assert(is_sentinel[sentinel])
		return get_label(sentinel)
	end,
}

local meta = {}
for _, op in ipairs(refuse_binary_ops) do
	local ev = "__" .. op
	meta[ev] = mk_binary_op(op)
end
for _, op in ipairs(refuse_unary_ops) do
	local ev = "__" .. op
	meta[ev] = mk_unary_op(op)
end
for ev, method in pairs(extra_ops) do
	meta[ev] = method
end






local i = {}

-- construction function.
-- label should be a suitably unique, namespaced string,
-- which will be used in error messages to aid debugging.
-- returns the created sentinel object.
local u = "__"
local get_mangled_label = function(label)
	return "__!sentinel_"..mangle()..u..label..u..mangle()..u
end
local construct = function(label)
	assert(type(label) == "string")

	local s = {}
	s[sentinel_label_key] = get_mangled_label(label)
	is_sentinel[s] = true
	return setmetatable(s, meta)
end
i.mk = construct



return i


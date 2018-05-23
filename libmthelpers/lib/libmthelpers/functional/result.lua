--[[
Lua implementation of an "Either" type used in the context of error handling.
Rust users: this is somewhat analogous to Result<T, E>.
]]

--[[
We use dynamic typing tricks to implement the "ok" and "error" sub-types,
somewhat like how one can emulate safe unions in OOP languages like Java;
in Java you'd have an interface Result<R, E> with visitor/unwrap methods,
then have subclasses Ok<R> and Error<E> which behave accordingly.
API of a result object:

* result:visit(func(v), func(e)) or result:visit({ok=func, err=func})
	result:visit() takes either a pair of visitor functions or an object,
	where the object has self-methods for the "ok" case and "err" case.
	In either case, the "ok" function (the left-hand function)
	is called with the inner value if this result represents success;
	the "err" function is called with the error object for failure.
	The bare function form is intended to be used with inline closures, e.g:

	local n = "somefunction() "
	result:visit(function(v)
			print(n.."result: "..tostring(v))
		end, function(e)
			print(n.."some error happened: "..tostring(e))
		end)
	-- adjust as appropriate for coding style.
	in either case, visit() will pass through return values.

* result:unwrap(caller, msg)
	in code using result types anyway, *this is strongly discouraged*.
	if this result represents success, returns the wrapped value;
	else, throw an error with an optional message and caller string.

* result:fmap(converter, econverter)
	"function map" operation
	(note this differs slightly from fmap for Either in Haskell).

	if the result represents success,
	let c be the result of calling converter with the unwrapped value,
	then return a new OK result wrapping c.

	if econverter is non-nil and the result represents failure,
	do similar to the above but for the unwrapped error value,
	calling econverter on it.

	if the result represents failure but econverter is nil,
	pass through the result unchanged
	(i.e. don't change the error value).

Additionally, result objects implement __tostring in their metatables.
tostring(result) will return an object of the form "[Result: Some $s]"
or "[Result: Error $s]",
where $s is the result of calling tostring on the wrapped value.
Note that this tostring format is explicitly considered not a part of the API.
]]



-- produce a function which returns a value at a later time.
-- XXX: candidate-for-library function delay
local delay = function(v)
	return function(...)
		return v
	end
end

local i = {}

--[[
in order to allow for testing,
the errors this module throws have to have some degree of machine readability.
this is so they can be distiguished from errors caused by other bugs.
thrown errors will utilise these prefixes.
]]
local errors = {
	e_notok = "ERESULTNOTOK",
	e_noterr = "ERESULTNOTERR",
}
i.error_throws = errors

-- unwrap implementation for error result:
-- throw an exception with message based on what the caller passes.
local desc = "tried to unwrap an error result"
local error_unwrap = function(self, caller, message)
	caller = (caller and (" "..caller..": ") or " ")
	message = (message and (": "..message) or "")
	local emsg = errors.e_notok..caller..desc..message
	return error(emsg)
end



-- visitors for each sub-type.
-- call the appropriate closure in either case.
local mk_ok_visit = function(v)
	return function(self, cv, ce)
		return cv(v)
	end
end
local mk_error_visit = function(e)
	return function(self, cv, ce)
		return ce(e)
	end
end



-- fmap operations for each sub-type.
-- again calls the appropriate closure,
-- *then* wrapping the value back into an object.
-- note the constructor definitions pass themselves to these functions.
local mk_ok_fmap = function(v, cons)
	return function(self, cv, ce)
		return cons(cv(v))
	end
end
local mk_err_fmap = function(e, cons)
	return function(self, cv, ce)
		-- return ourselves to represent "not modified" if ce is not set.
		return ce and cons(ce(e)) or self
	end
end

-- create __tostring operators for the specified value.
local mk_tostring = function(v, label, keylabel)
	return function(...)
		return "[Result: "..label.." "..keylabel.."=["..tostring(v).."] ]"
	end
end
local attach_tostring = function(t, ...)
	local f = mk_tostring(...)
	local meta = { __tostring=f }
	return setmetatable(t, meta)
end



--[[
module level constructors ("result" here means the module, not a result object):
result.ok(v) and result.err(e)
	respectively, construct a result object representing a success value,
	or a result object representing a failure value.
]]
local function ok(v)
	local self = {
		unwrap = delay(v),
		visit = mk_ok_visit(v),
		fmap = mk_ok_fmap(v, ok),
	}
	return attach_tostring(self, v, "Success", "v")
end
local function err(e)
	local self = {
		unwrap = error_unwrap,
		visit = mk_error_visit(e),
		fmap = mk_err_fmap(e, err),
	}
	return attach_tostring(self, e, "Error", "e")
end
i.ok = ok
i.err = err



-- error result construction helpers.
-- firstly, a __tostring operation which calls e:explain().
-- useful for structured error messages.
local h = {}
i.helpers = h
local explain = function(e)
	return e:explain()
end
h.explain_tostring = explain

local readonly = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.readonly")
local default_explain_meta = {
	__metatable = false,
	__tostring = explain,
}
local mk_default_explain = function(e)
	return setmetatable(e, readonly.shallowcopy(default_explain_meta))
end
i.mk_default_explain = mk_default_explain

-- then, a helper which constructs a structured error object from a *thrown* error.
-- note, this is not an error result but rather an object which would go in one;
-- it contains an explain() method analogous to the message method on Java exceptions.
local mk_exception_error = function(thrown)
	return mk_default_explain({

		data = thrown,
		explain = function(self)
			return "Unexpected thrown exception: "..tostring(self.data)
		end,
	})
end
i.mk_exception_error = mk_exception_error



-- and finally a helper wrapper around pcall to produce error resuts.
-- however, instead of returning a result object unconditionally,
-- this is intended to be used as an early return within imperative flow control.
-- it is analogous to pcall, except when an error is thrown,
-- the second argument is this error wrapped up.
local capture = function(status, ...)
	if not status then
		local e = ...
		return false, err(mk_exception_error(e))
	else
		return true, ...
	end
end
local rpcall = function(f, ...)
	return capture(pcall(f, ...))
end
i.rpcall = rpcall



return i


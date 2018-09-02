--[[
An interface proxy which works by calling a function with the name of the operation:
proxy("setpos", pos)
The proxy uses the first argument (expected to be a string)
as a method to call on an underlying object.
The proxy checks that access to a given method is allowed,
by seeing if that method is present as a key in a table provided upon construction.
Attempts to access a non-authorised method raises an error.
Otherwise, the proxy call operates identically to calling the method directly,
including preserving multiple arguments and return values.

The motivation for this comes from the way lua-based entities work in MT.
Ideally we would use closures to protect object state,
but in MT objects have a lua "self" table which is the primary means of carrying entity state;
in particular, it is the only source of the engine objectref used to move the entity around etc.
This proxy mechanism was devised as a safe way to hand out access to certain operations,
without losing the convenience of the self table for entities.
]]

local pre = "proxy method error: "

--[[
acl (the access control list) is queried by looking up acl[methodname].
Access is allowed iff acl[methodname] is a truth value.
In that case, the actually invoked method on targetobj
is (methodprefix..methodname), to allow internal naming conventions;
e.g. methodprefix = "interface_" will cause a proxy call to "setparams"
to actually invoke "targetobj:interface_setparams()" (assuming acl passed).

An exception to the above is if the value at acl[methodname] is itself a function.
In that case, that function is called instead,
with the target object as the first "self" parameter,
and varargs parameters following that.
This allows for defining the interface functions separately if desired.
]]
local create_proxy_inner = function(acl, targetobj, methodprefix)
	return function(method, ...)
		local t = type(method)
		if t ~= "string" then
			error(pre.."expected string method name, actual type "..t)
		end

		local a = acl[method]
		-- if it's a function, then use that directly
		local t = type(a)
		if t == "function" then
			return a(targetobj, ...)
		end

		-- otherwise, treat as an access value
		if not a then
			error(pre.."unknown interface method: "..method)
		end
		local methodk = methodprefix..method
		-- long form of method calling syntax to use custom key index.
		-- recall that t:f(...) is the same as t.f(t, ...),
		-- and in turn t.f is the same as t["f"].
		return targetobj[methodk](targetobj, ...)
	end
end



-- partially applied constructor to allow baking in a default acl and methodprefix,
-- to which the inner "self" objects can then be passed to retrieve proxies.
-- local getproxy = proxy_factory_(acl, methodprefix)
-- ...
-- local proxy = getproxy(obj)
local i = {}
local proxy_factory_ = function(acl, methodprefix)
	assert(type(acl) == "table")
	assert(type(methodprefix) == "string")
	return function(targetobj)
		return create_proxy_inner(acl, targetobj, methodprefix)
	end
end
i.proxy_factory_ = proxy_factory_



return i


--[[
Lua is most certainly a dynamically typed language,
and for the most part that matters little in practice
(performance/strict correctness concerns aside).

However, *every now and again*,
one comes across the need to distinguish types more finely.
For instance, consider a sparse octree where a parent node has 8 "slots",
where each slot may either be a leaf value or a child node.
If one were to decide to implement this by using arrays for nodes,
one would not be able to distinguish these from any table leaf values.

Therefore, some kind of marking is required.
For objects that are *solely* used inside a data structure and not exposed,
a simple type tag would be sufficient.
However, consider the case that some client of the structure adds a table,
setting this same type tag as a key in that table.
This could potentially cause unpredictable behaviour,
as well as violations of information hiding and internal pre/post conditions.

At the same time however, the "strong" method described below may be inefficient,
especially due to the increase in the number of table dereferences and memory consumption.
Therefore, there is a "simple" method and a "strong" method.

To create a type, request a type from the appropriate functions below.
This action returns two functions to the caller; a signer and a verifier.
The signer takes a constructed object and "signs" it,
returning a new object which is semantically identical bar pairs()
(see below for the details of this).
The verifier will (within reason, also see further down)
return true for any object signed by the matching signer, and false otherwise.
In other words, the signer is used to "make" objects of a type,
and the verifier is essentially "is this object an instance of this type".

Under the hood, for strong types this is done via metatables and object set tracking.
When objects are signed by a strong type, they get wrapped in a proxy table,
which uses metatables to redirect accesses to the real object.
The real object is accessed via metamethods which only hold the reference via closure capture.
This is so that values/methods on the real object cannot be removed
(potentially causing errors in client code).
This proxy object is then added to a set of objects considered "blessed".
The corresponding verifier then simply checks for the existance of the object in the set.

For simple types, the object to be signed is returned directly after having a special key set on it.
This key is randomised and has an equivalently randomised value;
the verifier for the same type checks if this key exists and has the correct value.
]]

--[[
Generate the random key/value strings for simple types.
Uses math.random to pick hexadecimal chars and concats them.

In theory, we would want to pick a key which is protected by obscurity
(in the abscence of a more secure language-level mechanism);
say it's some random selection of words.

In practice, obscurity almost always gets broken in practice;
it seems that for the simple method,
there is no 100% bulletproof way of hiding the key,
and there is also always the remote chance of collision with a real key.
Sometimes it just plain boils down to how stupid you expect clients to be.

So, to keep it sane and simple,
the table key generation below actually does use a predictable pattern,
if only for the sake of debugging.
Code which wants to use something more secure should use the strong variant.
]]
local hex = "0123456789ABCDEF"
local getrandhex = function()
	local v = math.random(16)
	local char = hex:sub(v, v)
	return char
end
local genhexstring = function(length)
	local result = ""
	for i = 1, length, 1 do
		result = result .. getrandhex()
	end
	return result
end



local r = function() return genhexstring(16) end
local rk = function() return "__"..r().."_type" end
local i = {}


-- names below should be somewhat self explanatory...

i.create_simple_type = function()
	local k = rk()
	local v = r()

	local signer = function(object)
		-- this really shouldn't happen due to random generation,
		-- though it may happen if someone tries to sign the object twice.
		local oldv = object[k]
		assert(oldv == nil, "object to be signed should not already possess the tag")
		object[k] = v
		return object
	end
	local verifier = function(object)
		return (type(object) == "table") and (object[k] == v) or false
	end

	return signer, verifier
end

return i

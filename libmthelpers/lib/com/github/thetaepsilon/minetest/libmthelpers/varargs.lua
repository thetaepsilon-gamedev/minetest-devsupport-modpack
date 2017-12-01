local interface = {}



-- varargs visitor.
-- calls a passed visitor object for each item, including nils.
--[[
-- argh, I miss java where I could declare interfaces as checkable code...
varargs visitor interface methods:
visit(v): called for each vararg parameter, in order. may be passed nil.
]]

-- recursion to peel away arguments:
-- is passed the number of varargs + 1 for the separate v.
local function varargs_visit_r(visitor, n, v, ...)
	if n < 1 then return end
	visitor:visit(v)
	varargs_visit_r(visitor, n-1, ...)
end
-- entry function for the above
local varargs_visit = function(visitor, ...)
	-- see lua docs: this is the incantation to reliably figure out number of varags.
	-- this works even if the last vararg is nil for example.
	local count = select("#", ...)
	return varargs_visit_r(visitor, count, ...)
end
interface.visit = varargs_visit



-- varargs capture helper.
-- as the table length operator isn't always accurate,
-- we need to explicitly capture the number of varargs,
-- before storing the varags themselves using { ... }.
local typestr = "tuple"
local tuple = function(...)
	local count = select("#", ...)
	-- in lua 5.1, not possible to override the # length operator for tables,
	-- as the table's own length operation takes precedence before metatables are tried.
	-- hence we have to make our own data type up.
	return { __type=typestr, len=count, e={ ... } }
end
interface.tuple = tuple

return interface

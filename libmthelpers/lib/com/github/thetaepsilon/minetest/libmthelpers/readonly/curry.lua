-- yes, I *know* calling partial application "currying" is incorrect...
local curry = {}

local check = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.check")
local mkfnexploder = check.mkfnexploder



-- partially applies the "self" object of a table method function into a closure.
-- that is, f(self, a, ...) becomes g(a, ...) and "self" is captured by closure scope of the function.
-- the function implicitly retains a handle to the original table,
-- and can be passed around invididually.
local check_currymethod = mkfnexploder("curry.method()")
local currymethod = function(tbl, mkey)
	local check = check_currymethod
	local m = tbl[mkey]
	check(m, "table method "..tostring(mkey))
	return function(...)
		return m(tbl, ...)
	end
end
curry.method = currymethod



-- curry a list of methods from an existing table.
local curryobject = function(tbl, list)
	local result = {}
	for _, key in ipairs(list) do
		result[key] = currymethod(tbl, key)
	end
	return result
end
curry.object = curryobject



return curry

-- goes through a table recursively and finds name entries that can be aliased.
-- e.g. a root component "com.example" which is { a = function() ... end, ... }
-- will produce a sub-component "com.example.a" automatically.
local function tvisit(object, basename, sep, visitor)
	visitor(basename, object)
	if type(object) == "table" then
		for k, sub in pairs(object) do
			local subname = basename..sep..k
			tvisit(sub, subname, sep, visitor)
		end
	end
end

return tvisit

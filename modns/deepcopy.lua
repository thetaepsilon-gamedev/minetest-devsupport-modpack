-- deep copy an object.
-- generally only tables can be shallow copied,
-- but this version won't throw if it's not.
-- table.copy is also an MT-specific extension.
local function deepcopy(obj)
	if type(obj) ~= "table" then return obj end
	local result = {}

	for k, v in pairs(obj) do
		result[k] = deepcopy(v)
	end

	return result
end

return deepcopy

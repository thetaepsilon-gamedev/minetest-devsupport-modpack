local isdim = {
	x = true,
	y = true,
	z = true,
}
local dims = 3

-- check if an object represents a valid vector.
-- optional strict flag sets whether or not to reject keys which are not x/y/z
-- (which is not on by default in case of e.g. extra data stored in a position table).
-- returns boolean true or false.
local check_vector = function(vec, strict)
	if type(vec) ~= "table" then
		--print("not a table")
		return false
	end
	local count = dims
	for k, v in pairs(vec) do
		if isdim[k] then
			if type(v) ~= "number" then
				--print("not number")
				return false 
			end
			count = count - 1
		else
			if strict then
				--print("strict mode rejected key: "..tostring(k))
				return false
			end
		end
	end
	-- should have encountered all three dimensions
	--print(count)
	return count == 0
end

return check_vector


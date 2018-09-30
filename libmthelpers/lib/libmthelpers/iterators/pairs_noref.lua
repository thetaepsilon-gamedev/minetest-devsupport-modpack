-- a version of pairs()-like iteration over a table,
-- which doesn't leak a reference to the table itself.
-- this can be useful to prevent unwanted modification to the table.

-- next :: Table -> Maybe Key -> Maybe (Key, Value)
local nextkey = next

-- pairs :: Table -> Iterator (Key, Value)
local f = function() return nil, nil end
local pairs = function(table)
	local t = type(table)
	if t ~= "table" then
		error("pairs(t): expected t to be a table, got "..t)
	end

	local ckey = nil
	local stop = false
	-- we're effectively mimicking the behaviour of normal pairs() here;
	-- except we closure over state variables instead of being passed them.
	-- this also has the benefit of being possible to pass around.
	return function()
		if stop then return f() end
		local k, v = next(table, ckey)
		if k == nil then
			stop = true
			return f()
		end
		ckey = k
		return k, v
	end
end

return pairs


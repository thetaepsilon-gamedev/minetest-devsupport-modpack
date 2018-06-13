--[[
fmap operation for various types.
]]

local i = {}
-- fmap for a generator: return a new generator applying f over values from inner generator.
-- in this case, the mapped function must not return nil,
-- as nil returns from a generator causes lua to terminate the loop.
-- the function itself will never see nil values from the inner iterator.
local generator_ = function(f)
	assert(type(f) == "function")

	return function(it)
		assert(type(it) == "function")

		return function()
			local src = it()
			if src == nil then return nil end
			local r = f(src)
			assert(r ~= nil)
			return r
		end
	end
end
i.generator_ = generator_



return i


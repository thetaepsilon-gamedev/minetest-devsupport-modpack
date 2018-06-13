--[[
Helpers for various other parts of libmthelpers for randomness.
]]

-- ffs, seeding, why...
math.randomseed(os.time())

-- generate base64 random strings (doesn't handle padding).
local base64_chars =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
	"abcdefghijklmnopqrstuvwxyz" ..
	"0123456789+/"

local i = {}
-- impure partial application, I know...
local get_random_base64_ = function(n)
	assert(type(n) == "number")
	assert(n > 0)
	assert(n % 1.0 == 0)
	return function()
		local s = ""
		for i = 1, n, 1 do
			local v = math.random(64)
			local char = base64_chars:sub(v, v)
			s = s .. char
		end
		return s
	end
end
i.base64_ = get_random_base64_



return i


-- stack data structure backed by an array-like list.
local i = {}



local lib = "com.github.thetaepsilon.minetest.libmthelpers"
local stdcodes = mtrequire(lib..".errors.stdcodes")
local naterr = stdcodes.args.expected_t.numeric.natural_or_zero
local sentinel = mtrequire(lib..".datastructs.sentinel")

local empty = sentinel.mk("libmthelpers.datastructs.stack.empty")
i.empty = function() return empty end



local base = " stack.new(): "
local eb = naterr..base.."expected non-negative integer length, "
local et = eb.."got type "
local ev = eb.."got value "
local new = function(length)

	local table = {}

	-- sometimes I wish we had type hints or something...
	-- at least C(++)'s unsigned ints never had this issue!
	if length == nil then length = 0 end
	local t = type(length)
	if t ~= "number" then
		error(et..t)
	end
	if (length % 1.0) ~= 0.0 then
		error(ev..length)
	end
	if length < 0 then
		error(ev..length)
	end



	local push = function(v)
		-- ree 1-based indexes
		local c = length
		c = c + 1
		table[c] = v
		length = c
	end

	-- this is iteration from the bottom, *not* in stack pop order
	local ipairs = function()
		-- modification during iteration... please don't
		local limit = length
		local c = 0

		return function()
			-- initially c is zero, so i will be 1
			-- (start of array in one-based indexing)
			local i = c + 1
			-- only update the index if we can continue;
			-- no point incrementing the counter when at the end
			if i > limit then return nil, nil end
			c = i
			return i, table[i]
		end
	end

	local size = function() return length end

	-- popping is a little more complicated because stacks can store nil.
	-- here a SENTINEL value is used, namely the empty sentinel above.
	local pop = function()
		if length == 0 then
			return empty
		end

		assert(length > 0)
		local e = table[length]
		length = length - 1
		return e
	end

	return {
		push = push,
		ipairs = ipairs,
		size = size,
		pop = pop,
	}
end
i.new = new



return i


-- returns a value that may be multiplied with another value to inherit the sign.
-- returns -1 if v < 0, 0 if v == 0, and 1 if v > 0.
-- does not preserve signed zero.
-- NaNs are propagated.
local sign = function(v)
	if (v < 0) then
		return -1
	else
		if (v > 0) then
			return 1
		else
			-- by ruling out math.huge and math.tiny,
			-- we're either left with (-)0 or NaN.
			-- in either case just return the input as that'll do what we want.
			return v
		end
	end
end
math.sign = sign

-- "signed" version of math.pow that only operates on the absolute value of x,
-- then reapplies the sign afterwards.
local pow = assert(math.pow)
local abs = assert(math.abs)
math.signpow = function(x, e)
	local magnitude = abs(x)
	local s = sign(x)
	local raised = pow(magnitude, e)
	return raised * s
end


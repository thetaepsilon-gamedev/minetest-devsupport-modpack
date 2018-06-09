--[[
vectorextras.equality
More rigourous comparisons of vectors that MT's distributed vector.equals;
performs checking of object type with optional strictness and throw behaviour.
]]

local checkvec = mtrequire("ds2.minetest.vectorextras.checkvec")



-- compare two vectors for equality.
-- returns true, false, or throws if one of the arguments was not a vector.
-- TODO: equality with tolerance?
-- flags:
-- * strict: same as for checkvec() (see appropriate source file)
-- * nothrow: return nil instead of throwing on failure.
--	requires callers to be paying attention to the ternary result!
local throw = function(label)
	error("are_vectors_equal(): "..label.." was not a valid vector!")
end
local nothrow = function(label)
	return nil
end
local are_vectors_equal = function(vec1, vec2, strict, _nothrow)
	local e = (_nothrow and nothrow or throw)
	if not checkvec(vec1, strict) then return e("vec1") end
	if not checkvec(vec2, strict) then return e("vec2") end

	return (vec1.x == vec2.x) and
		(vec1.y == vec2.y) and
		(vec1.z == vec2.z)
end



return are_vectors_equal

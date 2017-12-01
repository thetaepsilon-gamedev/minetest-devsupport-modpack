local check = {}
check.selftest = {}



local numbercheck = function(val, label, caller)
	local valtype = type(val)
	if (valtype ~= "number") then
		error(caller.."(): non-numerical value passed for "..label)
	end
end
check.number = numbercheck



local integercheck = function(val, label, caller)
	numbercheck(val, label, caller)
	if (val % 1.0 ~= 0.0) then
		error(caller.."(): integer value required for "..label)
	end
end
check.integer = integercheck



local rangecheck = function(val, lower, upper, isinteger, label, caller)
	if isinteger then integercheck(val, label, caller) else numbercheck(val, label, caller) end
	if (val < lower) or (val > upper) then
		error(caller.."(): "..label.." expected value in range "..lower.."-"..upper..", got "..val)
	end
end
check.range = rangecheck



check.mkassert = function(caller)
	return function(condition, message, extradata)
		if not condition then
			local extra=""
			if type(extradata) == "table" then
				for key, value in pairs(extradata) do
					extra = extra.." "..key.."="..value
				end
			elseif extradata ~= nil then
				extra = "data="..tostring(extradata)
			end
			error(caller..": "..message..extra)
		end
	end
end



-- convienience boilerplate for checking if a value is a function.
-- returns the value if valid, else throws an error.
check.mkfnexploder = function(callername)
	return function(val, label)
		if type(label) == nil then label = "checked value" end
		if type(val) ~= "function" then
			error(callername..": "..tostring(label).." expected to be a function, got "..tostring(val))
		end
		return val
	end
end



-- make a reference counter to track the number of holders of an object.
-- you could just use a plain integer for this,
-- but this object can be passed by reference and handles the boilerplate.
-- you can also pass the decrement function by value to isolate the refcounter's incrementer.
check.mkrefcounter = function()
	local refcount = 0
	local interface = {}

	interface.increment = function()
		refcount = refcount + 1
	end
	interface.decrement = function()
		if refcount < 0 then error("refcounter underflow!") end
		refcount = refcount - 1
	end
	interface.get = function() return refcount end

	return interface
end



-- the following functions do NOT throw errors but are tests only
-- used among other things for the set datatype self-tests in the assertion statements.
local tabletest = function(val)
	return type(val) == "table"
end

local listequal = function(a, b)
	if not tabletest(a) or not tabletest(b) then
		return false
	end
	-- doesn't really detect non-listlike tables...
	if #a ~= #b then return false end
	for index, value in ipairs(a) do
		if value ~= b[index] then return false end
	end

	return true
end
check.listequaltest = listequal

check.selftest.listequal = function()
	local name = "libmthelpers.check.selftest.listequal()"
	local assert = check.mkassert(name)

	assert(listequal({}, {}), "null lists should compare equal")
	assert(not listequal({}, { 1 }), "null and one-item list should NOT be equal")
	assert(not listequal({}, { 1, 2 }), "null and two-item list should NOT be equal")

	assert(listequal({1}, {1}), "identical one-item lists should compare equal")
	local sameref = { 2 }
	assert(listequal(sameref, sameref), "duplicate reference to one-item list should compare equal")
	assert(not listequal({42}, {4}), "differing one-item lists should NOT compare equal")
	assert(not listequal({3, 4}, {5}), "one- and two-item lists should NOT compare equal")

	assert(listequal({6, 7}, {6, 7}), "identical two-item lists should compare equal")
	assert(not listequal({6, 7}, {6, 8}), "differing two-item lists should NOT compare equal")
	assert(not listequal({6, 7}, {7, 6}), "reversed-order two-item lists should NOT compare equal")

	return name.." self-tests completed successfully"
end



return check

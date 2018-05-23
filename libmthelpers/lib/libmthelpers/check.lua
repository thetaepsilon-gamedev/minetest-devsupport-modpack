local errors =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.errors")

local check = {}
check.selftest = {}
check.explain = {}



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



local fe_nf = errors.stdcodes.args.expected_t.func
-- convienience boilerplate for checking if a value is a function.
-- returns the value if valid, else throws an error.
check.mkfnexploder = function(callername)
	return function(val, label)
		if type(label) == nil then label = "checked value" end
		if type(val) ~= "function" then
			error(
				fe_nf .. callername .. ": " ..
				tostring(label) ..
				" expected to be a function, got " ..
				tostring(val))
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



-- check a table (or userdata)'s interface.
-- takes a target object and a "signature table".
-- for each string label found in the signature table,
-- check that the target object's corresponding key is a function.
-- stops and returns failure at the first non-match found,
-- as well as "failure data":
--[[
faildata = {
	reason = string,	-- one of "targettype", "missingkey" or "keytype"
	badkey = keyname,	-- set to the signature key that failed or is missing if relevant.
	extra = extradata,	-- see below:
			-- for "targettype", set to the unexpected type of the target object.
			-- for "keytype", set to the unexpected key type.
			-- for any other reason, not set.
	expected = "expectedtype",
			-- for any error returning a bad type in extradata, this is the expected type.
}
]]
local check_interface = function(target, signatures)
	local t = type(target)
	if not (t == "table" or t == "userdata") then
		return false, { reason="targettype", extra=t, expected="table or userdata" }
	end

	local success = true
	local faildata
	for _, key in ipairs(signatures) do
		local v = target[key]
		if v == nil then
			success = false
			faildata = { reason="missingkey", badkey=key }
			break
		else
			t = type(v)
			if t ~= "function" then
				success = false
				faildata = { reason="keytype", badkey=key, extra=t, expected="function"}
				break
			end
		end
	end
	return success, faildata
end
check.interface = check_interface
-- failure data formatter to give a reasonable error description.
-- I'm not going to bother translating this as it's not intended for general UI.
local formattype = function(expected, actual) return "expected "..expected..", got "..actual end
local utype = " had unexpected type: "
local explain_interface_faildata = function(faildata)
	local e = faildata.reason
	local t = faildata.extra
	local k = faildata.badkey
	local x = faildata.expected
	local msg = "???"
	if e == "targettype" then
		msg = "interface object"..utype..formattype(x, t)
	elseif e == "missingkey" then
		msg = "interface was missing member function "..k
	elseif e == "keytype" then
		msg = "interface member "..k..utype..formattype(x, t)
	end
	return msg
end
check.explain.interface = explain_interface_faildata

-- for callers that just need a signature to match for it to work.
check.mk_interface_check = function(signatures, prefix)
	if not prefix then prefix = "" else prefix = prefix .. " " end
	return function(target)
		local ok, faildata = check_interface(target, signatures)
		if not ok then error(prefix..explain_interface_faildata(faildata)) end
		return target
	end
end



-- variant of check_interface that stubs out functions or uses defaults from a provided table.
-- default stubbed functions do nothing and return no values.
-- this can only work for table targets; userdata cannot be written.
-- returns faildata compatible with explain_interface_faildata above.
-- first return value is the result table if successful, nil otherwise.
-- this function does NOT modify target.
local default = function() return function(self, ...) end end
local check_interface_or_missing = function(src, signatures, defaults)
	if not defaults then defaults = {} end
	local result = {}

	local t = type(src)
	local x = "table"
	if not (t == "nil" or t == x) then
		return nil, { reason="targettype", extra=t, expected=x }
	else
		-- allow passing a nil table to mean "default everything"
		src = src or {}
	end
	for k, v in pairs(src) do
		result[k] = v
	end

	x = "function"
	local faildata
	for _, key in ipairs(signatures) do
		local v = result[key]
		if v == nil then
			result[key] = defaults[key] or default()
		else
			t = type(v)
			if t ~= x then
				result = nil
				faildata = { reason="keytype", badkey=key, extra=t, expected=x}
				break
			end
		end
	end
	return result, faildata
end
check.interface_or_missing = check_interface_or_missing

check.mk_interface_defaulter = function(prefix, signatures, defaults)
	if not prefix then prefix = "" else prefix = prefix .. " " end
	return function(src)
		local result, faildata = check_interface_or_missing(src, signatures, defaults)
		if not result then error(prefix..explain_interface_faildata(faildata)) end
		return result
	end
end



return check

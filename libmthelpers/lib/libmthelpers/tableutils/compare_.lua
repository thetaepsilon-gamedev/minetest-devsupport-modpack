local err = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.errors.stdcodes")
--[[
Element-wise compare a given table against a reference one,
using a custom comparator function (defaulting to inbuilt "==" operator).
Curried partial application function, first level args:
+ opts: a table controlling things about the comparison (defaults to {}):
	+ comparator: two-arg comparison function, must return true or false value.
		may assume args are non-nil.
	+ strict: as well as checking that input has all the keys of reference,
		check that input does not have any unrecognised keys.
	+ throw: if either reference or input were not tables,
		raise an error instead of returning nil.
		off by default to allow better functional composition.
	+ verbose: if not throwing, when false is returned,
		return an extra table describing what went wrong.
		has no effect in throw mode as the exception will not return anyway.
Returns a function of two tables, the actual comparison closure.

Rationale:
It may be useful to compare tables where the subkeys are themselves tables;
in many cases, by-value equality comparison of tables is probably not what is desired.
Please refer to the relevant test cases.
]]
local eq = function(a, b) return a == b end

local throw = function(label)
	error("tableutils compare_(): "..label.." was not a table!")
end
local nothrow = function(label)
	return false
end
local e = err.args.expected_t.table
local nothrow_verbose = function(label)
	return false, {reason=e, which=label}
end



-- more verbose mode helpers
local ek = err.table.unknown_key
local v_badkey = function(k)
	return false, {reason=ek, key=k}
end
local em = err.table.missing_key
local v_missingkey = function(k)
	return false, {reason=em, key=k}
end
local ev = err.table.bad_key_value
local v_compfail = function(k)
	return false, {reason=ev, key=k}
end
-- consistency with number of returned values in success/verbose case
local v_success = function()
	return true, nil
end



local fail = function(...) return false end
local pass = function(...) return true end

local compare_ = function(opts)
	opts = opts or {}
	local comp = opts.comparator or eq
	assert(type(comp) == "function")
	local strict = opts.strict
	local verbose = opts.verbose
	local maybethrow = (
		opts.throw
		and throw
		or (
			verbose
			and nothrow_verbose
			or nothrow
		)
	)
	local badkey = verbose and v_badkey or fail
	local missingkey = verbose and v_missingkey or fail
	local compfail = verbose and v_compfail or fail
	local success = verbose and v_success or pass

	return function(reference, input)
		if type(reference) ~= "table" then return maybethrow("reference") end
		if type(input) ~= "table" then return maybethrow("input") end

		if strict then
			for k, _ in pairs(input) do
				-- key that doesn't exist in reference?
				if reference[k] == nil then return badkey(k) end
			end
		end

		for k, ref in pairs(reference) do
			local i = input[k]
			-- reference key missing in input?
			if i == nil then return missingkey(k) end
			-- key itself doesn't match reference?
			if not comp(ref, i) then return compfail(k) end
		end

		return success()
	end
end

return compare_


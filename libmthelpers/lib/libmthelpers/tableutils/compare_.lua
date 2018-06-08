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
local nothrow = function(label) return false end

local compare_ = function(opts)
	opts = opts or {}
	local comp = opts.comparator or eq
	assert(type(comp) == "function")
	local strict = opts.strict
	local maybethrow = opts.throw and throw or nothrow

	return function(reference, input)
		if type(reference) ~= "table" then return maybethrow("reference") end
		if type(input) ~= "table" then return maybethrow("input") end

		if strict then
			for k, _ in pairs(input) do
				-- key that doesn't exist in reference?
				if reference[k] == nil then return false end
			end
		end

		for k, ref in pairs(reference) do
			local i = input[k]
			-- reference key missing in input?
			if i == nil then return false end
			if not comp(ref, i) then return false end
		end

		return true
	end
end

return compare_


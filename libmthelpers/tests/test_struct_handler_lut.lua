#!/usr/bin/env lua5.1
local errors =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.errors")
local expect_error = errors.expect_error
local handler_lut =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.datastructs.handler_lut")

local testing =
	mtrequire("com.github.thetaepsilon.minetest.libmthelpers.testing")



local example_getkey = function(data)
	return data.key
end
local label = "test_handler_lut"
local get_test_object = function()
	local q, r = handler_lut.mk_handler_lut(example_getkey, label, {})
	return { query=q, register=r }
end



-- test helper data:
-- neighbour set table which should be passed through unchanged.
-- it is assumed that the neighbourset will NOT copy the handler's return tables.
local testdata = {}
local delay = function(v)
	return function()
		return v
	end
end
local testhandler = delay(testdata)
local failhandler = function() end
local nodatahandler = function() return nil, "ENODATA" end

-- test helper: assert that the query for a given key returns no data.
local assert_no_data = function(query, key)
	local data, err = query({key=key})
	assert(data == nil)
	assert(err == "ENODATA")
end

-- test helper: assert that a query returns EHOOKFAIL.
local assert_hook_fail = function(query, key)
	local data, err = query({key=key})
	assert(data == nil)
	assert(err == "EHOOKFAIL")
end

-- test helper: assert that a given query returns an expected value.
local assert_expected = function(query, key, expected)
	local data, err = query({key=key})
	assert(err == nil)
	assert(data == expected)
end



local dummy = function() end
local n = "example"
local altlabel = label.."_alt"
local testvecs = {
	function(dep)
		-- test wrongly typed objects,
		-- and that normal functions can still go in afterwards.
		dep.register("1", dummy)
		expect_error("err.args.expected_t.func", function()
			dep.register(n, 1)
		end)
		dep.register("2", dummy)
		expect_error("err.args.expected_t.func", function()
			dep.register("3", 1)
		end)
	end,

	function(dep)
		-- check that duplicate insertions are caught correctly.
		dep.register(n, dummy)
		dep.register("example2", dummy)
		expect_error("err.register.duplicate", function()
			dep.register(n, dummy)
		end)
	end,

	function(dep)
		-- a completely emtpy lut should not respond to anything.
		assert_no_data(dep.query, n)
		assert_no_data(dep.query, "wat")
	end,

	function(dep)
		-- check that first no data is returned,
		-- then that it starts returning the expected data after registration.
		-- meanwhile another name should still return empty.
		local n2 = "1234"
		assert_no_data(dep.query, n)
		assert_no_data(dep.query, n2)
		dep.register(n, testhandler)
		local r = dep.query({key=n})
		assert(r == testdata)
		assert_no_data(dep.query, n2)
	end,

	function()
		-- check that different getkey functions work.
		local getkey = function(data) return data.key2 end
		local query, register = handler_lut.mk_handler_lut(getkey, altlabel, {})
		local n2 = "1234"

		local assert_no_data = function(query, key)
			local data, err = query({key2=key})
			assert(data == nil)
			assert(err == "ENODATA")
		end
		assert_no_data(query, n)
		assert_no_data(query, n2)
		register(n, testhandler)
		local r = query({key2=n})
		assert(r == testdata)
		assert_no_data(query, n2)
	end,

	function()
		-- check that the getkey function gets access to the provided data object.
		local data = {}
		local peek = {}
		local getkey = function(data)
			peek.data = data
			return n
		end
		local query, register = handler_lut.mk_handler_lut(getkey, altlabel, {})
		register(n, testhandler)

		-- if getkey was called, then it should have set peek.data
		local result, err = query(data)
		assert(result == testdata)
		assert(peek.data == data)
	end,

	function(dep)
		-- test that different handlers remain separate.
		for i = 1, 5, 1 do
			local t = {}
			local n = tostring(i)
			dep.register(n, delay(t))
			assert(dep.query({key=n}) == t)
		end
	end,

	function(dep)
		-- test that a handler which simply returns nil,
		-- with no other error indicated, causes EHOOKFAIL.
		-- this is to catch handler function bugs,
		-- as a mistaken return can result in nil results.
		dep.register(n, failhandler)
		assert_hook_fail(dep.query, n)
	end,

	function(dep)
		-- likewise catch that a hook that explicitly indicates EHOOKFAIL itself
		-- (by returning it as a second value)
		-- also gets passed through.
		dep.register(n, function() return nil, "EHOOKFAIL" end)
		assert_hook_fail(dep.query, n)
	end,

	function(dep)
		-- a handler should be able to explicitly indicate a non-fatal "no data available",
		-- in the same way the top-level object does if no handlers are present.
		-- this is to allow handler LUTs to compose,
		-- in that the handler for a given node type might be a sub-lut query function
		-- which further looks up handlers based on other data fields.
		dep.register(n, nodatahandler)
		local data, err = dep.query({name=n})
		assert(data == nil)
		assert(err == "ENODATA")
	end,

	function()
		-- test setting up a *default value* for a lut.
		-- if no data is found, the default should be returned instead.
		local default = {}
		local opts = { default=default }
		local query, register = handler_lut.mk_handler_lut(example_getkey, label, opts)
		register(n, testhandler)
		assert_expected(query, n, testdata)
		assert_expected(query, "Random McRandface", default)
	end,
}

testing.test_harness_with_deps({testvecs=testvecs, get_dep = get_test_object})


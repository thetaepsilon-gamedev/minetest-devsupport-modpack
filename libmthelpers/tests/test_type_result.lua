#!/usr/bin/env lua5.1
-- note to self: maybe make the module names a bit shorter...
local m_result = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.functional.result")

-- because lua doesn't really support non-string throwables correctly,
-- in order to correctly determine whether the error was the *expected* one,
-- we have to string match the error message for a well-known, stable prefix.

-- call a function and expect it to return an error which matches a predicate.
-- errors that don't match and errors from the predicate are propogated.
local expect_error = function(f, predicate, ...)
	local n = "expect_error: "
	local ok, err = pcall(f, ...)
	
	if ok then error(n.."error expected but function succeeded") end
	if not predicate(err) then
		error(n.."error caught but did not match predicate")
	end
end
-- use the above to look for prefixes in the error string.
-- however, somewhere between the throw and the catch,
-- lua injects the source file which caused the error.
-- therefore it's not always at the start of the string.
local expect_error_prefix = function(f, prefix, ...)
	local s = #prefix
	local predicate = function(msg)
		local start, last = msg:find(prefix, 1, true)
		return (start and last) and (last - start == s-1)
	end
	return expect_error(f, predicate, ...)
end
-- do the same but for method calls
local expect_error_method = function(self, method, prefix, ...)
	return expect_error_prefix(self[method], prefix, self, ...) 
end



local v = {}
local e = "ENOENT"
local ok = m_result.ok(v)
local err = m_result.err(e)

local caller = "functional.result test script"
local v1 = ok:unwrap(caller, "expected ok result")
assert(v1 == v, "unwrap of ok result should return original object")
expect_error_method(
	err,
	"unwrap",
	m_result.error_throws.e_notok,
	caller,
	"unwrap exception should have been caught")
-- repeat but with no caller/message combination;
-- this should NOT cause some error due to them being nil.
expect_error_method(
	err,
	"unwrap",
	m_result.error_throws.e_notok)



local retval = "result returned from visitor"
local r1 = ok:visit(function(v2)
		assert(v2 == v, "object passed to visitor should be original value")
		return retval
	end, function(e)
		error("result object should not have been an error")
	end)
assert(r1 == retval, "visitor should have returned expected string")

local errval = "result returned from error visitor"
local r2 = err:visit(function(v)
		error("error object should not have called success visitor")
	end, function(e1)
		assert(e1 == e, "error object passed to visitor should be original error")
		return errval
	end)
assert(r2 == errval, "visitor should have returned expected string")



-- fmap transformations
local d = "No such file or directory"
local descriptions = {
	[e] = d,
}
local converter = function(v)
	return { v }
end
local econverter = function(e)
	return descriptions[e]
end
local bang = function()
	return error("converter or econverter called where other was expected")
end

local ok2 = ok:fmap(converter, bang)
local r3 = ok2:visit(function(v1)
		assert(v1[1] == v, "converted value should hold original value")
		return true
	end, function(e)
		error("error result not expected after fmap")
	end)
assert(r3, "successful visit should have returned true")

local err2 = err:fmap(bang, econverter)
local cv = function(v)
	error("success result not expected after fmap of error")
end
local r4 = err2:visit(cv, function(e)
		assert(e == d, "converted error should be long form of original")
		return true
	end)
assert(r4, "visit of error result should have returned true")

-- nil econverter should pass through the error.
local err3 = err:fmap(bang, nil)
local r5 = err3:visit(cv, function(e1)
		assert(e == e1, "nil econverter fmap should have preserved error object")
		return true
	end)
assert(r5, "visit of error result should have returned true")



--print(ok)
--print(err)

return true


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
local expect_error_prefix = function(f, prefix, ...)
	local s = #prefix
	local predicate = function(msg)
		local start, last = msg:find(prefix, 1, true)
		return (start == 1) and (last == s)
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




print("libmthelpers.functional.result tests passed")
return true


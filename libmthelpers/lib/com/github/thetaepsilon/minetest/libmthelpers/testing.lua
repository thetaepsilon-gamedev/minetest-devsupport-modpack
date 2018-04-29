--[[
testing module: various helpers to reduce boilerplate when writing test scripts.
]]

local i = {}

i.test_harness_with_deps = function(testdata)
	local testvecs = testdata.testvecs
	local get_test_object = testdata.get_dep

	local total = #testvecs
	for index, vec in ipairs(testvecs) do
		local dep = get_test_object()
		ok, err = pcall(vec, dep)
		if (not ok) then
			error("test case "..index.."/"..total.." failure: "..tostring(err))
		end
	end
end

return i


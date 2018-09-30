-- helpers to create a parent namespace which is simply a table housing sub-namespaces.
local mk_helpers = function(loader)



-- manual and automatic capture subloaders
local create_subloader = (dofile(_modpath.."subloader.lua"))(loader)
local p = _modpath.."subloader_child_modules.lua"
local get_child_subloader = (dofile(p))(loader, create_subloader)



local dname = "mk_parent_ns_noauto() "
local mk_parent_ns_noauto_inner = function(list, subloader)
	local result = {}
	for _, sub in ipairs(list) do
		result[sub] = subloader(sub)
	end
	return result
end

local dname = "mk_parent_ns() "
local mk_parent_ns = function(list)
	local subloader = get_child_subloader()
	return mk_parent_ns_noauto_inner(list, subloader)
end

return {
	ns = mk_parent_ns,
	create_subloader = create_subloader,
	get_child_subloader = get_child_subloader,
}



end	-- function(loader)
return mk_helpers

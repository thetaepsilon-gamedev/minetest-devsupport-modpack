-- helpers to create a parent namespace which is simply a table housing sub-namespaces.
local mk_helpers = function(loader)



-- manual and automatic capture subloaders
local create_subloader = (dofile(_modpath.."subloader.lua"))(loader)
local p = _modpath.."subloader_child_modules.lua"
local get_child_subloader = (dofile(p))(loader, create_subloader)



local dname = "mk_parent_ns_noauto() "
local mk_parent_ns_noauto_inner = function(list, base, sep)
	local result = {}
	for _, sub in ipairs(list) do
		local subpath = base..sep..sub
		result[sub] = loader:get(subpath)
	end
	return result
end

local dname = "mk_parent_ns() "
local mk_parent_ns = function(list)
	local inflight, ptype = loader:get_current_inflight()
	if not inflight then error(dname.."must be invoked via dynamic loading of another file") end
	local sep = ptype.pathsep
	if not sep then error(dname.."auto path deduction failure: path type "..ptype.label.." doesn't support separator concatenation") end
	return mk_parent_ns_noauto_inner(list, inflight, sep)
end

return {
	ns = mk_parent_ns,
	create_subloader = create_subloader,
	get_child_subloader = get_child_subloader,
}



end	-- function(loader)
return mk_helpers

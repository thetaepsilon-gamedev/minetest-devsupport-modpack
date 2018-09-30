return function(loader)
	function mtrequire(path)
		return loader:get(path)
	end

	local nsauto = (dofile(_modpath.."nsauto.lua"))(loader)

	local modns = {
		get = mtrequire,
		mk_parent_ns = nsauto.ns,
		create_subloader = nsauto.create_subloader,
	}

	return modns
end

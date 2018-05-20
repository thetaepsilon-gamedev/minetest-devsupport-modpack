--[[
Loader object: explicit registration.
loader:register() allows mods to directly load a component from their init.lua,
as opposed to passive on-demand loading at a later time.
This is only really intended for mods which make use of e.g. hook registration in-game,
where it is more convienient to register hooks and create mod objects
that both access some common state.

Note that mods that register components this way will lose the propery of demand-loaded ones,
whereby other mods mtrequire()'ing them don't have to explictly declare dependencies.
In other words, if your mod uses modns.register() (see construct_interface.lua)
then other mods using it must declare it in their depends.txt like classic mods.
]]

local lift_revdata_to_modname = _common.lift_revdata_to_modname

local evprefix = "modns.loader.register."
local ev_runtime_reg = evprefix.."runtime_reg_banned"
local ev_missing_reserve_reg = evprefix.."unreserved_reg_banned"
local ev_reg_conflict = evprefix.."wrong_namespace_owner"

-- check if the invoking mod owns this namespace.
local validate_path_owner = function(self, parsedpath, _path)
	local currentmod = minetest.get_current_modname()
	if (currentmod == nil) then
		self.debugger({n=ev_runtime_reg, args={path=_path}})
		error("explicit registration was called at runtime, cannot check namespace owner")
	end

	-- look up the mod that owns this namespace,
	-- and compare it against the current one.
	local revdata, closestdepth = self.reservations:locateparsed(parsedpath.tokens)

	if (revdata == nil) then
		self.debugger({n=ev_missing_reserve_reg, args={
			invoker=currentmod,
			path=_path,
		}})
		error("no reservations for this path found, mod must reserve a namespace to register this path")
	end

	local modname = lift_revdata_to_modname(revdata)
	if (modname ~= currentmod) then
		self.debugger({n=ev_reg_conflict, args={
			invoker = currentmod,
			offending_path = _path,
			realowner = modname,
		}})
		error("mod " .. currentmod ..
			" tried to register in a namespace already claimed by " ..
			modname)
	end
	-- otherwise we're good to go
end

local loader_self_register = function(self, _path, component)
	-- firstly, again, determine if this path is valid.
	local m_paths = self.paths
	local parsed = m_paths.parse(_path, "explicit register path")

	-- next, we must determine if the calling mod has reserved this path.
	-- if not raise an error.
	validate_path_owner(self, parsed, _path)

	-- if all goes to plan, directly insert component into cache,
	-- which will cause the file loading logic to be bypassed
	-- (see getcomponent_nocopy() in loader.lua)
	self.cache[_path] = component
end

return loader_self_register


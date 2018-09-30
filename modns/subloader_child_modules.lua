-- A subloader which captures the currently-loaded module path,
-- such that a modns component can request a subloader for it's child components,
-- without having to explicitly state it's own implied path.
-- to be used like this:
--[[
-- only works while a component is being loaded:
local subloader = modns.get_child_subloader()
-- then use it like normal (see subloader.lua):
local my_child_component = subloader("child")
	-- or: subloader({"child", "in", "nested", "directory"})
]]
local msg_notloaded =
	"subloader can only be created while dynamically loading another component"
local msg_sep_pre = "get_subloader(): auto path deduction failure: path type "
local msg_set_post = " doesn't support separator concatenation"



local setup = function(loader, create_subloader)
	local get_child_subloader = function()
		local inflight, ptype = loader:get_current_inflight()
		if not inflight then
			error(msg_notloaded)
		end
		local sep = ptype.pathsep
		if not sep then
			error(msg_sep_pre .. ptype.label .. msg_sep_post)
		end

		return create_subloader(inflight, sep)
	end

	return get_child_subloader
end



return setup


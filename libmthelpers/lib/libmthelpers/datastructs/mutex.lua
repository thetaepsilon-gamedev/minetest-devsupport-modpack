local mklock = function()
	local interface = {}
	local locked = false
	
	interface.lock = function()
		if locked then error("duplicate lock!") end
		locked = true

		return function() locked = false end
	end
	interface.assert_unlocked = function()
		if locked then error("guard expected to be unlocked!") end
	end
	return interface
end

return mklock

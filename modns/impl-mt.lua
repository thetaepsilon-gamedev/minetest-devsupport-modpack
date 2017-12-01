-- MT-specific implementations of various dependencies of the loader logic.

-- will trigger an error early if not run under MT
local getmodpath = minetest.get_modpath

-- FIXME: I *still* don't know if this varies across OSes or if lua handles it.
local dirsep = "/"

-- io implementation for the reservation manager to read the relevant files from mod directories.
local modopen = function(self, modname, relpath)
	local sep = self.dirsep
	local path = self.mp(modname)
	if path == nil then return nil end
	return io.open(path..sep..relpath, "r")
end
local ioimpl = {
	dirsep=dirsep,
	mp=getmodpath,
	open=modopen,
}

-- getmodpath wrapper for the main loader object
local mp = function(self, modname) return getmodpath(modname) end
local modfinder = { get=mp }

return ioimpl, modfinder

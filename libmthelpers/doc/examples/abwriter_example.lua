#!/usr/bin/env lua5.1

local base = "com.github.thetaepsilon.minetest.libmthelpers.io.abwriter."
local LuaIOFileSystem =  mtrequire(base.."lua_io_filesystem")
local fs = LuaIOFileSystem(io)

local ABWriter = mtrequire(base.."mk")
local controller, handle = ABWriter(fs, "test", ".txt")

--print(ABWriter, handle)
local data
if handle then
	--print("content:")
	data = handle.read(4096)
	--print(data)
	handle.close()
end

local c = controller
local f = c.get_writer()
data = data or ""
f.write(data)
f.write("+\n")
f.close()


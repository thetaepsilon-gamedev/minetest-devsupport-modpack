-- IFileSystem for ABWriter: use lua I/O primitives (as weak as they are).
-- for now just throws on error.
-- to remain as portable as possible, the IO table is passed in.
-- this means it could be ported to environments lacking global I/O.

local n = "LuaIOFileSystem"
local msg_open = n .. " io.open() for read failed: "
local msg_seek = n .. " file:seek() failed: "
local msg_owrite = n .. " io.open() for write failed: "
local msg_trunc_open = n .. " io.open() for truncate failed: "

-- it is implied here that returned files match the interface
-- of those returned from standard lua io.*.
-- we otherwise don't need to do anything special as they are local to the handle
-- (the capability to operate on a file),
-- whereas lua's ambient global io table is a bit more problematic.
local seek_or_die = function(f, ...)
	local n, err = f:seek(...)
	if err then
		error(msg_seek .. err)
	end
	return n
end



-- I really need an implied "prelude" for these kinds of things...
local const = function(v) return function(...) return v end end

local construct_open_or_die = function(io)
	local _open = io.open
	local open_or_die = function(path, mode, msg)
		local f, err = _open(path, mode)
		if not f then
			error(msg .. err)
		end
		return f
	end
	return open_or_die
end



local construct_open_read_or_create = function(open_or_die)
	local open_read_or_create = function(path)
		-- technically we open the file in a+ mode (r/w + create if not exist),
		-- but we only pass back a read function.
		-- this also handily positions the (read) position at the start of file.
		local f = open_or_die(path, "a+", msg_open)

		-- needs read, close, size.
		-- size is a bit tricky because we'd need to manipulate the seek pos
		-- (or at least to determine file size in a portable manner anyhow),
		-- however as we only allow reads we can do this at the beginning.
		local sz = seek_or_die(f, "end")
		seek_or_die(f, "set", 0)

		local i = {}
		i.size = const(sz)
		i.read = function(...) return f:read(...) end
		i.close = function(...) return f:close(...) end
		return i
	end

	return open_read_or_create
end


local construct_open_write_truncate = function(open_or_die)
	local open_write_truncate = function(path)
		-- no need to support size here as the file will always be empty.
		local f = open_or_die(path, "w", msg_owrite)

		local i = {}
		i.write = function(...) return f:write(...) end
		i.close = function(...) return f:close(...) end
		return i
	end
	return open_write_truncate
end



local construct_truncate = function(open_or_die)
	local truncate = function(path)
		-- similar to the above but immediately close the file;
		-- opening in write mode always truncates anyway.
		local f = open_or_die(path, "w", msg_trunc_open)
		f:close()
	end
	return truncate
end



local construct = function(io)
	local o = construct_open_or_die(io)
	return {
		open_read_or_create = construct_open_read_or_create(o),
		open_write_truncate = construct_open_write_truncate(o),
		truncate = construct_truncate(o),
	}
end



return construct


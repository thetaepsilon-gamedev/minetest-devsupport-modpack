local member = function(obj, k)
	local member_function = obj[k]
	assert(type(member_function) == "function")
	return member_function
end

local isempty = function(IFile)
	local size = IFile.size()
	return size == 0
end

local raise_corruption_error = function(pa, pb)
	error("half-written files detected;" .. 
		" please inspect " .. pa .. " and " .. pb ..
		" to determine which file to keep," ..
		" then remove the other file.")
end





local determine_state = function(fa, fb, pa, pb)
	local za = isempty(fa)
	local zb = isempty(fb)
	local next_target, readfile

	if za then
		next_target = false	-- "0", next target is A
		if zb then
			-- both zero: new state, write A next.
			-- close both files as no useful data will remain.
			readfile = nil
			fa.close()
			fb.close()
		else
			-- A zero, B *not* zero, target A next and return B's data.
			readfile = fb
			fa.close()
		end
	else
		if zb then
			-- A *not* zero, B is zero. target B next, return A.
			next_target = true	-- "1", next target is B
			readfile = fa
			fb.close()
		else
			-- both non-zero? oh noes!
			raise_corruption_error(pa, pb)
		end
	end

	return next_target, readfile
end

local msg_dup = "ABWriter initial read file was used after being closed"





-- wrap the initial read handle so we can track it has been closed,
-- before allowing opens of the next file.
local const = function(v) return function(...) return v end end
local wrap_handle = function(readfile)
	-- don't hold up write access below if there was no file to begin with!
	if not readfile then return nil, const(false) end

	local open = true
	local _read = readfile.read
	local _close = readfile.close

	-- hacky overwrite time...
	local rethandle = readfile

	-- this method allows the handle to expose other interface functions,
	-- e.g. metadata, buffering modes etc.
	-- the caller *could* circumvent our wrappers,
	-- but then they'd get deadlocks because they "forgot" to use close ;)
	rethandle.close = function()
		assert(open, msg_dup)
		open = false
		_close()
	end
	rethandle.read = function(...)
		assert(open, msg_dup)
		return _read(...)
	end

	local isopen = function()
		return open
	end
	return rethandle, isopen
end





local m = member
local setup_writer_factory = function(IFileSystem)
	local truncate = m(IFileSystem, "truncate")
	local _get_writer = m(IFileSystem, "open_write_truncate")
	local inflight = false

	local get_writer_private = function(target, oldpath, ...)
		local writefile = _get_writer(target)
		inflight = true
		local _close = writefile.close

		-- when the file is closed, we want to indicate not to use the other.
		-- we do this by truncating it to zero length.
		local close = function()
			assert(inflight)
			_close()
			truncate(oldpath)
		end
		-- the parent constructor still wants to do some state stuff...
		return writefile, close
	end
	local iswriting = function() return inflight end

	return get_writer_private, iswriting
end





-- ### public interface follows ###



-- MT, why do you not have a freaking rename() call
local construct = function(IFileSystem, path, ext)
	-- I've been doing too much C# on the job... ;_;
	local t = type(IFileSystem)
	if t ~= "table" then
		error("ArgumentTypeException: IFileSystem")
	end

	assert(type(path) == "string")
	ext = ext or ".txt"
	assert(type(ext) == "string")
	local openc = m(IFileSystem, "open_read_or_create")

	-- there a few possible states here.
	-- due to lua stlib I/O limitations, we always open or create the files,
	-- as there no portable manner in which to tell apart e.g. ENOENT,
	-- and the third return value of io.open is somewhat non-standard.
	-- therefore we rely upon the sizes of the file (non-zero is not allowed).
	-- if both are zero, we are in new state.
	-- if A is non-zero and B is zero, then target B for writing next;
	-- in the inverse case, vice versa.
	-- if both are non-zero, it is likely a fatal crash occurred;
	-- in that case it is up to the sysadmin to try and fix the situation,
	-- as there is nothing we can do here.
	local pa = path..".a"..ext
	local pb = path..".b"..ext
	local fa = openc(pa)
	local fb = openc(pb)
	local next_target, readfile
	local flip = function()
		next_target = not next_target
	end
	local next_target_to_filename = function()
		-- second arg is the current file.
		local target = (next_target and pb or pa)
		local current = (next_target and pa or pb)
		return target, current
	end

	next_target, readfile = determine_state(fa, fb, pa, pb)
	-- at this point, one or both files are closed,
	-- and the remaining one removed.
	-- zero out those refs to prevent accidental use.
	fa, fb = nil, nil

	-- get a wrapped handle from the inner one (if any)
	-- and a closure to keep track of if the file is still open.
	-- we want to avoid problems with reading and writing at the same time
	-- present on some platforms (clobbering on unix, locks on windows).
	local rethandle, islocked = wrap_handle(readfile)

	local get_writer_private, iswriting = setup_writer_factory(IFileSystem)

	-- at this point we can return the handle and interface to the caller.
	-- the initial file handle is intended to be used for initial load;
	-- thereafter (after that first handle has been closed),
	-- period syncs back to disk can be performed by calling get_writer().
	-- the caller must handle the case of no returned file handle;
	-- in that event they must assume a default initial state.
	local public = {
		get_writer = function(...)
			-- this may be the read file's islocked here.
			if islocked() then
				error("ABWriter file still open!")
			end

			-- then we switch to write file for lock checks after
			islocked = iswriting
			local fn, fn2 = next_target_to_filename()
			local writefile, _close = get_writer_private(fn, fn2)
			local close = function()
				-- leaning tower of closes...
				_close()
				flip()
			end
			writefile.close = close
			return writefile
		end,
	}
	return public, rethandle
end



return construct



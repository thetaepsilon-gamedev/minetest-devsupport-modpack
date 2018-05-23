local interface = {}

local check = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.check")
local mkfnexploder = check.mkfnexploder
local mkrefcounter = check.mkrefcounter

local prettyprint = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.prettyprint")
local repstr = prettyprint.repstr

-- used to fallback to the MT API's get_us_time(),
-- but to enable portable use this has been scrapped.
local default_timer = function(timerfunc)
	if type(timerfunc) ~= "table" then error("profiler requires specifying a timer function!") end
end



-- creates a timed event.
-- returns an object that can either be used to stop the timer,
-- or retrieve a sub-event which runs within this event.
-- retrieving a sub-event after stopping the timer is considered an error.
-- when stopped, stores the resulting time delta and any sub-events in the store table,
-- and calls onstop() - for sub-events, this decrements the reference count.

local indirect = {}	-- lua why you no make a function visible inside it's own definition
local create_event = function(label, timerfunc, store, onstop)
	local stopped = false
	local subtable = {}
	local evindex = 1
	local refcount = mkrefcounter()
	local tstart, tstop

	local checkrefcount = function()
		local r =  refcount.get()
		if r ~= 0 then error("timer.stop() sub-event refcount not zero! ("..r..")") end
	end

	local interface = {}
	interface.stop = function()
		tstop = timerfunc()
		checkrefcount()

		store.label = label
		store.duration = tstop - tstart
		store.sub = subtable
		onstop()
	end
	interface.mksub = function(label)
		if tstop ~= nil then error("timer.mksub() called after timer stopped") end
		local store = {}
		subtable[evindex] = store
		evindex = evindex + 1
		refcount.increment()
		return indirect.create_event(label, timerfunc, store, refcount.decrement)
	end

	tstart = timerfunc()
	return interface
end
interface.create_event = create_event
indirect.create_event = create_event



-- creates a profiler object.
-- timing function defaults to using the MT one;
-- time elapsed is measured as the differences returned by this
-- (it does not need to return wall time and should preferably be monotonic).
local check = mkfnexploder("create_profiler")
local create_profiler = function(timerfunc)
	timerfunc = default_timer(timerfunc)
	check(timerfunc, "timer function")

	local evlist = {}
	local evindex = 1

	local interface = {}
	interface.create_root_event = function()
		local label = "root"
		local store = {}
		local finish = function()
			evlist[evindex] = store
			evindex = evindex + 1
		end
		return create_event(label, timerfunc, store, finish)
	end
	interface.results = function()
		return evlist
	end

	return interface
end
interface.create_profiler = create_profiler



local self = {}
local tab = "    "
local format_event = function(event)
	return event.label..tab..tostring(event.duration)
end
local print_profiler_stats = function(evlist, printer, indentlevel)
	if indentlevel == nil then indentlevel = 0 end
	local indent = repstr(tab, indentlevel)

	for index, entry in ipairs(evlist) do
		printer(indent..format_event(entry))
		self.f(entry.sub, printer, indentlevel + 1)
	end
end
interface.format_data = print_profiler_stats
self.f = print_profiler_stats



return interface

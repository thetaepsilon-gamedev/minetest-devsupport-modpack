--[[
Traces a ray in a grid using digital differential analysis (DDA):
the ray is continually stepped to the next whole node boundary
that will be crossed by the ray, until a desired node is found.
This is done by looking at the distance to the next boundary in each dimension,
looking for the shortest one, and moving the entire ray by that shortest one.
]]



local infinity = 1 / 0

-- where's muh non-strict
local undefined = function(variable, value)
	error("input value for variable "..variable..
		" gives undefined result: "..value)
end

-- compute the distance to the next node boundary.
-- funny cases to deal with here:
-- if we are e.g near the bottom of the node (let psy = 0.1)
-- but going up (sdy > 0), then we have nearly whole node (0.9) to go in Y;
-- however if going down, then we have 0.1 to go in Y.
-- exact boundaries (psy == 0) are weird
-- because they must return a whole node to go and not zero;
-- if they did return zero, then the next call would also return zero,
-- and we could end up stuck in an infinite loop not going anywhere - no bueno.
-- zero on the step vectors (e.g. sdx == 0) must also be considered;
-- here we just return a placeholder non-numerical value indicating this condition,
-- as working with that distance in that case wouldn't make sense.

local i = {}
-- note: assumes pstart is % 1.0!
local l = "pstart"
-- special value: checked for later
local nm = "notmoving"

local distance1d = function(pstart, sdirection)
	if pstart < 0 then return undefined(l, pstart) end
	if pstart >= 1.0 then return undefined(l, pstart) end
	if sdirection == 0 then return nm end

	-- if we're on a node boundary, it doesn't matter which way we're going,
	-- we have exactly one node to traverse next
	if pstart == 0 then return 1.0 end

	-- otherwise, we have an open (non-inclusive) interval (0, 1.0).
	-- if we're going +ve in this dimension,
	-- the distance remaining is 1 - pstart, else it is pstart.
	-- we know sdirection will not be zero here.
	return (sdirection > 0) and (1 - pstart) or pstart
end
i.distance1d = distance1d




-- note, this function isn't suitable for MT on it's own -
-- it assumes that voxel boundaries are at whole integers,
-- not at .5's with .0's at the centre of nodes like MT does.
local d1di = function(...)
	local v = distance1d(...)
	-- return infinity if there is no movement in a given direction,
	-- making it get least precedence in the min() calls below.
	return (v == nm) and infinity or v
end
local min = math.min

--[[
parameters:
* _ps* (point start) are the coordinates of the ray starting point.
* sd* (speed direction) are the components of the ray's movement vector.
* tmax is a "maximum time" the ray can move (see comment in function)
returns:
three components of new position, consumed "time" to move ray
]]
local step_ray = function(_psx, _psy, _psz, sdx, sdy, sdz, tmax)
	assert((sdx ~= 0) or (sdy ~= 0) or (sdz ~= 0), "this ray will never move!")

	-- the ps* (position start) variables are modulo'd
	-- to their positions inside the node cube
	local psx = _psx % 1.0
	local psy = _psy % 1.0
	local psz = _psz % 1.0

	-- get the distances remaining to the next whole node on each axis,
	-- scaling them by their ray velocity -
	-- this will make dimensions with higher velocity more favourable.
	-- (NB this technically returns a time remaining: time = distance / speed)
	local trx = d1di(psx, sdx) / sdx
	local try = d1di(psy, sdy) / sdy
	local trz = d1di(psz, sdz) / sdz
	-- get the mininum side's time remaining.
	-- note that not-moving dimensions will end up with time remaining = infinity.
	-- however, we shouldn't get infinity as long as one of the ray components is non-zero.
	local trshortest = min(trx, min(try, trz))
	assert(trshortest ~= infinity)

	-- the optional tmax parameter to this function
	-- can optionally be used to specify a time limit.
	-- if trshortest is greater than this,
	-- the ray is only moved proportional to tmax.
	-- this could be used to e.g. specify dtime limits for an entity's ray.
	tmax = tmax or infinity
	local tmoved = math.min(trshortest, tmax)

	-- scale the ray velocity vector by movement time, giving a distance.
	-- this when added to the starting point will yield a point,
	-- if it was trshortest, this point will end up on a node boundary.
	local ddx = sdx * tmoved
	local ddy = sdy * tmoved
	local ddz = sdz * tmoved

	local prx = psx + ddx
	local pry = psy + ddy
	local prz = psz + ddz
	return prx, pry, prz, tmoved
end
i.step_ray = step_ray



return i


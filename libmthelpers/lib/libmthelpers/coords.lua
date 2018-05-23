local coords = {}

coords.format = function(vec, sep, start, tail)
	sep = sep or ","
	start = start or "("
	tail = tail or ")"

	local coord = function(val)
		local valtype = type(val)
		local ret = ""
		if valtype == nil then
			ret = "???"
		elseif valtype == "number" then
			ret = tostring(val)
		else
			ret = "<NaN>"
		end
		return ret
	end

	return start..coord(vec.x)..sep..coord(vec.y)..sep..coord(vec.z)..tail
end

coords.adjacent_offsets = {
	{x= 1,y= 0,z= 0},
	{x=-1,y= 0,z= 0},
	{x= 0,y= 1,z= 0},
	{x= 0,y=-1,z= 0},
	{x= 0,y= 0,z= 1},
	{x= 0,y= 0,z=-1},
}
local diagonals = {}
for x = -1, 1, 1 do
for y = -1, 1, 1 do
for z = -1, 1, 1 do
	if not (x == 0 and y == 0 and z == 0) then
		--print("x="..x.." y="..y.." z="..z)
		table.insert(diagonals, {x=x,y=y,z=z})
	end
end
end
end
coords.neighbour_offsets = diagonals



-- minetest's rounding of coords to nodes goes something like the following
-- (for each axis n in x, y, z):
-- * -0.5 < n < 0.5 (non-inclusive) rounds to node 0
-- * node t = (t-0.5) <= n < (t+0.5) for n > 0.5 and t > 0
-- * node t = (t-0.5) < n <= (t+0.5) for n < -0.5 and t < 0
-- this means that 0,0.5,0 is considered part of node 0,1,0,
-- and that 0,-0.5,0 is considered part of node 0,-1,0.
local positive = function(x) return (x > 0) end
local center = function(x)
	if positive(x) then
		-- x=0.5, math.floor(0.5+0.5) = math.floor(1.0) = 1.0
		return math.floor(x+0.5)
	else
		-- x=-0.5, math.ceil(-0.5 + -0.5) = math.ceil(-1.0) = -1.0
		return math.ceil(x-0.5)
	end
end
coords.round_axis_to_node = center

local center_on_node = function(v)
	local result = {}
	result.x = center(v.x)
	result.y = center(v.y)
	result.z = center(v.z)
	return result
end
coords.round_to_node = center_on_node




return coords

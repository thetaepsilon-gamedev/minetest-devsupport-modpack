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

local center_on_node_raw = function(x, y, z)
	local rx = center(x)
	local ry = center(y)
	local rz = center(z)
	return rx, ry, rz
end
coords.round_to_node_raw = center_on_node_raw

local center_on_node = function(v)
	local rx, ry, rz = center_on_node_raw(v.x, v.y, v.z)
	return {x=rx,y=ry,z=rz}
end
coords.round_to_node = center_on_node

-- mutating version if you're *absolutely sure* the original table isn't going to be used again...
coords.round_to_node_mut = function(v)
	local rx, ry, rz = center_on_node_raw(v.x, v.y, v.z)
	v.x = rx
	v.y = ry
	v.z = rz
	return v
end



-- identify which world chunk a given arbitary position is in.
-- as this is not a normal world position,
-- x y and z of the chunk (not world space coordinates!) are return separately.
local get_chunk_axis = function(axis)
	-- may be e.g. -0.3 but still in the 0,0,0 block
	local nodev = center(axis)
	return math.floor(axis / 16)
end
local gca = get_chunk_axis
local get_chunk_xyz = function(pos)
	return gca(pos.x), gca(pos.y), gca(pos.z)
end
coords.get_chunk_xyz = get_chunk_xyz



return coords

-- A block which will indicate which side it thinks was clicked,
-- by using a small particle effect.

-- vector bits
local pv = "ds2.minetest.vectorextras."
local unwrap = mtrequire(pv.."unwrap")
local wrap = mtrequire(pv.."wrap")
local vmult = mtrequire(pv.."scalar_multiply").raw
local vadd = mtrequire(pv.."add").raw
--local whichside = mtrequire(pv.."which_side").raw
local m_solve = mtrequire(pv.."cube_intersect_solve")
local solve = m_solve.solve_ws_raw

-- particle effects to indicate the detected face.
local m_particles = modtable("ds2.minetest.particleeffects")

local bprops = {time=0.5}
local spawner = m_particles.point_indicator.mk({"FFFFFF"}, bprops)
local fire_particles = function(pos)
	return spawner(minetest, pos)
end
local face_indicator = m_particles.point_indicator.mk({"FF4040"}, bprops)
local fire_face_indicator = function(pos)
	return face_indicator(minetest, pos)
end



-- note to self, this could change in 5.0...
local head = 1.625
local w = 0.5
local prn = minetest.chat_send_all
local vec3 = vector.new
local offsets = m_solve.enum_offsets
on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
	if clicker:is_player() then
		local ex, ey, ez = unwrap(pos)
		local cx, cy, cz = unwrap(clicker:get_pos())
		cy = cy + head

		local look = clicker:get_look_dir()
		local lx, ly, lz = unwrap(look)

		local rx, ry, rz, es, ef =
			solve(cx, cy, cz, lx, ly, lz, ex, ey, ez, w, w, w)
		if rx == nil then return end

		fire_particles(wrap(rx, ry, rz))
		local face = es..ef
		prn("face: "..face)

		local offset = offsets[face]
		local sidepos = vector.add(pos, offset)
		fire_face_indicator(sidepos)
	end
end



local mn = minetest.get_current_modname()
local n = mn..":block"
local tex = "whichside_block.png"
minetest.register_node(n, {
	description = "Which side did you click?",
	tiles = {tex},
	on_rightclick = on_rightclick,
})


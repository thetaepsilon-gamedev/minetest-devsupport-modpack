--[[
unit vector normalisation:
takes an input vector I, and returns a "unit vector" U
which points in the same direction as I, but has a length of exactly 1.
additionally returns the length L of U,
such that U scalar multiplied by L would give the original vector I.
]]

local bp = "ds2.minetest.vectorextras."
local m_len = mtrequire(bp.."magnitude")
local length = m_len.raw
local m_mult = mtrequire(bp.."scalar_multiply")
local scale = m_mult.raw
-- NB: currently lacking wrapped variant!

local i = {}

-- returns: x, y, z, length
local normalise_raw = function(ix, iy, iz)
	-- in awe at the size of this lad
	local len = length(ix, iy, iz)
	local s = 1 / len
	-- absolute unit
	local ux, uy, uz = scale(s, ix, iy, iz)

	return ux, uy, uz, len
end
i.raw = normalise_raw

return i


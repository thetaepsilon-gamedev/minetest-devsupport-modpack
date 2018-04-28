#!/usr/bin/env lua5.1

local m_fold = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.functional.fold")

local t = { 1, 2, 3, 4, 5 }
local foldl = m_fold.efoldln(1)

local op = m_fold.op

local r = foldl(m_fold.agen(t), op.add, 0)
--print(r)
assert(r:unwrap() == 15)



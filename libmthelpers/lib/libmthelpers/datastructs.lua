local datastructs = {}
datastructs.new = {}
datastructs.selftest = {}



-- FIFO queue structure
local qi = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.datastructs.queue")
datastructs.new.queue = qi.new

-- mutual exclusion lock.
-- used in the set structures to provide transactional batch add/removes.
local mklock = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.datastructs.mutex")
datastructs.new.mutex = mklock



-- a "set" structure.
-- allows adding objects, removing them by value, and iterating through them.
local tsi = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.datastructs.tableset")
datastructs.tableset = tsi

-- backwards compat aliases...
datastructs.new.tableset = tsi.new
datastructs.new.generic_set = tsi.mk_generic

-- alias to old set for backwards compat...
datastructs.new.set = tsi.mk_unique



-- other structures, see their respective files
local subloader = modns.get_child_subloader()
datastructs.guardedmap = subloader("guardedmap")
datastructs.matrix = subloader("matrix")
datastructs.handler_lut = subloader("handler_lut")
datastructs.regtable = subloader("regtable")
datastructs.proxy = subloader("proxy")
datastructs.sentinel = subloader("sentinel")



return datastructs

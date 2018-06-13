local random = mtrequire("com.github.thetaepsilon.minetest.libmthelpers.random")
local base64_ = random.base64_
assert(type(base64_) == "function")


-- I'm not going to throw high levels of statistical testing at this.
-- collisions can occasionally happen when only asking for 1 char
for n = 2, 10, 1 do
	local gen = base64_(n)
	assert(type(gen) == "function")
	local seen = {}

	for i = 1, 10, 1 do
		local rand = gen()
		--print(rand)

		-- at the very least, random strings shouldn't clash.
		assert(type(rand) == "string")
		assert(seen[rand] == nil)
		seen[rand] = true
	end
end


local stats={}

local node_modname = function(key, value)
	local start,_ = string.find(key, ":")
	-- if no colon found, it's probably air, which doesn't really belong to a mod.
	if start ~= nil then
		return string.sub(key, 1, start-1)
	else
		return nil
	end
end



local count_buckets = function(input, bucketfunc)
	local results={}
	local bucketed = {}
	local misc = {}
	local total = 0
	local total_with_nobucket = 0

	for key, value in pairs(input) do
		total_with_nobucket = total_with_nobucket + 1
		local bucket = bucketfunc(key, value)

		if bucket ~= nil then
			total = total + 1
			local currentcount=results[bucket]

			if currentcount == nil then
				currentcount = 1
			else
				currentcount = currentcount + 1
			end

			results[bucket] = currentcount

			local btable = bucketed[bucket]
			if btable == nil then
				btable = {}
				bucketed[bucket] = btable
			end
			btable[key] = value
		else
			misc[key] = value
		end
	end

	return results, { count=total, with_nobucket=total_with_nobucket}, bucketed, misc
end
stats.count_buckets = count_buckets



local nodes_by_modname = function(nodemap)
	if type(nodemap) ~= "table" then error("stats nodes_by_modname() expected to be passed registered nodes table") end
	return count_buckets(nodemap, node_modname)
end
stats.nodes_by_modname = nodes_by_modname



local show_bucket_counts = function(printer, input, bucketfunc, formatter)
	if not formatter then formatter = function(k, v) return k..": "..v end end

	local results, totals, bucketed, misc = count_buckets(input, bucketfunc)
	for name, value in pairs(results) do
		printer(formatter(name, value))
	end
	printer("-- total: "..totals.count)
	printer("-- total including uncategorised: "..totals.with_nobucket)
	return results, totals, bucketed, misc
end
stats.show_bucket_counts = show_bucket_counts



local show_nodes_by_modname = function(printer, nodemap)
	return show_bucket_counts(printer, nodemap, node_modname, nil)
end
stats.show_nodes_by_modname = show_nodes_by_modname



stats.increment_counter = function(t, countername)
	local count = t[countername]
	if count == nil then count = 0 end
	count = count + 1
	t[countername] = count
end

return stats

-- filter out common success messages so as to reduce log noise.
local list = {
	"modns.reservation",

	"modns.loader.owning_mod_located",
	"modns.loader.cache_hit",
	"modns.loader.cache_miss",
	"modns.loader.attempt_load_component",
	"modns.loader.mod_path_found",
	"modns.loader.component_file_found",
}

local map = {}
for _, item in ipairs(list) do
	map[item] = true
end

return map

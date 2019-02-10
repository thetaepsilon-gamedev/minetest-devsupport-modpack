local interface = {}
interface.patterns = {}

local strutil = dofile(_modpath.."strutil.lua")

-- component type matching
-- return an enum identifier depending on classification.
local enum_pathtype = {}
interface.enum_pathtype = enum_pathtype



-- URI scheme test
-- pattern match information based on IETF RFC3986
-- we don't support hierachical splitting for URIs,
-- as if a URL like http://github.com/... is used,
-- adding sub-component paths would likely form an invalid URL.
-- (e.g. github often requires /blob/master/... inserted to access a file)
local safeschemechar = "[a-zA-Z0-9+.-]"
local safeurichar = "[a-zA-Z0-9+.%/_-]"
local schemepart = "[a-z]"..safeschemechar.."*:"
local urimatch = "^"..schemepart..safeurichar.."*$"
interface.patterns.urimatch = urimatch
-- strip the scheme and hierachial indicator (the "//") if present
local uri_handler = function(path)
	local stripcount
	path = path:gsub("^"..schemepart, "", 1)
	-- The RFC says that // after scheme: is used to indicate hierachical URIs.
	-- if one is used, make a note of it's removal so we can split the path.
	path, stripcount = path:gsub("^//", "", 1)
	local hier = (stripcount == 1)
	if #path == 0 then return nil end
	-- a single / above would not have been stripped.
	-- // is only legal after the "scheme:" to indicate hierachial URIs.
	-- generally also the first URI component won't begin with a dot.
	if not path:match("^[a-zA-Z0-9]") then return nil end
	if not hier then
		-- should not be any more slashes if the URI is non-hierachical.
		if path:find("/") then return nil end
		return { path }
	else
		return strutil.split(path, "/", true)
	end
end
local uri_tostring = function(path, length) return table.concat(path, "/", 1, length) end
enum_pathtype.uri = {
	label="uri",
	matchpattern=urimatch,
	handler=uri_handler,
	tostring=uri_tostring,
	pathsep="/",
}



-- java-style package names.
-- we can't specify * on () in lua patterns.
-- and we can't have any external deps when *we are* the dependency loader.
-- instead, use a simpler initial test and validate more closely by splitting and checking the package levels.
local javamatch = "^[a-zA-Z][a-zA-Z0-9_.]*$"
interface.patterns.javamatch = javamatch
local java_handler = function(path)
	local tokens = strutil.split(path, ".", true)
	if #tokens < 1 then return nil end
	for _, token in ipairs(tokens) do
		if #token == 0 then return nil end
		-- note absence of dot separator
		if token:find("^[a-zA-Z][a-zA-Z0-9_]*$") == nil then return nil end
	end
	return tokens
end
local java_tostring = function(path, length)
	return table.concat(path, ".", 1, length)
end
enum_pathtype.java = {
	label="java",
	matchpattern=javamatch,
	handler=java_handler,
	tostring=java_tostring,
	pathsep=".",
}



-- classify a path by looking for different path pattern types.
-- if this succeeds, a hierachical list of tokens is returned.
local classifypath = function(path, label)
	if not label then label = "component path" end
	if type(path) ~= "string" then error(label.." must be a string") end
	for _, enum in pairs(enum_pathtype) do
		if path:find(enum.matchpattern) == 1 then
			-- run the handler function to check that the initial classification check was correct.
			local result = enum.handler(path)
			if type(result) == "table" then return { type=enum, tokens=result } end
		end
	end
	error(label.." "..string.format("%q", path).." did not match any known types of component path")
end
interface.parse = classifypath



--[[
get the suffix of a path after a certain number of base elements.
returns a new path containing just those suffix tokens,
or nil and an error identifier.
]]
local tail = function(path, n)
	local len = #path
	if n > len then return nil, "EOUTOFBOUNDS" end

	local tpos = 1
	local ret = {}
	for i = n + 1, len, 1 do
		ret[tpos] = path[i]
		tpos = tpos + 1
	end
	return ret
end
interface.tail = tail

--[[
split a path (just the tokens table) into two new ones,
where the number of elements in the first path is specified by n,
and the second path contains whatever remained after.
returns either a table { prefix = path1, suffix = remainder }
or nil and an error identifier (e.g. n was > length of path)
]]
local split = function(path, n)
	local len = #path
	if n > len then return nil, "EOUTOFBOUNDS" end
	local prefix = {}
	local suffix = {}

	for i = 1, n, 1 do
		prefix[i] = path[i]
	end

	local ipos = 1
	for i = n + 1, len, 1 do
		suffix[ipos] = path[i]
		ipos = ipos + 1
	end

	return { prefix = prefix, suffix = suffix }
end
interface.split = split



return interface

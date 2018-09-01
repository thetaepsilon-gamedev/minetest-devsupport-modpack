-- various string helpers that really ought to be in the default string table...
local i = {}





--[[
Look for the first occurrence of a given pattern
(as supported by string.find) inside of str, and returns either:
* before, match, after if the pattern is found:
	before is the substring before the found match,
	match itself is the substring range returned by string.find,
	after is the substring after the range of the match.
* nil, nil, nil if no match was found.

initpos is the "init" parameter passed to string.find,
plainmode is the "plain" parameter to string.find controlling pattern mode.
This effectively makes the parameters to split_once the same as string.find.
NB: any captures returned by string.find due to the pattern are ignored.

split_once :: String -> String -> Integer -> Bool -> Maybe (String, String, String)
]]
local find = string.find
local substr = string.sub
local split_once = function(str, pattern, initpos, plainmode)
	local pstart, pend = find(str, pattern, initpos, plainmode)
	if pstart == nil then return nil, nil, nil end

	local before = substr(str, 1, pstart-1)
	local match = substr(str, pstart, pend)
	local after = substr(str, pend+1)
	return before, match, after
end
i.split_once = split_once

-- partially applied version of the above for convenience with fixed parameters.
local split_once_ = function(pattern, initpos, plainmode)
	-- early checking of parameters in case they raise errors later.
	assert(type(pattern) == "string")
	-- string.sub is actually tolerant of fractional numbers...
	assert(type(initpos) == "number")
	-- likewise it tolerates non-boolean things for plain flag, so leave it

	return function(str)
		return split_once(str, pattern, initpos, plainmode)
	end
end
i.split_once_ = split_once_



return i


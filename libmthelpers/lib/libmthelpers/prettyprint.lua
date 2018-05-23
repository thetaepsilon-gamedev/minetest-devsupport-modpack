-- object pretty printing
prettyprint = {}

-- no-op left over from debugging.
-- I might re-add this at some point if it shows use.
--[[
local debugprint = function(msg)
	print("## "..msg)
end
]]
local debugprint = function(msg)
	-- no-op
end

local repstr = function(base, count)
	base = tostring(base)
	count = tonumber(count) or 0
	local ret = ""
	for i = 1, count, 1 do
		ret = ret..base
	end
	return ret
end
prettyprint.repstr = repstr

-- forward declaration for cyclic recursive calling
local tabletostring

local valuetostring = function(obj, label, level, recurselimit, visited, multiline, indentlevel, indentstr)
	local valtype = type(obj)
	if valtype == "string" then
		return "\""..tostring(obj).."\""
	elseif valtype == "table" then
		debugprint(tostring(obj))
		if level >= recurselimit then
			debugprint(label.." would exceed recursion limit, skipping")
			return tostring(obj)
		else
			local cyclelabel = visited[obj]
			if not cyclelabel then
				-- make a note of this object being visited to avoid cycle loops
				visited[obj] = label
				debugprint(label.." is an unvisited table, recursing.")
				return tabletostring(obj, label, level+1, recurselimit, visited, multiline, indentlevel, indentstr)
			else
				debugprint(label.." already encountered, skipping.")
				return tostring(obj).." -- "..cyclelabel
			end
		end
	else
		return tostring(obj)
	end
end



-- handle tables in particular, calling valuetostring() on each.
-- this and the above call each other recursively.
-- NB declared local above
tabletostring = function(t, label, level, recurselimit, visited, multiline, indentlevel, indentstr)
	local recordsep
	if multiline then
		recordsep = "\n" .. repstr(indentstr, indentlevel+1)
	else
		recordsep = " "
	end
	local kvsep = " = "

	local ret = "{"
	local first = true
	for key, value in pairs(t) do
		-- print comma after preceding item if not the first
		if first then first = false else
			ret = ret .. ","
		end
		ret = ret .. recordsep
		local valuestr = valuetostring(value, label.."."..key, level, recurselimit, visited, multiline, indentlevel+1, indentstr)
		ret = ret..key..kvsep..valuestr
	end
	if multiline then
		ret = ret.."\n"..repstr(indentstr, indentlevel)
	else
		ret = ret .. " "
	end
	ret = ret.."}"
	return ret
end



-- format an object in a canonical form for logs etc.
-- note that this is not advisable to call on large tables,
-- such as the minetest global.
-- doing so tends to lead to out-of-memory errors.
local formatobj = function(obj, label, recurselimit, multiline, indentstr)
	recurselimit = recurselimit or 4
	return valuetostring(obj, label, 0, recurselimit, {}, multiline, 0, indentstr)
end
prettyprint.format = formatobj

-- defaults for multi-line printing.
-- multiple spaces are used as the indent,
-- as chat output via the luacmd mod's print() doesn't give tabs a sane size.
prettyprint.format_multiline = function(obj, label, recurselimit)
	return formatobj(obj, label, recurselimit, true, "    ")
end



-- visual representation of a passed object.
local format_value = function(v)
	if type(v) == "string" then
		return string.format("%q", v)
	else
		return tostring(v)
	end
end
prettyprint.format_value = format_value

-- varargs print formatting:
-- prints out all passed values in a visually distinct way with sep cat'd between them.
local function vsfmt_r(sep, v, ...)
	local result = format_value(v)
	if select("#", ...) > 0 then
		result = result..sep..vsfmt_r(sep, ...)
	end
	return result
end
local vsfmt = function(sep, ...)
	if select("#", ...) > 0 then
		return vsfmt_r(sep, ...)
	else
		return ""
	end
end
prettyprint.vsfmt = vsfmt

-- sane default separator.
-- the MT console unfortunately doesn't do tabs correctly...
-- so a fixed-size whitespace will have to do.
local tab = "        "
prettyprint.vfmt = function(...) return vsfmt(tab, ...) end



return prettyprint

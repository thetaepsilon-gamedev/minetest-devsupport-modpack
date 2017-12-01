local interface = {}

interface.split = function(str, sep, plainmode)
	-- why does this not exist as a lua built-in...
	local tokens = {}
	local position = 1
	local stop = false
	while not stop do
		local istart, iend = str:find(sep, position, plainmode)
		local token
		if istart == nil then
			token = str:sub(position)
			stop = true
		else
			token = str:sub(position, istart-1)
			position = iend+1
		end
		if token == "" then error("null components not allowed in component path!") end
		table.insert(tokens,  token)
	end

	return tokens
end

-- byte iterator from a string.
-- each iteration retrieves the next byte as a distinct string.
local iterator_fn = function(self)
	local index = self.index
	local o = self.original
	if index > #o then return nil end

	self.index = index + 1
	return o:sub(index, index)
end
local mk_byte_iterator = function(str)
	return iterator_fn, { index=1, original=str }
end
interface.mk_byte_iterator = mk_byte_iterator

-- string "escaper".
-- characters that don't match a valid range are escaped using the escape char
-- (which must NOT appear in the allowed set),
-- by writing the escape char followed by the byte's hex code to the resulting string.
local escape = function(str, validset, escapechar)
	local result = ""
	for char in mk_byte_iterator(str) do
		local encoded
		if not char:match(validset) then
			local code = char:byte(1, 1)
			encoded = string.format("%s%02x", escapechar, code)
		else
			encoded = char
		end
		result = result..encoded
	end
	return result
end
interface.escape = escape

return interface

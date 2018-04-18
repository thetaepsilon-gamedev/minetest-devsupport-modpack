--[[
Matrix: the mathematical kind
basic matrix structure and primitive operations,
as well as an operation to convert to a MT xyz vector table,
in the specific case of a 1x3 column vector.
]]

local i = {}

local calculate_matrix_index = function(h, w, y, x)
	-- 1-based indexing strikes again...
	return (((y - 1) * w) + (x - 1)) + 1
end
-- NB: long and wonky on purpose, but may be useful in certain cases.
i.__calculate_matrix_index = calculate_matrix_index

local getsize = function(self)
	return self.__y, self.__x
end

local add_sz = function(matrix, x, y)
	matrix.__x = x
	matrix.__y = y
	matrix.get_size = getsize
end

-- pre-declare constructor for operations which create new matrices
local mk_uninit

-- check that a matrix's values are correctly initialised.
local n = "assert_initialised()"
local assert_initialised = function(matrix)
	local height, width = matrix:get_size()
	local total = height * width
	for i = 1, total, 1 do
		assert(matrix[i] ~= nil,
			n..": element "..i.."of "..height.."*"..width..
			" matrix was not present")
	end
	return matrix
end

-- matrices are typically immutable so this isn't yet a public member.
local checkinrange = function(upper, v, label)
	assert(((v >= 1) and (v <= upper)),
		"matrix "..label.." index out of bounds, expected range " .. 
		"1-"..upper..", got "..v)
	return v
end
local assign_element = function(matrix, __y, __x, v)
	local height, width = matrix:get_size()
	local y = checkinrange(height, __y, "Y")
	local x = checkinrange(width, __x, "X")
	matrix[calculate_matrix_index(height, width, y, x)] = v
end

-- bounds-checking index operation
local index = function(self, __y, __x)
	local height, width = self:get_size()
	local y = checkinrange(height, __y, "Y")
	local x = checkinrange(width, __x, "X")
	local v = self[calculate_matrix_index(height, width, y, x)]
	assert(v ~= nil, "insanity condition: matrix value was nil")
	return v
end

local err_wrong_size = "incompatible matrix dimensions: "
local matrix_multiply = function(self, other)
	--[[
	       [ b b b b ]
	       [ b b b b ]
	[ a a ][ c c c c ]
	[ a a ][ c c c c ]
	[ a a ][ c c c c ]
	]]
	local ha, wa = self:get_size()
	local hb, wb = other:get_size()
	assert(wa == hb,
		err_wrong_size.."matrix A of width " .. wa ..
		" expected B of same height, got "..hb)
	-- number of multiply-then-add operations per matrix element
	local oplen = wa

	local wr = wb
	local hr = ha
	local result = mk_uninit(hr, wr)
	for y = 1, hr, 1 do
		for x = 1, wr, 1 do
			local total = nil
			local first = true
			for i = 1, oplen, 1 do
				local v = (self:index(y, i) * other:index(i, x))
				total = first and v or (total + v)
				first = false
			end
			assert(total ~= nil, "insanity condition: no additions in matrix multiply!?")
			assign_element(result, y, x, total)
		end
	end
	return assert_initialised(result)
end

-- boolean equality operator:
-- checks matrix is the same size as another, and same values inside
local array_matches = function(a, b, length)
	for i = 1, length, 1 do
		if a[i] ~= b[i] then return false end
	end
	return true
end
local function operator_eq(self, other)
	local ha, wa = self:get_size()
	local hb, wb = other:get_size()
	local matches = (ha == hb) and (wa == wb)
	return matches and array_matches(self, other, ha * wa)
end

clone = function(self)
	local y, x = self:get_size()
	local c = mk_uninit(y, x)
	for i = 1, y*x, 1 do
		c[i] = self[i]
	end
	return assert_initialised(c)
end



local add_methods = function(matrix, x, y)
	-- get_size(): returns height, width (*in that order*)
	add_sz(matrix, x, y)
	-- index accessor
	matrix.index = index
	-- multiply_m: matrix multiplication (throws if sizes incompatible)
	matrix.multiply_m = matrix_multiply
	-- equals: check one matrix equals another
	matrix.equals = operator_eq
	-- clone operator
	matrix.clone = clone
end

local msg_dim = " dimension for matrix should be positive"
-- NB: matrices are specified in number of rows first!
mk_uninit = function(y, x)
	assert(x > 0, "x"..msg_dim)
	assert(y > 0, "y"..msg_dim)

	local result = {}
	add_methods(result, x, y)
	return result
end

mk = function(y, x, values)
	local result = mk_uninit(y, x)

	local size = x * y
	local desc = x .. "*" .. y
	local actual = #values
	assert(actual == size, desc.." matrix requires "..size.." values, got "..actual)
	for i = 1, x*y, 1 do
		result[i] = values[i]
	end

	return assert_initialised(result)
end
i.new = mk

-- primitive display routine, can't always guarantee a monospace terminal output.
i.primitive_print = function(matrix, printer)
	local height, width = matrix:get_size()
	for y = 1, height, 1 do
		local notfirst = false
		local row = ""
		for x = 1, width, 1 do
			--print(y, x)
			local sep = notfirst and ", " or ""
			row = row .. sep .. matrix:index(y, x)
			notfirst = true
		end
		printer(row)
	end
end

-- conversions to and from minetest XYZ vector tables.
-- the matrix equivalent of an XYZ vector is a 3x1 "column matrix".
i.to_xyz = function(matrix)
	local height, width = matrix:get_size()
	assert((height == 3) and (width == 1),
		"only 3x1 column matrices can be converted to a vector")
	return { x=matrix[1], y=matrix[2], z=matrix[3] }
end
local check_component = function(vec, k)
	local v = vec[k]
	local t = type(v)
	assert(t == "number",
		"xyz_to_matrix(): " .. k ..
		" component in vector table expected to be a number, got " .. t)
	return v
end
i.from_xyz = function(vector)
	local x = check_component(vector, "x")
	local y = check_component(vector, "y")
	local z = check_component(vector, "z")
	return mk(3, 1, {x, y, z})
end

return i


-- optimised param2 rotation functions.
-- please note, these were machine generated.

local rotation_functions = {}

rotation_functions[0] = function(v)
	return { x = v.x, y = v.y, z = v.z,  }
end

rotation_functions[1] = function(v)
	return { x = v.z, y = v.y, z = ( -v.x ),  }
end

rotation_functions[2] = function(v)
	return { x = ( -v.x ), y = v.y, z = ( -v.z ),  }
end

rotation_functions[3] = function(v)
	return { x = ( -v.z ), y = v.y, z = v.x,  }
end

rotation_functions[4] = function(v)
	return { x = v.x, y = ( -v.z ), z = v.y,  }
end

rotation_functions[5] = function(v)
	return { x = v.z, y = v.x, z = v.y,  }
end

rotation_functions[6] = function(v)
	return { x = ( -v.x ), y = v.z, z = v.y,  }
end

rotation_functions[7] = function(v)
	return { x = ( -v.z ), y = ( -v.x ), z = v.y,  }
end

rotation_functions[8] = function(v)
	return { x = v.x, y = v.z, z = ( -v.y ),  }
end

rotation_functions[9] = function(v)
	return { x = v.z, y = ( -v.x ), z = ( -v.y ),  }
end

rotation_functions[10] = function(v)
	return { x = ( -v.x ), y = ( -v.z ), z = ( -v.y ),  }
end

rotation_functions[11] = function(v)
	return { x = ( -v.z ), y = v.x, z = ( -v.y ),  }
end

rotation_functions[12] = function(v)
	return { x = v.y, y = ( -v.x ), z = v.z,  }
end

rotation_functions[13] = function(v)
	return { x = v.y, y = ( -v.z ), z = ( -v.x ),  }
end

rotation_functions[14] = function(v)
	return { x = v.y, y = v.x, z = ( -v.z ),  }
end

rotation_functions[15] = function(v)
	return { x = v.y, y = v.z, z = v.x,  }
end

rotation_functions[16] = function(v)
	return { x = ( -v.y ), y = v.x, z = v.z,  }
end

rotation_functions[17] = function(v)
	return { x = ( -v.y ), y = v.z, z = ( -v.x ),  }
end

rotation_functions[18] = function(v)
	return { x = ( -v.y ), y = ( -v.x ), z = ( -v.z ),  }
end

rotation_functions[19] = function(v)
	return { x = ( -v.y ), y = ( -v.z ), z = v.x,  }
end

rotation_functions[20] = function(v)
	return { x = ( -v.x ), y = ( -v.y ), z = v.z,  }
end

rotation_functions[21] = function(v)
	return { x = ( -v.z ), y = ( -v.y ), z = ( -v.x ),  }
end

rotation_functions[22] = function(v)
	return { x = v.x, y = ( -v.y ), z = ( -v.z ),  }
end

rotation_functions[23] = function(v)
	return { x = v.z, y = ( -v.y ), z = v.x,  }
end

return {
	funcs = rotation_functions,
}


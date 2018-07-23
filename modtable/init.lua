local mods = {}

local err = "long mod names must be strings"
local pre = "duplicate registration for mod: "
local add = function(name, obj)
  assert(type(name) == "string", err)
  if mods[name] then
    error(pre..name)
  end
  mods[name] = obj
end

-- we error by default to fail in an evident way,
-- as some mods may not be able to handle missing deps.
local ret = function(name)
  return mods[name]
end
local err = "mod object doesn't exist: "
local retrieve_throw = function(name)
  local obj = ret(name)
  if obj == nil then error(err..name) end
  return obj
end

-- interface export
modtable = retrieve_throw
modtable_tryget = ret
modtable_register = add

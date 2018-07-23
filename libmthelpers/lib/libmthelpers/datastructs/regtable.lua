--[[
registration table.
intended for the common pattern in Minetest
where mods will insert definitions into some table.
Duplicate insertions will raise an error -
conflicting entries often can't be resolved
unless the mods are fixed.
Supports the following callbacks:
* validator = function(value_to_insert)
should return an error message string if not suitable.
the structure is exception safe if this raises an error.
* checkkey = function(key_to_set)
similar but check the provided key is valid;
e.g. if key is a string.
* on_register = function(k, v)
callback invoked when a key and value passed the check,
but *before* the entry is inserted.
if the callback runs without error,
the entry will be retrievable
immediately after this callback returns.
]]



local nne = function(ok, msg, prefix)
  if not ok then
    error(prefix..": "..tostring(msg))
  end
end

local try_insert = function(entries, k, v, validate, checkkey, on_register)
  local ok, err = checkkey(k)
  local ks = tostring(k)
  nne(ok, err, "key "..ks.." not valid")
  local ok, err = validate(v)
  nne(ok, err, "value "..tostring(v).." for key "..ks.." not valid")
	 if entries[k] ~= nil then
    error("duplicate registration for key "..ks)
	 end
  on_register(k, v)
  entries[k] = v
end



local i = {}

-- construct assigns a few closures to a table.
-- register: checked assignment
-- get: entry or nil
local a = function(v)
  assert(type(v) == "function")
  return v
end
local stub = function() return true end
local construct = function(hooks)
  hooks = hooks or nil
  local validator = a(hooks.validator or stub)
  local checkkey = a(hooks.checkkey or stub)
  local on_register = a(hooks.on_register or stub)
  local locked = false

  -- FIXME: haven't we written this before?
  local lock = function()
    assert(not locked, "concurrent modification error")
    locked = true
  end
  local unlock = function()
    assert(locked, "duplicatr unlock - logic error?")
    locked = false
  end

  local export = {}
  local entries = {}
  export.get = function(k)
    lock()
    local v = entries[k]
    unlock()
    return v
  end
  export.register = function(k, v)
    lock()
    try_insert(entries, k, v, validator, checkkey, on_register)
    unlock()
  end

  return export
end
i.construct = construct



return i



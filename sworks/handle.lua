local reg = debug.getregistry()
local steam = reg.Portal
local api = steam.api
local ffi = require("ffi")

local Handle = {}
reg.Handle = Handle

local metas = {}

function Handle:new()
  assert(self ~= nil and self ~= Handle)
  local mt = metas[self]
  if not mt then
    mt = { __index = self, __eq = function(a, b)
      if getmetatable(a) ~= getmetatable(b) then
        return false
      end
      return a:getId() == b:getId()
    end }
    metas[self] = mt
  end
  return setmetatable({}, mt)
end

function Handle:destroy()
  self.handle = nil
end

function Handle:getId()
  local handle = self.handle
  if handle then
    if ffi.istype("CSteamID", handle) then
      handle = handle.m_steamid.m_unAll64Bits
    end
    local id = tostring(handle)
    return id:sub(1, -4)
  end
end

function Handle:setId(handle)
  if ffi.istype("CSteamID", handle) then
    handle = handle.m_steamid.m_unAll64Bits
  end
  self.handle = handle
end

function Handle:callback(func, res, ...)
  local args = { ... }
  if res ~= 1 then
    local msg = api.Fail(res)
    if type(func) == "string" then
      func = "onFail"
      args = { msg }
    end
  end
  if type(func) == "string" then
    local f = self[func]
    if f then
      f(self, unpack(args))
    end
  else
    func(res == 1, unpack(args))
  end
end
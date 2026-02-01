local ffi = require("ffi")
local reg = debug.getregistry()
local steam = reg.Portal
local api = steam.api

local Socket = {}
setmetatable(Socket, { __index = reg.Handle })
reg.Socket = Socket

local kinds =
{
  unreliable = 0,
  nodelay = 1,
  reliable = 2,
  buffered = 3,
}

function Socket:init(ch, kind)
  self.channel = ch or 0
  self.peer = nil
  self.kind = kinds[kind or "unreliable"]
end

function Socket:destroy()
  self:setPeer()
  self.channel = nil
  self.peer = nil
  self.kind = nil
end

function Socket:getId()
  return self.channel
end

function Socket:setProtocol(kind)
  self.kind = kinds[kind]
  assert(self.kind)
end

function Socket:setPeer(peer)
  if peer == nil or peer ~= self.peer then
    if self.peer then
      api.Networking.CloseP2PChannelWithUser(self.peer.handle, self.channel)
      -- todo: check if all channels to this peer are closed
      -- api.Networking.CloseP2PSessionWithUser(self.peer)
      self.peer = nil
    end
    if peer then
      self.peer = peer
      api.Networking.AcceptP2PSessionWithUser(peer.handle)
    end
  end
end

function Socket:getPeer()
  return self.peer
end

function Socket:send(data, user)
  user = user or self.peer
  return api.Networking.SendP2PPacket(user.handle, data, #data, self.kind, self.channel)
end

local buffer = ffi.new("unsigned char[1024]")
local size = ffi.new("int[1]")
local sender = ffi.new("CSteamID[1]")
function Socket:receive()
  if api.Networking.IsP2PPacketAvailable(size, self.channel) then
    local packet = buffer
    local n = size[0]
    if n > 1024 then
      -- only allocate if this packet exceeds the buffer size
      packet = ffi.new("char[?]", n)
    end
    if api.Networking.ReadP2PPacket(packet, n, size, sender, self.channel) then
      if not self.peer or self.peer.handle == sender[0].m_steamid.m_unAll64Bits then
        packet = (packet == ffi.NULL) and "" or ffi.string(packet, n)
        return packet, steam.getUser(sender[0].m_steamid.m_unAll64Bits)
      end
    end
  end
end

local state = ffi.new("P2PSessionState_t")
function Socket:getAddress(user)
  user = user or self.peer
  if api.Networking.GetP2PSessionState(user.handle, state) then
    -- todo: does not support ipv6
    local c = state.m_nRemoteIP.byte
    local ip = string.format("%d.%d.%d.%d", c[3], c[2], c[1], c[0])
    return ip, state.m_nRemotePort, state.m_bUsingRelay > 0
  end
end

function Socket:isConnected(user)
  user = user or self.peer
  if api.Networking.GetP2PSessionState(user.handle, state) then
    return state.m_bConnectionActive > 0
  end
end
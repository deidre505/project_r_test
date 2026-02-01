local ffi = require("ffi")
local reg = debug.getregistry()
local steam = reg.Portal
local api = steam.api

local Lobby = {}
setmetatable(Lobby, { __index = reg.Handle })
reg.Lobby = Lobby

local kinds =
{
  private = 0,
  friends = 1,
  public = 2,
  invisible = 3,
}

function Lobby:create(kind, limit, func)
  kind = kinds[kind or "public"]
  limit = limit or 250
  assert(not self.handle and kind)
  self.handle = api.CSteamID_Invalid
  api.Matchmaking.CreateLobby(function(q)
    if self.handle == api.CSteamID_Invalid then
      local res = q and q.m_eResult or 0
      if res == 1 then
        self:init(q.m_ulSteamIDLobby)
      end
      self:callback(func or "onCreate", res)
    end
  end, kind, limit)
end

function Lobby:init(id)
  self:setId(id)
end

function Lobby:setType(kind)
  kind = kinds[kind]
  return api.Matchmaking.SetLobbyType(self.handle, kind)
end

function Lobby:join(func)
  api.Matchmaking.JoinLobby(function(q)
    if self.handle then
      local res = (q and q.m_EChatRoomEnterResponse == 1) and 1 or 0
      local user
      if res == 1 then
        user = steam.getUser()
      end
      self:callback(func or "onJoin", res, user)
    end
  end, self.handle)
end

function Lobby:setJoinable(ok)
  return api.Matchmaking.SetLobbyJoinable(self.handle, ok)
end

function Lobby:leave(func)
  api.Matchmaking.LeaveLobby(self.handle)
end

-- Returns the lobby owner
-- @return User object or nil if you aren"t a member of the lobby
function Lobby:getOwner()
  local h = api.Matchmaking.GetLobbyOwner(self.handle)
  if h and h ~= api.CSteamID_Invalid then
    return steam.getUser(h)
  end
end

function Lobby:setOwner(user)
  return api.Matchmaking.SetLobbyOwner(self.handle, user.handle)
end

function Lobby:invite(user)
  if not user or user:isOwner() then
    -- choose which friend to invite
    api.Friends.ActivateGameOverlayInviteDialog(self.handle)
  else
    -- invite specific friend
    return api.Matchmaking.InviteUserToLobby(self.handle, user.handle)
  end
end

function Lobby:getMembers()
  local n = api.Matchmaking.GetNumLobbyMembers(self.handle)
  local list = {}
  for i = 1, n do
    local h = api.Matchmaking.GetLobbyMemberByIndex(self.handle, i - 1)
    list[i] = steam.getUser(h)
  end
  return list
end

function Lobby:getLimit()
  return api.Matchmaking.GetLobbyMemberLimit(self.handle)
end

function Lobby:setLimit(n)
  return api.Matchmaking.SetLobbyMemberLimit(self.handle, n)
end

function Lobby:setData(k, v)
  local owner = self:getOwner()
  if owner and owner:isOwner() then
    return api.Matchmaking.SetLobbyData(self.handle, k, v)
  else
    api.Matchmaking.SetLobbyMemberData(self.handle, k, v)
    return true
  end
end

function Lobby:getData(p1, p2)
  local s
  if not p2 then
    s = api.Matchmaking.GetLobbyData(self.handle, p1)
  else
    s = api.Matchmaking.GetLobbyMemberData(self.handle, p1, p2)
  end
  if s and s ~= ffi.null then
    s = ffi.string(s)
    return s ~= "" and s or nil
  end
end

function Lobby:deleteData(k)
  return api.Matchmaking.DeleteLobbyData(self.handle, k)
end

function Lobby:requestData()
  return api.Matchmaking.RequestLobbyData(self.handle)
end

local buffer = ffi.new("unsigned char[4000]")
local bsize = ffi.sizeof(buffer)
local kind = ffi.new("uint32[1]")
local sender = ffi.new("CSteamID[1]")
function Lobby:getChatMessage(i)
  assert(i >= 1)
  local n = api.Matchmaking.GetLobbyChatEntry(self.handle, i - 1, sender, buffer, bsize, kind)
  if n > 0 then
    if kind[0] == 1 then
      return ffi.string(buffer, n), steam.getUser(sender[0].m_steamid.m_unAll64Bits)
    elseif kind[0] > 0 then
      return false
    end
  end
end

function Lobby:getChatMessageCount()
  for i = 1, 1024 do
    local n = api.Matchmaking.GetLobbyChatEntry(self.handle, i - 1, sender, buffer, 1, kind)
    if n == 0 and kind[0] == 0 then
      return i - 1
    end
  end
end

function Lobby:sendChatMessage(msg)
  return api.Matchmaking.SendLobbyChatMsg(self.handle, msg, #msg)
end
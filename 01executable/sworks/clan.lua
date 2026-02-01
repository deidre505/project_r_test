local ffi = require("ffi")
local reg = debug.getregistry()
local steam = reg.Portal
local api = steam.api

local Clan = {}
setmetatable(Clan, { __index = reg.Handle })
reg.Clan = Clan

function Clan:init(id)
  self:setId(id)
end

function Clan:getName()
  local n = api.Friends.GetClanName(self.handle)
  return (n == ffi.NULL) and "" or ffi.string(n)
end

function Clan:isPublic()
  return api.Friends.IsClanPublic(self.handle)
end

function Clan:isOfficial()
  return api.Friends.IsClanOfficialGameGroup(self.handle)
end

function Clan:getOwner()
  local uid = api.Friends.GetClanOwner(self.handle)
  return steam.getUser(uid)
end

function Clan:getOfficers()
  local n = api.Friends.GetClanOfficerCount(self.handle)
  if n > 0 then
    local list = {}
    for i = 1, n do
      local h = api.Friends.GetClanOfficerByIndex(self.handle, i - 1)
      list[i] = steam.getUser(h)
    end
    return list
  end
end

function Clan:requestOfficers(func)
  api.Friends.RequestClanOfficerList(function(q)
    if self.handle then
      local res = (q and q.m_bSuccess > 0) and 1 or 0
      local list
      if res == 1 then
        list = self:getOfficers()
      end
      self:callback(func or "onReceiveOfficers", res, list)
    end
  end, self.handle)
end

local online = ffi.new("int[1]")
local ingame = ffi.new("int[1]")
local chatting = ffi.new("int[1]")
function Clan:getActivity()
  if api.Friends.GetClanActivityCounts(self.handle, online, ingame, chatting) then
    return online[0], ingame[0], chatting[0]
  end
end

local array = ffi.new("CSteamID[1]")
function Clan:requestActivity(func)
  array[0] = self.handle
  api.Friends.DownloadClanActivityCounts(function(q)
    if self.handle then
      local res = (q and q.m_bSuccess) and 1 or 0
      self:callback(func or "onReceiveActivity", res)
    end
  end, array, 1)
end

function Clan:joinChat(func)
  api.Friends.JoinClanChatRoom(function(q)
    if self.handle then
      local res = (q and q.m_eChatRoomEnterResponse == 1) and 1 or 0
      self:callback(func or "onJoinChat", res)
    end
  end, self.handle)
end

function Clan:leaveChat()
  return api.Friends.LeaveClanChatRoom(self.handle)
end

function Clan:getChatMembers()
  local n = api.Friends.GetClanChatMemberCount(self.handle)
  if n > 0 then
    local list = {}
    for i = 1, n do
      local h = api.Friends.GetChatMemberByIndex(self.handle, i - 1)
      list[i] = steam.getUser(h)
    end
    return list
  end
end

local buffer = ffi.new("unsigned char[8193]")
local bsize = ffi.sizeof(buffer)
local kind = ffi.new("uint32[1]")
local sender = ffi.new("CSteamID[1]")
function Clan:getChatMessage(i)
  assert(i >= 1)
  local n = api.Friends.GetClanChatMessage(self.handle, i - 1, buffer, bsize, kind, sender)
  if n > 0 then
    if kind[0] == 1 then
      return ffi.string(buffer, n), steam.getUser(sender[0])
    elseif kind[0] > 0 then
      return false
    end
  end
end

function Clan:getChatMessageCount()
  for i = 1, 1024 do
    local n = api.Friends.GetClanChatMessage(self.handle, i - 1, buffer, 1, kind, sender)
    if n == 0 and kind[0] == 0 then
      return i - 1
    end
  end
end

function Clan:sendChatMessage(msg)
  return api.Friends.SendClanChatMessage(self.handle, msg)
end

--[[
function Clan:isFollowing(func)
  app.portal.api.Friends.IsFollowing(function(q)
    if self.handle then
      local res = q and q.m_eResult or 0
      local follow = q and q.m_bIsFollowing or false
      self:callback(func or "onFollowing", res, follow)
    end
  end, self.handle)
end
]]
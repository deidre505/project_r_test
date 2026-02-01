local ffi = require("ffi")
local reg = debug.getregistry()
local steam = reg.Portal
local api = steam.api

local User = {}
setmetatable(User, { __index = reg.Handle })
reg.User = User

function User:init(id)
  self:setId(id)
end

function User:getName()
  local n = api.Friends.GetFriendPersonaName(self.handle)
  return (n == ffi.NULL) and "" or ffi.string(n)
end

function User:setName(name)
  assert(self:isOwner())
  api.Friends.SetPersonaName(name)
end

function User:requestName()
  return api.Friends.RequestUserInformation(self.handle, true)
end

-- Checks the user's status among friends
-- @return True if currently visible among friends
function User:isOnline()
  return api.Friends.GetFriendPersonaState(self.handle) > 0
end

function User:isFriend()
  return api.Friends.GetFriendRelationship(self.handle) == 3
end

-- Gets the user's Steam level if available, otherwise it queues the Steam level for download
-- @return Steam level or 0 if unavailable
function User:getLevel()
  return api.Friends.GetFriendSteamLevel(self.handle)
end

function User:inviteToGame(s)
  return api.Friends.InviteUserToGame(self.handle, s)
end

function User:isOwner()
  return self.handle == api.User.GetSteamID()
end

local width = ffi.new("uint32[1]")
local height = ffi.new("uint32[1]")
function User:getAvatar(size)
  size = size or "medium"
  local index = 0
  if size == "large" then
    index = api.Friends.GetLargeFriendAvatar(self.handle)
  elseif size == "small" then
    index = api.Friends.GetSmallFriendAvatar(self.handle)
  else
    index = api.Friends.GetMediumFriendAvatar(self.handle)
  end
  if index > 0 and api.Utils.GetImageSize(index, width, height) then
    local w, h = width[0], height[0]
    local n = w*h*4
    local b = ffi.new("char[?]", n)
    api.Utils.GetImageRGBA(index, b, n)
    return (b == ffi.NULL) and "" or ffi.string(b, n), w, h
  end
end

function User:requestAvatar()
  return api.Friends.RequestUserInformation(self.handle, false)
end

local int = ffi.new("int[1]")
local float = ffi.new("float[1]")
function User:getStat(k)
  if api.UserStats.GetUserStatInt32(self.handle, k, int) then
    return int[0]
  elseif api.UserStats.GetUserStatFloat(self.handle, k, float) then
    return float[0]
  end
end

local boolean = ffi.new("bool[1]")
local stamp = ffi.new("uint32[1]")
function User:getAchievement(k)
  if api.UserStats.GetUserAchievementAndUnlockTime(self.handle, k, boolean, stamp) then
    return boolean[0], stamp[0]
  end
end

function User:setStat(k, v)
  assert(self:isOwner())
  return api.UserStats.SetStatInt32(k, v) or api.UserStats.SetStatFloat(k, v)
end

function User:setAchievement(k)
  assert(self:isOwner())
  return api.UserStats.SetAchievement(k)
end

function User:clearAchievement(k)
  assert(self:isOwner())
  return api.UserStats.ClearAchievement(k)
end

function User:requestCurrentStats()
  assert(self:isOwner())
  return api.UserStats.RequestCurrentStats()
end

function User:requestStats(func)
  return api.UserStats.RequestUserStats(function(q)
    if self.handle then
      local res = q and q.m_eResult or 0
      self:callback(func or "onReceiveStats", res)
    end
  end, self.handle)
end

function User:storeStats()
  return api.UserStats.StoreStats()
end

function User:resetStats(ach)
  return api.UserStats.ResetAllStats(ach == true)
end

local info = ffi.new("FriendGameInfo_t[1]")
function User:getGamePlayed()
  local appid, lobby
  if self:isOwner() then
    appid = steam.getAppId()
  elseif api.Friends.GetFriendGamePlayed(self.handle, info) then
    local q = info[0]
    appid = q.m_gameID.parts.m_nAppID
    local lid = q.m_steamIDLobby.m_steamid.m_unAll64Bits
    if lid ~= api.CSteamID_Invalid then
      lobby = steam.getLobby(lid)
    end
  end
  return appid, lobby
end

local userDialogs = 
{
  steamid = true,
  chat = true,
  jointrade = true,
  stats = true,
  achievements = true,
  friendadd = true,
  friendremove = true,
  friendrequestaccept = true,
  friendrequestignore = true,
}

function User:activateOverlay(dialog)
  assert(userDialogs[dialog], "invalid user dialog")
  api.Friends.ActivateGameOverlayToUser(dialog, self.handle)
end

function User:setPlayedWith()
  assert(not self:isOwner())
  api.Friends.SetPlayedWith(self.handle)
end

function User:getPlayedWith()
  assert(not self:isOwner())
  local appid = api.Friends.GetFriendCoplayGame(self.handle)
  local tstamp = api.Friends.GetFriendCoplayTime(self.handle)
  if appid > 0 and tstamp > 0 then
    return appid, tstamp
  end
end

--- Sets the rich presence for up to 20 keys
-- @param k Key string (where "status", "connect", "steam_display", "steam_player_group", "steam_player_group_size" are reserved)
-- @param v Value string
function User:setRichPresence(k, v)
  assert(self:isOwner())
  return api.Friends.SetRichPresence(k, v)
end

function User:clearRichPresence()
  assert(self:isOwner())
  api.Friends.ClearRichPresence()
end

function User:getRichPresence(k)
  local v = api.Friends.GetFriendRichPresence(self.handle, k)
  v = ffi.string(v)
  return v ~= "" and v
end

--- Requests the rich presence details for users who are not friends
function User:requestRichPresence()
  api.Friends.RequestFriendRichPresence(self.handle)
end

local buffer = ffi.new("char[1024]")
local size = ffi.new("int[1]")
function User:getAuthTicket()
  api.User.GetAuthSessionTicket(buffer, 1024, size)
  return ffi.string(buffer, size[0])
end

function User:cancelAuthTicket(ticket)
  if type(ticket) ~= "cdata" then
    ticket = tostring(ticket)
    ticket = ffi.C.strtoull(ticket, nil, 10)
  end
  api.User.CancelAuthTicket(ticket)
end
local ffi = require("ffi")
local path = (...):match("(.-)[^%.]+$")
local api = require(path.."api")
local reg = debug.getregistry()

local steam = { api = api }
reg.Portal = steam
local isready = false
local users = nil
local clans = nil
local sockets = nil

-- Initializes the Steam client interface
-- @return True if the interface is initialized
function steam.init()
  if not isready and api.Init() then
    isready = true
    users = {}
    clans = {}
    sockets = {}
  end
  return isready
end

-- Shuts down the Steam client interface
function steam.shutdown()
  users = nil
  clans = nil
  sockets = nil
  api.Shutdown()
end

function steam.isRunning()
  return api.IsSteamRunning()
end

-- Checks if your executable was launched through Steam.
-- Returns true and re-launches your game through Steam if it was not.
-- Returns false when "steam_appid.txt" is present.
function steam.restart(id)
  return api.RestartAppIfNecessary(id)
end

-- Checks if the owner is connected to Steam
-- @return True if connected or false when offline
function steam.isConnected()
  return api.User.BLoggedOn()
end

-- Checks if the client is running in Big Picture mode.
-- @return True if Big Picture mode is enabled
function steam.isBigPicture()
  return api.Utils.IsSteamInBigPictureMode()
end

--[[
local width = ffi.new("int[1]")
local height = ffi.new("int[1]")
function steam.getClientResolution(s)
  s = s or api.RemotePlay.GetSessionID(0)
  if s > 0 and api.RemotePlay.BGetSessionClientResolution(s, width, height) then
    return width[0], height[0]
  end
end
]]

-- Triggers any registered callbacks.
function steam.update()
  api.Update()
end

-- Retrieves all regular friends.
-- @return List of user objects
function steam.getFriends()
  local list = {}
  for i = 1, api.Friends.GetFriendCount(0x04) do
    local h = api.Friends.GetFriendByIndex(i - 1, 0x04)
    list[i] = steam.getUser(h)
  end
  return list
end

-- Retrieves users we have recently played with.
-- @return List of user objects
function steam.getPlayedWith()
  local list = {}
  for i = 1, api.Friends.GetCoplayFriendCount() do
    local h = api.Friends.GetCoplayFriend(i - 1)
    list[i] = steam.getUser(h)
  end
  return list
end

function steam.getClan(id)
  if type(id) ~= "cdata" then
    id = tostring(id)
    id = ffi.C.strtoull(id, nil, 10)
  end
  if id == api.CSteamID_Invalid then
    api.Fail(19)
    return
  end
  local cid = tostring(id)
  local clan = clans[cid]
  if not clan then
    clan = reg.Clan:new()
    clan:init(id)
    clans[cid] = clan
  end
  return clan
end

-- Retrieves all clans.
-- @return List of clan objects
function steam.getClans()
  local list = {}
  for i = 1, api.Friends.GetClanCount() do
    local h = api.Friends.GetClanByIndex(i - 1)
    list[i] = steam.getClan(h)
  end
  return list
end

-- Retrieves a specific user.
-- @param id User ID in decimal format (optional)
-- @return User object
function steam.getUser(id)
  id = id or api.User.GetSteamID()
  if type(id) ~= "cdata" then
    id = tostring(id)
    id = ffi.C.strtoull(id, nil, 10)
  end
  if id == api.CSteamID_Invalid then
    api.Fail(19)
    return
  end
  local cid = tostring(id)
  local user = users[cid]
  if not user then
    user = reg.User:new()
    user:init(id)
    users[cid] = user
  end
  return user
end

-- Retrieves an existing leaderboard based on name.
-- @param name Leaderboard name
-- @return Board object
function steam.getBoard(name, ...)
  local board = reg.Board:new()
  board:init(name, ...)
  return board
end

-- Creates or retrieves an existing leaderboard based on name.
-- @param name Leaderboard name
-- @return Board object
function steam.newBoard(name, ...)
  local board = reg.Board:new()
  board:create(name, ...)
  return board
end

-- Creates or retrieves an existing socket via its channel number.
-- @param ch Channel number (optional)
-- @return Socket
function steam.getSocket(ch, ...)
  ch = tonumber(ch or 0)
  local sock = sockets[ch]
  if not sock then
    sock = reg.Socket:new()
    sockets[ch] = sock
    sock:init(ch, ...)
  end
  return sock
end

function steam.newLobby(...)
  local lobby = reg.Lobby:new()
  lobby:create(...)
  return lobby
end

function steam.getLobby(id, ...)
  if type(id) ~= "cdata" then
    id = tostring(id)
    id = ffi.C.strtoull(id, nil, 10)
  end
  if id == api.CSteamID_Invalid then
    api.Fail(19)
    return
  end
  local lobby = reg.Lobby:new()
  lobby:init(id)
  return lobby
end

function steam.queryLobbies(what, limit, func)
  if what then
    for k, v in pairs(what) do
      if k == "slots" then
        api.Matchmaking.AddRequestLobbyListFilterSlotsAvailable(v)
      elseif type(v) == "number" then
        api.Matchmaking.AddRequestLobbyListNumericalFilter(k, v, 0)        
      else
        api.Matchmaking.AddRequestLobbyListStringFilter(k, v, 0)
      end
    end
  end
  if limit then
    api.Matchmaking.AddRequestLobbyListResultCountFilter(limit)
  end
  api.Matchmaking.RequestLobbyList(function(q)
    local list
    if q then
      list = {}
      for i = 1, q.m_nLobbiesMatching do
        local id = api.Matchmaking.GetLobbyByIndex(i - 1)
        list[i] = steam.getLobby(id)
      end
    end
    func(q ~= nil, list)
  end)
end

-- Retrieves an existing user-generated content item
-- @param id User-generated item ID
-- @return User-generated item
function steam.getUGC(id, ...)
  if type(id) ~= "cdata" then
    id = tostring(id)
    id = ffi.C.strtoull(id, nil, 16)
  end
  if id == api.UGCHandle_Invalid then
    api.Fail(19)
    return
  end
  local ugc = reg.UGC:new()
  ugc:init(id, ...)
  return ugc
end

-- Creates a new user-generated content item
-- @param kind Type of object. Possible options are: "community", "micro", "collection",
-- "art", "video", "screenshot", "game", "software", "concept", "webguide", "guide", "merch",
-- "binding", "accessinvite", "steamvideo" or "managed".
-- @param appid Application ID
-- @return User-generated item
function steam.newItem(...)
  local ugc = reg.UGC:new()
  ugc:create(...)
  return ugc
end

-- Retrives all subscribed user-generated items.
-- @return List of user-generated items
function steam.getSubscribedUGC(s, e)
  local limit = api.UGC.GetNumSubscribedItems()
  local array = ffi.new("PublishedFileId_t[?]", limit)
  local n = api.UGC.GetSubscribedItems(array, limit)
  local list = {}
  for i = s, math.min(e, n) do
    local ugc = steam.getUGC(array[i - 1])
    table.insert(list, ugc)
  end
  return list, n
end

local queries =
{
  popular = 0,
  recent = 1,
  friends = 5,
  unrated = 8,
}

function steam.queryUGC(what, s, e, func, list)
  if what == "subscribed" then
    local q, total = steam.getSubscribedUGC(s, e)
    func(true, q, total)
    return
  end

  local page = math.ceil(s/50)
  local page2 = math.ceil(e/50)

  local appid = steam.getAppId()
  local query
  if type(what) == "string" then
    assert(queries[what])
    query = api.UGC.CreateQueryAllUGCRequestPage(queries[what], 0, appid, appid, page)
  else
    query = api.UGC.CreateQueryUserUGCRequest(what.handle, 0, 0, 0, appid, appid, page)
  end
  api.UGC.SetReturnOnlyIDs(query, true)
  api.UGC.SendQueryUGCRequest(function(q)
    local res = q and q.m_eResult or 0
    local total
    if res == 1 then
      local d = ffi.new("SteamUGCDetails_t[1]")
      list = list or {}
      local s2 = s - (page - 1)*50
      local e2 = math.min(q.m_unNumResultsReturned, s2 + e - s)
      for p = s2, e2 do
        api.UGC.GetQueryUGCResult(query, p - 1, d)
        local ugc = steam.getUGC(d[0].m_nPublishedFileId, appid)
        table.insert(list, ugc)
      end
      total = q.m_unTotalMatchingResults
    end
    api.UGC.ReleaseQueryUGCRequest(query)
    if res ~= 1 then
      api.Fail(res)
    end
    if page2 > page then
      steam.queryUGC(what, (page2 - 1)*50 + 1, e, func, list)
    else
      func(res == 1, list, total)
    end
  end, query)
end

-- Retrives all available achievements for this game.
-- @return List of achievement names
function steam.getAchievements()
  local n = api.UserStats.GetNumAchievements()
  local list = {}
  for i = 1, n do
    list[i] = ffi.string(api.UserStats.GetAchievementName(i - 1))
  end
  return list
end

local genDialogs =
{
  friends = true,
  community = true,
  players = true,
  settings = true,
  officialgamegroup = true,
  stats = true,
  achievements = true
}

-- Opens the Steam overlay if available to a specific dialog or page.
-- @param p1 Dialog, AppID or URL address
-- @param p2 User object (optional)
-- @return True if the overlay is enabled
function steam.activateOverlay(p1, p2)
  p1 = p1 or "friends"
  if genDialogs[p1] then
    -- dialog
    api.Friends.ActivateGameOverlay(p1)
  elseif tonumber(p1) then
    -- appid
    api.Friends.ActivateGameOverlayToStore(p1, 0)
  else
    -- url
    api.Friends.ActivateGameOverlayToWebPage(p1)
  end
end

-- Sets the notifcation position and offset.
-- @param pos Target corner
-- @param ox, oy Inset from the corner (optional)
local positions =
{
  topleft = 0,
  topright = 1,
  bottomleft = 2,
  bottomright = 3,
}
function steam.setNotificationPosition(pos, ox, oy)
  api.Utils.SetOverlayNotificationPosition(positions[pos])
  if ox and oy then
    api.Utils.SetOverlayNotificationInset(ox, oy)
  end
end

-- Gets the current application ID.
-- @return AppID number
function steam.getAppId()
  return tonumber(api.Utils.GetAppID())
end

-- Gets the selected language code for the current game or the client.
-- @return Language code
local langs = require(path.."languages")
function steam.getLanguage()
  return langs[ffi.string(api.Apps.GetCurrentGameLanguage())]
end

-- Gets the geographic location based on IP.
-- @return Country code
function steam.getCountry()
  return string.lower(ffi.string(api.Utils.GetIPCountry()))
end

-- Makes a new HTTP or HTTPS request
function steam.request(...)
  return api.Request(...)
end

-- check if we are in a "ready" state
local ignore = { init = true, isRunning = true, restart = true }
for k, v in pairs(steam) do
  if type(v) == "function" and not ignore[k] then
    local w = function(...)
      if not isready then
        api.Fail(3)
        return
      end
      return v(...)
    end
    steam[k] = w
  end
end

return steam
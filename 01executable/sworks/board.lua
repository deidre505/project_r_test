local ffi = require("ffi")
local reg = debug.getregistry()
local steam = reg.Portal
local api = steam.api

local Board = {}
setmetatable(Board, { __index = reg.Handle })
reg.Board = Board

function Board:init(name, func)
  assert(not self.handle)
  self.handle = api.CSteamID_Invalid
  api.UserStats.FindLeaderboard(function(q)
    if self.handle == api.CSteamID_Invalid then
      local res = (q and q.m_bLeaderboardFound > 0) and 1 or 0
      if res == 1 then
        self.handle = q.m_hSteamLeaderboard
      end
      self:callback(func or "onFind", res)
    end
  end, name)
end

local sorts = { none = 0, asc = 1, desc = 2 }
local displays = { none = 0, numeric = 1, seconds = 2, milliseconds = 3 }

function Board:create(name, sort, display, func)
  assert(not self.handle)
  self.handle = api.CSteamID_Invalid
  sort = sorts[sort or "desc"]
  display = displays[display or "numeric"]
  assert(sort and display)
  api.UserStats.FindOrCreateLeaderboard(function(q)
    if self.handle == api.CSteamID_Invalid then
      local res = (q and q.m_bLeaderboardFound > 0) and 1 or 0
      if res == 1 then
        self.handle = q.m_hSteamLeaderboard
      end
      self:callback(func or "onCreate", res)
    end
  end, name, sort, display)
end

function Board:destroy()
  self.handle = nil
end

function Board:getName()
  local n = api.UserStats.GetLeaderboardName(self.handle)
  return (n == ffi.NULL) and "" or ffi.string(n)
end

function Board:getEntryCount()
  return api.UserStats.GetLeaderboardEntryCount(self.handle)
end

function Board:attach(ugc, func)
  api.UserStats.AttachLeaderboardUGC(function(q)
    if self.handle then
      local res = q and q.m_eResult or 0
      self:callback(func or "onAttach", res, ugc)
    end
  end, self.handle, ugc.handle)
  return true
end

-- Uploading scores to Steam is rate limited to 10 uploads per 10 minutes
-- and you may only have one outstanding call to this function at a time.
local methods = { none = 0, best = 1, latest = 2 }

function Board:upload(score, method, func)
  method = methods[method or "best"]
  assert(method)
  api.UserStats.UploadLeaderboardScore(function(q)
    if self.handle then
      local res = q and 1 or 0
      local changed = nil
      if q then
        changed = (q.m_bScoreChanged > 0) or (q.m_nGlobalRankPrevious ~= q.m_nGlobalRankNew)
      end
      self:callback(func or "onUpload", res, changed)
    end
  end, self.handle, method, score, nil, 0)
end

local entry = ffi.new("LeaderboardEntry_t")
local filters = { global = 0, user = 1, friends = 2 }

function Board:download(what, i, j, func)
  local filter = filters[what or "global"] or 0
  assert(filter)
  
  local fetch = function(q)
    if self.handle then
      local res = q and 1 or 0
      local list, count
      if q then
        count = q.m_cEntryCount
        if filter ~= 2 then
          count = api.UserStats.GetLeaderboardEntryCount(self.handle)
        end
        if (filter == 0) or (filter == 1) or not (i and j) then
          i, j = 1, q.m_cEntryCount
        end
        list = {}
        for k = i, j do
          if api.UserStats.GetDownloadedLeaderboardEntry(q.m_hSteamLeaderboardEntries, k - 1, entry, nil, 0) then
            local v = {}
            v.user = steam.getUser(entry.m_steamIDUser.m_steamid.m_unAll64Bits)
            v.rank = entry.m_nGlobalRank
            v.score = entry.m_nScore
            if entry.m_hUGC ~= api.UGCHandle_Invalid then
              v.ugc = steam.getUGC(entry.m_hUGC)
            end
            table.insert(list, v)
          end
        end
      end
      self:callback(func or "onDownload", res, list, count)
    end
  end
  
  if type(what) == "table" then
    local array = ffi.new("CSteamID[?]", #what)
    for k, v in ipairs(what) do
      array[k - 1] = v.handle
    end
    return api.UserStats.DownloadLeaderboardEntriesForUsers(fetch, self.handle, array, #what)
  else
    return api.UserStats.DownloadLeaderboardEntries(fetch, self.handle, filter, i, j)
  end
end

-- sworks/api.lua
-- Minimal + robust Steam API binder for LuaJIT FFI
-- Adds Matchmaking (CreateLobby/LeaveLobby) via Flat API to avoid vtable crashes.

local ffi = require("ffi")

local win = (ffi.os == "Windows")
local x64 = ffi.abi("64bit")
local libname = (x64 and win) and "steam_api64" or "steam_api"

ffi.cdef[[
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef int int32_t;
typedef unsigned long long uint64_t;

// ---- Base ----
int  SteamAPI_Init(void);
int  SteamAPI_InitSafe(void);
int  SteamAPI_InitFlat(void);
int  SteamAPI_RestartAppIfNecessary(uint32_t);
void SteamAPI_Shutdown(void);
void SteamAPI_RunCallbacks(void);

// ---- Interfaces getters (versioned) ----
// NOTE: v009 is commonly available in steam_api64.dll for ISteamMatchmaking.
void* SteamAPI_SteamMatchmaking_v009(void);

// ---- Matchmaking Flat API (no vtable) ----
// ESteamLobbyType: 0=Private, 1=FriendsOnly, 2=Public, 3=Invisible (Steamworks enum)
uint64_t SteamAPI_ISteamMatchmaking_CreateLobby(void* self, int eLobbyType, int cMaxMembers);
void     SteamAPI_ISteamMatchmaking_LeaveLobby(void* self, uint64_t steamIDLobby);
]]

local M = {
  _lib = nil,
  _load_error = nil,
  _init_symbol = nil,
}

local function try_load()
  if M._lib then return true end
  local ok, err = pcall(function()
    -- Prefer working dir (exe folder). On Windows, "./steam_api64" works if dll is next to exe.
    M._lib = ffi.load("./" .. libname)
  end)
  if not ok then
    M._lib = nil
    M._load_error = tostring(err)
    return false
  end
  return true
end

local function has(sym)
  if not M._lib then return false end
  local ok = pcall(function() return M._lib[sym] end)
  return ok
end

local function call(sym, ...)
  return M._lib[sym](...)
end

-- Init: most compatible order
function M.init()
  if not try_load() then
    return false, "ffi.load failed: " .. tostring(M._load_error)
  end

  local order = { "SteamAPI_InitSafe", "SteamAPI_InitFlat", "SteamAPI_Init" }
  for _, sym in ipairs(order) do
    if has(sym) then
      local ok, res = pcall(function() return call(sym) end)
      if ok and res ~= 0 then
        M._init_symbol = sym
        return true, sym
      end
    end
  end

  local hints = {}
  for _, s in ipairs({ "SteamAPI_Init", "SteamAPI_InitSafe", "SteamAPI_InitFlat" }) do
    hints[#hints+1] = s .. "=" .. tostring(has(s))
  end
  return false, "Steam init failed (" .. table.concat(hints, ", ") .. ")"
end

function M.shutdown()
  if M._lib and has("SteamAPI_Shutdown") then
    pcall(function() call("SteamAPI_Shutdown") end)
  end
end

function M.runCallbacks()
  if M._lib and has("SteamAPI_RunCallbacks") then
    pcall(function() call("SteamAPI_RunCallbacks") end)
  end
end

function M.isLoaded()
  return M._lib ~= nil
end

function M.getLoadError()
  return M._load_error
end

function M.getInitSymbol()
  return M._init_symbol
end

-- ---- Matchmaking interface ----
function M.getMatchmaking()
  if not M._lib then return nil, "steam api not loaded" end
  if not has("SteamAPI_SteamMatchmaking_v009") then
    return nil, "SteamAPI_SteamMatchmaking_v009 not found in DLL"
  end
  local mm = nil
  local ok, err = pcall(function()
    mm = call("SteamAPI_SteamMatchmaking_v009")
  end)
  if (not ok) or (mm == nil) then
    return nil, "failed to get matchmaking interface: " .. tostring(err)
  end
  return mm
end

-- CreateLobby (async in real Steamworks, but we only need "call succeeded" here)
function M.createLobby(lobbyType, maxMembers)
  local mm, err = M.getMatchmaking()
  if not mm then return false, err end

  lobbyType  = lobbyType  or 1  -- FriendsOnly default
  maxMembers = maxMembers or 2  -- 1v1

  if not has("SteamAPI_ISteamMatchmaking_CreateLobby") then
    return false, "SteamAPI_ISteamMatchmaking_CreateLobby not found in DLL"
  end

  local ok, res = pcall(function()
    return call("SteamAPI_ISteamMatchmaking_CreateLobby", mm, lobbyType, maxMembers)
  end)
  if not ok then
    return false, "CreateLobby call failed: " .. tostring(res)
  end

  -- res is SteamAPICall_t (uint64). 0 can mean failure.
  if res == nil or tonumber(res) == 0 then
    return false, "CreateLobby returned 0 (call not started)"
  end

  return true, res -- return call-handle (uint64)
end

function M.leaveLobby(lobby_id_u64)
  local mm, err = M.getMatchmaking()
  if not mm then return false, err end
  if not lobby_id_u64 then return true end

  if not has("SteamAPI_ISteamMatchmaking_LeaveLobby") then
    return false, "SteamAPI_ISteamMatchmaking_LeaveLobby not found in DLL"
  end

  local ok, e = pcall(function()
    call("SteamAPI_ISteamMatchmaking_LeaveLobby", mm, tonumber(lobby_id_u64))
  end)
  if not ok then
    return false, "LeaveLobby call failed: " .. tostring(e)
  end
  return true
end

M._libname = libname
return M

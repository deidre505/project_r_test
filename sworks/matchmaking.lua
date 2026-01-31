-- sworks/matchmaking.lua
-- Minimal Steam Matchmaking binding (CreateLobby + Invite)

local ffi = require("ffi")
local api = require("sworks.api")

-- C types (bool 쓰지 않음!)
ffi.cdef[[
typedef unsigned long long uint64;
typedef uint64 SteamAPICall_t;
typedef int EResult;

typedef struct {
  uint64 m_ulSteamIDLobby;
  EResult m_eResult;
} LobbyCreated_t;

SteamAPICall_t SteamAPI_ISteamMatchmaking_CreateLobby(
  void* self,
  int eLobbyType,
  int cMaxMembers
);

void SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialog(
  uint64 steamIDLobby
);
]]

local M = {}

-- Steam enums (필요 최소)
local k_ELobbyTypeFriendsOnly = 1
local k_EResultOK = 1

--------------------------------------------------
-- Create Lobby
--------------------------------------------------
function M.createLobby(Steam)
  local mm = api.Matchmaking
  if not mm then
    return false, "Matchmaking interface not available"
  end

  local call = mm.CreateLobby(k_ELobbyTypeFriendsOnly, 2)
  if not call or call == 0 then
    return false, "CreateLobby call failed"
  end

  -- 콜백 등록
  api.Register(function(data)
    if not data or data.m_eResult ~= k_EResultOK then
      Steam.lobby_state = "error"
      Steam.lobby_error = "LobbyCreated failed"
      return
    end

    Steam.lobby_id = tonumber(data.m_ulSteamIDLobby)
    Steam.lobby_state = "created"
    Steam.lobby_error = nil

    print("[Steam] Lobby created:", Steam.lobby_id)
  end, "LobbyCreated_t", call)

  return true
end

--------------------------------------------------
-- Invite Dialog
--------------------------------------------------
function M.openInviteDialog(Steam)
  if not Steam.lobby_id then
    return false, "No lobby to invite to"
  end

  local friends = api.Friends
  if not friends then
    return false, "Friends interface not available"
  end

  friends.ActivateGameOverlayInviteDialog(Steam.lobby_id)
  return true
end

return M

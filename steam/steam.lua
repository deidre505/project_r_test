-- steam/steam.lua
-- High-level Steam wrapper used by game code.
-- Depends on: sworks/api.lua (init + callbacks only)
-- NOTE: Lobby create here is "project-level state" (not real Steam matchmaking yet).

local api = require("sworks.api")
local matchmaking = require("sworks.matchmaking")


local Steam = {
  ok = false,
  init_method = nil,
  last_error = nil,
  _init_attempted = false,

  -- lobby state (project-level)
  lobby_state = "none",   -- "none" | "creating" | "created" | "error"
  lobby_id = nil,
  lobby_error = nil,
}

local function ensure_init()
  if Steam._init_attempted then return end
  Steam._init_attempted = true

  -- DLL load + SteamAPI_Init*
  local ok, how = api.init()
  Steam.ok = ok
  Steam.init_method = ok and how or nil
  Steam.last_error = ok and nil or how

  -- init 결과에 따라 기본 상태 정리
  if not ok then
    Steam.lobby_state = "none"
    Steam.lobby_id = nil
    Steam.lobby_error = nil
  end
end

function Steam.init()
  ensure_init()
  return Steam.ok
end

function Steam.shutdown()
  Steam.ok = false
  Steam.init_method = nil
  Steam.last_error = nil
  Steam._init_attempted = false

  Steam.lobby_state = "none"
  Steam.lobby_id = nil
  Steam.lobby_error = nil

  api.shutdown()
end

function Steam.update()
  -- LOVE update에서 매 프레임 호출용
  ensure_init()
  if Steam.ok then
    api.runCallbacks()
  end
end

function Steam.runCallbacks()
  ensure_init()
  if Steam.ok then
    api.runCallbacks()
  end
end

function Steam.isReady()
  ensure_init()
  return Steam.ok == true
end

function Steam.getStatus()
  -- UI에서 쓰는 (ok, statusString) 형태로 고정
  ensure_init()

  if Steam.ok then
    return true, ("Steam: OK (%s)"):format(tostring(Steam.init_method or "SteamAPI_Init*"))
  end

  -- 실패면 원인을 최대한 보여줌
  local err = Steam.last_error or api.getLoadError() or "unknown"
  return false, ("Steam: FAIL (%s)"):format(tostring(err))
end

function Steam.hasLobby()
  return Steam.lobby_state == "created" and Steam.lobby_id ~= nil
end

function Steam.leaveLobby()
  -- 현재 단계에서는 “상태 리셋”이 안전함
  Steam.lobby_state = "none"
  Steam.lobby_id = nil
  Steam.lobby_error = nil
  return true
end

function Steam.createLobby()
  if not Steam.ok then
    Steam.lobby_state = "error"
    Steam.lobby_error = "Steam not ready"
    return false, Steam.lobby_error
  end

  if Steam.lobby_state == "created" and Steam.lobby_id then
    return true
  end

  Steam.lobby_state = "creating"
  Steam.lobby_error = nil
  Steam.lobby_id = nil

  local ok, err = matchmaking.createLobby(Steam)
  if not ok then
    Steam.lobby_state = "error"
    Steam.lobby_error = err
    return false, err
  end

  return true
end


function Steam.openFriendsOverlay()
  if not Steam.ok then
    return false, "Steam not ready"
  end

  return matchmaking.openInviteDialog(Steam)
end


return Steam

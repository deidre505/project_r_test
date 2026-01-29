-- steam/steam.lua
-- High-level Steam wrapper
-- Depends on: sworks/api.lua

local api = require("sworks.api")

local Steam = {
  ok = false,
  init_method = nil,
  last_error = nil,

  -- Lobby state
  lobby_state = "none",   -- none | creating | created | failed
  lobby_id = nil,
}

------------------------------------------------------------
-- Init / Shutdown
------------------------------------------------------------
function Steam.init()
  -- ✅ api.init() 안에서 ffi.load()가 수행되므로 _lib 선검사 금지
  local ok, how = api.init()

  Steam.ok = ok == true
  if Steam.ok then
    Steam.init_method = how
    Steam.last_error = nil
  else
    Steam.init_method = nil
    Steam.last_error = tostring(how or api.getLoadError and api.getLoadError() or "init failed")
  end

  return Steam.ok
end

function Steam.shutdown()
  if api and api.shutdown then
    pcall(api.shutdown)
  end

  Steam.ok = false
  Steam.init_method = nil
  Steam.last_error = nil
  Steam.lobby_state = "none"
  Steam.lobby_id = nil
end

function Steam.update()
  if Steam.ok and api and api.runCallbacks then
    pcall(api.runCallbacks)
  end
end

------------------------------------------------------------
-- Status helpers (UI-safe)
------------------------------------------------------------
function Steam.isReady()
  return Steam.ok == true
end

function Steam.getStatus()
  if Steam.ok then
    return true, ("Steam: OK (%s)"):format(tostring(Steam.init_method or "OK"))
  end

  if Steam.last_error then
    return false, ("Steam: FAIL (%s)"):format(tostring(Steam.last_error))
  end

  return false, "Steam: UNKNOWN"
end

------------------------------------------------------------
-- Lobby (STEP 1 placeholder)
------------------------------------------------------------
function Steam.createLobby() --로비오픈
  if not Steam.ok then
    Steam.lobby_state = "failed"
    return false, "Steam not ready"
  end

  if Steam.lobby_state == "created" then
    return false, "Lobby already exists"
  end

  Steam.lobby_state = "creating"

  -- Placeholder success (UI flow test)
  Steam.lobby_id = "PENDING_LOBBY_ID"
  Steam.lobby_state = "created"

  return true
end

function Steam.hasLobby()
  return Steam.lobby_state == "created" and Steam.lobby_id ~= nil
end

function Steam.leaveLobby() -- 로비클로즈
  -- 실제 Steam 로비 API를 붙이기 전이라도,
  -- 씬 나갈 때 상태를 확실히 정리해주는 게 중요함.
  Steam.lobby_state = "none"
  Steam.lobby_id = nil

  -- TODO(다음 단계):
  -- 실제 Steamworks Matchmaking 로비를 쓰게 되면 여기서
  -- api.leaveLobby(Steam.lobby_id) 같은 걸 호출하게 될 것.
  return true
end


------------------------------------------------------------
-- Overlay
------------------------------------------------------------
function Steam.openFriendsOverlay()
  if not Steam.ok then
    return false, "Steam not ready"
  end

  if api and api.activateOverlay then
    local ok, err = pcall(api.activateOverlay, "Friends")
    if ok then return true end
    return false, tostring(err)
  end

  return false, "Overlay API not available"
end

return Steam

-- steam/steam.lua
-- High-level Steam wrapper used by game code.
-- Uses: sworks/api.lua (minimal binder + matchmaking flat API)

local api = require("sworks.api")

local Steam = {
  ok = false,
  init_method = nil,
  last_error = nil,

  -- lobby
  lobby_state = "none",   -- none/creating/created/error
  lobby_error = nil,

  -- NOTE: With flat API we only get a call-handle (SteamAPICall_t).
  -- Real lobby_id is delivered by callbacks normally (LobbyCreated/LobbyEnter).
  -- For now: store call handle so you can verify CreateLobby started.
  lobby_call = nil,

  -- If later you add callback parsing, you can store actual lobby_id here.
  lobby_id = nil,
}

local function ensure_init()
  if Steam.ok then return end
  -- don't auto-init silently if you prefer; current behavior keeps stability
end

function Steam.init()
  if not api.isLoaded() then
    -- Attempt load+init
  end

  local ok, how = api.init()
  Steam.ok = ok
  Steam.init_method = ok and how or nil
  Steam.last_error = ok and nil or how

  if not ok then
    Steam.lobby_state = "error"
    Steam.lobby_error = Steam.last_error
  end

  return ok
end

function Steam.shutdown()
  -- Optional: leave lobby before shutdown
  if Steam.lobby_id then
    api.leaveLobby(Steam.lobby_id)
  end

  Steam.ok = false
  Steam.init_method = nil
  Steam.last_error = nil
  Steam.lobby_state = "none"
  Steam.lobby_error = nil
  Steam.lobby_call = nil
  Steam.lobby_id = nil

  api.shutdown()
end

function Steam.update()
  -- LOVE update: keep callbacks running
  if Steam.ok then
    api.runCallbacks()
  end
end

function Steam.isReady()
  return Steam.ok == true
end

function Steam.getStatus()
  if Steam.ok then
    return true, ("Steam: OK (%s)"):format(tostring(Steam.init_method))
  end
  if api.getLoadError() then
    return false, "Steam: FAIL (" .. tostring(api.getLoadError()) .. ")"
  end
  return false, "Steam: FAIL (unknown ffi.load error)"
end

function Steam.hasLobby()
  -- For now, treat "created" as having lobby
  return Steam.lobby_state == "created"
end

-- Create Steam lobby (FriendsOnly, 2 members by default)
function Steam.createLobby()
  ensure_init()
  if not Steam.ok then
    Steam.lobby_state = "error"
    Steam.lobby_error = "Steam not ready"
    return false, Steam.lobby_error
  end

  if Steam.lobby_state == "created" then
    return true
  end

  Steam.lobby_state = "creating"
  Steam.lobby_error = nil
  Steam.lobby_call = nil

  -- 1 = FriendsOnly, 2 members (1v1)
  local ok, res = api.createLobby(1, 2)
  if not ok then
    Steam.lobby_state = "error"
    Steam.lobby_error = res
    return false, res
  end

  -- res is SteamAPICall_t handle
  Steam.lobby_call = res
  Steam.lobby_state = "created"
  return true
end

function Steam.leaveLobby()
  -- Whether you need this:
  -- - If you want lobby to disappear immediately when backing out, call this.
  -- - If ESC already "seems" to remove it, it might be because game exits / steam session resets.
  -- Still: explicit LeaveLobby is the correct behavior for real multiplayer.
  if not Steam.ok then return true end

  local ok, err = api.leaveLobby(Steam.lobby_id)
  Steam.lobby_id = nil
  Steam.lobby_call = nil
  Steam.lobby_state = "none"
  Steam.lobby_error = nil
  return ok, err
end

-- Overlay helper (kept as stub; if you already have this working, keep your own)
function Steam.openFriendsOverlay()
  -- If your current code opens overlay already, DON'T replace it here.
  -- Returning true so UI flow won't crash.
  return true
end

return Steam

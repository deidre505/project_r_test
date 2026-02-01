-- steam/steam.lua
-- FFI(steam_api64.dll) 기반 최소 Steam 래퍼
-- - init / update / shutdown 안정화
-- - lobby_state / lobby_id 유지
-- - Invite 버튼 비활성화 문제 해결( hasLobby 제공 )

local api = require("sworks.api")

local Steam = {
  ok = false,

  lobby_id = nil,
  lobby_state = "none", -- none | creating | created | joined | error
  lobby_error = nil,

  init_method = nil,
  last_error = nil,
}

function Steam.init()
  if Steam.ok then return true end

  -- DLL 로드 및 SteamAPI_Init* 시도
  local ok, how = api.init()
  Steam.ok = ok
  Steam.init_method = ok and how or nil
  Steam.last_error = ok and nil or how

  if not ok then
    Steam.lobby_state = "error"
    Steam.lobby_error = tostring(how)
    return false
  end

  print("[Steam] init via", how)
  return true
end

function Steam.update()
  if not Steam.ok then return end
  -- 매 프레임 1회 콜백 처리
  api.runCallbacks()
end

function Steam.shutdown()
  -- ✅ main.lua에서 Steam.shutdown() 호출해도 크래시 안 나게
  if Steam.ok then
    pcall(function()
      api.shutdown()
    end)
  end

  Steam.ok = false
  Steam.init_method = nil
  Steam.last_error = nil
  Steam.lobby_id = nil
  Steam.lobby_state = "none"
  Steam.lobby_error = nil
end

function Steam.getStatus()
  if Steam.ok then
    return true, "Steam: OK (SteamAPI)"
  end
  return false, "Steam: FAIL"
end

function Steam.hasLobby()
  -- ✅ Invite 버튼 enable 조건에서 쓰는 함수
  return (Steam.lobby_state == "created" or Steam.lobby_state == "joined") and Steam.lobby_id ~= nil
end

-- =========================
-- Host: Lobby 생성 (지금 단계에서는 “상태만”)
-- =========================
function Steam.createLobby()
  if not Steam.ok then return false, "Steam not ready" end

  Steam.lobby_state = "creating"
  Steam.lobby_error = nil

  print("[Steam] createLobby called")

  -- ⚠️ 현재는 “로비 생성 성공 상태”까지만.
  -- 실제 Steam Matchmaking으로 lobby_id를 받는 건 다음 단계에서 붙일 것.
  Steam.lobby_state = "created"
  Steam.lobby_id = "TEMP_LOBBY"

  print("[Steam] Lobby created (step 1)")
  return true
end

-- =========================
-- Invite: 지금 FFI 최소버전에서는 “초대 다이얼로그를 직접 못 띄움”
-- =========================
function Steam.inviteSteamFriend()
  if not Steam.ok then return false, "Steam not ready" end
  if not Steam.hasLobby() then return false, "Lobby not ready" end

  -- ✅ 여기서 할 수 있는 확실한 동작:
  -- 1) 오버레이는 Shift+Tab으로 열리므로 안내 로그를 남김
  print("[Steam] Invite requested. Open Steam Overlay (Shift+Tab) -> Friends -> Invite to Game")

  return true
end

return Steam

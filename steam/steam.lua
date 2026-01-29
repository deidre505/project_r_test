-- steam/steam.lua
-- High-level Steam wrapper used by game code.
-- Depends on: sworks/api.lua

local api = require("sworks.api")

local Steam = {
  ok = false,
  init_method = nil,
  last_error = nil,
}

-- 내부 유틸: 안전 호출
local function _safe_call(fn, ...)
  if type(fn) ~= "function" then return false, "missing function" end
  local ok, res1, res2 = pcall(fn, ...)
  if not ok then
    return false, tostring(res1)
  end
  return true, res1, res2
end

function Steam.init()
  -- DLL 로드 실패 방어
  if not api or not api._lib then
    Steam.ok = false
    Steam.init_method = nil
    Steam.last_error = (api and api._load_error) or "steam api not loaded"
    return false
  end

  -- api.init()는 (bool, "InitFlat"/"Init"/"error msg") 형태로 만들었을 때 가장 편함
  local ok, how = api.init()
  Steam.ok = ok == true
  Steam.init_method = ok and (how or "OK") or nil
  Steam.last_error = ok and nil or (how or "Steam init failed")

  return Steam.ok
end

function Steam.shutdown()
  Steam.ok = false
  Steam.init_method = nil
  Steam.last_error = nil
  if api and api.shutdown then
    pcall(api.shutdown)
  end
end

function Steam.runCallbacks()
  if Steam.ok and api and api.runCallbacks then
    pcall(api.runCallbacks)
  end
end

function Steam.update()
  Steam.runCallbacks()
end

function Steam.isReady()
  return Steam.ok == true
end

-- ✅ 여기서 (ok, status_string) 형태로 반환해야 play_with_friends가 안 깨짐
function Steam.getStatus()
  if Steam.ok then
    local how = Steam.init_method or "OK"
    return true, ("Steam: OK (%s)"):format(how)
  end
  local err = Steam.last_error or "NOT INITIALIZED"
  return false, ("Steam: FAIL (%s)"):format(err)
end

-- ✅ Invite 버튼 눌렀을 때 “아무 것도 안 됨”이 아니라,
-- 가장 먼저 확인 가능한 동작(스팀 오버레이 Friends 창)을 띄우는 방식이 안전함
function Steam.openFriendsOverlay()
  if not Steam.ok then
    return false, "Steam not ready"
  end

  -- api.activateOverlay("Friends") 류 함수가 있으면 사용
  if api.activateOverlay then
    local ok, err = _safe_call(api.activateOverlay, "Friends")
    if ok then return true end
    return false, err
  end

  -- 다른 이름으로 만들어져 있을 수도 있으니 흔한 후보도 방어적으로 시도
  if api.activateGameOverlay then
    local ok, err = _safe_call(api.activateGameOverlay, "Friends")
    if ok then return true end
    return false, err
  end

  return false, "No overlay function in api"
end

return Steam

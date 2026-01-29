-- steam/steam.lua
-- High-level Steam wrapper used by game code.
-- Requires: sworks/api.lua

local api = require("sworks.api")

local Steam = {
  ok = false,
  init_method = nil,
  last_error = nil,
}

function Steam.init()
  -- DLL 로드가 실패했으면 여기서 종료
  if not api.isLoaded() then
    -- 로드 시도 한 번 해봄
    local ok, how = api.init()
    if ok then
      Steam.ok = true
      Steam.init_method = how
      Steam.last_error = nil
      return true
    else
      Steam.ok = false
      Steam.init_method = nil
      Steam.last_error = how
      return false
    end
  end

  local ok, how = api.init()
  Steam.ok = ok
  Steam.init_method = ok and how or nil
  Steam.last_error = ok and nil or how
  return ok
end

function Steam.shutdown()
  Steam.ok = false
  Steam.init_method = nil
  Steam.last_error = nil
  api.shutdown()
end

function Steam.runCallbacks()
  if Steam.ok then
    api.runCallbacks()
  end
end

function Steam.update()
  -- LOVE update에서 매 프레임 호출용 (선택)
  Steam.runCallbacks()
end

function Steam.isReady()
  return Steam.ok == true
end

-- ✅ 크래시 방지 핵심: getStatus는 항상 존재해야 함
function Steam.getStatus()
  if Steam.ok then
    return "Steam: OK (" .. tostring(Steam.init_method or "unknown") .. ")"
  end
  if Steam.last_error then
    return "Steam: INIT FAILED (" .. tostring(Steam.last_error) .. ")"
  end
  return "Steam: NOT INITIALIZED"
end

return Steam

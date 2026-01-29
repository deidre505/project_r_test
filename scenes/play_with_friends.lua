-- scenes/play_with_friends.lua
-- Steam P2P 멀티 전용 진입 씬
-- - 모바일: 사용 불가 안내
-- - PC: Steam 상태(OK/FAIL) 표시 + 다음 단계 버튼 자리

local Button = require("ui.button")
local Steam = require("steam.steam")

local Scene = {}
Scene.__index = Scene

-- Steam.getStatus()의 반환 형태가 바뀌어도(문자열 1개 / (bool, string) 2개) 항상 안전하게 정규화
local function normalizeSteamStatus()
  -- Steam 모듈 로딩 실패/누락 방어
  if not Steam then
    return false, "Steam: MODULE NOT FOUND"
  end

  local ok, a, b = pcall(function()
    return Steam.getStatus and Steam.getStatus() or nil
  end)

  if not ok then
    -- getStatus 호출 중 에러
    return false, "Steam: STATUS ERROR"
  end

  -- 케이스 1) getStatus()가 (bool, string) 반환
  if type(a) == "boolean" then
    local status = (type(b) == "string" and b) or tostring(b or "Steam: UNKNOWN")
    return a, status
  end

  -- 케이스 2) getStatus()가 string 1개만 반환
  if type(a) == "string" then
    -- 문자열에 "OK"가 포함되면 ok=true로 간주(기존 기능 유지용)
    local inferred_ok = a:find("OK", 1, true) ~= nil
    return inferred_ok, a
  end

  -- 케이스 3) nil/기타 타입
  return false, tostring(a or "Steam: UNKNOWN")
end

function Scene.new(sm, params)
  local self = setmetatable({}, Scene)
  self.sm = sm

  params = params or {}
  self.viewport = params.viewport

  self.pointerX, self.pointerY = 0, 0

  local os = love.system.getOS()
  self.isMobile = (os == "Android" or os == "iOS")

  self.backBtn = Button.new(
    { x = 20, y = 20, w = 160, h = 48 },
    "Back",
    function()
      self.sm:switch("scenes.lobby", { viewport = self.viewport })
    end
  )

  -- 다음 단계(초대/로비)로 이어질 버튼: 지금은 자리만 둠
  self.inviteBtn = Button.new(
    { x = 340, y = 420, w = 320, h = 60 },
    "Invite Steam Friend",
    function()
      print("[Steam P2P] Invite friend (next step)")
    end
  )

  return self
end

function Scene:pointerMoved(x, y)
  self.pointerX, self.pointerY = x, y
end

function Scene:pointerPressed(x, y)
  self.pointerX, self.pointerY = x, y
  if self.backBtn and self.backBtn:tryClick(x, y) then return end
  if self.inviteBtn then self.inviteBtn:tryClick(x, y) end
end

function Scene:keypressed(key)
  if key == "escape" then
    self.sm:switch("scenes.lobby", { viewport = self.viewport })
  end
end

function Scene:draw()
  if self.backBtn then
    self.backBtn:draw(self.pointerX, self.pointerY)
  end

  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.print("Play With Friends", 20, 90)

  -- ✅ Steam 상태 표시 (항상 string 보장)
  local ok, status = normalizeSteamStatus()

  if ok then
    love.graphics.setColor(0.6, 1, 0.6, 0.95)
  else
    love.graphics.setColor(1, 0.6, 0.6, 0.95)
  end
  love.graphics.print(tostring(status or "Steam: UNKNOWN"), 20, 130)

  if self.isMobile then
    love.graphics.setColor(1, 0.45, 0.45, 0.95)
    love.graphics.print(
      "This mode is not available on mobile devices.\n\n" ..
      "Please use a PC (Steam) to play with friends.",
      20, 180
    )
    return
  end

  -- PC 안내
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.print(
    "PC only mode.\n\n" ..
    "Next steps:\n" ..
    "1) Confirm Steam shows OK above\n" ..
    "2) Implement Steam invite / lobby\n" ..
    "3) Implement P2P message (Ping -> Shot)\n",
    20, 180
  )

  -- Steam이 OK일 때만 버튼 활성
  if self.inviteBtn then
    self.inviteBtn.enabled = (ok == true) -- nil 방지
    self.inviteBtn:draw(self.pointerX, self.pointerY)
  end

  if not ok then
    love.graphics.setColor(1, 1, 1, 0.55)
    love.graphics.print(
      "Tip: Steam binding not installed or game not running under Steam.\n" ..
      "Steam P2P implementation will be added next.",
      20, 520
    )
  end
end

return Scene

-- scenes/play_with_friends.lua
-- Steam P2P 멀티 전용 진입 씬

local Button = require("ui.button")
local Steam = require("steam.steam")

local Scene = {}
Scene.__index = Scene

function Scene.new(sm, params)
  local self = setmetatable({}, Scene)
  self.sm = sm
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

  self.inviteBtn = Button.new(
    { x = 340, y = 420, w = 320, h = 60 },
    "Invite Steam Friend",
    function()
      -- ✅ 여기서 바로 “친구 초대”는 보통 '로비 SteamID'가 있어야 의미가 있어서,
      -- 우선은 오버레이 Friends 창을 띄우는 걸 1차 확인 단계로 둠.
      if not Steam.isReady() then
        print("[Steam] not ready - cannot open overlay")
        return
      end

      local ok, err = Steam.openFriendsOverlay()
      if ok then
        print("[Steam] Friends overlay opened")
      else
        print("[Steam] Failed to open overlay: " .. tostring(err))
      end
    end
  )

  return self
end

function Scene:pointerMoved(x, y)
  self.pointerX, self.pointerY = x, y
end

function Scene:pointerPressed(x, y)
  self.pointerX, self.pointerY = x, y
  if self.backBtn:tryClick(x, y) then return end
  self.inviteBtn:tryClick(x, y)
end

function Scene:keypressed(key)
  if key == "escape" then
    self.sm:switch("scenes.lobby", { viewport = self.viewport })
  end
end

function Scene:draw()
  self.backBtn:draw(self.pointerX, self.pointerY)

  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.print("Play With Friends", 20, 90)

  -- ✅ Steam 상태 표시 (항상 문자열 보장)
  local ok, status = Steam.getStatus()
  status = status or "Steam: (status nil)"

  if ok then
    love.graphics.setColor(0.6, 1, 0.6, 0.95)
  else
    love.graphics.setColor(1, 0.6, 0.6, 0.95)
  end
  love.graphics.print(status, 20, 130)

  if self.isMobile then
    love.graphics.setColor(1, 0.45, 0.45, 0.95)
    love.graphics.print(
      "This mode is not available on mobile devices.\n\n" ..
      "Please use a PC (Steam) to play with friends.",
      20, 180
    )
    return
  end

  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.print(
    "PC only mode.\n\n" ..
    "Next steps:\n" ..
    "1) Confirm Steam shows OK above\n" ..
    "2) Confirm Steam overlay opens with Invite button\n" ..
    "3) Implement Lobby + invite-to-lobby\n" ..
    "4) Implement P2P message (Ping -> Shot)\n",
    20, 180
  )

  -- Steam OK일 때만 버튼 활성
  self.inviteBtn.enabled = ok
  self.inviteBtn:draw(self.pointerX, self.pointerY)

  if not ok then
    love.graphics.setColor(1, 1, 1, 0.55)
    love.graphics.print(
      "Tip: Run under Steam (Add as Non-Steam Game or proper AppID build).\n" ..
      "Also ensure steam_api64.dll is next to the exe.",
      20, 520
    )
  end
end

return Scene

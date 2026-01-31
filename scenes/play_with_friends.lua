-- scenes/play_with_friends.lua
-- Steam P2P entry scene (Create Lobby - STEP 1)
-- - PC: Steam 상태 표시 + 로비 생성 + 오버레이(친구) 열기
-- - Mobile: 사용 불가 안내
-- - Back/ESC 시 로비가 있으면 LeaveLobby 호출(정석 정리)

local Button = require("ui.button")
local Steam  = require("steam.steam")

local Scene = {}
Scene.__index = Scene

function Scene.new(sm, params)
  local self = setmetatable({}, Scene)
  self.sm = sm
  self.viewport = params.viewport
  self.pointerX, self.pointerY = 0, 0

  local os = love.system.getOS()
  self.isMobile = (os == "Android" or os == "iOS")

  --------------------------------------------------
  -- Buttons
  --------------------------------------------------
  self.backBtn = Button.new(
    { x = 20, y = 20, w = 160, h = 48 },
    "Back",
    function()
      -- ✅ (A) Back 버튼: 로비가 있으면 닫고 나가기
      if Steam.hasLobby and Steam.hasLobby() then
        pcall(function() Steam.leaveLobby() end)
      end
      self.sm:switch("scenes.lobby", { viewport = self.viewport })
    end
  )

  self.createLobbyBtn = Button.new(
    { x = 340, y = 330, w = 320, h = 60 },
    "Create Lobby",
    function()
      local ok, err = Steam.createLobby()
      if ok then
        print("[Steam] Lobby created (step 1)")
      else
        print("[Steam] CreateLobby failed:", err)
      end
    end
  )

  self.inviteBtn = Button.new(
    { x = 340, y = 420, w = 320, h = 60 },
    "Invite Steam Friend",
    function()
      local ok, err = Steam.openFriendsOverlay()
      if not ok then
        print("[Steam] Invite failed:", err)
      end
    end
  )

  return self
end

--------------------------------------------------
-- Input
--------------------------------------------------
function Scene:pointerMoved(x, y)
  self.pointerX, self.pointerY = x, y
end

function Scene:pointerPressed(x, y)
  self.pointerX, self.pointerY = x, y
  if self.backBtn:tryClick(x, y) then return end
  self.createLobbyBtn:tryClick(x, y)
  self.inviteBtn:tryClick(x, y)
end

function Scene:keypressed(key)
  if key == "escape" then
    -- ✅ (B) ESC: 로비가 있으면 닫고 나가기
    if Steam.hasLobby and Steam.hasLobby() then
      pcall(function() Steam.leaveLobby() end)
    end
    self.sm:switch("scenes.lobby", { viewport = self.viewport })
  end
end

--------------------------------------------------
-- Draw
--------------------------------------------------
function Scene:draw()
  self.backBtn:draw(self.pointerX, self.pointerY)

  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.print("Play With Friends", 20, 90)

  -- Steam status
  local ok, status = Steam.getStatus()
  if ok then
    love.graphics.setColor(0.6, 1, 0.6, 0.95)
  else
    love.graphics.setColor(1, 0.6, 0.6, 0.95)
  end
  love.graphics.print(status, 20, 130)

  if self.isMobile then
    love.graphics.setColor(1, 0.45, 0.45, 0.95)
    love.graphics.print(
      "This mode is not available on mobile devices.",
      20, 180
    )
    return
  end

  -- Lobby status
  love.graphics.setColor(1, 1, 1, 0.85)
  love.graphics.print("Lobby State: " .. tostring(Steam.lobby_state), 20, 170)

  if Steam.lobby_id then
    love.graphics.print("Lobby ID: " .. tostring(Steam.lobby_id), 20, 195)
  end

  if Steam.lobby_error then
    love.graphics.setColor(1, 0.5, 0.5, 0.95)
    love.graphics.print("Lobby Error: " .. tostring(Steam.lobby_error), 20, 225)
  end

  -- Button enable rules
  self.createLobbyBtn.enabled = ok and Steam.lobby_state ~= "created"
  self.inviteBtn.enabled      = ok and (Steam.hasLobby and Steam.hasLobby() or false)

  self.createLobbyBtn:draw(self.pointerX, self.pointerY)
  self.inviteBtn:draw(self.pointerX, self.pointerY)
end

return Scene

-- scenes/play_with_friends.lua
-- Steam P2P entry scene (Create Lobby - STEP 1)
-- + Leave/Close lobby on Back / ESC (to avoid stale lobbies)

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
      -- ✅ leave/close lobby when leaving this scene
      if Steam.leaveLobby then
        Steam.leaveLobby()
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
    -- ✅ leave/close lobby when leaving this scene
    if Steam.leaveLobby then
      Steam.leaveLobby()
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
  love.graphics.setColor(ok and 0.6 or 1, ok and 1 or 0.6, 0.6, 0.95)
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
  love.graphics.print(
    "Lobby State: " .. tostring(Steam.lobby_state),
    20, 170
  )

  if Steam.lobby_id then
    love.graphics.print(
      "Lobby ID: " .. tostring(Steam.lobby_id),
      20, 195
    )
  end

  -- Button enable rules
  self.createLobbyBtn.enabled = ok and Steam.lobby_state ~= "created"
  self.inviteBtn.enabled      = ok and Steam.hasLobby()

  self.createLobbyBtn:draw(self.pointerX, self.pointerY)
  self.inviteBtn:draw(self.pointerX, self.pointerY)
end

return Scene

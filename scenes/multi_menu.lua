local Button = require("ui.button")

local MultiMenu = {}
MultiMenu.__index = MultiMenu

function MultiMenu.new(sm, params)
  local self = setmetatable({}, MultiMenu)
  self.sm = sm
  self.viewport = params.viewport
  self.pointerX, self.pointerY = 0, 0

  self.buttons = {
    Button.new({ x = 340, y = 280, w = 320, h = 60 }, "Create Room", function()
      self.sm:switch("scenes.multi_host", { viewport = self.viewport })
    end),
    Button.new({ x = 340, y = 360, w = 320, h = 60 }, "Join Room", function()
      self.sm:switch("scenes.multi_join", { viewport = self.viewport })
    end),
    Button.new({ x = 20, y = 20, w = 160, h = 48 }, "Back", function()
      self.sm:switch("scenes.lobby", { viewport = self.viewport })
    end),
  }

  return self
end

function MultiMenu:pointerMoved(x, y)
  self.pointerX, self.pointerY = x, y
end

function MultiMenu:pointerPressed(x, y)
  self.pointerX, self.pointerY = x, y
  for _, b in ipairs(self.buttons) do
    if b:tryClick(x, y) then return end
  end
end

function MultiMenu:keypressed(key)
  if key == "escape" then
    self.sm:switch("scenes.lobby", { viewport = self.viewport })
  end
end

function MultiMenu:draw()
  love.graphics.setColor(1, 1, 1, 0.95)
  local title = "Multiplayer"
  local tw = love.graphics.getFont():getWidth(title)
  love.graphics.print(title, (1000 - tw)/2, 170)

  for _, b in ipairs(self.buttons) do
    b:draw(self.pointerX, self.pointerY)
  end

  love.graphics.setColor(1, 1, 1, 0.6)
  love.graphics.print("This version: UI flow only (no real networking yet).", 20, 620)
end

return MultiMenu

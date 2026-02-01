local Button = require("ui.button")

local Settings = {}
Settings.__index = Settings

function Settings.new(sm, params)
  local self = setmetatable({}, Settings)
  self.sm = sm
  self.viewport = params.viewport
  self.pointerX, self.pointerY = 0, 0

  self.backBtn = Button.new({ x = 20, y = 20, w = 160, h = 48 }, "Back", function()
    self.sm:switch("scenes.lobby", { viewport = self.viewport })
  end)

  return self
end

function Settings:pointerMoved(x, y)
  self.pointerX, self.pointerY = x, y
end

function Settings:pointerPressed(x, y)
  self.pointerX, self.pointerY = x, y
  self.backBtn:tryClick(x, y)
end

function Settings:keypressed(key)
  if key == "escape" then
    self.sm:switch("scenes.lobby", { viewport = self.viewport })
  end
end

function Settings:draw()
  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.print("Settings (placeholder)", 20, 90)
  love.graphics.setColor(1, 1, 1, 0.6)
  love.graphics.print("No settings implemented in this version.", 20, 120)

  self.backBtn:draw(self.pointerX, self.pointerY)
end

return Settings

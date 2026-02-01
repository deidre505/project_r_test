-- scenes/lobby.lua
local Button = require("ui.button")
local LocalController = require("controllers.local_controller")

local Lobby = {}
Lobby.__index = Lobby

function Lobby.new(sm, params)
  local self = setmetatable({}, Lobby)
  self.sm = sm
  self.viewport = params.viewport
  self.pointerX, self.pointerY = 0, 0

  self.buttons = {
    Button.new({ x = 340, y = 250, w = 320, h = 60 }, "Play Local", function()
      self.sm:switch("scenes.game", {
        viewport = self.viewport,
        controller = LocalController.new()
      })
    end),

    Button.new({ x = 340, y = 330, w = 320, h = 60 }, "Play With Friends", function()
      self.sm:switch("scenes.play_with_friends", { viewport = self.viewport })
    end),

    Button.new({ x = 340, y = 410, w = 320, h = 60 }, "Random Lobby", function()
      -- 서버 멀티(나중에)
      self.sm:switch("scenes.multi_menu", { viewport = self.viewport })
    end),

    Button.new({ x = 340, y = 490, w = 320, h = 60 }, "Settings", function()
      self.sm:switch("scenes.settings", { viewport = self.viewport })
    end),
  }

  return self
end

function Lobby:pointerMoved(x, y)
  self.pointerX, self.pointerY = x, y
end

function Lobby:pointerPressed(x, y)
  self.pointerX, self.pointerY = x, y
  for _, b in ipairs(self.buttons) do
    if b:tryClick(x, y) then return end
  end
end

function Lobby:draw()
  love.graphics.setColor(1, 1, 1, 0.95)
  local title = "ALGGAKI"
  local tw = love.graphics.getFont():getWidth(title)
  love.graphics.print(title, (1000 - tw)/2, 140)

  for _, b in ipairs(self.buttons) do
    b:draw(self.pointerX, self.pointerY)
  end
end

return Lobby

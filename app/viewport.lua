-- app/viewport.lua
-- Handles logical resolution scaling + letterboxing.
local Viewport = {}
Viewport.__index = Viewport

function Viewport.new(lw, lh)
  local self = setmetatable({}, Viewport)
  self.lw, self.lh = lw, lh
  self.scale = 1
  self.ox, self.oy = 0, 0
  self:update()
  return self
end

function Viewport:update()
  local sw, sh = love.graphics.getDimensions()
  self.scale = math.min(sw / self.lw, sh / self.lh)
  self.ox = (sw - self.lw * self.scale) / 2
  self.oy = (sh - self.lh * self.scale) / 2
end

function Viewport:beginDraw()
  love.graphics.push()
  love.graphics.translate(self.ox, self.oy)
  love.graphics.scale(self.scale, self.scale)
end

function Viewport:endDraw()
  love.graphics.pop()
end

function Viewport:screenToWorld(mx, my)
  local x = (mx - self.ox) / self.scale
  local y = (my - self.oy) / self.scale
  return x, y
end

return Viewport

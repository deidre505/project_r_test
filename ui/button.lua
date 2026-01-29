-- ui/button.lua
-- Simple rectangle button with hover + click.

local Button = {}
Button.__index = Button

function Button.new(rect, label, onClick)
  return setmetatable({
    rect = rect,
    label = label,
    onClick = onClick,
    enabled = true
  }, Button)
end

local function pointInRect(x, y, r)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function Button:isHover(x, y)
  return pointInRect(x, y, self.rect)
end

function Button:tryClick(x, y)
  if not self.enabled then return false end
  if self:isHover(x, y) then
    if self.onClick then self.onClick() end
    return true
  end
  return false
end

function Button:draw(pointerX, pointerY)
  local hover = self:isHover(pointerX, pointerY)

  if not self.enabled then
    love.graphics.setColor(0.12, 0.12, 0.13)
  elseif hover then
    love.graphics.setColor(0.25, 0.25, 0.28)
  else
    love.graphics.setColor(0.18, 0.18, 0.20)
  end
  love.graphics.rectangle("fill", self.rect.x, self.rect.y, self.rect.w, self.rect.h, 14, 14)

  love.graphics.setColor(0.65, 0.65, 0.7)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", self.rect.x, self.rect.y, self.rect.w, self.rect.h, 14, 14)

  love.graphics.setColor(1, 1, 1, 0.95)
  local font = love.graphics.getFont()
  local tw = font:getWidth(self.label)
  local th = font:getHeight()
  love.graphics.print(self.label, self.rect.x + (self.rect.w - tw)/2, self.rect.y + (self.rect.h - th)/2)
end

return Button

-- ui/checkbox.lua
-- 간단한 체크박스 UI 컴포넌트
-- - 클릭하면 checked 토글
-- - 라벨 표시

local Checkbox = {}
Checkbox.__index = Checkbox

local function pointInRect(x, y, r)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function Checkbox.new(rect, label, initial, onChange)
  return setmetatable({
    rect = rect,
    label = label or "",
    checked = initial or false,
    onChange = onChange
  }, Checkbox)
end

function Checkbox:tryClick(x, y)
  if pointInRect(x, y, self.rect) then
    self.checked = not self.checked
    if self.onChange then self.onChange(self.checked) end
    return true
  end
  return false
end

function Checkbox:draw(pointerX, pointerY)
  local hover = pointInRect(pointerX, pointerY, self.rect)

  -- box
  love.graphics.setColor(0.16, 0.16, 0.18)
  love.graphics.rectangle("fill", self.rect.x, self.rect.y, 28, 28, 6, 6)

  if hover then love.graphics.setColor(0.75, 0.75, 0.8)
  else love.graphics.setColor(0.45, 0.45, 0.5) end
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", self.rect.x, self.rect.y, 28, 28, 6, 6)

  -- check mark
  if self.checked then
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.line(self.rect.x + 6, self.rect.y + 14, self.rect.x + 12, self.rect.y + 20)
    love.graphics.line(self.rect.x + 12, self.rect.y + 20, self.rect.x + 22, self.rect.y + 8)
  end

  -- label
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.print(self.label, self.rect.x + 40, self.rect.y + 4)
end

return Checkbox

-- ui/textbox.lua
-- 단일 라인 텍스트 입력 박스
-- - focus 개념 있음(클릭해서 활성화)
-- - love.textinput / keypressed(backspace) 처리
-- - 글자수 제한, 허용 문자 필터 가능

local TextBox = {}
TextBox.__index = TextBox

local function pointInRect(x, y, r)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function TextBox.new(rect, placeholder, maxLen, options)
  options = options or {}
  return setmetatable({
    rect = rect,
    placeholder = placeholder or "",
    text = "",
    maxLen = maxLen or 24,
    focused = false,
    enabled = (options.enabled ~= false),
    -- 허용 문자 패턴(기본: 모든 문자 허용)
    allowPattern = options.allowPattern, -- 예: "^[%w%s%p]$" 같은 식으로 1글자 체크
  }, TextBox)
end

function TextBox:setEnabled(v)
  self.enabled = v
  if not v then self.focused = false end
end

function TextBox:tryClick(x, y)
  if not self.enabled then
    self.focused = false
    return false
  end
  self.focused = pointInRect(x, y, self.rect)
  return self.focused
end

function TextBox:keypressed(key)
  if not self.enabled or not self.focused then return end
  if key == "backspace" then
    self.text = self.text:sub(1, math.max(0, #self.text - 1))
  end
end

function TextBox:textinput(t)
  if not self.enabled or not self.focused then return end
  if #self.text >= self.maxLen then return end

  -- 1글자 단위 필터링
  if self.allowPattern and not t:match(self.allowPattern) then
    return
  end
  -- 줄바꿈/탭 같은 건 제외
  if t == "\n" or t == "\r" or t == "\t" then return end

  self.text = self.text .. t
end

function TextBox:draw()
  local r = self.rect

  -- background
  if not self.enabled then
    love.graphics.setColor(0.12, 0.12, 0.13)
  else
    love.graphics.setColor(0.16, 0.16, 0.18)
  end
  love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 12, 12)

  -- border
  if self.focused and self.enabled then
    love.graphics.setColor(1, 1, 1, 0.9)
  else
    love.graphics.setColor(0.38, 0.38, 0.42, 0.9)
  end
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", r.x, r.y, r.w, r.h, 12, 12)

  -- text / placeholder
  local show = self.text
  if show == "" and not self.focused then
    love.graphics.setColor(1, 1, 1, 0.35)
    love.graphics.print(self.placeholder, r.x + 12, r.y + 14)
  else
    love.graphics.setColor(1, 1, 1, 0.9)
    local caret = ""
    if self.focused and (love.timer.getTime() % 1 < 0.5) then caret = "_" end
    love.graphics.print(show .. caret, r.x + 12, r.y + 14)
  end
end

return TextBox

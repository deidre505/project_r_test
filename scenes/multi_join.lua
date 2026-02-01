local Button = require("ui.button")

local MultiJoin = {}
MultiJoin.__index = MultiJoin

function MultiJoin.new(sm, params)
  local self = setmetatable({}, MultiJoin)
  self.sm = sm
  self.viewport = params.viewport
  self.pointerX, self.pointerY = 0, 0

  self.joinCode = ""
  self.maxLen = 8
  self.status = "Enter room code"

  self.backBtn = Button.new({ x = 20, y = 20, w = 160, h = 48 }, "Back", function()
    self.sm:switch("scenes.multi_menu", { viewport = self.viewport })
  end)

  self.joinBtn = Button.new({ x = 20, y = 260, w = 220, h = 56 }, "Join (stub)", function()
    -- 이번 버전은 실제 연결 없음: 입력 검증 흉내만
    if #self.joinCode >= 4 then
      self.status = "Join requested: " .. self.joinCode .. " (not implemented)"
    else
      self.status = "Code too short"
    end
  end)

  return self
end

function MultiJoin:pointerMoved(x, y)
  self.pointerX, self.pointerY = x, y
end

function MultiJoin:pointerPressed(x, y)
  self.pointerX, self.pointerY = x, y
  if self.backBtn:tryClick(x, y) then return end
  self.joinBtn:tryClick(x, y)
end

function MultiJoin:keypressed(key)
  if key == "escape" then
    self.sm:switch("scenes.multi_menu", { viewport = self.viewport })
    return
  end

  if key == "backspace" then
    self.joinCode = self.joinCode:sub(1, math.max(0, #self.joinCode - 1))
  elseif key == "return" or key == "kpenter" then
    self.joinBtn.onClick()
  end
end

function MultiJoin:textinput(t)
  -- 방 코드는 영문/숫자만 받는다고 가정
  if #self.joinCode >= self.maxLen then return end
  local upper = t:upper()
  if upper:match("^[A-Z0-9]$") then
    self.joinCode = self.joinCode .. upper
  end
end

function MultiJoin:draw()
  self.backBtn:draw(self.pointerX, self.pointerY)

  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.print("Join Room", 20, 90)

  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.print("Room Code:", 20, 140)

  -- 입력 박스
  local box = { x = 20, y = 175, w = 340, h = 54 }
  love.graphics.setColor(0.16, 0.16, 0.18)
  love.graphics.rectangle("fill", box.x, box.y, box.w, box.h, 12, 12)
  love.graphics.setColor(0.35, 0.35, 0.38)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", box.x, box.y, box.w, box.h, 12, 12)

  love.graphics.setColor(1, 1, 1, 1.0)
  love.graphics.print(self.joinCode .. ((love.timer.getTime() % 1 < 0.5) and "_" or ""), box.x + 12, box.y + 15)

  self.joinBtn:draw(self.pointerX, self.pointerY)

  love.graphics.setColor(1, 1, 1, 0.6)
  love.graphics.print(self.status, 20, 340)
  love.graphics.print("Enter to submit, Backspace to delete, ESC to go back.", 20, 620)
end

return MultiJoin

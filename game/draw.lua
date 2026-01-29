-- game/draw.lua
-- Draw helpers: board, pieces, aim arrow, UI.

local Draw = {}

function Draw.board(state)
  local b = state.board
  love.graphics.setColor(0.16, 0.16, 0.18)
  love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 18, 18)

  love.graphics.setColor(0.35, 0.35, 0.38)
  love.graphics.setLineWidth(3)
  love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 18, 18)
end

function Draw.pieces(state)
  for _, p in ipairs(state.pieces) do
    if not p.dead then
      if p.owner == 1 then
        love.graphics.setColor(0.35, 0.65, 1.0)
      else
        love.graphics.setColor(1.0, 0.45, 0.45)
      end
      love.graphics.circle("fill", p.x, p.y, p.r)

      love.graphics.setColor(0, 0, 0, 0.35)
      love.graphics.setLineWidth(2)
      love.graphics.circle("line", p.x, p.y, p.r)
    end
  end
end

-- 현재 플레이어/선택 말 하이라이트
function Draw.highlights(state)
  if state.turnState ~= "aim" then return end

  for _, p in ipairs(state.pieces) do
    if not p.dead and p.owner == state.currentPlayer then
      love.graphics.setColor(1, 1, 1, 0.22)
      love.graphics.setLineWidth(2)
      love.graphics.circle("line", p.x, p.y, p.r + 4)
    end
  end
end

-- 드래그 중 화살표(발사 방향으로 나감)
function Draw.aimArrow(state)
  if not state.dragging or not state.selected or state.turnState ~= "aim" then return end

  local s = state.selected
  local ax = s.x - state.dragNow.x
  local ay = s.y - state.dragNow.y
  local len = math.sqrt(ax*ax + ay*ay)
  if len < 1 then return end

  local nx, ny = ax / len, ay / len
  local arrowLen = math.max(40, math.min(220, len * 2.0))

  local sx, sy = s.x, s.y
  local ex, ey = sx + nx * arrowLen, sy + ny * arrowLen

  love.graphics.setColor(1, 1, 1, 0.85)
  love.graphics.setLineWidth(3)
  love.graphics.line(sx, sy, ex, ey)

  -- Arrow head triangle
  local px, py = -ny, nx
  local headLen = 16
  local headWid = 10

  local hx, hy = ex - nx * headLen, ey - ny * headLen
  local lx, ly = hx + px * headWid, hy + py * headWid
  local rx, ry = hx - px * headWid, hy - py * headWid

  love.graphics.polygon("fill", ex, ey, lx, ly, rx, ry)
end

function Draw.ui(state)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.print(("Turn: Player %d   State: %s"):format(state.currentPlayer, state.turnState), 20, 20)

  -- 현재 플레이어 강조 색
  if state.currentPlayer == 1 then
    love.graphics.setColor(0.35, 0.65, 1.0, 0.9)
  else
    love.graphics.setColor(1.0, 0.45, 0.45, 0.9)
  end
  love.graphics.print(("Player %d"):format(state.currentPlayer), 20, 44)

  love.graphics.setColor(1, 1, 1, 0.9)
  local alive1, alive2 = 0, 0
  for _, p in ipairs(state.pieces) do
    if not p.dead then
      if p.owner == 1 then alive1 = alive1 + 1 else alive2 = alive2 + 1 end
    end
  end
  love.graphics.print(("P1 alive: %d   P2 alive: %d"):format(alive1, alive2), 20, 68)

  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.print("Drag to shoot | R: restart after win | ESC: Lobby", 20, 624)

  if state.turnState == "over" then
    love.graphics.setColor(1, 1, 1, 0.95)
    local text = state.winnerText .. "   (Press R)"
    local tw = love.graphics.getFont():getWidth(text)
    love.graphics.print(text, (1000 - tw)/2, 320)
  end
end

return Draw

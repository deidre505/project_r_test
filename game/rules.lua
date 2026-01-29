-- game/rules.lua
-- Setup, win conditions, turn transitions.

local Rules = {}

-- 5개씩, "ㅣ ㅣ" 배치(세로 1줄) 기본
function Rules.spawnDefaultPieces(state)
  state.pieces = {}

  local board = state.board
  local r = 18

  local cx = board.x + board.w / 2
  local cy = board.y + board.h / 2

  local p1x = cx - 260
  local p2x = cx + 260

  local spacing = 70
  local offsets = {
    { 0, -2*spacing },
    { 0, -1*spacing },
    { 0,  0 },
    { 0,  1*spacing },
    { 0,  2*spacing },
  }

  local id = 1
  for _, o in ipairs(offsets) do
    table.insert(state.pieces, { id = id, x = p1x + o[1], y = cy + o[2], vx = 0, vy = 0, r = r, owner = 1, dead = false })
    id = id + 1
  end
  for _, o in ipairs(offsets) do
    table.insert(state.pieces, { id = id, x = p2x + o[1], y = cy + o[2], vx = 0, vy = 0, r = r, owner = 2, dead = false })
    id = id + 1
  end
end

function Rules.countAlive(state, owner)
  local c = 0
  for _, p in ipairs(state.pieces) do
    if not p.dead and p.owner == owner then c = c + 1 end
  end
  return c
end

function Rules.allStopped(state)
  local minS2 = state.minStopSpeed * state.minStopSpeed
  for _, p in ipairs(state.pieces) do
    if not p.dead then
      local s2 = p.vx*p.vx + p.vy*p.vy
      if s2 > minS2 then return false end
    end
  end
  return true
end

function Rules.checkWinner(state)
  local p1 = Rules.countAlive(state, 1)
  local p2 = Rules.countAlive(state, 2)
  if p1 == 0 or p2 == 0 then
    if p1 == 0 and p2 == 0 then return "Draw!" end
    if p1 == 0 then return "Player 2 Wins!" end
    return "Player 1 Wins!"
  end
  return nil
end

function Rules.nextTurn(state)
  state.currentPlayer = (state.currentPlayer == 1) and 2 or 1
  state.turnState = "aim"
  state.selected = nil
  state.dragging = false
end

return Rules

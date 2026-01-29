-- scenes/game.lua
-- 로컬/멀티 공통 게임 씬.
-- "규칙/물리/승패"는 여기서만 처리하고,
-- "입력/내 턴인지 여부"는 controller가 제공한다.

local State = require("game.state")
local Rules = require("game.rules")
local Physics = require("game.physics")
local Draw = require("game.draw")
local Abilities = require("abilities.manager")

local Game = {}
Game.__index = Game

-- 거리 계산(선택 말 찾기용)
local function dist2(ax, ay, bx, by)
  local dx, dy = ax - bx, ay - by
  return dx*dx + dy*dy
end

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

-- 현재 턴 플레이어의 말만 선택 가능하게(로컬/멀티 공통 규칙)
local function pieceAt(state, x, y)
  local best, bestD2 = nil, 1e18
  for _, p in ipairs(state.pieces) do
    if not p.dead and p.owner == state.currentPlayer then
      local d2 = dist2(x, y, p.x, p.y)
      if d2 <= p.r*p.r and d2 < bestD2 then
        best, bestD2 = p, d2
      end
    end
  end
  return best
end

function Game.new(sm, params)
  local self = setmetatable({}, Game)
  self.sm = sm
  self.viewport = params.viewport

  -- controller 주입:
  --  - 로컬: controllers/local_controller.lua
  --  - 멀티: controllers/net_controller.lua (스텁)
  self.controller = assert(params.controller, "Game scene requires params.controller")

  self.state = State.new()

  -- 이번 버전 능력 없음. 다음 버전에서 abilities 모듈을 교체하면 됨.
  Abilities.setActive(require("abilities.none"))

  self:reset()
  return self
end

function Game:reset()
  Rules.spawnDefaultPieces(self.state)
  self.state.currentPlayer = 1
  self.state.turnState = "aim"
  self.state.winnerText = ""
  self.state.selected = nil
  self.state.dragging = false

  -- 턴 시작 훅(다음 버전 초능력 확장 포인트)
  Abilities.onTurnStart(self.state)
end

-- "내 턴인지 + 조준 상태인지"를 한 곳에서 통일해서 판단
function Game:canInteract()
  return self.state.turnState == "aim"
     and self.controller:isMyTurn(self.state.currentPlayer)
end

function Game:update(dt)
  -- 멀티(스텁)는 다음 버전에서 여기 update로 네트워크 이벤트 처리
  self.controller:update(dt, self.state)

  -- 게임 오버면 물리 정지
  if self.state.turnState == "over" then return end

  -- 물리 업데이트
  Physics.step(self.state, dt)

  -- 발사 후(wait) 모두 멈추면 턴 종료 처리
  if self.state.turnState == "wait" and Rules.allStopped(self.state) then
    local winner = Rules.checkWinner(self.state)
    if winner then
      self.state.winnerText = winner
      self.state.turnState = "over"
      return
    end

    -- 턴 종료 훅
    Abilities.onTurnEnd(self.state)

    -- 다음 턴
    Rules.nextTurn(self.state)

    -- 턴 시작 훅
    Abilities.onTurnStart(self.state)
  end
end

function Game:pointerMoved(x, y)
  -- 드래그 중 조준선 갱신을 위해 항상 좌표는 업데이트
  self.state.dragNow.x, self.state.dragNow.y = x, y
end

function Game:pointerPressed(x, y)
  -- ✅ 멀티 턴 분리 핵심: 내 턴이 아니면 클릭 자체 무시
  if not self:canInteract() then return end

  local p = pieceAt(self.state, x, y)
  if p then
    self.state.selected = p
    self.state.dragging = true
    self.state.dragNow.x, self.state.dragNow.y = x, y
  end
end

function Game:pointerReleased(x, y)
  -- ✅ 멀티 턴 분리 핵심: 내 턴이 아니면 발사도 무시
  if not self:canInteract() then return end
  if not self.state.dragging or not self.state.selected then return end

  self.state.dragging = false
  self.state.dragNow.x, self.state.dragNow.y = x, y

  local s = self.state.selected
  self.state.selected = nil

  -- "당긴 반대방향"으로 발사(알까기 느낌)
  local ax = s.x - x
  local ay = s.y - y
  local len = math.sqrt(ax*ax + ay*ay)
  if len < 1 then return end

  local power = clamp(len * 6.0, 0, self.state.maxShotPower)
  if power <= 30 then return end

  -- ===== 초능력 확장 포인트 =====
  -- 발사 "직전"에만 shotIntent를 수정할 수 있게 설계
  local shotIntent = {
    player = self.state.currentPlayer,
    pieceId = s.id,
    nx = ax / len,
    ny = ay / len,
    power = power
  }
  shotIntent = Abilities.beforeShot(self.state, shotIntent)

  -- 발사 적용
  s.vx = shotIntent.nx * shotIntent.power
  s.vy = shotIntent.ny * shotIntent.power

  Abilities.afterShot(self.state, shotIntent)

  self.state.turnState = "wait"
end

function Game:keypressed(key)
  -- 언제든 로비로
  if key == "escape" then
    self.sm:switch("scenes.lobby", { viewport = self.viewport })
    return
  end

  -- 승리 후 재시작
  if key == "r" and self.state.turnState == "over" then
    self:reset()
  end

  -- 디버그: T로 강제 턴 넘기기
  if key == "t" and self.state.turnState == "aim" then
    Abilities.onTurnEnd(self.state)
    Rules.nextTurn(self.state)
    Abilities.onTurnStart(self.state)
  end

end

function Game:draw()
  Draw.board(self.state)
  Draw.pieces(self.state)
  Draw.highlights(self.state)
  Draw.aimArrow(self.state)
  Draw.ui(self.state)

  -- 멀티에서 "상대 턴"일 때 안내 문구(UX 개선)
  if self.state.turnState == "aim" and not self.controller:isMyTurn(self.state.currentPlayer) then
    love.graphics.setColor(1, 1, 1, 0.75)
    local msg = "Waiting for opponent..."
    local tw = love.graphics.getFont():getWidth(msg)
    love.graphics.print(msg, (1000 - tw)/2, 590)
  end
end

return Game

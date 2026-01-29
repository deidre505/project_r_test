-- game/physics.lua
-- Physics: integrate, friction, circle collisions, out-of-bounds elimination.

local Physics = {}

local function resolveCircleCollision(a, b)
  local dx = b.x - a.x
  local dy = b.y - a.y
  local r = a.r + b.r
  local d2 = dx*dx + dy*dy
  if d2 <= 0 or d2 > r*r then return end

  local d = math.sqrt(d2)
  local nx, ny = dx / d, dy / d

  -- Push apart
  local overlap = r - d
  local push = overlap * 0.5
  a.x = a.x - nx * push
  a.y = a.y - ny * push
  b.x = b.x + nx * push
  b.y = b.y + ny * push

  -- Relative velocity along normal
  local rvx = b.vx - a.vx
  local rvy = b.vy - a.vy
  local vn = rvx * nx + rvy * ny
  if vn > 0 then return end

  local e = 0.95
  local j = -(1 + e) * vn / 2

  local ix = j * nx
  local iy = j * ny

  a.vx = a.vx - ix
  a.vy = a.vy - iy
  b.vx = b.vx + ix
  b.vy = b.vy + iy
end

local function killOutOfBoard(state)
  local b = state.board
  for _, p in ipairs(state.pieces) do
    if not p.dead then
      if p.x < b.x or p.x > b.x + b.w or p.y < b.y or p.y > b.y + b.h then
        p.dead = true
        p.vx, p.vy = 0, 0
      end
    end
  end
end

function Physics.step(state, dt)
  -- Integrate + friction
  local fr = math.pow(state.friction, dt * 60)
  local minS2 = state.minStopSpeed * state.minStopSpeed

  for _, p in ipairs(state.pieces) do
    if not p.dead then
      p.x = p.x + p.vx * dt
      p.y = p.y + p.vy * dt

      p.vx = p.vx * fr
      p.vy = p.vy * fr

      if (p.vx*p.vx + p.vy*p.vy) < minS2 then
        p.vx, p.vy = 0, 0
      end
    end
  end

  -- Collisions (naive N^2)
  for i = 1, #state.pieces do
    local a = state.pieces[i]
    if not a.dead then
      for j = i + 1, #state.pieces do
        local b = state.pieces[j]
        if not b.dead then
          resolveCircleCollision(a, b)
        end
      end
    end
  end

  -- Out rule (no wall bounce)
  killOutOfBoard(state)
end

return Physics

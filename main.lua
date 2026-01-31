-- main.lua
-- - SceneManager로 씬 전환/입력 라우팅
-- - Steam 래퍼(steam/steam.lua) init/update/shutdown 연결

-- steam diagnostics (크래시 방지: 실패해도 게임 계속)
pcall(require, "steam_diag")

local SceneManager = require("app.scene_manager")
local Steam = require("steam.steam")

local sm = nil

-- 현재 프로젝트 기준 고정 해상도
local VIRTUAL_W, VIRTUAL_H = 1000, 650

function love.load()
  love.window.setTitle("Alggaki")
  love.window.setMode(VIRTUAL_W, VIRTUAL_H, {
    resizable = false,
    vsync = true
  })

  love.math.setRandomSeed(os.time())

  -- Steam 초기화 (실패해도 게임은 계속 실행)
  Steam.init()

  sm = SceneManager.new()
  sm:switch("scenes.lobby", { viewport = { w = VIRTUAL_W, h = VIRTUAL_H } })
end

function love.update(dt)
  -- Steam 콜백 처리(초대/네트워크 이벤트 수신에 필요)
  Steam.update()

  if sm then
    sm:update(dt)
  end
end

function love.draw()
  if sm then
    sm:draw()
  end
end

function love.mousemoved(x, y, dx, dy)
  if sm then sm:pointerMoved(x, y) end
end

function love.mousepressed(x, y, button)
  if button == 1 and sm then
    sm:pointerPressed(x, y)
  end
end

function love.mousereleased(x, y, button)
  if button == 1 and sm then
    sm:pointerReleased(x, y)
  end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  local px, py = x * VIRTUAL_W, y * VIRTUAL_H
  if sm then sm:pointerMoved(px, py) end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  local px, py = x * VIRTUAL_W, y * VIRTUAL_H
  if sm then sm:pointerPressed(px, py) end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  local px, py = x * VIRTUAL_W, y * VIRTUAL_H
  if sm then sm:pointerReleased(px, py) end
end

function love.keypressed(key)
  if sm then
    sm:keypressed(key)
  end
end

function love.textinput(t)
  if sm then
    sm:textinput(t)
  end
end

function love.quit()
  -- Steam 종료
  Steam.shutdown()
end

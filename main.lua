-- main.lua
-- - SceneManager로 씬 전환/입력 라우팅
-- - Steam 래퍼(steam/steam.lua) init/update/shutdown 연결

-- ✅ file logger (Steam 실행에서도 로그 남기기)
local Logger = require("logger")
Logger.hook_print()
Logger.hook_errorhandler()
print("[Logger] writing to:", Logger.path())

-- steam diagnostics
require("steam_diag")

local SceneManager = require("app.scene_manager")
local Steam = require("steam.steam")

local sm = nil

-- 현재 프로젝트 기준 고정 해상도 (원하면 바꿔도 됨)
local VIRTUAL_W, VIRTUAL_H = 1000, 650

function love.load()
  love.window.setTitle("Alggaki")
  love.window.setMode(VIRTUAL_W, VIRTUAL_H, {
    resizable = false,
    vsync = true
  })

  -- 랜덤 시드 (룸코드 등)
  love.math.setRandomSeed(os.time())

  print("[Boot] LOVE started")
  print("[Boot] OS:", love.system.getOS(), "SaveDir:", love.filesystem.getSaveDirectory())

  -- ✅ Steam 초기화 (바인딩 없으면 실패해도 게임은 계속 실행)
  local ok = Steam.init()
  print("[Steam] init:", ok, Steam.getStatus and (select(2, Steam.getStatus())) or "")

  -- 씬 매니저 생성 + 로비 진입
  sm = SceneManager.new()
  sm:switch("scenes.lobby", { viewport = { w = VIRTUAL_W, h = VIRTUAL_H } })
end

function love.update(dt)
  -- ✅ Steam 콜백 처리(초대/네트워크 이벤트 수신에 필요)
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

-- 마우스 → 포인터 이벤트로 통일
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

-- 터치도 같은 포인터 이벤트로 통일 (모바일 대비)
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

-- ✅ 텍스트 입력(UI TextBox 등)
function love.textinput(t)
  if sm then
    sm:textinput(t)
  end
end

function love.quit()
  print("[Quit] love.quit called")
  -- ✅ Steam 종료
  Steam.shutdown()
end

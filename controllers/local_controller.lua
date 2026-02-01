-- controllers/local_controller.lua
-- 로컬 플레이용 입력 컨트롤러.
-- 같은 PC에서 번갈아 조작하므로 "내 턴" 개념이 사실상 없음.
-- (GameScene이 현재 턴 플레이어 말만 선택되게 제한하므로, 항상 true로 처리)

local LocalController = {}
LocalController.__index = LocalController

function LocalController.new()
  local self = setmetatable({}, LocalController)
  self.type = "local"
  return self
end

-- 로컬에서는 항상 입력 가능(단, GameScene에서 turnState=="aim"인지 체크)
function LocalController:isMyTurn(currentPlayer)
  return true
end

-- 로컬은 네트워크 이벤트가 없으므로 update에서 할 일 없음
function LocalController:update(dt, state) end

return LocalController

-- controllers/net_controller.lua
-- 멀티플레이용 컨트롤러(스텁).
-- 핵심: "내 턴이 아니면 입력을 막는다"를 강제하기 위한 myPlayerId 제공.
-- 실제 네트워크 연결/동기화는 다음 버전에서 붙이면 됨.

local NetController = {}
NetController.__index = NetController

function NetController.new(myPlayerId)
  local self = setmetatable({}, NetController)
  self.type = "net"
  self.myPlayerId = myPlayerId or 1
  return self
end

-- 멀티에서는 내 플레이어 번호가 고정이므로, currentPlayer와 비교해서 내 턴 여부를 판단
function NetController:isMyTurn(currentPlayer)
  return self.myPlayerId == currentPlayer
end

-- 다음 버전에서:
-- - 네트워크 메시지 수신(상대 샷)
-- - 샷 큐 관리
-- - 재접속/핑 처리
function NetController:update(dt, state) end

return NetController

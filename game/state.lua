-- game/state.lua
-- Holds game state (data only).

local State = {}

function State.new()
  return {
    board = { x = 70, y = 70, w = 860, h = 510 },
    friction = 0.985,
    minStopSpeed = 10,
    maxShotPower = 1600,

    pieces = {},

    currentPlayer = 1,
    turnState = "aim", -- aim / wait / over
    winnerText = "",

    dragging = false,
    selected = nil,
    dragNow = { x = 0, y = 0 },
  }
end

return State

-- util/room_code.lua
-- Generates easy-to-read room code (no 0/O, 1/I confusion).

local M = {}

local ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

function M.generate(len)
  len = len or 10   -- ✅ 기본값을 10자리
  local out = {}
  for i = 1, len do
    local idx = love.math.random(1, #ALPHABET)
    out[i] = ALPHABET:sub(idx, idx)
  end
  return table.concat(out)
end


return M

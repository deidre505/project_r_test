-- abilities/manager.lua
-- Ability hook manager (scaffold).
-- Next version: replace None with real abilities, but keep hooks the same.

local None = require("abilities.none")

local M = {
  active = None
}

function M.setActive(abilityModule)
  M.active = abilityModule or None
end

-- Hook wrappers (safe calls)
function M.onTurnStart(state)
  if M.active and M.active.onTurnStart then M.active.onTurnStart(state) end
end

function M.beforeShot(state, shotIntent)
  if M.active and M.active.beforeShot then
    return M.active.beforeShot(state, shotIntent) or shotIntent
  end
  return shotIntent
end

function M.afterShot(state, shotIntent)
  if M.active and M.active.afterShot then M.active.afterShot(state, shotIntent) end
end

function M.onTurnEnd(state)
  if M.active and M.active.onTurnEnd then M.active.onTurnEnd(state) end
end

return M

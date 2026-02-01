-- abilities/none.lua
-- Default ability set: does nothing.
local None = {}

function None.onTurnStart(state) end
function None.beforeShot(state, shotIntent) return shotIntent end
function None.afterShot(state, shotIntent) end
function None.onTurnEnd(state) end

return None

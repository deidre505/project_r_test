-- app/scene_manager.lua
-- Minimal scene stack/switch manager.
local SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager.new()
  return setmetatable({ current = nil }, SceneManager)
end

function SceneManager:switch(sceneModulePath, params)
  local mod = require(sceneModulePath)
  local scene = mod.new(self, params or {})
  self.current = scene
  if scene.enter then scene:enter(params or {}) end
end

function SceneManager:update(dt)
  if self.current and self.current.update then
    self.current:update(dt)
  end
end

function SceneManager:draw()
  if self.current and self.current.draw then
    self.current:draw()
  end
end

function SceneManager:pointerPressed(x, y)
  if self.current and self.current.pointerPressed then
    self.current:pointerPressed(x, y)
  end
end

function SceneManager:pointerMoved(x, y)
  if self.current and self.current.pointerMoved then
    self.current:pointerMoved(x, y)
  end
end

function SceneManager:pointerReleased(x, y)
  if self.current and self.current.pointerReleased then
    self.current:pointerReleased(x, y)
  end
end

function SceneManager:keypressed(key)
  if self.current and self.current.keypressed then
    self.current:keypressed(key)
  end
end

function SceneManager:textinput(t)
  if self.current and self.current.textinput then
    self.current:textinput(t)
  end
end

return SceneManager

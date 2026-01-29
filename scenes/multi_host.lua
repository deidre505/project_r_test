-- scenes/multi_host.lua
-- 방 만들기 화면
-- 기능:
--  - 10자리 룸코드 생성 (서버 없음)
--  - 룸코드 클립보드 복사
--  - 공방 등록 체크박스
--  - 공방 체크 시 방 제목 입력(글자수 제한)
--  - 서버 업로드는 아직 stub

local Button   = require("ui.button")
local Checkbox = require("ui.checkbox")
local TextBox  = require("ui.textbox")
local RoomCode = require("util.room_code")

local MultiHost = {}
MultiHost.__index = MultiHost

local TITLE_MAX = 20

-- 서버 업로드 스텁 (다음 단계에서 실제 API로 교체)
local function uploadRoomStub(payload)
  return true, "Uploaded (stub): " .. payload.roomCode
end

function MultiHost.new(sm, params)
  local self = setmetatable({}, MultiHost)
  self.sm = sm
  self.viewport = params.viewport
  self.pointerX, self.pointerY = 0, 0

  -- 10자리 룸코드 생성
  self.roomCode = RoomCode.generate(10)
  self.status = ""

  -- 뒤로가기
  self.backBtn = Button.new(
    { x = 20, y = 20, w = 160, h = 48 },
    "Back",
    function()
      self.sm:switch("scenes.multi_menu", { viewport = self.viewport })
    end
  )

  -- 룸코드 복사 버튼
  self.copyBtn = Button.new(
    { x = 280, y = 165, w = 180, h = 48 },
    "Copy Code",
    function()
      love.system.setClipboardText(self.roomCode)
      self.status = "Copied to clipboard!"
    end
  )

  -- 공방 등록 체크박스
  self.publicCb = Checkbox.new(
    { x = 20, y = 260, w = 28, h = 28 },
    "List this room in Public Lobby",
    false,
    function(checked)
      self.titleBox:setEnabled(checked)
      if not checked then
        self.status = ""
      end
    end
  )

  -- 방 제목 입력 (공방 체크 시에만 활성)
  self.titleBox = TextBox.new(
    { x = 20, y = 300, w = 520, h = 54 },
    ("Room Title (max %d chars)"):format(TITLE_MAX),
    TITLE_MAX,
    { enabled = false }
  )

  -- 업로드 버튼 (stub)
  self.uploadBtn = Button.new(
    { x = 20, y = 370, w = 220, h = 56 },
    "Upload (stub)",
    function()
      if not self.publicCb.checked then
        self.status = "Enable Public Lobby first."
        return
      end

      if self.titleBox.text:gsub("%s+", "") == "" then
        self.status = "Please enter a room title."
        return
      end

      local ok, msg = uploadRoomStub({
        roomCode = self.roomCode,
        title    = self.titleBox.text,
        platform = "PC",
      })

      self.status = ok and msg or "Upload failed."
    end
  )

  return self
end

function MultiHost:pointerMoved(x, y)
  self.pointerX, self.pointerY = x, y
end

function MultiHost:pointerPressed(x, y)
  self.pointerX, self.pointerY = x, y

  if self.backBtn:tryClick(x, y) then return end
  if self.copyBtn:tryClick(x, y) then return end
  if self.publicCb:tryClick(x, y) then return end

  self.titleBox:tryClick(x, y)

  self.uploadBtn:tryClick(x, y)
end

function MultiHost:keypressed(key)
  if key == "escape" then
    self.sm:switch("scenes.multi_menu", { viewport = self.viewport })
    return
  end

  -- 디버그: R로 룸코드 재생성
  if key == "r" then
    self.roomCode = RoomCode.generate(10)
    self.status = ""
    return
  end

  self.titleBox:keypressed(key)

  if key == "return" or key == "kpenter" then
    self.uploadBtn.onClick()
  end
end

function MultiHost:textinput(t)
  self.titleBox:textinput(t)
end

function MultiHost:draw()
  self.backBtn:draw(self.pointerX, self.pointerY)

  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.print("Create Room", 20, 90)

  -- 룸코드 표시
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.print("Room Code:", 20, 140)

  love.graphics.setColor(1, 1, 1, 1.0)
  love.graphics.print(self.roomCode, 20, 175)

  self.copyBtn:draw(self.pointerX, self.pointerY)

  love.graphics.setColor(1, 1, 1, 0.6)
  love.graphics.print("Share this code with your friend.", 20, 215)
  love.graphics.print("Press R to regenerate code.", 20, 235)

  -- 공방 UI
  self.publicCb:draw(self.pointerX, self.pointerY)

  love.graphics.setColor(1, 1, 1, 0.75)
  love.graphics.print("Room Title:", 20, 285)
  self.titleBox:draw()

  self.uploadBtn:draw(self.pointerX, self.pointerY)

  -- 상태 메시지
  if self.status ~= "" then
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.print(self.status, 20, 440)
  end

  love.graphics.setColor(1, 1, 1, 0.5)
  love.graphics.print(
    "Server upload is stubbed. Next step: Steam P2P or real server API.",
    20, 620
  )
end

return MultiHost

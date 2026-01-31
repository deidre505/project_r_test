-- logger.lua
-- Safe file logger for LOVE (Steam-friendly: writes to SaveDirectory)

local Logger = {}

Logger.filename = "steam.log"
Logger._path = nil

local function get_path()
  if Logger._path then return Logger._path end
  local dir = love.filesystem.getSaveDirectory() -- 권한 안전한 표준 경로
  Logger._path = dir .. "/" .. Logger.filename
  return Logger._path
end

local function safe_line(...)
  local n = select("#", ...)
  local parts = {}
  for i = 1, n do
    local v = select(i, ...)
    parts[#parts+1] = tostring(v)
  end
  return table.concat(parts, "\t")
end

function Logger.path()
  return get_path()
end

function Logger.write(line)
  -- love.filesystem.append는 SaveDirectory에 안전하게 append
  -- (directory 생성은 LOVE가 identity 기준으로 자동 관리)
  local ok, err = pcall(function()
    love.filesystem.append(Logger.filename, line .. "\n")
  end)
  return ok, err
end

function Logger.log(...)
  local msg = safe_line(...)
  -- 시간 찍기(로컬)
  local stamp = os.date("%Y-%m-%d %H:%M:%S")
  Logger.write(("[" .. stamp .. "] " .. msg))
end

-- ✅ print 오버라이드: 기존 print 기능은 유지 + 파일에도 기록
function Logger.hook_print()
  if Logger._print_hooked then return end
  Logger._print_hooked = true

  local original_print = print
  _G.print = function(...)
    -- 콘솔(있으면) 출력
    original_print(...)
    -- 파일 기록
    Logger.log(...)
  end
end

-- ✅ LOVE 에러도 파일로 남기기
function Logger.hook_errorhandler()
  if Logger._err_hooked then return end
  Logger._err_hooked = true

  local original = love.errorhandler
  love.errorhandler = function(msg)
    Logger.log("LOVE ERROR:", msg)
    Logger.log(debug.traceback("", 2))
    if original then
      return original(msg)
    end
    return msg
  end
end

return Logger

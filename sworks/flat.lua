-- sworks/flat.lua
local ffi = require("ffi")
local win = (ffi.os == "Windows")
local x64 = ffi.abi("64bit")

-- NOTE:
-- Steamworks SDK 배포 DLL 중 일부는 SteamAPI_Init export가 없고 SteamAPI_InitFlat만 있습니다.
-- 그래서 InitFlat로 고정해서 초기화합니다.

ffi.cdef([[
  typedef unsigned int uint32;
  typedef int int32;

  // InitFlat 고정 사용
  bool SteamAPI_InitFlat(char *pszErrMsg, int32 cubErrMsg);

  // 종료 (대부분 존재)
  void SteamAPI_Shutdown();
]])

local lib = ffi.load((x64 and win) and "steam_api64" or "steam_api")

local M = { lib = lib }

-- 기존 코드가 SteamAPI_Init()을 기대하는 경우가 많아서
-- 이름은 SteamAPI_Init로 제공하되 내부는 InitFlat로 고정합니다.
function M.SteamAPI_Init()
  local buf = ffi.new("char[1024]")
  local ok = lib.SteamAPI_InitFlat(buf, 1024)
  if ok then
    return true
  end
  -- 실패 시 InitFlat이 버퍼에 에러 메시지를 써줍니다.
  local msg = ffi.string(buf)
  if msg == "" then msg = "SteamAPI_InitFlat failed (no message)" end
  return false, msg
end

function M.SteamAPI_Shutdown()
  -- DLL에 심볼이 없을 수도 있으니 안전하게 호출
  if lib.SteamAPI_Shutdown ~= nil then
    pcall(function() lib.SteamAPI_Shutdown() end)
  end
end

return M

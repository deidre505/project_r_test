-- steam_diag.lua
-- Steam DLL/심볼 진단 + 안전한 로그 파일 출력 (SaveDirectory)
-- "시작 시 덮어쓰기(w) + 이후 append(a)" 유지

local function _get_save_dir()
  -- LÖVE 환경이면 save directory 사용 (Steam 출시/Program Files에서도 안전)
  if love and love.filesystem and love.filesystem.getSaveDirectory then
    -- identity가 세팅 안 되어있으면 LOVE 기본 디렉터리로 잡힐 수 있음.
    -- 이미 프로젝트에서 setIdentity 쓰고 있으면 그대로 따라감.
    local ok, dir = pcall(love.filesystem.getSaveDirectory)
    if ok and dir and #dir > 0 then
      return dir
    end
  end

  -- LÖVE가 없거나 실패 시: 최소한 AppData에 fallback (Windows)
  local appdata = os.getenv("APPDATA")
  if appdata and #appdata > 0 then
    return appdata
  end

  return "."
end

local SAVE_DIR = _get_save_dir()
local LOG_PATH = SAVE_DIR .. "/steam_diag.log"

local function _writeln(mode, s)
  local f = io.open(LOG_PATH, mode)
  if not f then return end
  f:write(s .. "\n")
  f:close()
end

local function log(s) _writeln("a", s) end

-- 실행 시작 시 덮어쓰기
_writeln("w", "== steam diag ==")
log("log path = " .. LOG_PATH)

-- 진단: lua-jit/ffi 환경 확인
local ok_ffi, ffi = pcall(require, "ffi")
if not ok_ffi then
  log("ffi require FAILED: " .. tostring(ffi))
  return
end

log("jit.arch = " .. tostring((jit and jit.arch) or "nil"))
log("ffi.os   = " .. tostring(ffi.os))
log("64bit?   = " .. tostring(ffi.abi("64bit")))
log("le?      = " .. tostring(ffi.abi("le")))
log("package.cpath = " .. tostring(package.cpath))

-- 최소 cdef만 (여기서 'bool' 같은 걸 쓰면 LuaJIT 파싱 문제 생길 수 있어서 int로 통일)
ffi.cdef[[
typedef unsigned int uint32_t;
typedef int int32_t;

int  SteamAPI_Init(void);
int  SteamAPI_InitSafe(void);
int  SteamAPI_InitFlat(void);
int  SteamAPI_RestartAppIfNecessary(uint32_t);
void SteamAPI_Shutdown(void);
void SteamAPI_RunCallbacks(void);
]]

-- DLL 로드
local libname = (ffi.abi("64bit") and ffi.os == "Windows") and "steam_api64" or "steam_api"

local lib
local ok_load, err = pcall(function()
  -- 현재 폴더의 dll을 우선 찾게 "./"를 붙임
  lib = ffi.load("./" .. libname)
end)

if ok_load and lib then
  log("ffi.load OK: ./" .. libname)
else
  log("ffi.load FAILED: ./" .. libname)
  log("load error: " .. tostring(err))
  return
end

-- 심볼 확인 함수
local function has(sym)
  local ok, _ = pcall(function() return lib[sym] end)
  return ok
end

-- 어떤 Init 심볼이 있는지 체크
local symbols = { "SteamAPI_Init", "SteamAPI_InitSafe", "SteamAPI_InitFlat", "SteamAPI_RunCallbacks", "SteamAPI_Shutdown" }
for _, s in ipairs(symbols) do
  log(string.format("%s symbol? %s", s, tostring(has(s))))
end

-- Init 실제 호출(가능한 것부터 순서대로)
local init_ok = false
local init_how = nil
local init_err = nil

local function try_init(sym)
  if not has(sym) then return false, "missing" end
  local ok, res = pcall(function() return lib[sym]() end)
  if not ok then return false, tostring(res) end
  return (res ~= 0), "ret=" .. tostring(res)
end

do
  -- 많은 최신 Steamworks DLL에서 SteamAPI_Init이 없고 InitSafe/InitFlat만 있는 경우가 있음
  local order = { "SteamAPI_InitSafe", "SteamAPI_InitFlat", "SteamAPI_Init" }
  for _, sym in ipairs(order) do
    local ok, info = try_init(sym)
    log(string.format("try %s -> %s (%s)", sym, tostring(ok), tostring(info)))
    if ok then
      init_ok = true
      init_how = sym
      break
    end
  end
end

log("INIT RESULT = " .. tostring(init_ok) .. " via " .. tostring(init_how))
if not init_ok then
  log("NOTE: Steam overlay may still appear even if API init failed; but P2P/Lobby will not work without a valid init.")
end

-- shutdown은 진단용으로만(원하면 꺼도 됨)
if init_ok and has("SteamAPI_Shutdown") then
  -- 바로 꺼버리면 게임 본 init에 영향 갈 수 있어서 여기서는 끄지 않음
  log("Diag: leaving SteamAPI alive (not calling Shutdown here).")
end

return {
  log_path = LOG_PATH,
  init_ok = init_ok,
  init_how = init_how,
}

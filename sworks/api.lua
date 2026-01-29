-- sworks/api.lua
-- Low-level Steam API binder for LuaJIT FFI (minimal + robust symbol fallback)

local ffi = require("ffi")

local win = (ffi.os == "Windows")
local x64 = ffi.abi("64bit")
local libname = (x64 and win) and "steam_api64" or "steam_api"

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

local M = {
  _lib = nil,
  _load_error = nil,
  _init_symbol = nil,
}

local function try_load()
  if M._lib then return true end
  local ok, err = pcall(function()
    -- dll은 exe 옆(working dir)에서 찾게 "./" 우선
    M._lib = ffi.load("./" .. libname)
  end)
  if not ok then
    M._lib = nil
    M._load_error = tostring(err)
    return false
  end
  return true
end

local function has(sym)
  if not M._lib then return false end
  local ok = pcall(function() return M._lib[sym] end)
  return ok
end

local function call(sym, ...)
  return M._lib[sym](...)
end

-- Init: 가장 호환성 높은 순서로 시도
function M.init()
  if not try_load() then
    return false, "ffi.load failed: " .. tostring(M._load_error)
  end

  local order = { "SteamAPI_InitSafe", "SteamAPI_InitFlat", "SteamAPI_Init" }
  for _, sym in ipairs(order) do
    if has(sym) then
      local ok, res = pcall(function() return call(sym) end)
      if ok and res ~= 0 then
        M._init_symbol = sym
        return true, sym
      end
      -- 심볼은 있는데 호출 실패/리턴 0이면 다음으로
    end
  end

  -- 여기까지 오면 init 실패. 어떤 심볼들이 있는지 힌트를 남김
  local hints = {}
  for _, s in ipairs({ "SteamAPI_Init", "SteamAPI_InitSafe", "SteamAPI_InitFlat" }) do
    hints[#hints+1] = s .. "=" .. tostring(has(s))
  end
  return false, "Steam init failed (" .. table.concat(hints, ", ") .. ")"
end

function M.shutdown()
  if M._lib and has("SteamAPI_Shutdown") then
    pcall(function() call("SteamAPI_Shutdown") end)
  end
end

function M.runCallbacks()
  if M._lib and has("SteamAPI_RunCallbacks") then
    pcall(function() call("SteamAPI_RunCallbacks") end)
  end
end

function M.isLoaded()
  return M._lib ~= nil
end

function M.getLoadError()
  return M._load_error
end

function M.getInitSymbol()
  return M._init_symbol
end

-- 노출(steam_diag에서도 쓸 수 있게)
M._libname = libname

return M

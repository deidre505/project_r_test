-- conf.lua
function love.conf(t)
  t.identity = "Alggaki"   -- ✅ 로그/세이브가 저장될 폴더명 (권한 안전)
  t.console  = false       -- Steam 배포 기준 보통 false (콘솔창 안 뜸)
end

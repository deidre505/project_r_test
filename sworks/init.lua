-- sworks/init.lua
-- 목적:
--  - Lua에서 `require("sworks")`가 가능하게 만드는 엔트리 파일
--  - 실제 구현은 sworks/main.lua에 있음
--
-- 이 파일은 "중간 연결자" 역할만 한다.
-- 유지보수 및 가독성을 위해 별도 파일로 둔다.

return require("sworks.main")



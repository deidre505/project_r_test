# Steamworks FFI for Love2D

This repository provides a legacy Steam API layer for Love2D games using FFI bindings. Originally developed by Ivan "2dengine" and discussed in the LÖVE forums, it is now maintained by groverburger solely for backwards compatibility with games like [Vector Prospector](https://store.steampowered.com/app/1145950/Vector_Prospector/).

## Key Features

- Comprehensive Steamworks integration including friends, lobbies, clans, UGC, leaderboards, achievements, and P2P networking.
- Lua-friendly API wrappers over raw Steamworks calls via FFI.
- Callback-based asynchronous operations for non-blocking gameplay.
- HTTP request support for external API calls.

## Usage

Initialize Steam in your Love2D `love.load()` function:

```
local steam = require 'sworks'
steam.init()
if steam.restart(123456) then love.event.quit() end
```

Call `steam.update()` in `love.update(dt)` to process callbacks. Common operations include:

- User management: `local me = steam.getUser(); me:setName("Player")`
- Friends: `local friends = steam.getFriends()`
- Lobbies: `local lobby = steam.newLobby("public", 4)`
- Leaderboards: `local board = steam.newBoard("highscore")`
- Sockets: `local sock = steam.getSocket(); sock:setPeer(user)`

Full API details are in individual Lua modules like `user.lua`, `lobby.lua`, and `api.lua`.

## Compatibility Notice

This implementation supports Steam SDK up to v1.5.7 (released 2023). Newer versions have breaking changes not yet supported. Tested and working on both macOS and Windows.

## Important Recommendation

This is a **legacy** implementation kept for backwards compatibility. New projects should use the actively maintained **luasteam** instead: https://github.com/uspgamedev/luasteam.

## Requirements

- Love2D 11.0+ with LuaJIT FFI support.
- Steam client running.
- `steam_api.dll` (Windows), `libsteam_api.so` (Linux), or `libsteam_api.dylib` (macOS) in your game directory.
- Include `steam_appid.txt` with your AppID for testing outside Steam.

## Files

- `api.lua`: Core Steam interface and initialization.
- `flat.lua`: FFI definitions for Steamworks structs/enums.
- `main.lua`: High-level steam module entry point.
- Modules for specific features: `lobby.lua`, `user.lua`, `clan.lua`, `ugc.lua`, `board.lua`, `socket.lua`.

## License & Credits

Originally by Ivan "2dengine": https://love2d.org/forums/viewtopic.php?t=87917. Maintained by groverburger. MIT license.

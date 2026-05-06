# Bhub — Remastered

## Features

- Full Drawing UI library (`src/util/DrawingUILib.lua`) with theme support, layout, dropdowns, sliders, color pickers, keybinds and more.
- ESP drawing library (`src/util/Esp.lua`) for entity overlays (boxes, names, health bars, tracers).
- Built-in config save/load and quick actions.
- Small main loader (`src/main.lua`) that supports running per-game modules.

## Supported Games

- Evade
- Dive Down

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bo-xd/Bhub-remastered/main/src/main.lua"))()
```
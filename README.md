# Bhub — Remastered

## Features

- **Hybrid UI Library** (`src/util/ui/`): Supports both  **Drawing API** and standard **Instance-based** GUI fallbacks for executors with limited Drawing support.
    - Theme support with 8+ built-in presets (Neon, Sunset, Ocean, etc.).
    - Functional components including Command Palettes, Sliders, Dropdowns, Color Pickers, and Keybinds.
- **Adaptive ESP** (`src/util/Esp.lua`): A ESP system featuring box overlays, health bars, names, distances, and tracers. It automatically toggles between Drawing and Instance modes based on executor capabilities.
- **Executor Compatibility Layer** (`src/util/ExecutorCompat.lua`): Standardizes API calls across various executors, ensuring features like file I/O (config saving) and HTTP requests work reliably.
- **Utility Modules**:
    - **Pathfinding** (`src/util/Pathfinding.lua`): Integrated waypoint following with timeout and stuck-teleport logic.
- **Main Loader** (`src/main.lua`): Automatically detects the game and loads the appropriate module, with a built-in notification system for status updates.

## Supported Games

-- Evade
-- Dive Down


## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bo-xd/Bhub-remastered/main/src/main.lua"))()
```

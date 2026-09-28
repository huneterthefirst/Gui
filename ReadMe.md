# Novier // Dynamic Island & Cyber Engine (v4.3)

A cyberpunk-inspired Roblox UI library built around an overhead Dynamic Island capsule, real-time 16-band audio spectrum analyzer, live Lua code rain background, and an expandable high-capacity drawer interface.

---

## Features

* **Dynamic Island Capsule**: Sleek top-pinned island with integrated 16-band audio visualizer.
* **Audio Engine & Media Suite**: Real-time reactive spectrum analyzer with master volume gain, preset tracks, and custom Sound ID loading.
* **Full-Screen Lua Bytecode Rain**: Ambient real-time code-stream canvas running in the background.
* **Infinite Auto-Scrolling**: Drawer workspace automatically calculates and scales its canvas for limitless controls without boundary clipping.
* **High-Contrast OLED Palette**: Deep matte containers with vivid neon cyan and mint accents.
* **Zero Boilerplate Toggle**: Defaults to `[RightControl]` automatically.

---

## Quickstart

```lua
local RAW_URL = "https://raw.githubusercontent.com/YourUsername/Novier-UI/main/NovierLibrary.lua"
local Novier = loadstring(game:HttpGet(RAW_URL .. "?v=" .. tostring(os.time())))()

-- Initialize the island capsule
local Window = Novier:CreateWindow("NOVIER // ISLAND")

```

---

## Full API Reference & Tutorials

### 1. Window Creation

Creates the screen HUD, background rain canvas, audio driver, and top capsule.

```lua
local Window = Novier:CreateWindow(windowTitle)

```

* `windowTitle` *(string)*: The title displayed on the left side of the top island.

---

### 2. Built-in Media Suite

Generates a dedicated audio tab with preset selection, play/pause controls, master gain adjustment (up to 200%), and a custom sound loader.

```lua
local MediaSuite = Window:CreateMediaSuite({
    ["Synth Action"]    = "rbxassetid://9043887091",
    ["Action Drive"]    = "rbxassetid://1840590064",
    ["Dark Cyber"]      = "rbxassetid://1843404009"
})

-- Manually load any audio ID directly via script:
MediaSuite:PlayCustom("9043887091")

```

---

### 3. Tabs

Tabs are added to the right side of the pill capsule. Clicking any tab toggles the dropdown drawer deck underneath.

```lua
-- CreateTab(tabName, iconSymbol)
-- iconSymbol can be a single character/emoji or left blank
local CombatTab = Window:CreateTab("COMBAT", "⚔")
local VisualsTab = Window:CreateTab("VISUALS", "👁")
local SystemTab  = Window:CreateTab("SYS", ">_")

```

---

### 4. Sections

Sections group related controls inside high-contrast bordered cards within the active tab.

```lua
local Locomotion = CombatTab:CreateSection("Locomotion Engine")

```

---

### 5. Components

#### Buttons

Standard clickable action button with animated feedback.

```lua
Locomotion:CreateButton("Emergency Deceleration", function()
    local root = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        Novier:Notify("Physics Engine", "Linear velocity arrested.", 2, "Warning")
    end
end)

```

#### Toggles

Animated pill switch supporting default values and state callbacks.

```lua
local JumpToggle = Locomotion:CreateToggle("Super Jump", false, function(enabled)
    local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = enabled and 120 or 50
    end
end)

-- Programmatic control:
JumpToggle:Set(true)            -- Force switch to on
local state = JumpToggle:Get()  -- Returns current boolean

```

#### Sliders

Precise draggable and click-to-seek slider with step-snapping.

```lua
-- CreateSlider(name, min, max, default, step, callback)
local SpeedSlider = Locomotion:CreateSlider("WalkSpeed Velocity", 16, 250, 16, 1, function(value)
    local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = value
    end
end)

-- Programmatic control:
SpeedSlider:Set(100)            -- Set value
local current = SpeedSlider:Get()

```

#### Textboxes

Custom text input with `ClearTextOnFocus` options and enter-key detection.

```lua
-- CreateTextbox(name, placeholder, clearOnFocus, callback)
Locomotion:CreateTextbox("Custom Teleport", "Enter player name...", false, function(text, enterPressed)
    if enterPressed and #text > 0 then
        print("Target submitted:", text)
        Novier:Notify("Network", "Searching for " .. text, 3, "Success")
    end
end)

```

#### Dropdowns

Unclipped overlay dropdown with automatic sizing and hover states.

```lua
-- CreateDropdown(name, optionsList, default, callback)
local TeamSelector = VisualsTab:CreateDropdown("Target Teams", {"Enemies", "Friendlies", "Neutral", "All"}, "Enemies", function(selected)
    print("Filter mode updated:", selected)
end)

-- Programmatic control:
TeamSelector:Set("All")
local currentChoice = TeamSelector:Get()

```

#### Virtual Terminal / Console Output

In-window scrolling terminal for logging, live debugging, and telemetry.

```lua
-- CreateTerminal(height)
local Console = SystemTab:CreateTerminal(140)

Console:Log("Routine memory scan initialized.")
Console:Warn("Telemetry latency at standard thresholds.")
Console:Error("Buffer bypass failure (Test).")

-- Clear all logs:
Console:Clear()

```

---

### 6. Toast Notifications

Edge-mounted status alerts with slide-in animations and automatic dismiss timeouts.

```lua
-- Novier:Notify(title, message, duration, type)
-- Types: "Success", "Warning", "Error", or nil (Accent)
Novier:Notify("Kernel", "Configuration loaded successfully.", 3, "Success")
Novier:Notify("Memory", "Unstable allocation detected.", 4, "Warning")
Novier:Notify("Security", "Connection rejected by remote host.", 5, "Error")

```

---

### 7. Window Visibility & Keybind Management

By default, pressing `[RightControl]` slides the island and drawer in and out. You can change this keybind or toggle visibility programmatically.

```lua
-- Change the keybind:
Window.ToggleKey = Enum.KeyCode.LeftAlt

-- Programmatic toggle:
Window:SetVisible(false) -- Hide the UI
Window:SetVisible(true)  -- Show the UI
Window:SetVisible()      -- Toggle current state

```

---

## Complete Example

```lua
local RAW_URL = "https://raw.githubusercontent.com/YourUsername/Novier-UI/main/NovierLibrary.lua"
local Novier = loadstring(game:HttpGet(RAW_URL .. "?v=" .. tostring(os.time())))()

local Window = Novier:CreateWindow("NOVIER // ISLAND")

-- 1. Music and Visualizer
local MediaSuite = Window:CreateMediaSuite({
    ["Synth Action"]    = "rbxassetid://9043887091",
    ["Action Drive"]    = "rbxassetid://1840590064",
    ["Dark Cyber"]      = "rbxassetid://1843404009"
})

-- 2. Player Mechanics
local PlayerTab = Window:CreateTab("PLAYER", "⚡")
local Movement = PlayerTab:CreateSection("Locomotion")

Movement:CreateToggle("Super Jump", false, function(active)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").JumpPower = active and 120 or 50
    end
end)

Movement:CreateSlider("WalkSpeed", 16, 250, 16, 1, function(val)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = val
    end
end)

Movement:CreateButton("Emergency Stop", function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        Novier:Notify("Physics", "Momentum arrested.", 2, "Warning")
    end
end)

-- 3. System Console
local SysTab = Window:CreateTab("SYS", ">_")
local SysSec = SysTab:CreateSection("Live Diagnostics")
local Console = SysSec:CreateTerminal(120)

SysSec:CreateButton("Run Diagnostic", function()
    Console:Log("Inspecting local thread status...")
    task.wait(0.2)
    Console:Warn("Pill visualizer running smoothly at 60 FPS.")
    Novier:Notify("Kernel", "Diagnostics completed.", 3, "Success")
end)

SysSec:CreateButton("Clear Logs", function()
    Console:Clear()
end)

Novier:Notify("Novier Core", "Dynamic Island online. Press [RightControl] to toggle.", 4, "Success")

```

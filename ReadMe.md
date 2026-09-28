# Novier // Dynamic Island & Cyber Engine (v4.7)

An advanced cyberpunk Roblox UI library built around an overhead Dynamic Island capsule, real-time audio spectrum visualization, beat-synchronized camera FOV pulsing, live falling Lua bytecode rain, and dynamic horizontally-scrolling nested sub-tabs.

---

## Direct GitHub Loader

Load the library directly using standard `loadstring` and `game:HttpGet`:

```lua
local RAW_URL = "https://raw.githubusercontent.com/huneterthefirst/Gui/refs/heads/main/Main.Lua"
local Novier = loadstring(game:HttpGet(RAW_URL))()

-- Initialize the top pill capsule
local Window = Novier:CreateWindow("NOVIER // ISLAND")

```

---

## Core Features

* **Dynamic Island Capsule**: Top-center pinned capsule holding the branding, interactive tabs, and an oscillating 16-band real-time audio visualizer.
* **Dual Edge-Screen Beat Wings**: Mirrored 12-band audio reactive pulses on the left and right edges of the screen that expand inward with bass drops.
* **Beat-Synchronized Camera FOV**: Camera dynamically punches in and out with audio peaks and bass kicks, toggled instantly via `[RightAlt]`.
* **Horizontal Scrolling Sub-Tabs**: Add unlimited nested tabs (e.g., 14+ players in a server) without clipping off the edge of the screen; includes dedicated horizontal scrolling and auto-calculating canvas widths.
* **Full-Screen Lua Bytecode Rain**: Ambient background canvas streaming real Lua instructions, functions, and hex memory offsets (`ZIndex = 1`).
* **High-Capacity Auto-Scrolling Drawer**: 840x560 workspace that automatically expands its canvas bounds for unlimited sections and components.
* **Zero-Boilerplate Hotkeys**: UI toggle defaults to `[RightControl]`, Beat FOV toggle defaults to `[RightAlt]`.

---

## API Reference & Examples

### 1. Window Initialization

```lua
local Window = Novier:CreateWindow(windowTitle)

```

* `windowTitle` *(string)*: Label displayed on the left side of the top pill capsule.

---

### 2. Media Suite & Beat FOV

Creates the audio controller, track switcher, volume slider, custom asset ID loader, and Beat FOV kick configuration:

```lua
local MediaSuite = Window:CreateMediaSuite({
    ["Synth Action"]    = "rbxassetid://9043887091",
    ["Action Drive"]    = "rbxassetid://1840590064",
    ["Dark Cyber"]      = "rbxassetid://1843404009"
})

-- Manually load any numeric sound asset ID via script:
MediaSuite:PlayCustom("9043887091")

```

---

### 3. Top-Level Tabs

Creates capsule buttons on the right side of the pill. Clicking a tab opens/closes the drawer deck below:

```lua
local CombatTab  = Window:CreateTab("COMBAT", "⚔")
local PlayersTab = Window:CreateTab("PLAYERS", "👤")
local ConsoleTab = Window:CreateTab("SYS", ">_")

```

---

### 4. Horizontal Scrolling Sub-Tabs

Adds a secondary horizontal navigation bar inside any tab with an automated horizontal scroll container:

```lua
-- Initialize a sub-tab group inside a parent tab:
local SubSystem = PlayersTab:CreateSubTabs({
    {"Server Info", "🌐"},
    {"Whitelist", "🛡"}
})

-- Access an initialized sub-tab:
local ServerPage = SubSystem.SubTabs["Server Info"]
local InfoSec = ServerPage:CreateSection("Server Overview")

-- Dynamically inject a new sub-tab at runtime (smoothly scrolls right if space runs out):
local NewSub = SubSystem:AddSubTab("Player123", "⚡")
local ActionSec = NewSub:CreateSection("Target Actions")
ActionSec:CreateButton("Teleport", function() end)

-- Dynamically remove a sub-tab:
SubSystem:RemoveSubTab("Player123")

-- Clear all active sub-tabs:
SubSystem:ClearSubTabs()

```

---

### 5. Sections & Components

Sections can be added to standard tabs or nested sub-tabs:

```lua
local Section = CombatTab:CreateSection("Locomotion Engine")
-- or
local Section = SubTab:CreateSection("Target Settings")

```

#### Buttons

```lua
Section:CreateButton("Emergency Stop", function()
    local root = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        Novier:Notify("Physics", "Velocity arrested.", 2, "Warning")
    end
end)

```

#### Toggles

```lua
local JumpToggle = Section:CreateToggle("Super Jump", false, function(state)
    local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = state and 120 or 50
    end
end)

JumpToggle:Set(true)             -- Programmatic update
local active = JumpToggle:Get()  -- Returns boolean

```

#### Sliders

```lua
-- CreateSlider(name, min, max, default, step, callback)
local SpeedSlider = Section:CreateSlider("WalkSpeed", 16, 250, 16, 1, function(val)
    local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = val end
end)

SpeedSlider:Set(100)
local currentSpeed = SpeedSlider:Get()

```

#### Textboxes

```lua
-- CreateTextbox(name, placeholder, clearOnFocus, callback)
Section:CreateTextbox("Custom Payload", "Type code here...", false, function(text, enterPressed)
    if enterPressed and #text > 0 then
        print("Payload saved:", text)
    end
end)

```

#### Dropdowns

```lua
-- CreateDropdown(name, optionsTable, default, callback)
local ModeSelector = Section:CreateDropdown("Filter Mode", {"Enemies", "Friendlies", "All"}, "Enemies", function(selected)
    print("Mode updated:", selected)
end)

ModeSelector:Set("All")

```

#### Virtual Terminal / Console Output

```lua
local Terminal = Section:CreateTerminal(130)

Terminal:Log("Thread started.")
Terminal:Warn("Latency spike detected.")
Terminal:Error("Buffer allocation failure.")
Terminal:Clear()

```

---

### 6. Notifications & Controls

```lua
-- Toast Notification: "Success", "Warning", "Error", or nil (Accent)
Novier:Notify("System", "Script loaded successfully.", 3, "Success")

-- Window Visibility
Window:SetVisible(true)   -- Open
Window:SetVisible(false)  -- Close
Window:SetVisible()       -- Toggle

-- Hotkey Configuration
Window.ToggleKey = Enum.KeyCode.RightControl
Window.FovKey = Enum.KeyCode.RightAlt

```

---

## Complete Starter Script

```lua
--========================================================--
-- NOVIER // ZERO-DAY DYNAMIC RUNNER
--========================================================--

local RAW_URL = "https://raw.githubusercontent.com/huneterthefirst/Gui/refs/heads/main/Main.Lua"
local Novier = loadstring(game:HttpGet(RAW_URL))()

-- 1. Initialize Top Dynamic Capsule
local Window = Novier:CreateWindow("NOVIER // ZERO-DAY")

-- 2. Integrated Media & Beat-FOV Audio Engine
-- Hotkey to toggle Beat Camera Kick: [RightAlt]
local MediaSuite = Window:CreateMediaSuite({
    ["Synth Action"]    = "rbxassetid://9043887091",
    ["Action Drive"]    = "rbxassetid://1840590064",
    ["Dark Cyber"]      = "rbxassetid://1843404009"
})

-- 3. Executor / Workbench Tab (Textbox + Button)
local ExecTab = Window:CreateTab("EXEC", "⚡")
local ExecSec = ExecTab:CreateSection("Custom Bytecode Runner")

local currentPayload = ""

ExecSec:CreateTextbox("Script Payload", "Type or paste script code here...", false, function(txt)
    currentPayload = txt
end)

ExecSec:CreateButton("Execute Script", function()
    if #currentPayload == 0 then
        Novier:Notify("Warning", "Input field is completely empty.", 2, "Warning")
        return
    end

    local fn, compileErr = loadstring(currentPayload)
    if not fn then
        Novier:Notify("Syntax Error", tostring(compileErr), 4, "Error")
        return
    end

    local success, runtimeErr = pcall(fn)
    if success then
        Novier:Notify("Executed", "Code executed with 0 errors.", 3, "Success")
    else
        Novier:Notify("Runtime Error", tostring(runtimeErr), 4, "Error")
    end
end)

-- 4. Dynamic Live Players Tab with Horizontal Scrollable Sub-Tabs
local PlayersTab = Window:CreateTab("PLAYERS", "👤")

local PlayerSubTabs = PlayersTab:CreateSubTabs({
    {"Server Info", "🌐"}
})

local ServerPage = PlayerSubTabs.SubTabs["Server Info"]
local InfoSec = ServerPage:CreateSection("Server Overview")

InfoSec:CreateButton("Ping Server Population", function()
    local count = #game:GetService("Players"):GetPlayers()
    Novier:Notify("Server Stats", "Active Players: " .. tostring(count), 3, "Success")
end)

-- Dynamically mount sub-tabs for joined players (Supports 14+ players with horizontal scrolling)
local function hookPlayer(player)
    if player == game.Players.LocalPlayer then return end

    local userSub = PlayerSubTabs:AddSubTab(player.DisplayName, "⚡")
    local actionSec = userSub:CreateSection(player.Name .. " (@" .. player.UserId .. ")")

    actionSec:CreateButton("Teleport to Target", function()
        local myRoot = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

        if myRoot and theirRoot then
            myRoot.CFrame = theirRoot.CFrame * CFrame.new(0, 0, 3)
            Novier:Notify("Teleport", "Jumped to " .. player.DisplayName, 2, "Success")
        else
            Novier:Notify("Error", "Character model missing.", 2, "Error")
        end
    end)

    actionSec:CreateButton("Spectate Target", function()
        local cam = workspace.CurrentCamera
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            cam.CameraSubject = player.Character.Humanoid
            Novier:Notify("Spectate", "Targeting " .. player.DisplayName, 2, "Success")
        end
    end)
end

for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
    hookPlayer(pl)
end

game:GetService("Players").PlayerAdded:Connect(function(pl)
    hookPlayer(pl)
    Novier:Notify("Connected", pl.DisplayName .. " joined the session.", 3, "Success")
end)

game:GetService("Players").PlayerRemoving:Connect(function(pl)
    PlayerSubTabs:RemoveSubTab(pl.DisplayName)
    Novier:Notify("Disconnected", pl.DisplayName .. " left the session.", 3, "Warning")
end)

-- 5. System Console Tab
local ConsoleTab = Window:CreateTab("SYS", ">_")
local ConsoleSec = ConsoleTab:CreateSection("Virtual Output")
local Console = ConsoleSec:CreateTerminal(140)

ConsoleSec:CreateButton("Run Integrity Check", function()
    Console:Log("Inspecting thread execution...")
    task.wait(0.2)
    Console:Warn("Audio Beat-FOV & Matrix Rain stable.")
    Novier:Notify("Diagnostics", "System health at 100%.", 3, "Success")
end)

ConsoleSec:CreateButton("Flush Terminal", function()
    Console:Clear()
end)

-- Startup Alert
Novier:Notify("Novier Online", "UI: [RightControl] | Beat-FOV Kick: [RightAlt]", 5, "Success")

```

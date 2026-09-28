# ⚡ Novier // Dynamic Island & Cyber Engine (v5.0 "AURORA")

A cyberpunk Roblox UI library built around a top-center Dynamic Island capsule, a **beat-detecting audio analyzer**, a mirrored edge-of-screen spectrum, live themes, and a pile of quality-of-life features most UI libs skip.

> **TL;DR:** Load it, call `CreateWindow`, add `CreateMediaSuite()` and `CreateSettingsTab()`, then build tabs. Every control takes an optional trailing `opts` table (`Flag`, `Tooltip`) so it can save/load with configs. Your v4.7 scripts keep working unchanged.

---

## 📦 Loader

```lua
local RAW_URL = "https://raw.githubusercontent.com/huneterthefirst/Gui/refs/heads/main/Main.Lua"
local Novier = loadstring(game:HttpGet(RAW_URL))()

local Window = Novier:CreateWindow("NOVIER // ISLAND")
```

---

## ✨ What's New in 5.0

| Area | Upgrade |
|---|---|
| 🎵 **Audio Analyzer** | Auto-gain, envelope followers, synthesized bass/mid/high bands, spring-physics spectrum with peak-hold caps, beat + BPM detection |
| 🌌 **Edge Visuals** | Mirrored, center-symmetric spectrum (bass in the middle, treble at the ends), side/top/bottom glows, beat shockwave rings, rotating gradient pill border |
| 🎨 **Themes** | `Neon`, `Sakura`, `Sunset`, `Glacier`, `Matrix`, switchable live with `Novier:SetTheme(name)` |
| 🖱 **UX** | Click ripples, tooltips, collapsible sections, keybind picker, labels, separators, dropdown click-outside-to-close |
| 💾 **Configs** | `Flag` support on controls plus `Novier:SaveConfig()` / `LoadConfig()` |
| ⚙ **Settings Tab** | One call (`Window:CreateSettingsTab()`) gives theme, scale, blur, visual FPS cap, sensitivity, keybinds, config save/load |
| 📱 **Mobile** | Auto `UIScale` for small screens and a floating ⚡ toggle button on touch devices |
| 📊 **Pill Stats** | Live FPS and ping inside the capsule, grow-in intro animation, background blur when the drawer is open |
| 🔔 **Notifications** | Rebuilt with slide-in, icon, and countdown progress bar |
| 🥁 **Hooks** | `Window:OnBeat(fn)` and `Window:AddTicker(fn)` for your own beat-reactive code |

### 🐛 Fixes from 4.7

- `Window:SetVisible(false)` now actually closes the window.
- Beat FOV no longer overwrites the game camera's FOV while disabled.
- The `SecondaryAccent` peak color is now reachable (the branch order was wrong).
- Notification slide-in now animates (`UIListLayout` was overriding `Position`).
- Code rain uses a single driver instead of 24 looping tween threads.

---

## 🧩 Core Features

* **Dynamic Island Capsule**: pinned top-center, holds the brand, FPS/ping, a 16-bar visualizer, and your tabs.
* **Edge Spectrum**: 36 bars per side on the left and right edges, mirrored, with falling peak caps.
* **Beat-Synchronized Camera FOV**: the camera punches in with bass and beats, toggled with `[RightAlt]`.
* **Scrolling Sub-Tabs**: unlimited nested tabs (14+ players) with horizontal scrolling and auto canvas sizing.
* **Code Rain**: ambient falling Lua snippets that speed up and brighten with the bass.
* **Auto-Scrolling Drawer**: 840x560 workspace that grows to fit any number of sections.
* **Hotkeys**: `[RightControl]` toggles the UI, `[RightAlt]` toggles Beat FOV (both rebindable).

---

## 📚 API Reference

### 1. Window

```lua
local Window = Novier:CreateWindow(windowTitle)
```

| Member | Description |
|---|---|
| `Window:SetVisible(state?)` | `true` open, `false` close, no argument toggles |
| `Window:SetToggleKey(keyCode)` / `Window:SetFovKey(keyCode)` | Rebind hotkeys (`Window.ToggleKey` / `Window.FovKey` also work) |
| `Window:OnBeat(fn)` | `fn(strength, bpm)` fires on every detected beat |
| `Window:AddTicker(fn)` | `fn(analyzer, fps, ping)` fires 4 times per second |
| `Window.Analyzer` | Live audio values: `level`, `bass`, `mid`, `high`, `beat`, `bpm`, `bands` |
| `Window.Sound` | The underlying `Sound` instance |
| `Window:Destroy()` | Same as `Novier:Destroy()` |

---

### 2. Media Suite & Beat FOV

Creates the audio controller, track dropdown, play/pause, volume slider, now-playing readout (time, BPM, level), custom asset ID loader, and Beat FOV controls:

```lua
local MediaSuite = Window:CreateMediaSuite({
    ["Synth Action"] = "rbxassetid://9043887091",
    ["Action Drive"] = "rbxassetid://1840590064",
    ["Dark Cyber"]   = "rbxassetid://1843404009",
})

MediaSuite:PlayCustom("9043887091")   -- load any numeric sound ID from script
```

---

### 3. Settings Tab

```lua
Window:CreateSettingsTab()
```

Adds a **SETTINGS** tab with:

- **Appearance**: theme, UI scale, FPS/ping toggle, background blur, UI sounds
- **Visuals**: edge spectrum, code rain, shockwave rings, idle breathing, visual FPS cap
- **Audio Reactivity**: sensitivity, auto gain
- **Keybinds**: rebind UI toggle and Beat FOV
- **Config**: name, Save, Load

Add it last so it sits at the end of the capsule.

---

### 4. Themes

```lua
Novier:SetTheme("Sunset")   -- Neon | Sakura | Sunset | Glacier | Matrix
print(Novier.ThemeName)
```

Add your own before or after creating a window (needs every key from an existing theme, so copy one):

```lua
local t = table.clone(Novier.Themes.Neon)
t.Accent = Color3.fromRGB(255, 80, 80)
t.Border = t.Accent
Novier.Themes.Blood = t
Novier:SetTheme("Blood")
```

---

### 5. Top-Level Tabs

```lua
local CombatTab  = Window:CreateTab("COMBAT", "⚔")
local PlayersTab = Window:CreateTab("PLAYERS", "👤")
local ConsoleTab = Window:CreateTab("SYS", ">_")
```

Clicking a tab opens the drawer; clicking the active tab closes it.

---

### 6. Scrolling Sub-Tabs

```lua
local SubSystem = PlayersTab:CreateSubTabs({
    {"Server Info", "🌐"},
    {"Whitelist", "🛡"},
})

local ServerPage = SubSystem.SubTabs["Server Info"]
local InfoSec = ServerPage:CreateSection("Server Overview")

local NewSub = SubSystem:AddSubTab("Player123", "⚡")   -- runtime add (auto-scrolls into view)
NewSub:CreateSection("Target Actions"):CreateButton("Teleport", function() end)

SubSystem:RemoveSubTab("Player123")
SubSystem:ClearSubTabs()
```

---

### 7. Sections

```lua
local Section = CombatTab:CreateSection("Locomotion Engine")   -- or SubTab:CreateSection(...)
```

Section headers are clickable and **collapse/expand** their contents.

---

### 8. Controls

Every control accepts an optional trailing `opts` table:

| Option | Applies to | Effect |
|---|---|---|
| `Flag = "name"` | all value controls | Saved and loaded by configs |
| `Tooltip = "text"` | all controls | Hover tooltip |
| `OnChanged = fn` | keybinds | Called with the new `KeyCode` (or `nil` if cleared) |

#### Button

```lua
-- CreateButton(name, callback, opts?)
Section:CreateButton("Emergency Stop", function()
    local root = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        Novier:Notify("Physics", "Velocity arrested.", 2, "Warning")
    end
end, { Tooltip = "Zeroes your velocity" })
```

#### Toggle

```lua
-- CreateToggle(name, default, callback, opts?)
local JumpToggle = Section:CreateToggle("Super Jump", false, function(state)
    local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = state and 120 or 50
    end
end, { Flag = "super_jump" })

JumpToggle:Set(true)
local active = JumpToggle:Get()
```

#### Slider

```lua
-- CreateSlider(name, min, max, default, step, callback, opts?)
local SpeedSlider = Section:CreateSlider("WalkSpeed", 16, 250, 16, 1, function(val)
    local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = val end
end, { Flag = "walkspeed" })

SpeedSlider:Set(100)
local currentSpeed = SpeedSlider:Get()
```

Decimal steps (like `0.05`) display the right number of decimals automatically.

#### Textbox

```lua
-- CreateTextbox(name, placeholder, clearOnFocus, callback, opts?)
Section:CreateTextbox("Custom Payload", "Type code here...", false, function(text, enterPressed)
    if enterPressed and #text > 0 then print("Saved:", text) end
end)
```

#### Dropdown

```lua
-- CreateDropdown(name, options, default, callback, opts?)
local Mode = Section:CreateDropdown("Filter Mode", {"Enemies", "Friendlies", "All"}, "Enemies", function(selected)
    print("Mode:", selected)
end, { Flag = "filter_mode" })

Mode:Set("All")
Mode:Refresh({"A", "B", "C"}, true)   -- swap the list; true keeps the selection if it still exists
```

#### Keybind (new)

```lua
-- CreateKeybind(name, defaultKeyCode, onPress, opts?)
Section:CreateKeybind("Panic", Enum.KeyCode.P, function()
    Novier:Destroy()
end, { Flag = "panic_key" })
```

Click the row, press a key to bind it. `Backspace` clears, `Escape` cancels.

#### Label & Separator (new)

```lua
local Info = Section:CreateLabel("Ready.")
Info:Set("Connected to 14 players.")

Section:CreateSeparator()
```

#### Terminal

```lua
local Terminal = Section:CreateTerminal(130)

Terminal:Log("Thread started.")
Terminal:Warn("Latency spike detected.")
Terminal:Error("Buffer allocation failure.")
Terminal:Clear()
```

Keeps the newest 150 lines.

---

### 9. Notifications

```lua
-- Novier:Notify(title, message, duration, kind)
-- kind: "Success" | "Warning" | "Error" | nil (accent)
Novier:Notify("System", "Script loaded successfully.", 3, "Success")
```

---

### 10. Configs

Tag controls with `Flag`, then:

```lua
local ok, err = Novier:SaveConfig("legit")   -- writes Novier/legit.json
local ok2, err2 = Novier:LoadConfig("legit")
```

> Requires executor file functions (`writefile`, `readfile`, `isfile`). Without them both calls return `false, "filesystem functions unavailable"`.

---

### 11. Audio Reactivity

Roblox only exposes `Sound.PlaybackLoudness` (no FFT), so the analyzer builds its bands from that single number. The look is convincing, but the bands are not real frequency data.

```lua
Window:OnBeat(function(strength, bpm)
    print("boom", math.floor(bpm))
end)

Window:AddTicker(function(an, fps, ping)
    if an.bass > 0.8 then print("drop!") end
end)
```

Live-tweakable settings (all also exposed in the Settings tab):

```lua
local S = Novier.Settings
S.EdgeVisuals   = true   -- edge spectrum & glows
S.Rain          = true   -- code rain
S.Rings         = true   -- beat shockwave rings
S.Blur          = true   -- blur while the drawer is open
S.IdleBreathing = true   -- gentle motion when no music plays
S.UISounds      = false  -- tiny click/hover sounds
S.ShowStats     = true   -- FPS / ping in the pill
S.AutoGain      = true   -- normalize quiet/loud tracks
S.Sensitivity   = 1      -- 0.3 to 2.5
S.VisualHz      = 60     -- visual update cap (lower = cheaper)
S.UIScale       = 1      -- extra scale on top of the automatic one
```

Beat FOV tuning:

```lua
local F = Novier.FOVConfig
F.Enabled    = false
F.BaseFOV    = 70
F.MaxKick    = 24
F.Smoothness = 0.18
```

---

## 🚀 Complete Starter Script

```lua
--========================================================--
-- NOVIER // ZERO-DAY DYNAMIC RUNNER (v5.0)
--========================================================--

local RAW_URL = "https://raw.githubusercontent.com/huneterthefirst/Gui/refs/heads/main/Main.Lua"
local Novier = loadstring(game:HttpGet(RAW_URL))()

-- 1. Top Dynamic Capsule
local Window = Novier:CreateWindow("NOVIER // ZERO-DAY")

-- 2. Media + Beat-FOV engine  ([RightAlt] toggles the camera kick)
Window:CreateMediaSuite({
    ["Synth Action"] = "rbxassetid://9043887091",
    ["Action Drive"] = "rbxassetid://1840590064",
    ["Dark Cyber"]   = "rbxassetid://1843404009",
})

-- 3. Executor / Workbench Tab
local ExecTab = Window:CreateTab("EXEC", "⚡")
local ExecSec = ExecTab:CreateSection("Custom Bytecode Runner")

local currentPayload = ""

ExecSec:CreateTextbox("Script Payload", "Type or paste script code here...", false, function(txt)
    currentPayload = txt
end, { Flag = "payload" })

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
end, { Tooltip = "Compiles and runs the payload above" })

ExecSec:CreateKeybind("Quick Kill UI", Enum.KeyCode.P, function()
    Novier:Destroy()
end, { Flag = "kill_key" })

-- 4. Live Players Tab with scrolling sub-tabs
local PlayersTab = Window:CreateTab("PLAYERS", "👤")
local PlayerSubTabs = PlayersTab:CreateSubTabs({ {"Server Info", "🌐"} })

local InfoSec = PlayerSubTabs.SubTabs["Server Info"]:CreateSection("Server Overview")
local PopLabel = InfoSec:CreateLabel("Players: --")

InfoSec:CreateButton("Ping Server Population", function()
    local count = #game:GetService("Players"):GetPlayers()
    PopLabel:Set("Players: " .. count)
    Novier:Notify("Server Stats", "Active Players: " .. count, 3, "Success")
end)

local function hookPlayer(player)
    if player == game.Players.LocalPlayer then return end

    local userSub = PlayerSubTabs:AddSubTab(player.DisplayName, "⚡")
    local actionSec = userSub:CreateSection(player.Name .. " (@" .. player.UserId .. ")")

    actionSec:CreateButton("Teleport to Target", function()
        local me = game.Players.LocalPlayer.Character
        local myRoot = me and me:FindFirstChild("HumanoidRootPart")
        local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

        if myRoot and theirRoot then
            myRoot.CFrame = theirRoot.CFrame * CFrame.new(0, 0, 3)
            Novier:Notify("Teleport", "Jumped to " .. player.DisplayName, 2, "Success")
        else
            Novier:Notify("Error", "Character model missing.", 2, "Error")
        end
    end)

    actionSec:CreateButton("Spectate Target", function()
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then
            workspace.CurrentCamera.CameraSubject = hum
            Novier:Notify("Spectate", "Targeting " .. player.DisplayName, 2, "Success")
        end
    end)
end

for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do hookPlayer(pl) end

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
    Console:Warn("Audio analyzer & edge visuals stable.")
    Novier:Notify("Diagnostics", "System health at 100%.", 3, "Success")
end)

ConsoleSec:CreateButton("Flush Terminal", function() Console:Clear() end)

-- 6. React to the music from your own code
Window:OnBeat(function(strength, bpm)
    if bpm > 0 then Console:Log("beat @ " .. math.floor(bpm) .. " BPM") end
end)

-- 7. Settings (add last so it sits at the end of the capsule)
Window:CreateSettingsTab()

Novier:Notify("Novier Online", "UI: [RightControl] | Beat-FOV Kick: [RightAlt]", 5, "Success")
```

---

## ⚠️ Notes

- The capsule is 780px wide, so a large number of top-level tabs will overflow it. Sub-tabs scroll and are the right tool for long lists.
- If the visuals cost you frames, lower **Visual FPS Cap** or turn off **Code Rain** in Settings.
- Themes re-color live, but a control's own hover or active tween can briefly show the old color until you move the mouse off it.

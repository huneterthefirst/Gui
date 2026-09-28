--========================================================--
-- NOVIER v5.0 // FULL FEATURE EXAMPLE
-- Every control, hook, theme, config and setting in one script.
--========================================================--

local RAW_URL = "https://raw.githubusercontent.com/huneterthefirst/Gui/refs/heads/main/Main.Lua"
local Novier = loadstring(game:HttpGet(RAW_URL))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

--========================================================--
-- 0. PRE-WINDOW SETUP (settings, FOV, custom theme)
--========================================================--

-- Live settings (all also appear in the Settings tab)
local S = Novier.Settings
S.Sensitivity   = 1.2    -- audio reactivity, 0.3 to 2.5
S.AutoGain      = true   -- normalize quiet and loud tracks
S.VisualHz      = 60     -- visual update cap
S.IdleBreathing = true   -- gentle motion when nothing plays
S.Rings         = true   -- beat shockwave rings
S.UISounds      = false  -- click/hover sounds

-- Beat FOV tuning
local F = Novier.FOVConfig
F.BaseFOV    = 70
F.MaxKick    = 20
F.Smoothness = 0.2

-- Custom theme: clone an existing one and override. Do this BEFORE
-- CreateSettingsTab so it shows up in the theme dropdown.
local blood = table.clone(Novier.Themes.Neon)
blood.Accent          = Color3.fromRGB(255, 70, 70)
blood.AccentGlow      = Color3.fromRGB(255, 150, 90)
blood.SecondaryAccent = Color3.fromRGB(255, 220, 90)
blood.Border          = blood.Accent
blood.TextTerminal    = blood.Accent
Novier.Themes.Blood = blood

--========================================================--
-- 1. WINDOW
--========================================================--
local Window = Novier:CreateWindow("NOVIER // SHOWCASE")

-- Rebind hotkeys from code (also rebindable in the Settings tab)
Window:SetToggleKey(Enum.KeyCode.RightControl)
Window:SetFovKey(Enum.KeyCode.RightAlt)

--========================================================--
-- 2. MEDIA SUITE (tracks, volume, custom ID, Beat FOV)
--========================================================--
local Media = Window:CreateMediaSuite({
    ["Synth Action"] = "rbxassetid://9043887091",
    ["Action Drive"] = "rbxassetid://1840590064",
    ["Dark Cyber"]   = "rbxassetid://1843404009",
})

--========================================================--
-- 3. MAIN TAB: every control type
--========================================================--
local MainTab = Window:CreateTab("MAIN", "⚡")

-- Section 1: buttons, toggles, sliders
local Move = MainTab:CreateSection("Locomotion")

Move:CreateLabel("Every control below supports Flag (saved in configs) and Tooltip.")
Move:CreateSeparator()

local JumpToggle = Move:CreateToggle("Super Jump", false, function(on)
    local hum = getHumanoid()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = on and 120 or 50
    end
    Novier:Notify("Super Jump", on and "Enabled" or "Disabled", 2, on and "Success" or "Warning")
end, { Flag = "super_jump", Tooltip = "Raises JumpPower to 120" })

local SpeedSlider = Move:CreateSlider("WalkSpeed", 16, 250, 16, 1, function(v)
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = v end
end, { Flag = "walkspeed", Tooltip = "Drag or tap the bar" })

Move:CreateSlider("Gravity (decimal step demo)", 0.5, 2, 1, 0.05, function(v)
    workspace.Gravity = 196.2 * v
end, { Flag = "gravity", Tooltip = "Decimal steps show the right number of decimals" })

Move:CreateButton("Emergency Stop", function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        Novier:Notify("Physics", "Velocity arrested.", 2, "Warning")
    end
end, { Tooltip = "Zeroes your velocity" })

Move:CreateButton("Reset Speed + Jump (programmatic Set)", function()
    SpeedSlider:Set(16)      -- Set on a slider fires its callback
    JumpToggle:Set(false)    -- so does Set on a toggle
    print("Slider now:", SpeedSlider:Get(), "| Toggle now:", JumpToggle:Get())
end)

-- Section 2: text, dropdown, keybind
local Input = MainTab:CreateSection("Input Controls")

local nameBox = Input:CreateTextbox("Nickname", "Type something...", false, function(text, enter)
    if enter and #text > 0 then
        Novier:Notify("Textbox", "Saved: " .. text, 2, "Success")
    end
end, { Flag = "nickname" })

local ModeDrop = Input:CreateDropdown("Filter Mode", { "Enemies", "Friendlies", "All" }, "Enemies", function(sel)
    Novier:Notify("Dropdown", "Mode: " .. sel, 2)
end, { Flag = "filter_mode", Tooltip = "Click outside to close" })

Input:CreateButton("Dropdown:Set('All')", function() ModeDrop:Set("All") end)

Input:CreateButton("Dropdown:Refresh(players)", function()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do table.insert(names, p.Name) end
    ModeDrop:Refresh(names, true) -- true keeps the selection if it still exists
    Novier:Notify("Dropdown", "List replaced with " .. #names .. " players", 2, "Success")
end)

Input:CreateKeybind("Panic (destroy UI)", Enum.KeyCode.P, function()
    Novier:Destroy()
end, {
    Flag = "panic_key",
    Tooltip = "Click, then press a key. Backspace clears, Escape cancels.",
    OnChanged = function(key)
        Novier:Notify("Keybind", "Panic key: " .. (key and key.Name or "NONE"), 2)
    end,
})

-- Section 3: collapsible + terminal
local Log = MainTab:CreateSection("Terminal (click this header to collapse)")
local Terminal = Log:CreateTerminal(120)
Terminal:Log("Terminal online.")

Log:CreateButton("Log / Warn / Error", function()
    Terminal:Log("Thread started.")
    Terminal:Warn("Latency spike detected.")
    Terminal:Error("Buffer allocation failure.")
end)
Log:CreateButton("Clear", function() Terminal:Clear() end)

--========================================================--
-- 4. PLAYERS TAB: scrolling sub-tabs
--========================================================--
local PlayersTab = Window:CreateTab("PLAYERS", "👤")
local Subs = PlayersTab:CreateSubTabs({ { "Server Info", "🌐" } })

local InfoSec = Subs.SubTabs["Server Info"]:CreateSection("Server Overview")
local PopLabel = InfoSec:CreateLabel("Players: --")

InfoSec:CreateButton("Refresh Population", function()
    PopLabel:Set("Players: " .. #Players:GetPlayers())
end)
InfoSec:CreateButton("Clear All Sub-Tabs (except rebuilds)", function()
    Subs:ClearSubTabs()
    Novier:Notify("Sub-Tabs", "Cleared. Re-join or add players to rebuild.", 3, "Warning")
end)

local function hookPlayer(player)
    if player == LocalPlayer then return end
    local sub = Subs:AddSubTab(player.DisplayName, "⚡")
    local sec = sub:CreateSection(player.Name .. " (@" .. player.UserId .. ")")

    sec:CreateButton("Teleport to Target", function()
        local me = LocalPlayer.Character
        local myRoot = me and me:FindFirstChild("HumanoidRootPart")
        local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and theirRoot then
            myRoot.CFrame = theirRoot.CFrame * CFrame.new(0, 0, 3)
            Novier:Notify("Teleport", "Jumped to " .. player.DisplayName, 2, "Success")
        else
            Novier:Notify("Error", "Character model missing.", 2, "Error")
        end
    end)

    sec:CreateButton("Spectate Target", function()
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then
            workspace.CurrentCamera.CameraSubject = hum
            Novier:Notify("Spectate", "Targeting " .. player.DisplayName, 2, "Success")
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end

Players.PlayerAdded:Connect(function(p)
    hookPlayer(p)
    Novier:Notify("Connected", p.DisplayName .. " joined.", 3, "Success")
end)
Players.PlayerRemoving:Connect(function(p)
    Subs:RemoveSubTab(p.DisplayName)
    Novier:Notify("Disconnected", p.DisplayName .. " left.", 3, "Warning")
end)

--========================================================--
-- 5. AUDIO LAB TAB: analyzer, beat hooks, tickers
--========================================================--
local LabTab = Window:CreateTab("LAB", "🎛")
local Lab = LabTab:CreateSection("Live Analyzer")

local Readout = Lab:CreateLabel("Play a track in the MEDIA tab...")
local BeatLog = Lab:CreateTerminal(110)

-- Ticker: runs 4x/sec with (analyzer, fps, ping)
Window:AddTicker(function(an, fps, ping)
    Readout:Set(string.format(
        "bass %.2f | mid %.2f | high %.2f | level %.2f | BPM %s | %d FPS | %dms",
        an.bass, an.mid, an.high, an.level,
        an.bpm > 1 and tostring(math.floor(an.bpm + 0.5)) or "--", fps, ping
    ))
end)

-- OnBeat: runs on every detected beat with (strength, bpm)
local beatCount = 0
Window:OnBeat(function(strength, bpm)
    beatCount = beatCount + 1
    if beatCount % 4 == 0 then -- one line per bar
        BeatLog:Log(string.format("bar %d @ %d BPM", beatCount / 4, math.floor(bpm)))
    end
end)

Lab:CreateButton("Peek band 1 (bass) via Window.Analyzer", function()
    Novier:Notify("Analyzer", string.format("Band 1 = %.2f", Window.Analyzer.bands[1]), 2)
end)

Lab:CreateButton("Play a custom ID via MediaSuite:PlayCustom", function()
    Media:PlayCustom("9043887091")
end)

Lab:CreateButton("Toggle Beat FOV via MediaSuite.FovToggle", function()
    Media.FovToggle:Set(not Media.FovToggle:Get())
end)

Lab:CreateButton("Pause / resume Window.Sound", function()
    local snd = Window.Sound
    if snd.IsPlaying then snd:Pause() else snd:Resume() end
end)

--========================================================--
-- 6. THEMES + CONFIG TAB
--========================================================--
local StyleTab = Window:CreateTab("STYLE", "🎨")
local Themes = StyleTab:CreateSection("Themes & Visual Toggles")

Themes:CreateLabel("The theme dropdown below includes the custom 'Blood' theme.")

local names = {}
for n in pairs(Novier.Themes) do table.insert(names, n) end
table.sort(names)

Themes:CreateDropdown("Theme", names, Novier.ThemeName, function(n)
    Novier:SetTheme(n) -- re-colors everything live, including edge visuals
end)

Themes:CreateButton("Cycle Themes (visualizer demo)", function()
    task.spawn(function()
        for _, n in ipairs(names) do
            Novier:SetTheme(n)
            task.wait(0.8)
        end
    end)
end)

Themes:CreateToggle("Edge Spectrum", S.EdgeVisuals, function(v) S.EdgeVisuals = v end)
Themes:CreateToggle("Code Rain", S.Rain, function(v) S.Rain = v end)
Themes:CreateToggle("Shockwave Rings", S.Rings, function(v) S.Rings = v end)

local Cfg = StyleTab:CreateSection("Config Save / Load")
local cfgName = "showcase"
Cfg:CreateLabel("Saves every control that has a Flag. Needs executor file functions.")
Cfg:CreateTextbox("Config name", "showcase", false, function(t)
    if t and #t > 0 then cfgName = t end
end)
Cfg:CreateButton("Save Config", function()
    local ok, err = Novier:SaveConfig(cfgName)
    Novier:Notify("Config", ok and ("Saved '" .. cfgName .. "'") or ("Failed: " .. tostring(err)), 3, ok and "Success" or "Error")
end)
Cfg:CreateButton("Load Config", function()
    local ok, err = Novier:LoadConfig(cfgName)
    Novier:Notify("Config", ok and ("Loaded '" .. cfgName .. "'") or ("Failed: " .. tostring(err)), 3, ok and "Success" or "Error")
end)

--========================================================--
-- 7. WINDOW CONTROL + SETTINGS TAB (add last)
--========================================================--
local SysTab = Window:CreateTab("SYS", ">_")
local Sys = SysTab:CreateSection("Window Control")

Sys:CreateButton("Window:SetVisible(false) for 2s", function()
    Window:SetVisible(false)
    task.delay(2, function() Window:SetVisible(true) end)
end, { Tooltip = "Slides the pill away, then back" })

Sys:CreateButton("Window:SetVisible() (toggle)", function() Window:SetVisible() end)

Sys:CreateButton("Notification kinds", function()
    Novier:Notify("Default", "Accent-colored toast", 2)
    task.delay(0.3, function() Novier:Notify("Success", "Everything worked", 3, "Success") end)
    task.delay(0.6, function() Novier:Notify("Warning", "Careful now", 3, "Warning") end)
    task.delay(0.9, function() Novier:Notify("Error", "Something broke", 3, "Error") end)
end)

Sys:CreateButton("Destroy UI (Window:Destroy)", function() Window:Destroy() end)

-- Built-in settings tab: theme, scale, blur, visual FPS cap, sensitivity,
-- keybinds, config save/load
Window:CreateSettingsTab()

--========================================================--
-- 8. STARTUP
--========================================================--
Novier:Notify("Novier Online", "UI: [RightControl] | Beat-FOV: [RightAlt] | Panic: [P]", 5, "Success")

--========================================================--
-- NOVIER // ZERO-DAY VISOR INITIALIZER
--========================================================--

local RAW_URL = "YOUR_HOSTED_RAW_URL_HERE"

-- The '?v=' parameter forces executors to pull fresh code and bypass HTTP caching
local Novier = loadstring(game:HttpGet(RAW_URL .. "?v=" .. tostring(os.time())))()

-- Window spawns as an overhead slide-down visor
local Window = Novier:CreateWindow("NOVIER // VISOR PROTOCOL")

-- NOTE: Global window toggle defaults to [Right Control] automatically!
-- If you ever want to change it via script, call: Window:SetToggleKey(Enum.KeyCode.LeftAlt)

-- 1. Integrated Media Suite (Preset Music + Fixed Master Volume Slider + Custom ID Loader)
local MediaSuite = Window:CreateMediaSuite({
    ["Synth Action"]    = "rbxassetid://9043887091",
    ["Action Drive"]    = "rbxassetid://1840590064",
    ["Dark Cyber"]      = "rbxassetid://1843404009"
})

-- 2. Locomotion / Combat Tab
local CombatTab = Window:CreateTab("PLAYER", "⚡")
local Locomotion = CombatTab:CreateSection("Locomotion Engine")

Locomotion:CreateToggle("Super Jump", false, function(enabled)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").UseJumpPower = true
        char:FindFirstChildOfClass("Humanoid").JumpPower = enabled and 120 or 50
    end
end)

Locomotion:CreateSlider("WalkSpeed Velocity", 16, 250, 16, 1, function(val)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = val
    end
end)

Locomotion:CreateButton("Emergency Deceleration", function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        Novier:Notify("Physics Engine", "Momentum arrested.", 2, "Warning")
    end
end)

-- 3. Live Hacker Terminal & Output
local TerminalTab = Window:CreateTab("SYS-CONSOLE", ">_")
local TermSec = TerminalTab:CreateSection("Live Virtual Output")
local Console = TermSec:CreateTerminal(160)

TermSec:CreateButton("Inspect Local Environment", function()
    Console:Log("Inspecting local thread status...")
    task.wait(0.2)
    Console:Warn("Visor HUD operational. Zero thread collisions.")
    Novier:Notify("Kernel", "Telemetry test finished.", 3, "Success")
end)

TermSec:CreateButton("Flush Terminal Output", function()
    Console:Clear()
end)

-- 4. Environment & Visuals
local EnvironmentTab = Window:CreateTab("VISUALS", "👁")
local RenderSec = EnvironmentTab:CreateSection("Target Filtering")

RenderSec:CreateDropdown("Target Filtering", {"Enemies", "Friendlies", "Neutral", "All Entities"}, "Enemies", function(selected)
    Console:Log("Tracking filter updated: " .. selected)
end)

RenderSec:CreateTextbox("Filter Tag", "Enter tag name...", false, function(txt, enter)
    if enter and #txt > 0 then
        Console:Log("Custom tag appended: " .. txt)
        Novier:Notify("Filter Pipeline", "Tag registered: " .. txt, 2, "Success")
    end
end)

Novier:Notify("Novier Cyber", "Full-screen HUD & overhead Visor online. Press [Right Control] to toggle.", 5, "Success")

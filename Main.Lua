--[[
    NOVIER // DYNAMIC ISLAND & CAPSULE ENGINE (V4.6 DYNAMIC SUB-TABS EDITION)
    - Dynamic Sub-Tabs & Segmented Nested Containers (Add/Remove/Clear at runtime)
    - Beat-Synchronized Audio FOV Pulsing: Camera kicks with bass & amplitude ([RightAlt])
    - Hardcoded Global Toggle for Island UI: [RightControl]
    - Mirrored Dual Edge-Screen Beat Pulse Wings (Left & Right)
    - Full-Screen Real-Time Falling Lua Bytecode Matrix
    - High-Capacity 840x560 Auto-Scrolling Drawer
]]

local Novier = {}
Novier.__index = Novier

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Palette
Novier.Version = "4.6.0 SUB-TABS"

Novier.Theme = {
    PillBackground   = Color3.fromRGB(12, 14, 19),
    DrawerBackground = Color3.fromRGB(14, 17, 23),
    SurfaceElevated  = Color3.fromRGB(22, 27, 38),
    SurfaceHighlight = Color3.fromRGB(32, 40, 56),
    
    Accent           = Color3.fromRGB(0, 255, 170),
    AccentGlow       = Color3.fromRGB(0, 255, 230),
    SecondaryAccent  = Color3.fromRGB(255, 0, 110),
    
    TextPrimary      = Color3.fromRGB(255, 255, 255),
    TextSecondary    = Color3.fromRGB(180, 195, 210),
    TextTerminal     = Color3.fromRGB(0, 255, 170),
    TextDisabled     = Color3.fromRGB(115, 130, 145),
    
    Border           = Color3.fromRGB(0, 255, 170),
    BorderSubtle     = Color3.fromRGB(45, 55, 75),
    
    Success          = Color3.fromRGB(0, 255, 128),
    Warning          = Color3.fromRGB(255, 204, 0),
    Error            = Color3.fromRGB(255, 60, 90)
}

Novier.Config = {
    FontNormal       = Enum.Font.GothamMedium,
    FontBold         = Enum.Font.GothamBold,
    FontCode         = Enum.Font.Code,
    PillWidth        = 780,
    PillHeight       = 46,
    DrawerWidth      = 840,
    DrawerHeight     = 560,
    DefaultToggleKey = Enum.KeyCode.RightControl,
    DefaultFovKey    = Enum.KeyCode.RightAlt
}

Novier._Connections = {}

-- Camera FOV State
Novier.FOVConfig = {
    Enabled       = false,
    BaseFOV       = 70,
    MaxKick       = 24,
    Smoothness    = 0.18
}

-- Utility helpers
local function create(className, properties, children)
    local inst = Instance.new(className)
    for prop, val in pairs(properties or {}) do
        inst[prop] = val
    end
    for _, child in ipairs(children or {}) do
        if typeof(child) == "Instance" then
            child.Parent = inst
        end
    end
    return inst
end

local function tween(inst, props, duration, style, dir)
    local tw = TweenService:Create(
        inst,
        TweenInfo.new(duration or 0.22, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function track(conn)
    table.insert(Novier._Connections, conn)
    return conn
end

local function getGuiContainer()
    local ok, core = pcall(function() return CoreGui end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

--========================================================--
-- FULL-SCREEN LUA CODE-RAIN BACKGROUND CANVAS
--========================================================--
local function buildFullScreenMatrix(screenGui)
    local RainCanvas = create("Frame", {
        Name = "FullScreenLuaRain",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 1,
        ClipsDescendants = true,
        Active = false,
        Parent = screenGui
    })

    local luaSnippets = {
        "local function exec(addr)", "setreadonly(mt, false)", "bit32.bxor(a, b)",
        "task.spawn(function()", "os.clock() - tick()", "getrawmetatable(game)",
        "hookmetamethod(game)", "0x7FFD98A2B", "checkcaller() == true",
        "loadstring(bytecode)()", "math.clamp(alpha, 0, 1)", "run_service.Heartbeat",
        "debug.getinfo(1).func", "table.insert(buffers)", "collectgarbage('count')"
    }

    local numCols = 24
    for i = 1, numCols do
        local colLabel = create("TextLabel", {
            Size = UDim2.new(1 / numCols, 0, 2, 0),
            Position = UDim2.new((i - 1) / numCols, 0, -1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Font = Novier.Config.FontCode,
            TextSize = 10,
            TextColor3 = Novier.Theme.Accent,
            TextTransparency = 0.90,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextWrapped = true,
            ZIndex = 1,
            Parent = RainCanvas
        })

        local stream = ""
        for _ = 1, 35 do stream = stream .. luaSnippets[math.random(1, #luaSnippets)] .. "\n" end
        colLabel.Text = stream

        local fallSpeed = math.random(16, 32)
        task.spawn(function()
            while colLabel.Parent do
                colLabel.Position = UDim2.new((i - 1) / numCols, 0, -1, 0)
                local tw = TweenService:Create(colLabel, TweenInfo.new(fallSpeed, Enum.EasingStyle.Linear), {
                    Position = UDim2.new((i - 1) / numCols, 0, 0, 0)
                })
                tw:Play()
                tw.Completed:Wait()
            end
        end)
    end
end

--========================================================--
-- SCREEN HUD
--========================================================--
local function buildScreenHUD(screenGui)
    local HUD = create("Frame", {
        Name = "ScreenHUD",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Active = false,
        Parent = screenGui
    })

    local function makeBracket(anchor, pos, labelText)
        local frame = create("Frame", {
            Size = UDim2.fromOffset(150, 42),
            AnchorPoint = anchor,
            Position = pos,
            BackgroundTransparency = 1,
            ZIndex = 3,
            Parent = HUD
        })

        create("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Font = Novier.Config.FontCode,
            TextSize = 10,
            TextColor3 = Novier.Theme.Accent,
            TextTransparency = 0.35,
            TextXAlignment = (anchor.X == 0) and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
            TextYAlignment = (anchor.Y == 0) and Enum.TextYAlignment.Top or Enum.TextYAlignment.Bottom,
            Text = labelText,
            ZIndex = 3,
            Parent = frame
        })
        return frame
    end

    makeBracket(Vector2.new(0, 0), UDim2.fromOffset(14, 14), "┌── [ISLAND: DYNAMIC]\n│ SUB-TABS: ONLINE")
    makeBracket(Vector2.new(1, 0), UDim2.new(1, -14, 0, 14), "[NOVIER // ZERO-DAY] ──┐\nSTATUS: RUNNING │")
    local bl = makeBracket(Vector2.new(0, 1), UDim2.new(0, 14, 1, -14), "│ POS: SCANNING...\n└── [TELEMETRY]")

    track(RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            local label = bl:FindFirstChildOfClass("TextLabel")
            if label then
                label.Text = string.format("│ POS: %.1f, %.1f, %.1f\n└── [BEAT FOV: %s]", pos.X, pos.Y, pos.Z, Novier.FOVConfig.Enabled and "ON" or "OFF")
            end
        end
    end))
end

--========================================================--
-- DUAL EDGE-SCREEN BEAT PULSE WINGS
--========================================================--
local function buildEdgePulseWings(screenGui)
    local PulseContainer = create("Frame", {
        Name = "EdgePulseWings",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
        Active = false,
        Parent = screenGui
    })

    local LeftWing = create("Frame", {
        Name = "LeftWing",
        Size = UDim2.new(0, 60, 0.45, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 4,
        Parent = PulseContainer
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            Padding = UDim.new(0, 4)
        })
    })

    local RightWing = create("Frame", {
        Name = "RightWing",
        Size = UDim2.new(0, 60, 0.45, 0),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 4,
        Parent = PulseContainer
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 4)
        })
    })

    local LeftGlow = create("Frame", {
        Size = UDim2.new(0, 16, 0.55, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Novier.Theme.Accent,
        BackgroundTransparency = 0.95,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = PulseContainer
    }, {
        create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.3),
                NumberSequenceKeypoint.new(1, 1)
            })
        })
    })

    local RightGlow = create("Frame", {
        Size = UDim2.new(0, 16, 0.55, 0),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Novier.Theme.Accent,
        BackgroundTransparency = 0.95,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = PulseContainer
    }, {
        create("UIGradient", {
            Rotation = 180,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.3),
                NumberSequenceKeypoint.new(1, 1)
            })
        })
    })

    local LeftBars, RightBars = {}, {}
    for _ = 1, 12 do
        local lBar = create("Frame", {
            Size = UDim2.fromOffset(4, 4),
            BackgroundColor3 = Novier.Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 5,
            Parent = LeftWing
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        table.insert(LeftBars, lBar)

        local rBar = create("Frame", {
            Size = UDim2.fromOffset(4, 4),
            BackgroundColor3 = Novier.Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 5,
            Parent = RightWing
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        table.insert(RightBars, rBar)
    end

    return {
        LeftBars = LeftBars,
        RightBars = RightBars,
        LeftGlow = LeftGlow,
        RightGlow = RightGlow
    }
end

--========================================================--
-- CAPSULE / DYNAMIC PILL CONSTRUCTOR
--========================================================--
function Novier:CreateWindow(windowTitle)
    if Novier._Gui then Novier:Destroy() end

    local Window = {}
    Window.Tabs = {}
    Window.ActiveTab = nil
    Window.IsOpen = true
    Window.DrawerOpen = false
    Window.ToggleKey = Novier.Config.DefaultToggleKey
    Window.FovKey = Novier.Config.DefaultFovKey

    local Gui = create("ScreenGui", {
        Name = "Novier_Pill_Island",
        ResetOnSpawn = false,
        DisplayOrder = 9999,
        IgnoreGuiInset = true,
        Parent = getGuiContainer()
    })
    Novier._Gui = Gui

    buildFullScreenMatrix(Gui)
    buildScreenHUD(Gui)
    local EdgeWings = buildEdgePulseWings(Gui)

    local OverlayLayer = create("Frame", {
        Name = "OverlayLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 500,
        Parent = Gui
    })

    local pillOpenPos = UDim2.new(0.5, 0, 0, 16)
    local pillClosePos = UDim2.new(0.5, 0, 0, -65)

    -- THE PILL
    local Pill = create("Frame", {
        Name = "PillBar",
        Size = UDim2.fromOffset(Novier.Config.PillWidth, Novier.Config.PillHeight),
        Position = pillOpenPos,
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Novier.Theme.PillBackground,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 100,
        Parent = Gui
    }, {
        create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        create("UIStroke", {
            Name = "PillStroke",
            Thickness = 1.6,
            Color = Novier.Theme.Border,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        }),
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 16)
        })
    })

    -- Brand
    local BrandHolder = create("Frame", {
        Size = UDim2.new(0, 170, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 101,
        Parent = Pill
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8)
        })
    })

    create("TextLabel", {
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = Novier.Theme.SurfaceElevated,
        Text = "⚡",
        Font = Novier.Config.FontBold,
        TextSize = 13,
        TextColor3 = Novier.Theme.Accent,
        ZIndex = 102,
        Parent = BrandHolder
    }, {
        create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        create("UIStroke", { Thickness = 1, Color = Novier.Theme.Accent })
    })

    create("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1,
        Text = string.upper(windowTitle or "NOVIER // ISLAND"),
        Font = Novier.Config.FontBold,
        TextSize = 12,
        TextColor3 = Novier.Theme.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102,
        Parent = BrandHolder
    })

    -- Center Visualizer
    local VisualizerHolder = create("Frame", {
        Name = "PillVisualizer",
        Size = UDim2.fromOffset(140, 24),
        Position = UDim2.new(0.5, -70, 0.5, -12),
        BackgroundTransparency = 1,
        ZIndex = 101,
        Parent = Pill
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 2)
        })
    })

    local VisualizerBars = {}
    for _ = 1, 16 do
        local bar = create("Frame", {
            Size = UDim2.fromOffset(3, 4),
            BackgroundColor3 = Novier.Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 102,
            Parent = VisualizerHolder
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) })
        })
        table.insert(VisualizerBars, bar)
    end

    -- Tab Bar (Inside Pill)
    local TabBar = create("Frame", {
        Size = UDim2.new(0.48, 0, 1, 0),
        Position = UDim2.new(0.52, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 101,
        Parent = Pill
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6)
        })
    })

    -- Drawer
    local drawerOpenPos = UDim2.new(0.5, 0, 0, 72)
    local drawerClosePos = UDim2.new(0.5, 0, 0, 45)

    local Drawer = create("Frame", {
        Name = "PillDrawer",
        Size = UDim2.fromOffset(Novier.Config.DrawerWidth, Novier.Config.DrawerHeight),
        Position = drawerClosePos,
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Novier.Theme.DrawerBackground,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 10,
        Parent = Gui
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 14) }),
        create("UIStroke", { Thickness = 1.4, Color = Novier.Theme.BorderSubtle }),
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 16),
            PaddingTop = UDim.new(0, 16),
            PaddingBottom = UDim.new(0, 16)
        })
    })

    -- Audio Core
    local ActiveSound = create("Sound", {
        Name = "NovierAudioStream",
        Volume = 0.5,
        Looped = true,
        SoundId = "rbxassetid://9043887091",
        Parent = SoundService
    })
    Window.Sound = ActiveSound

    -- FOV Kick & Synth Processing Loop
    local currentFovOffset = 0
    track(RunService.RenderStepped:Connect(function()
        local isPlaying = ActiveSound.IsPlaying
        local loudness = isPlaying and ActiveSound.PlaybackLoudness or 0
        local bass = math.clamp(loudness / 340, 0, 1)

        -- Audio Beat FOV
        if Camera then
            if Novier.FOVConfig.Enabled and isPlaying then
                local targetKick = bass * Novier.FOVConfig.MaxKick
                currentFovOffset = currentFovOffset + (targetKick - currentFovOffset) * Novier.FOVConfig.Smoothness
                Camera.FieldOfView = Novier.FOVConfig.BaseFOV + currentFovOffset
            else
                currentFovOffset = currentFovOffset + (0 - currentFovOffset) * 0.2
                Camera.FieldOfView = Novier.FOVConfig.BaseFOV + currentFovOffset
            end
        end

        -- Edge Flares
        if isPlaying and bass > 0.05 then
            Pill.PillStroke.Color = Novier.Theme.BorderSubtle:Lerp(Novier.Theme.Accent, bass)
            EdgeWings.LeftGlow.BackgroundTransparency = 0.95 - (bass * 0.4)
            EdgeWings.RightGlow.BackgroundTransparency = 0.95 - (bass * 0.4)
            EdgeWings.LeftGlow.Size = UDim2.new(0, math.floor(16 + (bass * 35)), 0.55, 0)
            EdgeWings.RightGlow.Size = UDim2.new(0, math.floor(16 + (bass * 35)), 0.55, 0)
        else
            Pill.PillStroke.Color = Novier.Theme.Border
            EdgeWings.LeftGlow.BackgroundTransparency = 0.95
            EdgeWings.RightGlow.BackgroundTransparency = 0.95
            EdgeWings.LeftGlow.Size = UDim2.new(0, 16, 0.55, 0)
            EdgeWings.RightGlow.Size = UDim2.new(0, 16, 0.55, 0)
        end

        -- Edge Wings
        for idx = 1, 12 do
            local lBar = EdgeWings.LeftBars[idx]
            local rBar = EdgeWings.RightBars[idx]
            local width = 4
            local clr = Novier.Theme.Accent

            if isPlaying then
                local freqFactor = (13 - idx) / 12
                local wave = math.sin((os.clock() * 10) + (idx * 0.5))
                local norm = math.clamp((loudness / 350) * freqFactor * (0.6 + (0.4 * wave)), 0.05, 1)
                width = math.floor(norm * 55)

                if norm > 0.65 then clr = Novier.Theme.AccentGlow
                elseif norm > 0.85 then clr = Novier.Theme.SecondaryAccent end
            end

            lBar.Size = UDim2.fromOffset(math.max(4, width), 4)
            rBar.Size = UDim2.fromOffset(math.max(4, width), 4)
            lBar.BackgroundColor3 = clr
            rBar.BackgroundColor3 = clr
        end

        -- Pill Center Waveform
        local centerIndex = 8.5
        for idx, bar in ipairs(VisualizerBars) do
            local height = 3
            if isPlaying then
                local distFromCenter = math.abs(idx - centerIndex) / 7.5
                local wave = math.sin((os.clock() * 9) + (idx * 0.4))
                local curve = (1 - (distFromCenter * 0.45))
                height = math.floor(math.clamp((loudness / 380) * curve * (0.6 + (0.4 * wave)), 0.1, 1) * 24)
            end
            bar.Size = UDim2.fromOffset(3, math.max(3, height))
            bar.BackgroundColor3 = (idx % 2 == 0) and Novier.Theme.Accent or Novier.Theme.AccentGlow
        end
    end))

    -- Visibility & Keybind
    function Window:SetVisible(state)
        Window.IsOpen = (state ~= nil) and state or (not Window.IsOpen)
        if Window.IsOpen then
            Pill.Visible = true
            EdgeWings.LeftGlow.Visible = true
            EdgeWings.RightGlow.Visible = true
            tween(Pill, { Position = pillOpenPos }, 0.28)
        else
            tween(Pill, { Position = pillClosePos }, 0.22).Completed:Connect(function()
                if not Window.IsOpen then Pill.Visible = false end
            end)
            EdgeWings.LeftGlow.Visible = false
            EdgeWings.RightGlow.Visible = false
            Window:CloseDrawer()
        end
    end

    function Window:OpenDrawer()
        Window.DrawerOpen = true
        Drawer.Visible = true
        tween(Drawer, { Position = drawerOpenPos }, 0.25)
    end

    function Window:CloseDrawer()
        Window.DrawerOpen = false
        for _, t in ipairs(Window.Tabs) do
            t.Page.Visible = false
            tween(t.Button, { BackgroundColor3 = Novier.Theme.SurfaceElevated, TextColor3 = Novier.Theme.TextSecondary }, 0.15)
        end
        local tw = tween(Drawer, { Position = drawerClosePos }, 0.2)
        tw.Completed:Connect(function()
            if not Window.DrawerOpen then Drawer.Visible = false end
        end)
    end

    track(UserInputService.InputBegan:Connect(function(input, processed)
        if not processed then
            if input.KeyCode == Window.ToggleKey then
                Window:SetVisible()
            elseif input.KeyCode == Window.FovKey then
                Novier.FOVConfig.Enabled = not Novier.FOVConfig.Enabled
                Novier:Notify("Beat FOV", Novier.FOVConfig.Enabled and "Camera Kick Activated." or "Camera Kick Deactivated.", 2, Novier.FOVConfig.Enabled and "Success" or "Warning")
            end
        end
    end))

    -- Forward declarations for control builders
    local buildSection

    --====================================================--
    -- TABS (MAIN TOP-LEVEL NAVIGATION)
    --====================================================--
    function Window:CreateTab(tabName, iconSymbol)
        local Tab = {}
        local displayText = (iconSymbol and iconSymbol ~= "") and (iconSymbol .. " " .. tabName) or tabName

        local TabBtn = create("TextButton", {
            Name = tabName .. "_Tab",
            Size = UDim2.fromOffset(0, 28),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Novier.Theme.SurfaceElevated,
            Text = displayText,
            Font = Novier.Config.FontBold,
            TextSize = 11,
            TextColor3 = Novier.Theme.TextSecondary,
            AutoButtonColor = false,
            ZIndex = 102,
            Parent = TabBar
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle }),
            create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
        })

        local Page = create("ScrollingFrame", {
            Name = tabName .. "_Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Novier.Theme.Accent,
            CanvasSize = UDim2.new(),
            Visible = false,
            ZIndex = 13,
            ClipsDescendants = true,
            Parent = Drawer
        }, {
            create("UIListLayout", {
                Padding = UDim.new(0, 12),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            create("UIPadding", {
                PaddingRight = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 14)
            })
        })

        Page.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.fromOffset(0, Page.UIListLayout.AbsoluteContentSize.Y + 24)
        end)

        local function selectTab()
            if Window.ActiveTab == Tab and Window.DrawerOpen then
                Window:CloseDrawer()
                Window.ActiveTab = nil
                return
            end

            for _, t in ipairs(Window.Tabs) do
                t.Page.Visible = false
                tween(t.Button, { BackgroundColor3 = Novier.Theme.SurfaceElevated, TextColor3 = Novier.Theme.TextSecondary }, 0.15)
            end

            Page.Visible = true
            Window.ActiveTab = Tab
            tween(TabBtn, { BackgroundColor3 = Novier.Theme.SurfaceHighlight, TextColor3 = Novier.Theme.Accent }, 0.15)
            Window:OpenDrawer()
        end

        track(TabBtn.MouseButton1Click:Connect(selectTab))

        Tab.Button = TabBtn
        Tab.Page = Page
        table.insert(Window.Tabs, Tab)

        -- Section creation on a base tab
        function Tab:CreateSection(sectionName)
            return buildSection(Page, sectionName, OverlayLayer)
        end

        --====================================================--
        -- DYNAMIC SUB-TABS BUILDER
        --====================================================--
        function Tab:CreateSubTabs(initialList)
            local SubTabSystem = {}
            SubTabSystem.SubTabs = {}
            SubTabSystem.ActiveSubTab = nil

            -- Header Bar for Sub-Tabs
            local SubTabBar = create("ScrollingFrame", {
                Name = "SubTabBar",
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                ScrollBarThickness = 0,
                CanvasSize = UDim2.new(),
                ZIndex = 14,
                Parent = Page
            }, {
                create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6)
                })
            })

            SubTabBar.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SubTabBar.CanvasSize = UDim2.fromOffset(SubTabBar.UIListLayout.AbsoluteContentSize.X + 10, 0)
            end)

            -- Sub-Page Viewport Holder
            local SubPageHolder = create("Frame", {
                Name = "SubPageHolder",
                Size = UDim2.new(1, 0, 0, 480),
                BackgroundTransparency = 1,
                ZIndex = 13,
                Parent = Page
            })

            -- Method to add a single sub-tab dynamically
            function SubTabSystem:AddSubTab(subName, icon)
                if SubTabSystem.SubTabs[subName] then
                    return SubTabSystem.SubTabs[subName]
                end

                local SubTab = {}
                local label = (icon and icon ~= "") and (icon .. " " .. subName) or subName

                local SubBtn = create("TextButton", {
                    Name = subName .. "_SubBtn",
                    Size = UDim2.fromOffset(0, 26),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = Novier.Theme.SurfaceElevated,
                    Text = label,
                    Font = Novier.Config.FontBold,
                    TextSize = 10,
                    TextColor3 = Novier.Theme.TextSecondary,
                    AutoButtonColor = false,
                    ZIndex = 15,
                    Parent = SubTabBar
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle }),
                    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
                })

                local SubPage = create("ScrollingFrame", {
                    Name = subName .. "_SubPage",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Novier.Theme.Accent,
                    CanvasSize = UDim2.new(),
                    Visible = false,
                    ZIndex = 13,
                    ClipsDescendants = true,
                    Parent = SubPageHolder
                }, {
                    create("UIListLayout", {
                        Padding = UDim.new(0, 10),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    create("UIPadding", {
                        PaddingRight = UDim.new(0, 6),
                        PaddingBottom = UDim.new(0, 10)
                    })
                })

                SubPage.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    SubPage.CanvasSize = UDim2.fromOffset(0, SubPage.UIListLayout.AbsoluteContentSize.Y + 20)
                end)

                local function activateSubTab()
                    for _, s in pairs(SubTabSystem.SubTabs) do
                        s.Page.Visible = false
                        tween(s.Button, { BackgroundColor3 = Novier.Theme.SurfaceElevated, TextColor3 = Novier.Theme.TextSecondary }, 0.12)
                    end

                    SubPage.Visible = true
                    SubTabSystem.ActiveSubTab = SubTab
                    tween(SubBtn, { BackgroundColor3 = Novier.Theme.SurfaceHighlight, TextColor3 = Novier.Theme.Accent }, 0.12)
                end

                track(SubBtn.MouseButton1Click:Connect(activateSubTab))

                SubTab.Button = SubBtn
                SubTab.Page = SubPage

                function SubTab:CreateSection(secName)
                    return buildSection(SubPage, secName, OverlayLayer)
                end

                SubTabSystem.SubTabs[subName] = SubTab

                -- Auto-select the first one created
                if not SubTabSystem.ActiveSubTab then
                    activateSubTab()
                end

                return SubTab
            end

            -- Method to remove a subtab dynamically
            function SubTabSystem:RemoveSubTab(subName)
                local sub = SubTabSystem.SubTabs[subName]
                if sub then
                    sub.Button:Destroy()
                    sub.Page:Destroy()
                    SubTabSystem.SubTabs[subName] = nil

                    if SubTabSystem.ActiveSubTab == sub then
                        SubTabSystem.ActiveSubTab = nil
                        for _, nextSub in pairs(SubTabSystem.SubTabs) do
                            nextSub.Page.Visible = true
                            SubTabSystem.ActiveSubTab = nextSub
                            tween(nextSub.Button, { BackgroundColor3 = Novier.Theme.SurfaceHighlight, TextColor3 = Novier.Theme.Accent }, 0.12)
                            break
                        end
                    end
                end
            end

            -- Method to clear all sub-tabs at once
            function SubTabSystem:ClearSubTabs()
                for name, sub in pairs(SubTabSystem.SubTabs) do
                    sub.Button:Destroy()
                    sub.Page:Destroy()
                end
                table.clear(SubTabSystem.SubTabs)
                SubTabSystem.ActiveSubTab = nil
            end

            -- Populate initial list if supplied
            if type(initialList) == "table" then
                for _, item in ipairs(initialList) do
                    if type(item) == "table" then
                        SubTabSystem:AddSubTab(item.Name or item[1], item.Icon or item[2])
                    else
                        SubTabSystem:AddSubTab(tostring(item))
                    end
                end
            end

            return SubTabSystem
        end

        return Tab
    end

    --====================================================--
    -- MODULAR SECTION BUILDER HELPER
    --====================================================--
    buildSection = function(parentContainer, sectionName, overlayLayer)
        local Section = {}

        local Box = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Novier.Theme.SurfaceElevated,
            BackgroundTransparency = 0,
            ZIndex = 14,
            Parent = parentContainer
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 10) }),
            create("UIStroke", { Thickness = 1.2, Color = Novier.Theme.BorderSubtle }),
            create("UIPadding", {
                PaddingTop = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 14),
                PaddingLeft = UDim.new(0, 14),
                PaddingRight = UDim.new(0, 14)
            })
        })

        create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = "// " .. string.upper(sectionName),
            Font = Novier.Config.FontBold,
            TextSize = 11,
            TextColor3 = Novier.Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 15,
            Parent = Box
        })

        local ControlsHolder = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.fromOffset(0, 24),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            ZIndex = 15,
            Parent = Box
        }, {
            create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
        })

        Section.Box = Box
        Section.ControlsHolder = ControlsHolder

        -- Button
        function Section:CreateButton(name, callback)
            local Btn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Novier.Theme.SurfaceHighlight,
                Text = "[ " .. name .. " ]",
                Font = Novier.Config.FontBold,
                TextSize = 12,
                TextColor3 = Novier.Theme.TextPrimary,
                AutoButtonColor = false,
                ZIndex = 16,
                Parent = ControlsHolder
            }, {
                create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
            })

            track(Btn.MouseEnter:Connect(function() tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceElevated, TextColor3 = Novier.Theme.Accent }, 0.12) end))
            track(Btn.MouseLeave:Connect(function() tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceHighlight, TextColor3 = Novier.Theme.TextPrimary }, 0.12) end))
            track(Btn.MouseButton1Click:Connect(function()
                tween(Btn, { BackgroundColor3 = Novier.Theme.Accent, TextColor3 = Color3.fromRGB(0, 0, 0) }, 0.08)
                task.delay(0.1, function() tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceHighlight, TextColor3 = Novier.Theme.TextPrimary }, 0.12) end)
                if callback then callback() end
            end))
            return Btn
        end

        -- Toggle
        function Section:CreateToggle(name, default, callback)
            local state = default or false
            local ToggleBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Novier.Theme.SurfaceHighlight,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 16,
                Parent = ControlsHolder
            }, {
                create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle }),
                create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
            })

            create("TextLabel", {
                Size = UDim2.new(1, -50, 1, 0),
                BackgroundTransparency = 1,
                Text = name,
                Font = Novier.Config.FontNormal,
                TextSize = 12,
                TextColor3 = Novier.Theme.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 17,
                Parent = ToggleBtn
            })

            local Switch = create("Frame", {
                Size = UDim2.fromOffset(40, 20),
                Position = UDim2.new(1, -40, 0.5, -10),
                BackgroundColor3 = state and Novier.Theme.Accent or Novier.Theme.SurfaceElevated,
                ZIndex = 17,
                Parent = ToggleBtn
            }, {
                create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
            })

            local Dot = create("Frame", {
                Size = UDim2.fromOffset(14, 14),
                Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex = 18,
                Parent = Switch
            }, {
                create("UICorner", { CornerRadius = UDim.new(1, 0) })
            })

            local function apply(val)
                state = val
                tween(Switch, { BackgroundColor3 = state and Novier.Theme.Accent or Novier.Theme.SurfaceElevated }, 0.15)
                tween(Dot, { Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) }, 0.15)
                if callback then callback(state) end
            end

            track(ToggleBtn.MouseButton1Click:Connect(function() apply(not state) end))
            return { Set = function(_, v) apply(v) end, Get = function() return state end }
        end

        -- Slider
        function Section:CreateSlider(name, min, max, default, step, callback)
            min = min or 0
            max = max or 100
            step = step or 1
            local current = math.clamp(default or min, min, max)

            local SliderFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Novier.Theme.SurfaceHighlight,
                ZIndex = 16,
                Parent = ControlsHolder
            }, {
                create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle }),
                create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 6) })
            })

            create("TextLabel", {
                Size = UDim2.new(0.7, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = name,
                Font = Novier.Config.FontNormal,
                TextSize = 12,
                TextColor3 = Novier.Theme.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 17,
                Parent = SliderFrame
            })

            local Readout = create("TextLabel", {
                Size = UDim2.new(0.3, 0, 0, 18),
                Position = UDim2.new(0.7, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(current),
                Font = Novier.Config.FontBold,
                TextSize = 12,
                TextColor3 = Novier.Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 17,
                Parent = SliderFrame
            })

            local Bar = create("Frame", {
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.fromOffset(0, 28),
                BackgroundColor3 = Novier.Theme.SurfaceElevated,
                ZIndex = 17,
                Parent = SliderFrame
            }, {
                create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
            })

            local Fill = create("Frame", {
                Size = UDim2.fromScale((current - min) / (max - min), 1),
                BackgroundColor3 = Novier.Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 18,
                Parent = Bar
            }, {
                create("UICorner", { CornerRadius = UDim.new(1, 0) })
            })

            local Knob = create("Frame", {
                Size = UDim2.fromOffset(14, 14),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new((current - min) / (max - min), 0, 0.5, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex = 19,
                Parent = Bar
            }, {
                create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                create("UIStroke", { Thickness = 1, Color = Novier.Theme.Accent })
            })

            local isDragging = false
            local function setVal(v, emit)
                local snapped = math.floor((v - min) / step + 0.5) * step + min
                current = math.clamp(snapped, min, max)
                local alpha = (current - min) / (max - min)
                Fill.Size = UDim2.fromScale(alpha, 1)
                Knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                Readout.Text = tostring(current)
                if emit and callback then callback(current) end
            end

            local function updateFromMouse(x)
                local alpha = math.clamp((x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                setVal(min + ((max - min) * alpha), true)
            end

            track(Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    updateFromMouse(input.Position.X)
                end
            end))

            track(UserInputService.InputChanged:Connect(function(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromMouse(input.Position.X)
                end
            end))

            track(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                end
            end))

            return { Set = function(_, v) setVal(v, true) end, Get = function() return current end }
        end

        -- Textbox
        function Section:CreateTextbox(name, placeholder, clearOnFocus, callback)
            local BoxFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Novier.Theme.SurfaceHighlight,
                ZIndex = 16,
                Parent = ControlsHolder
            }, {
                create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle }),
                create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
            })

            local Input = create("TextBox", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                PlaceholderText = placeholder or "Enter text...",
                PlaceholderColor3 = Novier.Theme.TextDisabled,
                Text = "",
                Font = Novier.Config.FontNormal,
                TextSize = 12,
                TextColor3 = Novier.Theme.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = clearOnFocus or false,
                ZIndex = 17,
                Parent = BoxFrame
            })

            track(Input.FocusLost:Connect(function(enter)
                if callback then callback(Input.Text, enter) end
            end))
            return { Set = function(_, t) Input.Text = t end, Get = function() return Input.Text end }
        end

        -- Dropdown
        function Section:CreateDropdown(name, list, default, callback)
            local selected = default or list[1]
            local isOpen = false

            local MainBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Novier.Theme.SurfaceHighlight,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 16,
                Parent = ControlsHolder
            }, {
                create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle }),
                create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
            })

            create("TextLabel", {
                Size = UDim2.fromScale(0.5, 1),
                BackgroundTransparency = 1,
                Text = name,
                Font = Novier.Config.FontNormal,
                TextSize = 12,
                TextColor3 = Novier.Theme.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 17,
                Parent = MainBtn
            })

            local SelectedLbl = create("TextLabel", {
                Size = UDim2.new(0.5, -16, 1, 0),
                Position = UDim2.fromScale(0.5, 0),
                BackgroundTransparency = 1,
                Text = tostring(selected),
                Font = Novier.Config.FontBold,
                TextSize = 12,
                TextColor3 = Novier.Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 17,
                Parent = MainBtn
            })

            local Menu = create("Frame", {
                Size = UDim2.fromOffset(0, 0),
                BackgroundColor3 = Novier.Theme.PillBackground,
                ClipsDescendants = true,
                Visible = false,
                ZIndex = 501,
                Parent = overlayLayer
            }, {
                create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                create("UIStroke", { Thickness = 1.4, Color = Novier.Theme.Accent })
            })

            local Scroll = create("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Novier.Theme.Accent,
                CanvasSize = UDim2.new(),
                ZIndex = 502,
                Parent = Menu
            }, {
                create("UIListLayout", { Padding = UDim.new(0, 3) }),
                create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })
            })

            local function populate()
                for _, c in ipairs(Scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                for _, item in ipairs(list) do
                    local opt = create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 26),
                        BackgroundColor3 = (selected == item) and Novier.Theme.SurfaceHighlight or Novier.Theme.SurfaceElevated,
                        Text = tostring(item),
                        Font = Novier.Config.FontNormal,
                        TextSize = 11,
                        TextColor3 = (selected == item) and Novier.Theme.Accent or Novier.Theme.TextPrimary,
                        AutoButtonColor = false,
                        ZIndex = 503,
                        Parent = Scroll
                    }, { create("UICorner", { CornerRadius = UDim.new(0, 4) }) })

                    track(opt.MouseButton1Click:Connect(function()
                        selected = item
                        SelectedLbl.Text = tostring(item)
                        if callback then callback(selected) end
                        isOpen = false
                        Menu.Visible = false
                    end))
                end
                Scroll.CanvasSize = UDim2.fromOffset(0, #list * 29 + 8)
            end

            track(MainBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    populate()
                    local absPos = MainBtn.AbsolutePosition
                    local absSize = MainBtn.AbsoluteSize
                    Menu.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
                    Menu.Size = UDim2.fromOffset(absSize.X, math.clamp(#list * 29 + 10, 30, 160))
                    Menu.Visible = true
                else
                    Menu.Visible = false
                end
            end))

            return { Set = function(_, v) selected = v; SelectedLbl.Text = tostring(v) end, Get = function() return selected end }
        end

        -- Terminal
        function Section:CreateTerminal(height)
            local TermFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, height or 130),
                BackgroundColor3 = Color3.fromRGB(6, 7, 10),
                ZIndex = 16,
                Parent = ControlsHolder
            }, {
                create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                create("UIStroke", { Thickness = 1.2, Color = Novier.Theme.BorderSubtle }),
                create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
            })

            local TermScroll = create("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Novier.Theme.Accent,
                CanvasSize = UDim2.new(),
                ZIndex = 17,
                Parent = TermFrame
            }, {
                create("UIListLayout", { Padding = UDim.new(0, 3) })
            })

            local function append(msg, color)
                create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Text = string.format("[%s] > %s", os.date("%X"), tostring(msg)),
                    Font = Novier.Config.FontCode,
                    TextSize = 11,
                    TextColor3 = color or Novier.Theme.TextTerminal,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 18,
                    Parent = TermScroll
                })
                TermScroll.CanvasSize = UDim2.fromOffset(0, TermScroll.UIListLayout.AbsoluteContentSize.Y + 16)
                TermScroll.CanvasPosition = Vector2.new(0, TermScroll.CanvasSize.Y.Offset)
            end

            append("SUB-MODULE ONLINE.", Novier.Theme.Accent)

            return {
                Log = function(_, m) append(m, Novier.Theme.TextTerminal) end,
                Warn = function(_, m) append(m, Novier.Theme.Warning) end,
                Error = function(_, m) append(m, Novier.Theme.Error) end,
                Clear = function(_)
                    for _, c in ipairs(TermScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
                    TermScroll.CanvasSize = UDim2.new()
                end
            }
        end

        return Section
    end

    -- Dedicated Audio & Media Suite
    function Window:CreateMediaSuite(defaultTrackTable)
        local tracks = defaultTrackTable or {
            ["Synth Loop"]        = "rbxassetid://9043887091",
            ["Action Electronic"] = "rbxassetid://1840590064",
            ["Dark Cyber"]        = "rbxassetid://1843404009"
        }

        local MediaTab = Window:CreateTab("MEDIA", "♫")
        local MediaSec = MediaTab:CreateSection("Audio Stream Controller")

        local trackNames = {}
        for name in pairs(tracks) do table.insert(trackNames, name) end

        MediaSec:CreateDropdown("Tracks", trackNames, trackNames[1], function(chosen)
            ActiveSound.SoundId = tracks[chosen]
            ActiveSound.TimePosition = 0
            ActiveSound:Play()
            Novier:Notify("Audio Driver", "Stream: " .. chosen, 2, "Success")
        end)

        MediaSec:CreateButton("Toggle Play / Pause", function()
            if ActiveSound.IsPlaying then ActiveSound:Pause() else ActiveSound:Resume() end
        end)

        MediaSec:CreateSlider("Master Volume", 0, 200, 50, 1, function(val)
            ActiveSound.Volume = val / 100
        end)

        local FovSec = MediaTab:CreateSection("Beat-Synchronized Camera FOV")
        
        FovSec:CreateToggle("Audio Beat FOV (Toggle: [RightAlt])", Novier.FOVConfig.Enabled, function(active)
            Novier.FOVConfig.Enabled = active
            Novier:Notify("Camera Engine", active and "Beat FOV Kick Enabled." or "Beat FOV Disabled.", 2, active and "Success" or "Warning")
        end)

        FovSec:CreateSlider("Base FOV", 50, 110, Novier.FOVConfig.BaseFOV, 1, function(val)
            Novier.FOVConfig.BaseFOV = val
            if not Novier.FOVConfig.Enabled and Camera then
                Camera.FieldOfView = val
            end
        end)

        FovSec:CreateSlider("Beat Kick Intensity", 5, 45, Novier.FOVConfig.MaxKick, 1, function(val)
            Novier.FOVConfig.MaxKick = val
        end)

        local CustomSec = MediaTab:CreateSection("Custom Sound ID")
        local Term = CustomSec:CreateTerminal(80)

        CustomSec:CreateTextbox("Audio ID", "Paste numeric ID...", false, function(txt, enter)
            if enter and txt and #txt > 0 then
                local cleanId = txt:gsub("%D", "")
                if #cleanId > 0 then
                    ActiveSound.SoundId = "rbxassetid://" .. cleanId
                    ActiveSound.TimePosition = 0
                    ActiveSound:Play()
                    Term:Log("Mounted Sound: " .. cleanId)
                    Novier:Notify("Audio", "Playing ID: " .. cleanId, 2, "Success")
                end
            end
        end)

        return {
            PlayCustom = function(_, id)
                local cleanId = tostring(id):gsub("%D", "")
                ActiveSound.SoundId = "rbxassetid://" .. cleanId
                ActiveSound.TimePosition = 0
                ActiveSound:Play()
            end
        }
    end

    return Window
end

-- Notification System
function Novier:Notify(title, message, duration, kind)
    if not Novier._Gui then return end

    local Holder = Novier._Gui:FindFirstChild("NotifyStack")
    if not Holder then
        Holder = create("Frame", {
            Name = "NotifyStack",
            Size = UDim2.fromOffset(280, 420),
            Position = UDim2.new(1, -16, 1, -40),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 500,
            Parent = Novier._Gui
        }, {
            create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6) })
        })
    end

    local edgeColor = (kind == "Success" and Novier.Theme.Success) 
                   or (kind == "Warning" and Novier.Theme.Warning) 
                   or (kind == "Error" and Novier.Theme.Error) 
                   or Novier.Theme.Accent

    local Card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        Position = UDim2.fromScale(1.3, 0),
        BackgroundColor3 = Novier.Theme.PillBackground,
        ZIndex = 501,
        Parent = Holder
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", { Thickness = 1.4, Color = edgeColor }),
        create("TextLabel", {
            Size = UDim2.new(1, -16, 0, 18),
            Position = UDim2.fromOffset(10, 6),
            BackgroundTransparency = 1,
            Text = "[ " .. string.upper(title) .. " ]",
            Font = Novier.Config.FontBold,
            TextSize = 11,
            TextColor3 = edgeColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 502
        }),
        create("TextLabel", {
            Size = UDim2.new(1, -16, 0, 24),
            Position = UDim2.fromOffset(10, 24),
            BackgroundTransparency = 1,
            Text = message,
            Font = Novier.Config.FontNormal,
            TextSize = 11,
            TextColor3 = Novier.Theme.TextPrimary,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 502
        })
    })

    tween(Card, { Position = UDim2.fromScale(0, 0) }, 0.2)
    task.delay(duration or 3, function()
        if Card and Card.Parent then
            local tw = tween(Card, { Position = UDim2.fromScale(1.3, 0) }, 0.2)
            tw.Completed:Connect(function() Card:Destroy() end)
        end
    end)
end

function Novier:Destroy()
    for _, conn in ipairs(Novier._Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(Novier._Connections)
    local s = SoundService:FindFirstChild("NovierAudioStream")
    if s then s:Destroy() end
    if Camera then Camera.FieldOfView = Novier.FOVConfig.BaseFOV end
    if Novier._Gui then Novier._Gui:Destroy(); Novier._Gui = nil end
end

return Novier

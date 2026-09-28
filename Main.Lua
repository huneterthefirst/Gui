--[[
    NOVIER // ZERO-DAY CYBER ENGINE (VISOR SLIDE-DOWN EDITION)
    - Full-Screen Cyberpunk HUD: Corner tactical crosshairs, live coordinate telemetry, CRT scanlines
    - Slide-Down Overhead Console Architecture: Smooth drop-down visor with momentum physics
    - Default Global Toggle: Hardcoded to [RightControl] (Zero boilerplate required)
    - Fixed Audio Core: Rock-solid Master Volume pipeline with direct gain control
    - 16-Band Topbar Audio Spectrum Visualizer + Ambient Bass Reactor
]]

local Novier = {}
Novier.__index = Novier

--========================================================--
-- SERVICES
--========================================================--
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- PALETTE & CONFIG
--========================================================--
Novier.Version = "3.5.0 VISOR"

Novier.Theme = {
    Background       = Color3.fromRGB(8, 9, 13),
    Surface          = Color3.fromRGB(14, 16, 23),
    SurfaceElevated  = Color3.fromRGB(20, 24, 35),
    SurfaceHighlight = Color3.fromRGB(28, 34, 50),

    Accent           = Color3.fromRGB(0, 255, 170),
    AccentGlow       = Color3.fromRGB(0, 255, 230),
    AccentDark       = Color3.fromRGB(0, 70, 50),
    SecondaryAccent  = Color3.fromRGB(255, 0, 110),

    TextPrimary      = Color3.fromRGB(240, 255, 250),
    TextSecondary    = Color3.fromRGB(140, 160, 175),
    TextTerminal     = Color3.fromRGB(0, 255, 170),
    TextDisabled     = Color3.fromRGB(70, 85, 95),

    Border           = Color3.fromRGB(0, 255, 170),
    BorderSubtle     = Color3.fromRGB(25, 45, 40),

    Success          = Color3.fromRGB(0, 255, 128),
    Warning          = Color3.fromRGB(255, 204, 0),
    Error            = Color3.fromRGB(255, 50, 90)
}

Novier.Config = {
    FontNormal       = Enum.Font.GothamMedium,
    FontBold         = Enum.Font.GothamBold,
    FontCode         = Enum.Font.Code,
    DefaultWidth     = 780,
    DefaultHeight    = 480,
    DefaultToggleKey = Enum.KeyCode.RightControl
}

Novier._Connections = {}
Novier._ActiveDropdown = nil

--========================================================--
-- UTILITIES
--========================================================--
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
        TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
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
-- FULL-SCREEN CYBERPUNK HUD OVERLAY
--========================================================--
local function buildScreenHUD(screenGui)
    local HUD = create("Frame", {
        Name = "ScreenHUD",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = screenGui
    })

    -- Full-screen CRT Scanline overlay (Passes all clicks through)
    create("ImageLabel", {
        Name = "CRTScanlines",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = "rbxassetid://497746594",
        ImageTransparency = 0.94,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.fromOffset(512, 4),
        ZIndex = 2,
        Active = false,
        Parent = HUD
    })

    -- Helper to generate corner brackets
    local function makeBracket(name, anchor, pos, labelText)
        local bracketFrame = create("Frame", {
            Name = name,
            Size = UDim2.fromOffset(130, 45),
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
            TextTransparency = 0.45,
            TextXAlignment = (anchor.X == 0) and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
            TextYAlignment = (anchor.Y == 0) and Enum.TextYAlignment.Top or Enum.TextYAlignment.Bottom,
            Text = labelText,
            ZIndex = 3,
            Parent = bracketFrame
        })
        return bracketFrame
    end

    local tl = makeBracket("TL", Vector2.new(0, 0), UDim2.fromOffset(16, 16), "┌── [SYS: READY]\n│ SENSORS: ONLINE")
    local tr = makeBracket("TR", Vector2.new(1, 0), UDim2.new(1, -16, 0, 16), "[SYS: 0x99A] ──┐\nENCRYPTION: AES │")
    local bl = makeBracket("BL", Vector2.new(0, 1), UDim2.new(0, 16, 1, -16), "│ COORD: TRACKING\n└── [ZONE: LOCAL]")
    local br = makeBracket("BR", Vector2.new(1, 1), UDim2.new(1, -16, 1, -16), "FEED: UNRESTRICTED │\n[OVERRIDE: ENGAGED] ──┘")

    -- Dynamic Live Coordinates Tracker on Bottom-Left
    track(RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            local label = bl:FindFirstChildOfClass("TextLabel")
            if label then
                label.Text = string.format("│ POS: %.1f, %.1f, %.1f\n└── [NOVIER KERNEL v%s]", pos.X, pos.Y, pos.Z, Novier.Version)
            end
        end
    end))

    return HUD
end

--========================================================--
-- WINDOW & VISOR SLIDE-DOWN SYSTEM
--========================================================--
function Novier:CreateWindow(windowTitle)
    if Novier._Gui then Novier:Destroy() end

    local Window = {}
    Window.Tabs = {}
    Window.ActiveTab = nil
    Window.IsOpen = true
    Window.ToggleKey = Novier.Config.DefaultToggleKey

    local Gui = create("ScreenGui", {
        Name = "Novier_Visor_V3",
        ResetOnSpawn = false,
        DisplayOrder = 9999,
        IgnoreGuiInset = true,
        Parent = getGuiContainer()
    })
    Novier._Gui = Gui

    buildScreenHUD(Gui)

    local OverlayLayer = create("Frame", {
        Name = "OverlayLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 300,
        Parent = Gui
    })

    -- Positions for slide-down Visor (anchored at top-center)
    local openPos = UDim2.new(0.5, 0, 0, 14)
    local closedPos = UDim2.new(0.5, 0, 0, -(Novier.Config.DefaultHeight + 40))

    local Main = create("Frame", {
        Name = "VisorWindow",
        Size = UDim2.fromOffset(Novier.Config.DefaultWidth, Novier.Config.DefaultHeight),
        Position = openPos,
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Novier.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10,
        Parent = Gui
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", {
            Name = "ShellStroke",
            Thickness = 1.4,
            Color = Novier.Theme.BorderSubtle,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
    })

    local Backlight = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, -10),
        Size = UDim2.new(1, 70, 1, 70),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = Novier.Theme.Accent,
        ImageTransparency = 0.9,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        ZIndex = 9,
        Parent = Main
    })

    -- Matrix Rain Canvas
    local MatrixCanvas = create("Frame", {
        Name = "MatrixCanvas",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 11,
        ClipsDescendants = true,
        Parent = Main
    })

    local hexChars = {"0","1","A","F","7","X","9","C","K","0x","//",">","§"}
    local columns = 20
    for i = 1, columns do
        local colLabel = create("TextLabel", {
            Size = UDim2.new(1 / columns, 0, 2, 0),
            Position = UDim2.new((i - 1) / columns, 0, -1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Font = Novier.Config.FontCode,
            TextSize = 11,
            TextColor3 = Novier.Theme.Accent,
            TextTransparency = 0.88,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            ZIndex = 11,
            Parent = MatrixCanvas
        })

        local stream = ""
        for _ = 1, 35 do stream = stream .. hexChars[math.random(1, #hexChars)] .. "\n" end
        colLabel.Text = stream

        local fallSpeed = math.random(14, 28)
        task.spawn(function()
            while colLabel.Parent do
                colLabel.Position = UDim2.new((i - 1) / columns, 0, -1, 0)
                local tw = TweenService:Create(colLabel, TweenInfo.new(fallSpeed, Enum.EasingStyle.Linear), {
                    Position = UDim2.new((i - 1) / columns, 0, 0, 0)
                })
                tw:Play()
                tw.Completed:Wait()
            end
        end)
    end

    create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Novier.Theme.Background,
        BackgroundTransparency = 0.55,
        ZIndex = 12,
        Parent = Main
    })

    -- Visor Bottom Pull Handle Tab (Quick Click Toggle)
    local PullHandle = create("TextButton", {
        Name = "PullHandle",
        Size = UDim2.fromOffset(130, 18),
        Position = UDim2.new(0.5, -65, 1, -18),
        BackgroundColor3 = Novier.Theme.SurfaceElevated,
        Text = "▲ VISOR ACTIVE ▲",
        Font = Novier.Config.FontCode,
        TextSize = 9,
        TextColor3 = Novier.Theme.Accent,
        AutoButtonColor = false,
        ZIndex = 16,
        Parent = Main
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
    })

    -- Topbar & Visualizer
    local Topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Novier.Theme.Surface,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = Main
    }, {
        create("Frame", {
            Name = "AccentStrip",
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = Novier.Theme.Accent,
            BorderSizePixel = 0
        })
    })

    create("TextLabel", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.fromOffset(12, 10),
        BackgroundColor3 = Novier.Theme.SurfaceElevated,
        Text = "⚡",
        Font = Novier.Config.FontBold,
        TextSize = 14,
        TextColor3 = Novier.Theme.Accent,
        ZIndex = 16,
        Parent = Topbar
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        create("UIStroke", { Thickness = 1, Color = Novier.Theme.Accent })
    })

    create("TextLabel", {
        Size = UDim2.new(0, 220, 1, 0),
        Position = UDim2.fromOffset(48, 0),
        BackgroundTransparency = 1,
        Font = Novier.Config.FontBold,
        TextSize = 13,
        Text = string.upper(windowTitle or "NOVIER VISOR // V3.5"),
        TextColor3 = Novier.Theme.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 16,
        Parent = Topbar
    })

    -- 16-Band Real-Time Audio Visualizer
    local VisualizerHolder = create("Frame", {
        Name = "VisualizerHolder",
        Size = UDim2.fromOffset(140, 22),
        Position = UDim2.new(0.5, -70, 0.5, -11),
        BackgroundTransparency = 1,
        ZIndex = 16,
        Parent = Topbar
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 3)
        })
    })

    local VisualizerBars = {}
    for _ = 1, 16 do
        local bar = create("Frame", {
            Size = UDim2.fromOffset(4, 4),
            BackgroundColor3 = Novier.Theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 16,
            Parent = VisualizerHolder
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) })
        })
        table.insert(VisualizerBars, bar)
    end

    local WindowControls = create("Frame", {
        Size = UDim2.fromOffset(70, 48),
        Position = UDim2.new(1, -78, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 16,
        Parent = Topbar
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6)
        })
    })

    local function makeControlBtn(symbol, hoverColor, cb)
        local btn = create("TextButton", {
            Size = UDim2.fromOffset(26, 26),
            BackgroundColor3 = Novier.Theme.SurfaceElevated,
            Text = symbol,
            Font = Novier.Config.FontCode,
            TextSize = 11,
            TextColor3 = Novier.Theme.TextSecondary,
            AutoButtonColor = false,
            ZIndex = 17,
            Parent = WindowControls
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 5) }),
            create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
        })
        track(btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundColor3 = hoverColor, TextColor3 = Color3.fromRGB(255,255,255) }, 0.12)
        end))
        track(btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundColor3 = Novier.Theme.SurfaceElevated, TextColor3 = Novier.Theme.TextSecondary }, 0.12)
        end))
        track(btn.MouseButton1Click:Connect(cb))
        return btn
    end

    --====================================================--
    -- SLIDE-DOWN TOGGLE ENGINE
    --====================================================--
    function Window:SetVisible(state)
        Window.IsOpen = (state ~= nil) and state or (not Window.IsOpen)
        if Window.IsOpen then
            Main.Visible = true
            PullHandle.Text = "▲ VISOR ACTIVE ▲"
            tween(Main, { Position = openPos }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        else
            PullHandle.Text = "▼ VISOR DOCKED ▼"
            local tw = tween(Main, { Position = closedPos }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            tw.Completed:Connect(function()
                if not Window.IsOpen then Main.Visible = false end
            end)
        end
    end

    function Window:GetVisible()
        return Window.IsOpen
    end

    function Window:SetToggleKey(newKey)
        Window.ToggleKey = newKey
    end

    -- Hardcoded Default Toggle (Right Control)
    track(UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Window.ToggleKey then
            Window:SetVisible()
        end
    end))

    makeControlBtn("▲", Novier.Theme.SurfaceHighlight, function()
        Window:SetVisible(false)
    end)

    makeControlBtn("✕", Novier.Theme.Error, function()
        Novier:Destroy()
    end)

    track(PullHandle.MouseButton1Click:Connect(function()
        Window:SetVisible()
    end))

    -- Working Audio Engine
    local ActiveSound = create("Sound", {
        Name = "NovierAudioStream",
        Volume = 0.5,
        Looped = true,
        SoundId = "rbxassetid://9043887091",
        Parent = SoundService
    })
    Window.Sound = ActiveSound

    track(RunService.RenderStepped:Connect(function()
        local isPlaying = ActiveSound.IsPlaying
        local pLoudness = isPlaying and ActiveSound.PlaybackLoudness or 0
        local bassFactor = math.clamp(pLoudness / 350, 0, 1)

        if isPlaying and bassFactor > 0.05 then
            Main.ShellStroke.Color = Novier.Theme.BorderSubtle:Lerp(Novier.Theme.Accent, bassFactor)
            Backlight.ImageTransparency = 0.9 - (bassFactor * 0.3)
        else
            Main.ShellStroke.Color = Novier.Theme.BorderSubtle
            Backlight.ImageTransparency = 0.9
        end

        for idx, bar in ipairs(VisualizerBars) do
            local height
            if isPlaying then
                local wave = math.sin((os.clock() * 8) + (idx * 0.45))
                local norm = math.clamp((pLoudness / 400) * (0.6 + (0.4 * wave)), 0.1, 1)
                height = math.floor(norm * 20)
            else
                height = 3
            end
            bar.Size = UDim2.fromOffset(4, math.max(3, height))
            bar.BackgroundColor3 = (idx % 2 == 0) and Novier.Theme.Accent or Novier.Theme.AccentGlow
        end
    end))

    -- Body & Layout
    local Body = create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -74),
        Position = UDim2.fromOffset(0, 48),
        BackgroundTransparency = 1,
        ZIndex = 14,
        Parent = Main
    })

    local Sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 175, 1, 0),
        BackgroundColor3 = Novier.Theme.Surface,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = Body
    }, {
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10)
        }),
        create("Frame", {
            Name = "RightDivider",
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, -1, 0, 0),
            BackgroundColor3 = Novier.Theme.BorderSubtle,
            BorderSizePixel = 0
        })
    })

    local TabContainer = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        ZIndex = 16,
        Parent = Sidebar
    }, {
        create("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })
    TabContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.fromOffset(0, TabContainer.UIListLayout.AbsoluteContentSize.Y)
    end)

    local ContentHolder = create("Frame", {
        Name = "ContentHolder",
        Size = UDim2.new(1, -175, 1, 0),
        Position = UDim2.fromOffset(175, 0),
        BackgroundTransparency = 1,
        ZIndex = 14,
        Parent = Body
    }, {
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 14),
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10)
        })
    })

    -- Footer HUD Telemetry
    local FooterHUD = create("Frame", {
        Name = "FooterHUD",
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 1, -26),
        BackgroundColor3 = Novier.Theme.Surface,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = Main
    }, {
        create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Novier.Theme.BorderSubtle,
            BorderSizePixel = 0
        }),
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12)
        })
    })

    local HUDText = create("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Font = Novier.Config.FontCode,
        TextSize = 11,
        TextColor3 = Novier.Theme.TextSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "INITIALIZING TELEMETRY...",
        ZIndex = 16,
        Parent = FooterHUD
    })

    local frameCount, lastFpsUpdate, liveFps, startTime = 0, os.clock(), 60, os.clock()
    track(RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = os.clock()
        if now - lastFpsUpdate >= 0.5 then
            liveFps = math.floor(frameCount / (now - lastFpsUpdate))
            frameCount = 0
            lastFpsUpdate = now

            local ping = 0
            pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            local mem = math.floor(collectgarbage("count") / 1024)
            local uptime = math.floor(now - startTime)

            HUDText.Text = string.format(
                "FPS: %d  |  PING: %dms  |  MEM: %dMB  |  UPTIME: %02dm:%02ds  |  TOGGLE: [%s]",
                liveFps, ping, mem, math.floor(uptime / 60), uptime % 60, Window.ToggleKey.Name
            )
        end
    end))

    -- Tabs & Sections
    function Window:CreateTab(tabName, iconSymbol)
        local Tab = {}
        Tab.Sections = {}

        local TabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Novier.Theme.SurfaceElevated,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 17,
            Parent = TabContainer
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
        })

        local GlowLine = create("Frame", {
            Size = UDim2.new(0, 3, 0, 16),
            Position = UDim2.new(0, -5, 0.5, -8),
            BackgroundColor3 = Novier.Theme.Accent,
            BackgroundTransparency = 1,
            ZIndex = 18,
            Parent = TabBtn
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) })
        })

        local Icon = create("TextLabel", {
            Size = UDim2.fromOffset(20, 34),
            BackgroundTransparency = 1,
            Text = iconSymbol or "◆",
            Font = Novier.Config.FontCode,
            TextSize = 13,
            TextColor3 = Novier.Theme.TextSecondary,
            ZIndex = 18,
            Parent = TabBtn
        })

        local Name = create("TextLabel", {
            Size = UDim2.new(1, -26, 1, 0),
            Position = UDim2.fromOffset(26, 0),
            BackgroundTransparency = 1,
            Text = string.upper(tabName),
            Font = Novier.Config.FontBold,
            TextSize = 12,
            TextColor3 = Novier.Theme.TextSecondary,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 18,
            Parent = TabBtn
        })

        local Page = create("ScrollingFrame", {
            Name = tabName .. "_Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Novier.Theme.Accent,
            CanvasSize = UDim2.new(),
            Visible = false,
            ZIndex = 15,
            Parent = ContentHolder
        }, {
            create("UIListLayout", {
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            create("UIPadding", { PaddingRight = UDim.new(0, 6) })
        })
        Page.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.fromOffset(0, Page.UIListLayout.AbsoluteContentSize.Y + 16)
        end)

        local function activate()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
                tween(t.Name, { TextColor3 = Novier.Theme.TextSecondary }, 0.15)
                tween(t.Icon, { TextColor3 = Novier.Theme.TextSecondary }, 0.15)
                tween(t.GlowLine, { BackgroundTransparency = 1 }, 0.15)
            end

            Page.Visible = true
            Window.ActiveTab = Tab
            tween(TabBtn, { BackgroundColor3 = Novier.Theme.SurfaceElevated, BackgroundTransparency = 0 }, 0.15)
            tween(Name, { TextColor3 = Novier.Theme.Accent }, 0.15)
            tween(Icon, { TextColor3 = Novier.Theme.AccentGlow }, 0.15)
            tween(GlowLine, { BackgroundTransparency = 0 }, 0.15)
        end

        track(TabBtn.MouseButton1Click:Connect(activate))

        Tab.Button = TabBtn
        Tab.Page = Page
        Tab.Name = Name
        Tab.Icon = Icon
        Tab.GlowLine = GlowLine

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then activate() end

        function Tab:CreateSection(sectionName)
            local Section = {}

            local Box = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Novier.Theme.Surface,
                BackgroundTransparency = 0.35,
                Parent = Page
            }, {
                create("UICorner", { CornerRadius = UDim.new(0, 7) }),
                create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle }),
                create("UIPadding", {
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 12),
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12)
                })
            })

            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Text = "// " .. string.upper(sectionName),
                Font = Novier.Config.FontCode,
                TextSize = 11,
                TextColor3 = Novier.Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Box
            })

            local ControlsHolder = create("Frame", {
                Name = "ControlsHolder",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.fromOffset(0, 22),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = Box
            }, {
                create("UIListLayout", {
                    Padding = UDim.new(0, 7),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            })

            Section.Box = Box
            Section.ControlsHolder = ControlsHolder

            function Section:CreateButton(name, callback)
                local Btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundColor3 = Novier.Theme.SurfaceElevated,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = ControlsHolder
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle }),
                    create("TextLabel", {
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        Text = "[ " .. name .. " ]",
                        Font = Novier.Config.FontCode,
                        TextSize = 12,
                        TextColor3 = Novier.Theme.TextPrimary
                    })
                })

                track(Btn.MouseEnter:Connect(function() tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceHighlight }, 0.12) end))
                track(Btn.MouseLeave:Connect(function() tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceElevated }, 0.12) end))
                track(Btn.MouseButton1Click:Connect(function()
                    tween(Btn, { BackgroundColor3 = Novier.Theme.Accent }, 0.08)
                    task.delay(0.1, function() tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceElevated }, 0.12) end)
                    if callback then callback() end
                end))
                return Btn
            end

            function Section:CreateToggle(name, default, callback)
                local state = default or false
                local ToggleFrame = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = ControlsHolder
                })

                create("TextLabel", {
                    Size = UDim2.new(1, -60, 1, 0),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Novier.Config.FontNormal,
                    TextSize = 12,
                    TextColor3 = Novier.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ToggleFrame
                })

                local Switch = create("Frame", {
                    Size = UDim2.fromOffset(40, 18),
                    Position = UDim2.new(1, -40, 0.5, -9),
                    BackgroundColor3 = state and Novier.Theme.Accent or Novier.Theme.SurfaceElevated,
                    Parent = ToggleFrame
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
                })

                local Dot = create("Frame", {
                    Size = UDim2.fromOffset(12, 12),
                    Position = state and UDim2.fromOffset(24, 3) or UDim2.fromOffset(4, 3),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = Switch
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) })
                })

                local function apply(val)
                    state = val
                    tween(Switch, { BackgroundColor3 = state and Novier.Theme.Accent or Novier.Theme.SurfaceElevated }, 0.18)
                    tween(Dot, { Position = state and UDim2.fromOffset(24, 3) or UDim2.fromOffset(4, 3) }, 0.18)
                    if callback then callback(state) end
                end

                track(ToggleFrame.MouseButton1Click:Connect(function() apply(not state) end))
                return {
                    Set = function(_, v) apply(v) end,
                    Get = function() return state end
                }
            end

            -- FIXED SLIDER WITH ROCK-SOLID MOUSE CAPTURE & VOLUME ROUTING
            function Section:CreateSlider(name, min, max, default, step, callback)
                min = min or 0
                max = max or 100
                step = step or 1
                local current = math.clamp(default or min, min, max)

                local SliderFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 46),
                    BackgroundTransparency = 1,
                    Parent = ControlsHolder
                })

                create("TextLabel", {
                    Size = UDim2.new(0.7, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Novier.Config.FontNormal,
                    TextSize = 12,
                    TextColor3 = Novier.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = SliderFrame
                })

                local Readout = create("TextLabel", {
                    Size = UDim2.new(0.3, 0, 0, 18),
                    Position = UDim2.new(0.7, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(current),
                    Font = Novier.Config.FontCode,
                    TextSize = 12,
                    TextColor3 = Novier.Theme.Accent,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = SliderFrame
                })

                local Bar = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.fromOffset(0, 26),
                    BackgroundColor3 = Novier.Theme.SurfaceElevated,
                    Parent = SliderFrame
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
                })

                local Fill = create("Frame", {
                    Size = UDim2.fromScale((current - min) / (max - min), 1),
                    BackgroundColor3 = Novier.Theme.Accent,
                    BorderSizePixel = 0,
                    Parent = Bar
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) })
                })

                local Knob = create("Frame", {
                    Size = UDim2.fromOffset(12, 12),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new((current - min) / (max - min), 0, 0.5, 0),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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

                return {
                    Set = function(_, v) setVal(v, true) end,
                    Get = function() return current end
                }
            end

            function Section:CreateTextbox(name, placeholder, clearOnFocus, callback)
                local BoxFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Novier.Theme.SurfaceElevated,
                    Parent = ControlsHolder
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
                })

                local Input = create("TextBox", {
                    Size = UDim2.new(1, -20, 1, 0),
                    Position = UDim2.fromOffset(10, 0),
                    BackgroundTransparency = 1,
                    PlaceholderText = placeholder or "Type input...",
                    PlaceholderColor3 = Novier.Theme.TextDisabled,
                    Text = "",
                    Font = Novier.Config.FontNormal,
                    TextSize = 12,
                    TextColor3 = Novier.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = clearOnFocus or false,
                    Parent = BoxFrame
                })

                track(Input.FocusLost:Connect(function(enterPressed)
                    if callback then callback(Input.Text, enterPressed) end
                end))
                return {
                    Set = function(_, text) Input.Text = text end,
                    Get = function() return Input.Text end
                }
            end

            function Section:CreateDropdown(name, list, default, callback)
                local selected = default or list[1]
                local isOpen = false

                local MainBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundColor3 = Novier.Theme.SurfaceElevated,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = ControlsHolder
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle }),
                    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
                })

                create("TextLabel", {
                    Size = UDim2.fromScale(0.5, 1),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Novier.Config.FontNormal,
                    TextSize = 12,
                    TextColor3 = Novier.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = MainBtn
                })

                local SelectedLbl = create("TextLabel", {
                    Size = UDim2.new(0.5, -20, 1, 0),
                    Position = UDim2.fromScale(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(selected),
                    Font = Novier.Config.FontCode,
                    TextSize = 12,
                    TextColor3 = Novier.Theme.Accent,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = MainBtn
                })

                local Chevron = create("TextLabel", {
                    Size = UDim2.fromOffset(16, 32),
                    Position = UDim2.new(1, -12, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "▼",
                    Font = Novier.Config.FontCode,
                    TextSize = 10,
                    TextColor3 = Novier.Theme.TextSecondary,
                    Parent = MainBtn
                })

                local Menu = create("Frame", {
                    Size = UDim2.fromOffset(0, 0),
                    BackgroundColor3 = Novier.Theme.SurfaceElevated,
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 301,
                    Parent = OverlayLayer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    create("UIStroke", { Thickness = 1.2, Color = Novier.Theme.Accent })
                })

                local Scroll = create("ScrollingFrame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 2,
                    CanvasSize = UDim2.new(),
                    ZIndex = 302,
                    Parent = Menu
                }, {
                    create("UIListLayout", { Padding = UDim.new(0, 2) }),
                    create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })
                })

                local function populate()
                    for _, child in ipairs(Scroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, item in ipairs(list) do
                        local opt = create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 24),
                            BackgroundColor3 = (selected == item) and Novier.Theme.SurfaceHighlight or Novier.Theme.SurfaceElevated,
                            Text = tostring(item),
                            Font = Novier.Config.FontCode,
                            TextSize = 11,
                            TextColor3 = (selected == item) and Novier.Theme.Accent or Novier.Theme.TextPrimary,
                            AutoButtonColor = false,
                            ZIndex = 303,
                            Parent = Scroll
                        }, {
                            create("UICorner", { CornerRadius = UDim.new(0, 4) })
                        })

                        track(opt.MouseButton1Click:Connect(function()
                            selected = item
                            SelectedLbl.Text = tostring(item)
                            if callback then callback(selected) end
                            isOpen = false
                            tween(Menu, { Size = UDim2.fromOffset(MainBtn.AbsoluteSize.X, 0) }, 0.15).Completed:Connect(function()
                                Menu.Visible = false
                            end)
                            Chevron.Text = "▼"
                        end))
                    end
                    Scroll.CanvasSize = UDim2.fromOffset(0, #list * 26 + 8)
                end

                track(MainBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        if Novier._ActiveDropdown and Novier._ActiveDropdown ~= Menu then
                            Novier._ActiveDropdown.Visible = false
                        end
                        Novier._ActiveDropdown = Menu
                        populate()
                        local absPos = MainBtn.AbsolutePosition
                        local absSize = MainBtn.AbsoluteSize
                        Menu.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
                        Menu.Size = UDim2.fromOffset(absSize.X, 0)
                        Menu.Visible = true
                        tween(Menu, { Size = UDim2.fromOffset(absSize.X, math.clamp(#list * 26 + 8, 26, 150)) }, 0.18)
                        Chevron.Text = "▲"
                    else
                        tween(Menu, { Size = UDim2.fromOffset(MainBtn.AbsoluteSize.X, 0) }, 0.15).Completed:Connect(function()
                            Menu.Visible = false
                        end)
                        Chevron.Text = "▼"
                    end
                end))

                return {
                    Set = function(_, v)
                        selected = v
                        SelectedLbl.Text = tostring(v)
                    end,
                    Get = function() return selected end
                }
            end

            function Section:CreateTerminal(height)
                local TermFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, height or 130),
                    BackgroundColor3 = Color3.fromRGB(5, 7, 10),
                    Parent = ControlsHolder
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle }),
                    create("UIPadding", {
                        PaddingTop = UDim.new(0, 6),
                        PaddingBottom = UDim.new(0, 6),
                        PaddingLeft = UDim.new(0, 8),
                        PaddingRight = UDim.new(0, 8)
                    })
                })

                local TermScroll = create("ScrollingFrame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = Novier.Theme.Accent,
                    CanvasSize = UDim2.new(),
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
                        Parent = TermScroll
                    })
                    TermScroll.CanvasSize = UDim2.fromOffset(0, TermScroll.UIListLayout.AbsoluteContentSize.Y + 20)
                    TermScroll.CanvasPosition = Vector2.new(0, TermScroll.CanvasSize.Y.Offset)
                end

                append("NOVIER CYBER-TERMINAL ONLINE.", Novier.Theme.Accent)

                return {
                    Log = function(_, msg) append(msg, Novier.Theme.TextTerminal) end,
                    Warn = function(_, msg) append(msg, Novier.Theme.Warning) end,
                    Error = function(_, msg) append(msg, Novier.Theme.Error) end,
                    Clear = function(_)
                        for _, child in ipairs(TermScroll:GetChildren()) do
                            if child:IsA("TextLabel") then child:Destroy() end
                        end
                        TermScroll.CanvasSize = UDim2.new()
                    end
                }
            end

            return Section
        end

        return Tab
    end

    -- MEDIA SUITE (DIRECT VOLUME BINDING)
    function Window:CreateMediaSuite(defaultTrackTable)
        local tracks = defaultTrackTable or {
            ["Synth Loop"]        = "rbxassetid://9043887091",
            ["Action Electronic"] = "rbxassetid://1840590064",
            ["Dark Cyber"]        = "rbxassetid://1843404009"
        }

        local MediaTab = Window:CreateTab("MEDIA", "♫")
        local MediaSec = MediaTab:CreateSection("Soundtrack & Visualizer Engine")

        local trackNames = {}
        for name in pairs(tracks) do table.insert(trackNames, name) end

        MediaSec:CreateDropdown("Preset Tracklist", trackNames, trackNames[1], function(chosen)
            ActiveSound.SoundId = tracks[chosen]
            ActiveSound.TimePosition = 0
            ActiveSound:Play()
            Novier:Notify("Audio Driver", "Stream loaded: " .. chosen, 2, "Success")
        end)

        MediaSec:CreateButton("Toggle Play / Pause", function()
            if ActiveSound.IsPlaying then
                ActiveSound:Pause()
            else
                ActiveSound:Resume()
            end
        end)

        -- Master Volume Slider (Supports up to 200% Gain)
        MediaSec:CreateSlider("Master Volume", 0, 200, 50, 1, function(val)
            ActiveSound.Volume = val / 100
        end)

        local CustomBoxSec = MediaTab:CreateSection("Load Custom Audio ID")
        local TerminalLogger = CustomBoxSec:CreateTerminal(90)

        CustomBoxSec:CreateTextbox("Audio ID", "Paste numeric Sound ID...", false, function(txt, enter)
            if enter and txt and #txt > 0 then
                local cleanId = txt:gsub("%D", "")
                if #cleanId > 0 then
                    local formatted = "rbxassetid://" .. cleanId
                    ActiveSound.SoundId = formatted
                    ActiveSound.TimePosition = 0
                    ActiveSound:Play()
                    TerminalLogger:Log("Mounted Sound: " .. formatted)
                    Novier:Notify("Audio System", "Playing ID: " .. cleanId, 3, "Success")
                else
                    TerminalLogger:Error("Invalid numeric Sound ID entered.")
                end
            end
        end)

        return {
            PlayCustom = function(_, soundId)
                local cleanId = tostring(soundId):gsub("%D", "")
                local formatted = "rbxassetid://" .. cleanId
                ActiveSound.SoundId = formatted
                ActiveSound.TimePosition = 0
                ActiveSound:Play()
                TerminalLogger:Log("Mounted Sound: " .. formatted)
            end
        }
    end

    -- Initial Visor Entrance Animation
    Main.Position = closedPos
    Window:SetVisible(true)

    return Window
end

--========================================================--
-- NOTIFICATIONS
--========================================================--
function Novier:Notify(title, message, duration, kind)
    if not Novier._Gui then return end

    local Holder = Novier._Gui:FindFirstChild("NotifyStack")
    if not Holder then
        Holder = create("Frame", {
            Name = "NotifyStack",
            Size = UDim2.fromOffset(280, 400),
            Position = UDim2.new(1, -20, 1, -50),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 500,
            Parent = Novier._Gui
        }, {
            create("UIListLayout", {
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = UDim.new(0, 6)
            })
        })
    end

    local edgeColor = (kind == "Success" and Novier.Theme.Success) 
                   or (kind == "Warning" and Novier.Theme.Warning) 
                   or (kind == "Error" and Novier.Theme.Error) 
                   or Novier.Theme.Accent

    local Card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        Position = UDim2.fromScale(1.3, 0),
        BackgroundColor3 = Novier.Theme.SurfaceElevated,
        ZIndex = 501,
        Parent = Holder
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        create("UIStroke", { Thickness = 1, Color = edgeColor }),
        create("Frame", {
            Size = UDim2.new(0, 3, 1, -10),
            Position = UDim2.fromOffset(5, 5),
            BackgroundColor3 = edgeColor
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) })
        }),
        create("TextLabel", {
            Size = UDim2.new(1, -24, 0, 18),
            Position = UDim2.fromOffset(14, 6),
            BackgroundTransparency = 1,
            Text = "[ " .. string.upper(title) .. " ]",
            Font = Novier.Config.FontCode,
            TextSize = 12,
            TextColor3 = edgeColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 502
        }),
        create("TextLabel", {
            Size = UDim2.new(1, -24, 0, 26),
            Position = UDim2.fromOffset(14, 24),
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
    for _, conn in ipairs(Novier._Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Novier._Connections)
    local s = SoundService:FindFirstChild("NovierAudioStream")
    if s then s:Destroy() end
    if Novier._Gui then
        Novier._Gui:Destroy()
        Novier._Gui = nil
    end
end

return Novier

--[[
    NOVIER // CYBERPUNK V3 ENGINE (FULL REVISED SOURCE)
    - Animated Matrix Code-Rain Canvas & Scanline Vignette
    - 16-Band Real-Time Audio Spectrum Visualizer
    - Integrated Media Controller (Verified Audio IDs, Custom ID Loader, Volume)
    - Live Performance Telemetry (FPS, Ping, Memory Usage, Uptime)
    - Interactive Embedded Terminal / Console Logging System
    - Dynamic Popout Layering (No ClipsDescendants Clipping on Dropdowns)
]]

local Novier = {}
Novier.__index = Novier

--========================================================--
-- SERVICES & DRIVERS
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
Novier.Version = "3.0.0 CYBER"

Novier.Theme = {
    Background       = Color3.fromRGB(10, 11, 15),
    Surface          = Color3.fromRGB(15, 17, 24),
    SurfaceElevated  = Color3.fromRGB(22, 26, 38),
    SurfaceHighlight = Color3.fromRGB(30, 36, 54),

    Accent           = Color3.fromRGB(0, 255, 170),      -- Cyber Mint
    AccentGlow       = Color3.fromRGB(0, 255, 230),      -- Neon Cyan
    AccentDark       = Color3.fromRGB(0, 80, 55),
    SecondaryAccent  = Color3.fromRGB(255, 0, 120),

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
    DefaultWidth     = 740,
    DefaultHeight    = 510,
    MinWidth         = 580,
    MinHeight        = 400
}

Novier._Connections = {}
Novier._ActiveDropdown = nil

--========================================================--
-- ENGINE UTILITIES
--========================================================--
local function create(className, properties, children)
    local inst = Instance.new(className)
    for prop, val in pairs(properties or {}) do
        inst[prop] = val
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function tween(inst, props, duration, style, dir)
    local tw = TweenService:Create(
        inst,
        TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Cubic, dir or Enum.EasingDirection.Out),
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
-- WINDOW & MATRIX CORE
--========================================================--
function Novier:CreateWindow(windowTitle)
    if Novier._Gui then Novier:Destroy() end

    local Window = {}
    Window.Tabs = {}
    Window.ActiveTab = nil

    local Gui = create("ScreenGui", {
        Name = "Novier_Cyber_V3",
        ResetOnSpawn = false,
        DisplayOrder = 9999,
        Parent = getGuiContainer()
    })
    Novier._Gui = Gui

    local OverlayLayer = create("Frame", {
        Name = "OverlayLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 200,
        Parent = Gui
    })

    -- Main Cyber Frame
    local Main = create("Frame", {
        Name = "MainWindow",
        Size = UDim2.fromOffset(Novier.Config.DefaultWidth, Novier.Config.DefaultHeight),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Novier.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
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

    -- Ambient Glow / Shadow
    local Backlight = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 80, 1, 80),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = Novier.Theme.Accent,
        ImageTransparency = 0.88,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        ZIndex = 0,
        Parent = Main
    })

    --====================================================--
    -- MATRIX CODE-RAIN BACKGROUND CANVAS
    --====================================================--
    local MatrixCanvas = create("Frame", {
        Name = "MatrixCanvas",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 1,
        ClipsDescendants = true,
        Parent = Main
    })

    local hexChars = {"0","1","A","F","7","X","9","C","K","0x","//",">","§"}
    local columns = 18
    for i = 1, columns do
        local colLabel = create("TextLabel", {
            Size = UDim2.new(1 / columns, 0, 2, 0),
            Position = UDim2.new((i - 1) / columns, 0, -1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Font = Novier.Config.FontCode,
            TextSize = 11,
            TextColor3 = Novier.Theme.Accent,
            TextTransparency = 0.85,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            ZIndex = 1,
            Parent = MatrixCanvas
        })

        local streamText = ""
        for _ = 1, 35 do
            streamText = streamText .. hexChars[math.random(1, #hexChars)] .. "\n"
        end
        colLabel.Text = streamText

        local fallSpeed = math.random(12, 28)
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

    -- Darkening Overlay
    create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Novier.Theme.Background,
        BackgroundTransparency = 0.55,
        ZIndex = 2,
        Parent = Main
    })

    --====================================================--
    -- TOPBAR & VISUALIZER
    --====================================================--
    local Topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Novier.Theme.Surface,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 5,
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
        ZIndex = 6,
        Parent = Topbar
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        create("UIStroke", { Thickness = 1, Color = Novier.Theme.Accent })
    })

    create("TextLabel", {
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.fromOffset(48, 0),
        BackgroundTransparency = 1,
        Font = Novier.Config.FontBold,
        TextSize = 14,
        Text = string.upper(windowTitle or "NOVIER CYBER // V3"),
        TextColor3 = Novier.Theme.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
        Parent = Topbar
    })

    -- 16-Band Visualizer
    local VisualizerHolder = create("Frame", {
        Name = "VisualizerHolder",
        Size = UDim2.fromOffset(140, 22),
        Position = UDim2.new(0.5, -70, 0.5, -11),
        BackgroundTransparency = 1,
        ZIndex = 6,
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
            ZIndex = 6,
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
        ZIndex = 6,
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
            ZIndex = 7,
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

    local isMinimized = false
    makeControlBtn("—", Novier.Theme.SurfaceHighlight, function()
        isMinimized = not isMinimized
        local targetSize = isMinimized and UDim2.fromOffset(Main.AbsoluteSize.X, 48) or UDim2.fromOffset(Main.AbsoluteSize.X, Novier.Config.DefaultHeight)
        tween(Main, { Size = targetSize }, 0.25)
        Main.Body.Visible = not isMinimized
        Main.FooterHUD.Visible = not isMinimized
    end)

    makeControlBtn("✕", Novier.Theme.Error, function()
        Novier:Destroy()
    end)

    -- Window Dragging
    local isDragging, dragStart, startPos = false, nil, nil
    track(Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end))

    track(UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end))

    --====================================================--
    -- AUDIO SYSTEM & REACTIVE LOOP
    --====================================================--
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
            Backlight.ImageTransparency = 0.88 - (bassFactor * 0.3)
        else
            Main.ShellStroke.Color = Novier.Theme.BorderSubtle
            Backlight.ImageTransparency = 0.88
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

    --====================================================--
    -- BODY & LAYOUT
    --====================================================--
    local Body = create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -74),
        Position = UDim2.fromOffset(0, 48),
        BackgroundTransparency = 1,
        ZIndex = 4,
        Parent = Main
    })

    local Sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 175, 1, 0),
        BackgroundColor3 = Novier.Theme.Surface,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 5,
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
        ZIndex = 6,
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
        ZIndex = 4,
        Parent = Body
    }, {
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 14),
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10)
        })
    })

    -- Footer HUD
    local FooterHUD = create("Frame", {
        Name = "FooterHUD",
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 1, -26),
        BackgroundColor3 = Novier.Theme.Surface,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 5,
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
        ZIndex = 6,
        Parent = FooterHUD
    })

    local frameCount = 0
    local lastFpsUpdate = os.clock()
    local liveFps = 60
    local startTime = os.clock()

    track(RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = os.clock()
        if now - lastFpsUpdate >= 0.5 then
            liveFps = math.floor(frameCount / (now - lastFpsUpdate))
            frameCount = 0
            lastFpsUpdate = now

            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            local mem = math.floor(collectgarbage("count") / 1024)
            local uptime = math.floor(now - startTime)

            HUDText.Text = string.format(
                "FPS: %d  |  PING: %dms  |  MEM: %dMB  |  UPTIME: %02dm:%02ds  |  STATUS: ACTIVE",
                liveFps, ping, mem, math.floor(uptime / 60), uptime % 60
            )
        end
    end))

    --====================================================--
    -- TABS & SECTIONS
    --====================================================--
    function Window:CreateTab(tabName, iconSymbol)
        local Tab = {}
        Tab.Sections = {}

        local TabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Novier.Theme.SurfaceElevated,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 7,
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
            ZIndex = 8,
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
            ZIndex = 8,
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
            ZIndex = 8,
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
            ZIndex = 5,
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

        -- Create Section
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

            -- Expose actual Instances so components parent properly
            Section.Box = Box
            Section.ControlsHolder = ControlsHolder

            -- Button
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

                track(Btn.MouseEnter:Connect(function()
                    tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceHighlight }, 0.12)
                end))
                track(Btn.MouseLeave:Connect(function()
                    tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceElevated }, 0.12)
                end))
                track(Btn.MouseButton1Click:Connect(function()
                    tween(Btn, { BackgroundColor3 = Novier.Theme.Accent }, 0.08)
                    task.delay(0.1, function()
                        tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceElevated }, 0.12)
                    end)
                    if callback then callback() end
                end))

                return Btn
            end

            -- Toggle
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

                track(ToggleFrame.MouseButton1Click:Connect(function()
                    apply(not state)
                end))

                return {
                    Set = function(_, v) apply(v) end,
                    Get = function() return state end
                }
            end

            -- Slider
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
                    Size = UDim2.new(1, 0, 0, 5),
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
                    Parent = Bar
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) })
                })

                local Knob = create("Frame", {
                    Size = UDim2.fromOffset(11, 11),
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
                    local snapped = math.floor(v / step + 0.5) * step
                    current = math.clamp(snapped, min, max)
                    local alpha = (current - min) / (max - min)
                    tween(Fill, { Size = UDim2.fromScale(alpha, 1) }, 0.05)
                    tween(Knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, 0.05)
                    Readout.Text = tostring(current)
                    if emit and callback then callback(current) end
                end

                local function updateFromMouse(x)
                    local alpha = math.clamp((x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    setVal(min + ((max - min) * alpha), true)
                end

                track(Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isDragging = true
                        updateFromMouse(input.Position.X)
                    end
                end))

                track(UserInputService.InputChanged:Connect(function(input)
                    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateFromMouse(input.Position.X)
                    end
                end))

                track(UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isDragging = false
                    end
                end))

                return {
                    Set = function(_, v) setVal(v, true) end,
                    Get = function() return current end
                }
            end

            -- Textbox
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

            -- Dropdown
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
                    ZIndex = 100,
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
                    ZIndex = 101,
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
                            ZIndex = 102,
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

            -- Terminal Widget
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

    --====================================================--
    -- MEDIA SUITE (FIXED INSTANCE HIERARCHY)
    --====================================================--
    function Window:CreateMediaSuite(defaultTrackTable)
        local tracks = defaultTrackTable or {
            ["Synth Loop"]        = "rbxassetid://9043887091",
            ["Action Electronic"] = "rbxassetid://1840590064",
            ["Dark Cyber"]        = "rbxassetid://1843404009"
        }

        local MediaTab = Window:CreateTab("MEDIA", "♫")
        local MediaSec = MediaTab:CreateSection("Soundtrack & Visualizer Engine")

        local trackNames = {}
        for name in pairs(tracks) do 
            table.insert(trackNames, name) 
        end

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

        MediaSec:CreateSlider("Master Volume", 0, 100, 50, 5, function(val)
            ActiveSound.Volume = val / 100
        end)

        local CustomBoxSec = MediaTab:CreateSection("Load Custom Audio ID")
        local TerminalLogger = CustomBoxSec:CreateTerminal(90)

        CustomBoxSec:CreateTextbox("Audio ID", "Paste numeric Sound ID here...", false, function(txt, enter)
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

    -- Initial Entry Animation
    Main.Size = UDim2.fromOffset(0, 0)
    tween(Main, { Size = UDim2.fromOffset(Novier.Config.DefaultWidth, Novier.Config.DefaultHeight) }, 0.35, Enum.EasingStyle.Back)

    function Window:SetVisible(state)
        Gui.Enabled = state
    end

    function Window:GetVisible()
        return Gui.Enabled
    end

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
            Position = UDim2.new(1, -16, 1, -40),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 300,
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
        ZIndex = 301,
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
            ZIndex = 302
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
            ZIndex = 302
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

--========================================================--
-- CLEANUP
--========================================================--
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

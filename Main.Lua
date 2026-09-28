--[[
    Novier UI Library (Next-Gen Sleek Edition)
    - Architecture: Modular hierarchy (Window -> Tabs -> Sections -> Components)
    - Design: Modern Dark Glass / Cyber-Minimalist
    - Features: Smooth spring-like tweens, dynamic HSV ColorPicker, search dropdowns,
      multi-keybind listeners, active theme propagation, and non-clipping overlay mechanics.
]]

local Novier = {}
Novier.__index = Novier

--========================================================--
-- SERVICES & CONSTANTS
--========================================================--
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--========================================================--
-- THEME ENGINE & CONFIG
--========================================================--
Novier.Version = "2.0.0 Pro"

Novier.Theme = {
    Background       = Color3.fromRGB(18, 19, 23),
    Surface          = Color3.fromRGB(26, 28, 35),
    SurfaceElevated  = Color3.fromRGB(33, 36, 46),
    SurfaceHighlight = Color3.fromRGB(42, 46, 59),
    
    Accent           = Color3.fromRGB(108, 92, 231),
    AccentGlow       = Color3.fromRGB(140, 122, 255),
    AccentMuted      = Color3.fromRGB(56, 50, 100),
    
    TextPrimary      = Color3.fromRGB(245, 246, 250),
    TextSecondary    = Color3.fromRGB(160, 165, 185),
    TextDisabled     = Color3.fromRGB(90, 95, 115),
    
    Border           = Color3.fromRGB(45, 48, 62),
    BorderSubtle     = Color3.fromRGB(35, 37, 48),
    
    Success          = Color3.fromRGB(46, 213, 115),
    Warning          = Color3.fromRGB(255, 171, 0),
    Error            = Color3.fromRGB(255, 71, 87)
}

Novier.Config = {
    FontNormal       = Enum.Font.GothamMedium,
    FontBold         = Enum.Font.GothamBold,
    FontMono         = Enum.Font.Code,
    DefaultWidth     = 680,
    DefaultHeight    = 460,
    MinWidth         = 520,
    MinHeight        = 360,
    AnimationSpeed   = 0.2
}

Novier._ThemeListeners = {}
Novier._ActiveDropdown = nil
Novier._Connections    = {}

--========================================================--
-- UTILITIES & ENGINE HELPERS
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
        TweenInfo.new(
            duration or Novier.Config.AnimationSpeed,
            style or Enum.EasingStyle.Cubic,
            dir or Enum.EasingDirection.Out
        ),
        props
    )
    tw:Play()
    return tw
end

local function track(conn)
    table.insert(Novier._Connections, conn)
    return conn
end

local function round(val, step)
    if not step or step == 0 then return val end
    return math.floor(val / step + 0.5) * step
end

local function registerTheme(inst, property, themeKey)
    if not Novier._ThemeListeners[themeKey] then
        Novier._ThemeListeners[themeKey] = {}
    end
    table.insert(Novier._ThemeListeners[themeKey], {
        Instance = inst,
        Property = property
    })
    inst[property] = Novier.Theme[themeKey]
end

function Novier:SetThemeColor(key, color)
    if not Novier.Theme[key] then return end
    Novier.Theme[key] = color
    if Novier._ThemeListeners[key] then
        for _, entry in ipairs(Novier._ThemeListeners[key]) do
            if entry.Instance and entry.Instance.Parent then
                tween(entry.Instance, { [entry.Property] = color }, 0.25)
            end
        end
    end
end

local function getGuiContainer()
    local ok, core = pcall(function() return CoreGui end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

--========================================================--
-- WINDOW & POPUP OVERLAY
--========================================================--
function Novier:CreateWindow(windowTitle)
    if Novier._Gui then Novier:Destroy() end

    local Window = {}
    Window.Tabs = {}
    Window.ActiveTab = nil

    local Gui = create("ScreenGui", {
        Name = "Novier_Modern",
        ResetOnSpawn = false,
        DisplayOrder = 9999,
        Parent = getGuiContainer()
    })
    Novier._Gui = Gui

    -- Global Popout/Interaction Overlay (prevents ClipsDescendants issues for dropdowns/pickers)
    local OverlayLayer = create("Frame", {
        Name = "InteractionOverlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = Gui
    })
    Window.OverlayLayer = OverlayLayer

    -- Main Shell
    local Main = create("Frame", {
        Name = "WindowShell",
        Size = UDim2.fromOffset(Novier.Config.DefaultWidth, Novier.Config.DefaultHeight),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = Gui
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        create("UIStroke", {
            Thickness = 1.2,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
    })
    registerTheme(Main, "BackgroundColor3", "Background")
    registerTheme(Main.UIStroke, "Color", "Border")

    -- Subtle Ambient Glow / Drop Shadow
    local Glow = create("ImageLabel", {
        Name = "ShadowGlow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 48, 1, 48),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        ZIndex = 0,
        Parent = Main
    })

    -- Top Navigation Bar
    local Topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent = Main
    })

    local TitleLabel = create("TextLabel", {
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        BackgroundTransparency = 1,
        Font = Novier.Config.FontBold,
        TextSize = 14,
        Text = string.upper(windowTitle or "NOVIER ENGINE"),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Topbar
    })
    registerTheme(TitleLabel, "TextColor3", "TextPrimary")

    -- Window Controls (Minimize / Close)
    local WindowControls = create("Frame", {
        Size = UDim2.fromOffset(60, 42),
        Position = UDim2.new(1, -68, 0, 0),
        BackgroundTransparency = 1,
        Parent = Topbar
    }, {
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8)
        })
    })

    local function makeControlBtn(iconText, hoverColorKey, callback)
        local btn = create("TextButton", {
            Size = UDim2.fromOffset(26, 26),
            BackgroundColor3 = Novier.Theme.Surface,
            Text = iconText,
            Font = Novier.Config.FontMono,
            TextSize = 12,
            TextColor3 = Novier.Theme.TextSecondary,
            AutoButtonColor = false,
            Parent = WindowControls
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
        })
        track(btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundColor3 = Novier.Theme[hoverColorKey], TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.15)
        end))
        track(btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundColor3 = Novier.Theme.Surface, TextColor3 = Novier.Theme.TextSecondary }, 0.15)
        end))
        track(btn.MouseButton1Click:Connect(callback))
        return btn
    end

    local isMinimized = false
    makeControlBtn("—", "SurfaceElevated", function()
        isMinimized = not isMinimized
        local targetSize = isMinimized and UDim2.fromOffset(Main.AbsoluteSize.X, 42) or UDim2.fromOffset(Main.AbsoluteSize.X, Novier.Config.DefaultHeight)
        tween(Main, { Size = targetSize }, 0.25)
        Main.Body.Visible = not isMinimized
    end)

    makeControlBtn("✕", "Error", function()
        Novier:Destroy()
    end)

    -- Window Body
    local Body = create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -42),
        Position = UDim2.fromOffset(0, 42),
        BackgroundTransparency = 1,
        Parent = Main
    })

    -- Sidebar (Tabs)
    local Sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 160, 1, 0),
        BackgroundTransparency = 1,
        Parent = Body
    }, {
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 12)
        })
    })

    local TabList = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        Parent = Sidebar
    }, {
        create("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })
    TabList.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabList.CanvasSize = UDim2.fromOffset(0, TabList.UIListLayout.AbsoluteContentSize.Y)
    end)

    -- Main Content Area
    local ContentHolder = create("Frame", {
        Name = "ContentHolder",
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.fromOffset(160, 0),
        BackgroundTransparency = 1,
        Parent = Body
    }, {
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 14),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 14)
        })
    })

    -- Window Dragging System
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

    -- Resizer System
    local ResizeGrip = create("TextButton", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(1, -16, 1, -16),
        BackgroundTransparency = 1,
        Text = "⇲",
        Font = Novier.Config.FontMono,
        TextSize = 13,
        TextColor3 = Novier.Theme.TextDisabled,
        Parent = Main
    })

    local isResizing, resizeStart, initSize = false, nil, nil
    track(ResizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isResizing = true
            resizeStart = input.Position
            initSize = Main.AbsoluteSize
        end
    end))

    track(UserInputService.InputChanged:Connect(function(input)
        if isResizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local newX = math.max(Novier.Config.MinWidth, initSize.X + delta.X)
            local newY = math.max(Novier.Config.MinHeight, initSize.Y + delta.Y)
            Main.Size = UDim2.fromOffset(newX, newY)
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isResizing = false
        end
    end))

    -- Close dropdowns when clicking outside
    track(UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if Novier._ActiveDropdown and not Novier._ActiveDropdown._Frame:IsDescendantOf(OverlayLayer) then
                Novier._ActiveDropdown:Close()
            end
        end
    end))

    --====================================================--
    -- TAB MANAGEMENT
    --====================================================--
    function Window:CreateTab(tabName, iconSymbol)
        local Tab = {}
        Tab.Sections = {}

        local TabBtn = create("TextButton", {
            Name = tabName .. "_Btn",
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Parent = TabList
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) })
        })

        local Indicator = create("Frame", {
            Size = UDim2.new(0, 3, 0, 16),
            Position = UDim2.new(0, -6, 0.5, -8),
            BackgroundColor3 = Novier.Theme.Accent,
            BackgroundTransparency = 1,
            Parent = TabBtn
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) })
        })

        local IconLabel = create("TextLabel", {
            Size = UDim2.fromOffset(20, 34),
            BackgroundTransparency = 1,
            Text = iconSymbol or "•",
            Font = Novier.Config.FontMono,
            TextSize = 14,
            TextColor3 = Novier.Theme.TextSecondary,
            Parent = TabBtn
        })

        local NameLabel = create("TextLabel", {
            Size = UDim2.new(1, -26, 1, 0),
            Position = UDim2.fromOffset(26, 0),
            BackgroundTransparency = 1,
            Text = tabName,
            Font = Novier.Config.FontNormal,
            TextSize = 13,
            TextColor3 = Novier.Theme.TextSecondary,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TabBtn
        })

        local Page = create("ScrollingFrame", {
            Name = tabName .. "_Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Novier.Theme.Border,
            CanvasSize = UDim2.new(),
            Visible = false,
            Parent = ContentHolder
        }, {
            create("UIListLayout", {
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            create("UIPadding", { PaddingRight = UDim.new(0, 6) })
        })
        Page.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.fromOffset(0, Page.UIListLayout.AbsoluteContentSize.Y + 12)
        end)

        local function activate()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
                tween(t.NameLabel, { TextColor3 = Novier.Theme.TextSecondary }, 0.15)
                tween(t.IconLabel, { TextColor3 = Novier.Theme.TextSecondary }, 0.15)
                tween(t.Indicator, { BackgroundTransparency = 1 }, 0.15)
            end

            Page.Visible = true
            Window.ActiveTab = Tab
            tween(TabBtn, { BackgroundColor3 = Novier.Theme.SurfaceElevated, BackgroundTransparency = 0 }, 0.15)
            tween(NameLabel, { TextColor3 = Novier.Theme.TextPrimary }, 0.15)
            tween(IconLabel, { TextColor3 = Novier.Theme.AccentGlow }, 0.15)
            tween(Indicator, { BackgroundTransparency = 0 }, 0.15)
        end

        track(TabBtn.MouseButton1Click:Connect(activate))

        Tab.Button = TabBtn
        Tab.Page = Page
        Tab.NameLabel = NameLabel
        Tab.IconLabel = IconLabel
        Tab.Indicator = Indicator

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then activate() end

        --====================================================--
        -- SECTION
        --====================================================--
        function Tab:CreateSection(sectionName)
            local Section = {}

            local SectionBox = create("Frame", {
                Name = sectionName .. "_Section",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Novier.Theme.Surface,
                BorderSizePixel = 0,
                Parent = Page
            }, {
                create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                create("UIStroke", {
                    Thickness = 1,
                    Color = Novier.Theme.BorderSubtle,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }),
                create("UIPadding", {
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12)
                })
            })

            local Header = create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = string.upper(sectionName),
                Font = Novier.Config.FontBold,
                TextSize = 11,
                TextColor3 = Novier.Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SectionBox
            })

            local ControlsHolder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.fromOffset(0, 22),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = SectionBox
            }, {
                create("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            })

            --================================================//
            -- BUTTON COMPONENT
            --================================================//
            function Section:CreateButton(name, callback)
                local Btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundColor3 = Novier.Theme.SurfaceElevated,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = ControlsHolder
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
                })

                local Lbl = create("TextLabel", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Novier.Config.FontNormal,
                    TextSize = 13,
                    TextColor3 = Novier.Theme.TextPrimary,
                    Parent = Btn
                })

                track(Btn.MouseEnter:Connect(function()
                    tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceHighlight }, 0.15)
                end))
                track(Btn.MouseLeave:Connect(function()
                    tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceElevated }, 0.15)
                end))
                track(Btn.MouseButton1Click:Connect(function()
                    tween(Btn, { BackgroundColor3 = Novier.Theme.Accent }, 0.08)
                    task.delay(0.1, function()
                        tween(Btn, { BackgroundColor3 = Novier.Theme.SurfaceElevated }, 0.15)
                    end)
                    if callback then callback() end
                end))

                return Btn
            end

            --================================================//
            -- TOGGLE COMPONENT (Pill Slider)
            --================================================//
            function Section:CreateToggle(name, default, callback)
                local state = default or false

                local ToggleFrame = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = ControlsHolder
                })

                local Lbl = create("TextLabel", {
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Novier.Config.FontNormal,
                    TextSize = 13,
                    TextColor3 = Novier.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ToggleFrame
                })

                local Pill = create("Frame", {
                    Size = UDim2.fromOffset(36, 18),
                    Position = UDim2.new(1, -38, 0.5, -9),
                    BackgroundColor3 = state and Novier.Theme.Accent or Novier.Theme.SurfaceElevated,
                    Parent = ToggleFrame
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
                })

                local Knob = create("Frame", {
                    Size = UDim2.fromOffset(12, 12),
                    Position = state and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = Pill
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) })
                })

                local function apply(val)
                    state = val
                    tween(Pill, { BackgroundColor3 = state and Novier.Theme.Accent or Novier.Theme.SurfaceElevated }, 0.2)
                    tween(Knob, { Position = state and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3) }, 0.2)
                    if callback then callback(state) end
                end

                track(ToggleFrame.MouseButton1Click:Connect(function()
                    apply(not state)
                end))

                return {
                    Set = function(_, val) apply(val) end,
                    Get = function() return state end
                }
            end

            --================================================//
            -- SLIDER COMPONENT (Accurate & Smooth Drag)
            --================================================//
            function Section:CreateSlider(name, min, max, default, step, callback)
                min = min or 0
                max = max or 100
                step = step or 1
                local current = math.clamp(default or min, min, max)

                local SliderBox = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 48),
                    BackgroundTransparency = 1,
                    Parent = ControlsHolder
                })

                local Title = create("TextLabel", {
                    Size = UDim2.new(0.7, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Novier.Config.FontNormal,
                    TextSize = 13,
                    TextColor3 = Novier.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = SliderBox
                })

                local ValLabel = create("TextBox", {
                    Size = UDim2.new(0.3, 0, 0, 20),
                    Position = UDim2.new(0.7, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(current),
                    Font = Novier.Config.FontMono,
                    TextSize = 12,
                    TextColor3 = Novier.Theme.AccentGlow,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ClearTextOnFocus = false,
                    Parent = SliderBox
                })

                local Track = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.fromOffset(0, 28),
                    BackgroundColor3 = Novier.Theme.SurfaceElevated,
                    Parent = SliderBox
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
                })

                local Fill = create("Frame", {
                    Size = UDim2.fromScale((current - min) / (max - min), 1),
                    BackgroundColor3 = Novier.Theme.Accent,
                    Parent = Track
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) })
                })

                local Knob = create("Frame", {
                    Size = UDim2.fromOffset(12, 12),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new((current - min) / (max - min), 0, 0.5, 0),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = Track
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) })
                })

                local isDraggingSlider = false

                local function setValue(newVal, emit)
                    current = math.clamp(round(newVal, step), min, max)
                    local alpha = (current - min) / (max - min)
                    tween(Fill, { Size = UDim2.fromScale(alpha, 1) }, 0.06)
                    tween(Knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, 0.06)
                    ValLabel.Text = tostring(current)
                    if emit and callback then callback(current) end
                end

                local function updateFromPos(xPos)
                    local trackAbs = Track.AbsolutePosition.X
                    local trackSize = Track.AbsoluteSize.X
                    local ratio = math.clamp((xPos - trackAbs) / trackSize, 0, 1)
                    setValue(min + ((max - min) * ratio), true)
                end

                track(Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isDraggingSlider = true
                        updateFromPos(input.Position.X)
                    end
                end))

                track(UserInputService.InputChanged:Connect(function(input)
                    if isDraggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateFromPos(input.Position.X)
                    end
                end))

                track(UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isDraggingSlider = false
                    end
                end))

                track(ValLabel.FocusLost:Connect(function()
                    local n = tonumber(ValLabel.Text)
                    if n then setValue(n, true) else ValLabel.Text = tostring(current) end
                end))

                return {
                    Set = function(_, v) setValue(v, true) end,
                    Get = function() return current end
                }
            end

            --================================================//
            -- DROPDOWN COMPONENT (Top-layer Unclipped)
            --================================================//
            function Section:CreateDropdown(name, list, default, isMulti, callback)
                local selected = isMulti and (type(default) == "table" and default or {}) or (default or list[1])
                local isOpen = false

                local MainBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Novier.Theme.SurfaceElevated,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = ControlsHolder
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle }),
                    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
                })

                local NameLbl = create("TextLabel", {
                    Size = UDim2.fromScale(0.5, 1),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Novier.Config.FontNormal,
                    TextSize = 13,
                    TextColor3 = Novier.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = MainBtn
                })

                local function getDisplayText()
                    if isMulti then
                        local active = {}
                        for item, ok in pairs(selected) do
                            if ok then table.insert(active, tostring(item)) end
                        end
                        return #active > 0 and table.concat(active, ", ") or "None"
                    end
                    return tostring(selected)
                end

                local SelectedLbl = create("TextLabel", {
                    Size = UDim2.new(0.5, -20, 1, 0),
                    Position = UDim2.fromScale(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = getDisplayText(),
                    Font = Novier.Config.FontMono,
                    TextSize = 12,
                    TextColor3 = Novier.Theme.AccentGlow,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = MainBtn
                })

                local Chevron = create("TextLabel", {
                    Size = UDim2.fromOffset(16, 34),
                    Position = UDim2.new(1, -12, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "▼",
                    Font = Novier.Config.FontMono,
                    TextSize = 10,
                    TextColor3 = Novier.Theme.TextSecondary,
                    Parent = MainBtn
                })

                -- Detached Overlay Menu
                local Menu = create("Frame", {
                    Size = UDim2.fromOffset(0, 0),
                    BackgroundColor3 = Novier.Theme.SurfaceElevated,
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 50,
                    Parent = OverlayLayer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    create("UIStroke", { Thickness = 1.2, Color = Novier.Theme.Border })
                })

                local OptionScroll = create("ScrollingFrame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 2,
                    CanvasSize = UDim2.new(),
                    ZIndex = 51,
                    Parent = Menu
                }, {
                    create("UIListLayout", { Padding = UDim.new(0, 2) }),
                    create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })
                })

                local function populate()
                    for _, c in ipairs(OptionScroll:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end

                    for _, item in ipairs(list) do
                        local isItemActive = isMulti and selected[item] or (selected == item)
                        local opt = create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 26),
                            BackgroundColor3 = isItemActive and Novier.Theme.SurfaceHighlight or Novier.Theme.SurfaceElevated,
                            Text = tostring(item),
                            Font = Novier.Config.FontNormal,
                            TextSize = 12,
                            TextColor3 = isItemActive and Novier.Theme.AccentGlow or Novier.Theme.TextPrimary,
                            AutoButtonColor = false,
                            ZIndex = 52,
                            Parent = OptionScroll
                        }, {
                            create("UICorner", { CornerRadius = UDim.new(0, 4) })
                        })

                        track(opt.MouseButton1Click:Connect(function()
                            if isMulti then
                                selected[item] = not selected[item]
                                SelectedLbl.Text = getDisplayText()
                                opt.TextColor3 = selected[item] and Novier.Theme.AccentGlow or Novier.Theme.TextPrimary
                                opt.BackgroundColor3 = selected[item] and Novier.Theme.SurfaceHighlight or Novier.Theme.SurfaceElevated
                                if callback then callback(selected) end
                            else
                                selected = item
                                SelectedLbl.Text = tostring(item)
                                if callback then callback(selected) end
                                isOpen = false
                                tween(Menu, { Size = UDim2.fromOffset(MainBtn.AbsoluteSize.X, 0) }, 0.15).Completed:Connect(function()
                                    Menu.Visible = false
                                end)
                                Chevron.Text = "▼"
                            end
                        end))
                    end
                    OptionScroll.CanvasSize = UDim2.fromOffset(0, #list * 28 + 8)
                end

                local function toggleMenu()
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

                        local targetHeight = math.clamp(#list * 28 + 8, 28, 160)
                        tween(Menu, { Size = UDim2.fromOffset(absSize.X, targetHeight) }, 0.2)
                        Chevron.Text = "▲"
                    else
                        tween(Menu, { Size = UDim2.fromOffset(MainBtn.AbsoluteSize.X, 0) }, 0.15).Completed:Connect(function()
                            Menu.Visible = false
                        end)
                        Chevron.Text = "▼"
                    end
                end

                track(MainBtn.MouseButton1Click:Connect(toggleMenu))

                return {
                    Set = function(_, val)
                        selected = val
                        SelectedLbl.Text = getDisplayText()
                    end,
                    Get = function() return selected end,
                    Refresh = function(_, newList)
                        list = newList
                        populate()
                    end
                }
            end

            --================================================//
            -- COLOR PICKER COMPONENT (HSV Matrix + Bar)
            --================================================//
            function Section:CreateColorPicker(name, defaultColor, callback)
                local color = defaultColor or Color3.fromRGB(255, 255, 255)
                local h, s, v = color:ToHSV()
                local isExpanded = false

                local Root = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                    Parent = ControlsHolder
                })

                local MainBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = Root
                })

                local Label = create("TextLabel", {
                    Size = UDim2.new(1, -40, 0, 34),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Novier.Config.FontNormal,
                    TextSize = 13,
                    TextColor3 = Novier.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = MainBtn
                })

                local ColorDisplay = create("Frame", {
                    Size = UDim2.fromOffset(24, 18),
                    Position = UDim2.new(1, -26, 0, 8),
                    BackgroundColor3 = color,
                    Parent = MainBtn
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
                })

                local Canvas = create("Frame", {
                    Size = UDim2.new(1, -30, 0, 110),
                    Position = UDim2.fromOffset(0, 40),
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    Parent = Root
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 4) })
                })

                -- Saturation & Value Overlay Gradients
                local WhiteGrad = create("ImageLabel", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://4155801252",
                    Parent = Canvas
                })

                local SVMarker = create("Frame", {
                    Size = UDim2.fromOffset(8, 8),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(s, 1 - v),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = Canvas
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(0, 0, 0) })
                })

                local HueBar = create("Frame", {
                    Size = UDim2.fromOffset(18, 110),
                    Position = UDim2.new(1, -20, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = Root
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                    create("UIGradient", {
                        Rotation = 90,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
                        })
                    })
                })

                local HueMarker = create("Frame", {
                    Size = UDim2.new(1, 4, 0, 4),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, h, 0),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = HueBar
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(0, 0, 0) })
                })

                local function emitColor()
                    local finalColor = Color3.fromHSV(h, s, v)
                    ColorDisplay.BackgroundColor3 = finalColor
                    Canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    if callback then callback(finalColor) end
                end

                local isDraggingHue = false
                local isDraggingSV = false

                track(HueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isDraggingHue = true
                        local relY = math.clamp((input.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                        h = relY
                        HueMarker.Position = UDim2.new(0.5, 0, h, 0)
                        emitColor()
                    end
                end))

                track(Canvas.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isDraggingSV = true
                        local relX = math.clamp((input.Position.X - Canvas.AbsolutePosition.X) / Canvas.AbsoluteSize.X, 0, 1)
                        local relY = math.clamp((input.Position.Y - Canvas.AbsolutePosition.Y) / Canvas.AbsoluteSize.Y, 0, 1)
                        s = relX
                        v = 1 - relY
                        SVMarker.Position = UDim2.fromScale(s, 1 - v)
                        emitColor()
                    end
                end))

                track(UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        if isDraggingHue then
                            local relY = math.clamp((input.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                            h = relY
                            HueMarker.Position = UDim2.new(0.5, 0, h, 0)
                            emitColor()
                        elseif isDraggingSV then
                            local relX = math.clamp((input.Position.X - Canvas.AbsolutePosition.X) / Canvas.AbsoluteSize.X, 0, 1)
                            local relY = math.clamp((input.Position.Y - Canvas.AbsolutePosition.Y) / Canvas.AbsoluteSize.Y, 0, 1)
                            s = relX
                            v = 1 - relY
                            SVMarker.Position = UDim2.fromScale(s, 1 - v)
                            emitColor()
                        end
                    end
                end))

                track(UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isDraggingHue = false
                        isDraggingSV = false
                    end
                end))

                track(MainBtn.MouseButton1Click:Connect(function()
                    isExpanded = not isExpanded
                    tween(Root, { Size = isExpanded and UDim2.new(1, 0, 0, 160) or UDim2.new(1, 0, 0, 34) }, 0.2)
                end))

                return {
                    Set = function(_, clr)
                        h, s, v = clr:ToHSV()
                        HueMarker.Position = UDim2.new(0.5, 0, h, 0)
                        SVMarker.Position = UDim2.fromScale(s, 1 - v)
                        emitColor()
                    end,
                    Get = function() return Color3.fromHSV(h, s, v) end
                }
            end

            --================================================//
            -- KEYBIND COMPONENT
            --================================================//
            function Section:CreateKeybind(name, defaultKey, callback)
                local currentKey = defaultKey or Enum.KeyCode.RightShift
                local isListening = false

                local KeybindFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = ControlsHolder
                })

                local Label = create("TextLabel", {
                    Size = UDim2.new(0.65, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Novier.Config.FontNormal,
                    TextSize = 13,
                    TextColor3 = Novier.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = KeybindFrame
                })

                local BindBtn = create("TextButton", {
                    Size = UDim2.fromOffset(80, 24),
                    Position = UDim2.new(1, -80, 0.5, -12),
                    BackgroundColor3 = Novier.Theme.SurfaceElevated,
                    Text = currentKey.Name,
                    Font = Novier.Config.FontMono,
                    TextSize = 11,
                    TextColor3 = Novier.Theme.AccentGlow,
                    AutoButtonColor = false,
                    Parent = KeybindFrame
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                    create("UIStroke", { Thickness = 1, Color = Novier.Theme.BorderSubtle })
                })

                track(BindBtn.MouseButton1Click:Connect(function()
                    isListening = true
                    BindBtn.Text = "..."
                    tween(BindBtn, { BackgroundColor3 = Novier.Theme.SurfaceHighlight }, 0.1)
                end))

                track(UserInputService.InputBegan:Connect(function(input, processed)
                    if isListening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = input.KeyCode
                            BindBtn.Text = currentKey.Name
                            isListening = false
                            tween(BindBtn, { BackgroundColor3 = Novier.Theme.SurfaceElevated }, 0.1)
                        end
                    elseif not processed and input.KeyCode == currentKey then
                        if callback then callback(currentKey) end
                    end
                end))

                return {
                    Set = function(_, key)
                        currentKey = key
                        BindBtn.Text = key.Name
                    end,
                    Get = function() return currentKey end
                }
            end

            --================================================//
            -- TEXTBOX COMPONENT
            --================================================//
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
                    PlaceholderText = placeholder or "Type here...",
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

            --================================================//
            -- STATUS LABEL COMPONENT
            --================================================//
            function Section:CreateLabel(text, defaultStatus)
                local Box = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Parent = ControlsHolder
                })

                local KeyLbl = create("TextLabel", {
                    Size = UDim2.new(0.65, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Novier.Config.FontNormal,
                    TextSize = 12,
                    TextColor3 = Novier.Theme.TextSecondary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Box
                })

                local ValLbl = create("TextLabel", {
                    Size = UDim2.new(0.35, 0, 1, 0),
                    Position = UDim2.fromScale(0.65, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(defaultStatus or ""),
                    Font = Novier.Config.FontMono,
                    TextSize = 12,
                    TextColor3 = Novier.Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = Box
                })

                return {
                    Set = function(_, val, color)
                        ValLbl.Text = tostring(val)
                        if color then ValLbl.TextColor3 = color end
                    end
                }
            end

            return Section
        end

        return Tab
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
-- MODERN TOAST NOTIFICATIONS
--========================================================--
function Novier:Notify(title, message, duration, kind)
    if not Novier._Gui then return end

    local Holder = Novier._Gui:FindFirstChild("NotificationStack")
    if not Holder then
        Holder = create("Frame", {
            Name = "NotificationStack",
            Size = UDim2.fromOffset(300, 500),
            Position = UDim2.new(1, -20, 1, -20),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            Parent = Novier._Gui
        }, {
            create("UIListLayout", {
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = UDim.new(0, 8)
            })
        })
    end

    local indicatorColor = Novier.Theme.Accent
    if kind == "Success" then indicatorColor = Novier.Theme.Success
    elseif kind == "Warning" then indicatorColor = Novier.Theme.Warning
    elseif kind == "Error" then indicatorColor = Novier.Theme.Error end

    local Card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        Position = UDim2.fromScale(1.2, 0),
        BackgroundColor3 = Novier.Theme.SurfaceElevated,
        Parent = Holder
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", { Thickness = 1, Color = Novier.Theme.Border }),
        create("Frame", {
            Size = UDim2.new(0, 3, 1, -12),
            Position = UDim2.fromOffset(6, 6),
            BackgroundColor3 = indicatorColor
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) })
        }),
        create("TextLabel", {
            Size = UDim2.new(1, -30, 0, 20),
            Position = UDim2.fromOffset(18, 10),
            BackgroundTransparency = 1,
            Text = title or "Notification",
            Font = Novier.Config.FontBold,
            TextSize = 13,
            TextColor3 = Novier.Theme.TextPrimary,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        create("TextLabel", {
            Size = UDim2.new(1, -30, 0, 26),
            Position = UDim2.fromOffset(18, 30),
            BackgroundTransparency = 1,
            Text = message or "",
            Font = Novier.Config.FontNormal,
            TextSize = 11,
            TextColor3 = Novier.Theme.TextSecondary,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    })

    -- Entry slide
    tween(Card, { Position = UDim2.fromScale(0, 0) }, 0.25, Enum.EasingStyle.Cubic)

    -- Auto dismiss
    task.delay(duration or 3.5, function()
        if Card and Card.Parent then
            local tw = tween(Card, { Position = UDim2.fromScale(1.3, 0) }, 0.25)
            tw.Completed:Connect(function() Card:Destroy() end)
        end
    end)
end

--========================================================--
-- CLEANUP
--========================================================--
function Novier:Destroy()
    for _, c in ipairs(Novier._Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Novier._Connections)
    if Novier._Gui then
        Novier._Gui:Destroy()
        Novier._Gui = nil
    end
end

return Novier

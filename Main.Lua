```lua
--[[
    Novier-HB
    Retro Roblox UI Library

    Retro-styled GUI library with:
    - Draggable window
    - Minimize / close
    - Tabs
    - Sections
    - Buttons
    - Toggles
    - Sliders
    - Dropdowns
    - Textboxes
    - Keybinds
    - Labels
    - Notifications
    - Themes
    - UI toggle keybind
]]

local Novier = {}

--========================================================--
-- SERVICES
--========================================================--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- CONFIG
--========================================================--

Novier.Version = "1.0.0"

Novier.Theme = {
    Window = Color3.fromRGB(35, 35, 35),
    WindowLight = Color3.fromRGB(55, 55, 55),

    Title = Color3.fromRGB(35, 80, 135),
    TitleLight = Color3.fromRGB(55, 105, 165),

    Sidebar = Color3.fromRGB(45, 45, 45),
    Content = Color3.fromRGB(38, 38, 38),

    Control = Color3.fromRGB(55, 55, 55),
    ControlHover = Color3.fromRGB(70, 70, 70),

    Accent = Color3.fromRGB(75, 145, 220),

    Text = Color3.fromRGB(235, 235, 235),
    MutedText = Color3.fromRGB(175, 175, 175),

    BorderDark = Color3.fromRGB(15, 15, 15),
    BorderLight = Color3.fromRGB(105, 105, 105),

    Success = Color3.fromRGB(80, 180, 100),
    Warning = Color3.fromRGB(220, 170, 70),
    Error = Color3.fromRGB(200, 75, 75)
}

Novier.Config = {
    Width = 650,
    Height = 450,

    MinWidth = 450,
    MinHeight = 320,

    Font = Enum.Font.Code,

    AnimationTime = 0.12
}

--========================================================--
-- INTERNALS
--========================================================--

Novier._Gui = nil
Novier._Window = nil
Novier._Tabs = {}
Novier._ActiveTab = nil
Novier._Connections = {}

--========================================================--
-- UTILITY
--========================================================--

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Novier._Connections, connection)
    return connection
end

local function tween(object, properties, duration)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(
            duration or Novier.Config.AnimationTime,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        properties
    )

    animation:Play()

    return animation
end

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 3)
    c.Parent = object
    return c
end

local function stroke(object, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Novier.Theme.BorderDark
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = object
    return s
end

local function padding(object, top, bottom, left, right)
    local p = Instance.new("UIPadding")

    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)

    p.Parent = object

    return p
end

local function label(parent, text, size, position)
    local object = Instance.new("TextLabel")

    object.BackgroundTransparency = 1
    object.Size = size or UDim2.new(1, 0, 0, 20)
    object.Position = position or UDim2.new()
    object.Font = Novier.Config.Font
    object.TextSize = 14
    object.TextColor3 = Novier.Theme.Text
    object.Text = text
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.TextYAlignment = Enum.TextYAlignment.Center

    object.Parent = parent

    return object
end

local function buttonStyle(button)
    button.BackgroundColor3 = Novier.Theme.Control
    button.AutoButtonColor = false

    stroke(button, Novier.Theme.BorderDark)
end

local function hover(button)
    connect(button.MouseEnter, function()
        tween(button, {
            BackgroundColor3 = Novier.Theme.ControlHover
        })
    end)

    connect(button.MouseLeave, function()
        tween(button, {
            BackgroundColor3 = Novier.Theme.Control
        })
    end)
end

--========================================================--
-- PARENT
--========================================================--

local function getParent()
    local success, core = pcall(function()
        return game:GetService("CoreGui")
    end)

    if success and core then
        return core
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

--========================================================--
-- DRAGGING
--========================================================--

local function makeDraggable(window, handle)
    local dragging = false
    local dragStart
    local startPosition

    connect(handle.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = window.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        window.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

--========================================================--
-- NOTIFICATIONS
--========================================================--

function Novier:Notify(title, message, duration, notificationType)
    if not Novier._Gui then
        return
    end

    duration = duration or 3

    local holder = Novier._Gui:FindFirstChild("Notifications")

    if not holder then
        holder = Instance.new("Frame")
        holder.Name = "Notifications"
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.fromOffset(320, 400)
        holder.Position = UDim2.new(1, -15, 1, -15)
        holder.AnchorPoint = Vector2.new(1, 1)
        holder.Parent = Novier._Gui

        local layout = Instance.new("UIListLayout")
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Padding = UDim.new(0, 7)
        layout.Parent = holder
    end

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(300, 72)
    box.BackgroundColor3 = Novier.Theme.Window
    box.BorderSizePixel = 0
    box.Parent = holder

    stroke(box, Novier.Theme.BorderDark, 2)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 5)
    top.BorderSizePixel = 0
    top.BackgroundColor3 = Novier.Theme.Accent
    top.Parent = box

    if notificationType == "Success" then
        top.BackgroundColor3 = Novier.Theme.Success
    elseif notificationType == "Warning" then
        top.BackgroundColor3 = Novier.Theme.Warning
    elseif notificationType == "Error" then
        top.BackgroundColor3 = Novier.Theme.Error
    end

    label(
        box,
        title,
        UDim2.new(1, -20, 0, 22),
        UDim2.fromOffset(10, 10)
    )

    local messageLabel = label(
        box,
        message,
        UDim2.new(1, -20, 0, 30),
        UDim2.fromOffset(10, 34)
    )

    messageLabel.TextColor3 = Novier.Theme.MutedText
    messageLabel.TextWrapped = true

    box.Position = UDim2.new(1, 320, 0, 0)

    tween(box, {
        Position = UDim2.new(0, 0, 0, 0)
    })

    task.delay(duration, function()
        if not box.Parent then
            return
        end

        tween(box, {
            Position = UDim2.new(1, 320, 0, 0)
        }, 0.2)

        task.wait(0.22)

        if box then
            box:Destroy()
        end
    end)
end

--========================================================--
-- WINDOW
--========================================================--

function Novier:CreateWindow(title)
    if Novier._Gui then
        Novier:Destroy()
    end

    local WindowObject = {}

    --====================================================--
    -- SCREEN GUI
    --====================================================--

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "Novier-HB"
    Gui.ResetOnSpawn = false
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Gui.Parent = getParent()

    Novier._Gui = Gui

    --====================================================--
    -- SHADOW
    --====================================================--

    local Shadow = Instance.new("Frame")
    Shadow.Name = "Shadow"

    Shadow.Size = UDim2.fromOffset(
        Novier.Config.Width + 8,
        Novier.Config.Height + 8
    )

    Shadow.Position = UDim2.new(0.5, 4, 0.5, 5)
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)

    Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.BackgroundTransparency = 0.45

    Shadow.BorderSizePixel = 0
    Shadow.Parent = Gui

    corner(Shadow, 4)

    --====================================================--
    -- MAIN WINDOW
    --====================================================--

    local Main = Instance.new("Frame")
    Main.Name = "Window"

    Main.Size = UDim2.fromOffset(
        Novier.Config.Width,
        Novier.Config.Height
    )

    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)

    Main.BackgroundColor3 = Novier.Theme.Window
    Main.BorderSizePixel = 0

    Main.ClipsDescendants = true
    Main.Parent = Gui

    stroke(Main, Novier.Theme.BorderDark, 2)

    Novier._Window = Main

    --====================================================--
    -- TITLE BAR
    --====================================================--

    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"

    TitleBar.Size = UDim2.new(1, 0, 0, 30)

    TitleBar.BackgroundColor3 = Novier.Theme.Title
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main

    -- Fake highlight line
    local titleHighlight = Instance.new("Frame")
    titleHighlight.Size = UDim2.new(1, 0, 0, 1)
    titleHighlight.BackgroundColor3 = Novier.Theme.TitleLight
    titleHighlight.BorderSizePixel = 0
    titleHighlight.Parent = TitleBar

    -- Icon
    local Icon = label(
        TitleBar,
        "◆",
        UDim2.fromOffset(24, 30),
        UDim2.fromOffset(7, 0)
    )

    Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    Icon.TextXAlignment = Enum.TextXAlignment.Center

    -- Title
    local Title = label(
        TitleBar,
        title or "Novier-HB",
        UDim2.new(1, -115, 1, 0),
        UDim2.fromOffset(34, 0)
    )

    Title.Font = Enum.Font.Code
    Title.TextSize = 15
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)

    --====================================================--
    -- WINDOW BUTTONS
    --====================================================--

    local function createWindowButton(text, position)
        local b = Instance.new("TextButton")

        b.Size = UDim2.fromOffset(27, 22)
        b.Position = position

        b.BackgroundColor3 = Novier.Theme.Title
        b.TextColor3 = Color3.fromRGB(255, 255, 255)

        b.Text = text
        b.TextSize = 14
        b.Font = Enum.Font.Code

        b.AutoButtonColor = false
        b.BorderSizePixel = 0

        b.Parent = TitleBar

        stroke(b, Novier.Theme.BorderDark)

        connect(b.MouseEnter, function()
            tween(b, {
                BackgroundColor3 = Novier.Theme.TitleLight
            })
        end)

        connect(b.MouseLeave, function()
            tween(b, {
                BackgroundColor3 = Novier.Theme.Title
            })
        end)

        return b
    end

    local Minimize =
        createWindowButton("-", UDim2.new(1, -87, 0, 4))

    local Maximize =
        createWindowButton("□", UDim2.new(1, -58, 0, 4))

    local Close =
        createWindowButton("X", UDim2.new(1, -29, 0, 4))

    --====================================================--
    -- BODY
    --====================================================--

    local Body = Instance.new("Frame")

    Body.Name = "Body"

    Body.Size = UDim2.new(1, 0, 1, -30)
    Body.Position = UDim2.fromOffset(0, 30)

    Body.BackgroundColor3 = Novier.Theme.Content
    Body.BorderSizePixel = 0

    Body.Parent = Main

    --====================================================--
    -- SIDEBAR
    --====================================================--

    local Sidebar = Instance.new("Frame")

    Sidebar.Name = "Sidebar"

    Sidebar.Size = UDim2.new(0, 145, 1, 0)

    Sidebar.BackgroundColor3 = Novier.Theme.Sidebar
    Sidebar.BorderSizePixel = 0

    Sidebar.Parent = Body

    local SidebarBorder = Instance.new("Frame")

    SidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    SidebarBorder.Position = UDim2.new(1, -1, 0, 0)

    SidebarBorder.BackgroundColor3 = Novier.Theme.BorderDark
    SidebarBorder.BorderSizePixel = 0
    SidebarBorder.Parent = Sidebar

    --====================================================--
    -- BRAND
    --====================================================--

    local Brand = label(
        Sidebar,
        "NOVIER-HB",
        UDim2.new(1, -20, 0, 35),
        UDim2.fromOffset(10, 8)
    )

    Brand.Font = Enum.Font.Code
    Brand.TextSize = 16
    Brand.TextColor3 = Novier.Theme.Accent

    local Version = label(
        Sidebar,
        "RETRO INTERFACE v" .. Novier.Version,
        UDim2.new(1, -20, 0, 18),
        UDim2.fromOffset(10, 35)
    )

    Version.TextSize = 10
    Version.TextColor3 = Novier.Theme.MutedText

    --====================================================--
    -- TAB CONTAINER
    --====================================================--

    local TabContainer = Instance.new("ScrollingFrame")

    TabContainer.Name = "Tabs"

    TabContainer.Size = UDim2.new(1, -10, 1, -75)
    TabContainer.Position = UDim2.fromOffset(5, 70)

    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0

    TabContainer.ScrollBarThickness = 2
    TabContainer.ScrollBarImageColor3 = Novier.Theme.Accent

    TabContainer.CanvasSize = UDim2.new()

    TabContainer.Parent = Sidebar

    local TabLayout = Instance.new("UIListLayout")

    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.Parent = TabContainer

    connect(TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabContainer.CanvasSize = UDim2.fromOffset(
            0,
            TabLayout.AbsoluteContentSize.Y + 5
        )
    end)

    --====================================================--
    -- CONTENT
    --====================================================--

    local Content = Instance.new("Frame")

    Content.Name = "Content"

    Content.Size = UDim2.new(1, -145, 1, 0)
    Content.Position = UDim2.fromOffset(145, 0)

    Content.BackgroundColor3 = Novier.Theme.Content
    Content.BorderSizePixel = 0

    Content.Parent = Body

    --====================================================--
    -- TAB CREATION
    --====================================================--

    function WindowObject:CreateTab(tabName, icon)
        local Tab = {}

        local TabButton = Instance.new("TextButton")

        TabButton.Name = tabName
        TabButton.Size = UDim2.new(1, 0, 0, 34)

        TabButton.BackgroundColor3 = Novier.Theme.Sidebar

        TabButton.Text = ""
        TabButton.AutoButtonColor = false

        TabButton.Parent = TabContainer

        stroke(TabButton, Novier.Theme.BorderDark)

        -- tiny retro icon
        local TabIcon = label(
            TabButton,
            icon or "■",
            UDim2.fromOffset(27, 34),
            UDim2.fromOffset(4, 0)
        )

        TabIcon.TextSize = 11
        TabIcon.TextXAlignment = Enum.TextXAlignment.Center
        TabIcon.TextColor3 = Novier.Theme.MutedText

        local TabText = label(
            TabButton,
            tabName,
            UDim2.new(1, -35, 1, 0),
            UDim2.fromOffset(34, 0)
        )

        TabText.TextSize = 13
        TabText.TextColor3 = Novier.Theme.MutedText

        --================================================//
        -- PAGE
        --================================================//

        local Page = Instance.new("ScrollingFrame")

        Page.Name = tabName .. "_Page"

        Page.Size = UDim2.new(1, 0, 1, 0)

        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0

        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Novier.Theme.Accent

        Page.CanvasSize = UDim2.new()

        Page.Visible = false
        Page.Parent = Content

        padding(Page, 12, 12, 12, 12)

        local PageLayout = Instance.new("UIListLayout")

        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder

        PageLayout.Parent = Page

        connect(PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Page.CanvasSize = UDim2.fromOffset(
                0,
                PageLayout.AbsoluteContentSize.Y + 25
            )
        end)

        --================================================//
        -- SECTION
        --================================================//

        function Tab:CreateSection(sectionName)
            local Section = {}

            local Frame = Instance.new("Frame")

            Frame.Name = sectionName

            Frame.Size = UDim2.new(1, 0, 0, 0)

            Frame.AutomaticSize = Enum.AutomaticSize.Y

            Frame.BackgroundColor3 = Novier.Theme.Window

            Frame.BorderSizePixel = 0

            Frame.Parent = Page

            stroke(Frame, Novier.Theme.BorderDark, 2)

            -- Section header
            local Header = Instance.new("Frame")

            Header.Size = UDim2.new(1, 0, 0, 28)

            Header.BackgroundColor3 = Novier.Theme.WindowLight

            Header.BorderSizePixel = 0

            Header.Parent = Frame

            local HeaderText = label(
                Header,
                "[ " .. sectionName:upper() .. " ]",
                UDim2.new(1, -16, 1, 0),
                UDim2.fromOffset(8, 0)
            )

            HeaderText.TextSize = 13
            HeaderText.Font = Enum.Font.Code
            HeaderText.TextColor3 = Novier.Theme.Accent

            -- Section contents
            local Container = Instance.new("Frame")

            Container.Name = "Controls"

            Container.Size = UDim2.new(1, -16, 0, 0)

            Container.Position = UDim2.fromOffset(8, 35)

            Container.AutomaticSize = Enum.AutomaticSize.Y

            Container.BackgroundTransparency = 1

            Container.Parent = Frame

            padding(Container, 0, 8, 0, 0)

            local Layout = Instance.new("UIListLayout")

            Layout.Padding = UDim.new(0, 6)

            Layout.Parent = Container

            --================================================//
            -- BUTTON
            --================================================//

            function Section:CreateButton(text, callback)
                local Button = Instance.new("TextButton")

                Button.Size = UDim2.new(1, 0, 0, 34)

                Button.BackgroundColor3 = Novier.Theme.Control

                Button.Text = text

                Button.TextColor3 = Novier.Theme.Text

                Button.TextSize = 13
                Button.Font = Novier.Config.Font

                Button.AutoButtonColor = false

                Button.Parent = Container

                stroke(Button, Novier.Theme.BorderDark)

                hover(Button)

                connect(Button.MouseButton1Click, function()
                    tween(Button, {
                        BackgroundColor3 = Novier.Theme.Accent
                    }, 0.05)

                    task.delay(0.06, function()
                        if Button.Parent then
                            tween(Button, {
                                BackgroundColor3 = Novier.Theme.Control
                            }, 0.08)
                        end
                    end)

                    if callback then
                        callback()
                    end
                end)

                return Button
            end

            --================================================//
            -- TOGGLE
            --================================================//

            function Section:CreateToggle(text, default, callback)
                local state = default == true

                local Button = Instance.new("TextButton")

                Button.Size = UDim2.new(1, 0, 0, 34)

                Button.BackgroundColor3 = Novier.Theme.Control

                Button.Text = ""
                Button.AutoButtonColor = false

                Button.Parent = Container

                stroke(Button, Novier.Theme.BorderDark)

                local Text = label(
                    Button,
                    text,
                    UDim2.new(1, -65, 1, 0),
                    UDim2.fromOffset(9, 0)
                )

                Text.TextSize = 13

                local Check = Instance.new("Frame")

                Check.Size = UDim2.fromOffset(42, 20)

                Check.Position = UDim2.new(1, -51, 0.5, -10)

                Check.BackgroundColor3 = Novier.Theme.BorderDark

                Check.Parent = Button

                stroke(Check, Novier.Theme.BorderLight)

                local CheckText = label(
                    Check,
                    "",
                    UDim2.new(1, 0, 1, 0)
                )

                CheckText.TextSize = 11
                CheckText.TextXAlignment = Enum.TextXAlignment.Center

                local function update()
                    if state then
                        Check.BackgroundColor3 = Novier.Theme.Accent
                        CheckText.Text = "ON"
                    else
                        Check.BackgroundColor3 = Novier.Theme.BorderDark
                        CheckText.Text = "OFF"
                    end

                    if callback then
                        callback(state)
                    end
                end

                connect(Button.MouseButton1Click, function()
                    state = not state
                    update()
                end)

                update()

                return {
                    Set = function(_, value)
                        state = value == true
                        update()
                    end,

                    Get = function()
                        return state
                    end
                }
            end

            --================================================//
            -- SLIDER
            --================================================//

            function Section:CreateSlider(text, minimum, maximum, default, callback)
                minimum = minimum or 0
                maximum = maximum or 100

                local value = math.clamp(
                    default or minimum,
                    minimum,
                    maximum
                )

                local Frame = Instance.new("Frame")

                Frame.Size = UDim2.new(1, 0, 0, 52)

                Frame.BackgroundColor3 = Novier.Theme.Control

                Frame.Parent = Container

                stroke(Frame, Novier.Theme.BorderDark)

                local Text = label(
                    Frame,
                    text,
                    UDim2.new(0.6, 0, 0, 22),
                    UDim2.fromOffset(9, 3)
                )

                Text.TextSize = 13

                local ValueText = label(
                    Frame,
                    tostring(value),
                    UDim2.new(0.4, -10, 0, 22),
                    UDim2.new(0.6, 0, 0, 3)
                )

                ValueText.TextXAlignment = Enum.TextXAlignment.Right
                ValueText.TextColor3 = Novier.Theme.MutedText

                local Bar = Instance.new("Frame")

                Bar.Size = UDim2.new(1, -18, 0, 7)

                Bar.Position = UDim2.fromOffset(9, 36)

                Bar.BackgroundColor3 = Novier.Theme.BorderDark

                Bar.Parent = Frame

                stroke(Bar, Novier.Theme.BorderLight)

                local Fill = Instance.new("Frame")

                Fill.BackgroundColor3 = Novier.Theme.Accent

                Fill.BorderSizePixel = 0

                Fill.Parent = Bar

                local function updateFromX(x)
                    local percentage = math.clamp(
                        (x - Bar.AbsolutePosition.X) /
                        Bar.AbsoluteSize.X,
                        0,
                        1
                    )

                    value =
                        minimum +
                        ((maximum - minimum) * percentage)

                    if math.floor(value) == value then
                        value = math.floor(value)
                    else
                        value = math.floor(value * 100) / 100
                    end

                    Fill.Size = UDim2.new(
                        percentage,
                        0,
                        1,
                        0
                    )

                    ValueText.Text = tostring(value)

                    if callback then
                        callback(value)
                    end
                end

                Fill.Size = UDim2.new(
                    (value - minimum) /
                    (maximum - minimum),
                    0,
                    1,
                    0
                )

                local dragging = false

                connect(Bar.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        updateFromX(input.Position.X)
                    end
                end)

                connect(UserInputService.InputChanged, function(input)
                    if dragging and
                        input.UserInputType == Enum.UserInputType.MouseMovement then

                        updateFromX(input.Position.X)
                    end
                end)

                connect(UserInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                return {
                    Set = function(_, newValue)
                        value = math.clamp(
                            newValue,
                            minimum,
                            maximum
                        )

                        local percentage =
                            (value - minimum) /
                            (maximum - minimum)

                        Fill.Size = UDim2.new(
                            percentage,
                            0,
                            1,
                            0
                        )

                        ValueText.Text = tostring(value)

                        if callback then
                            callback(value)
                        end
                    end,

                    Get = function()
                        return value
                    end
                }
            end

            --================================================//
            -- DROPDOWN
            --================================================//

            function Section:CreateDropdown(text, options, default, callback)
                local selected = default or options[1]
                local opened = false

                local Frame = Instance.new("Frame")

                Frame.Size = UDim2.new(1, 0, 0, 34)

                Frame.BackgroundColor3 = Novier.Theme.Control

                Frame.ClipsDescendants = true

                Frame.Parent = Container

                stroke(Frame, Novier.Theme.BorderDark)

                local MainButton = Instance.new("TextButton")

                MainButton.Size = UDim2.new(1, 0, 0, 34)

                MainButton.BackgroundTransparency = 1

                MainButton.Text = ""

                MainButton.Parent = Frame

                local Text = label(
                    MainButton,
                    text,
                    UDim2.new(0.55, 0, 1, 0),
                    UDim2.fromOffset(9, 0)
                )

                Text.TextSize = 13

                local Selected = label(
                    MainButton,
                    tostring(selected),
                    UDim2.new(0.45, -25, 1, 0),
                    UDim2.new(0.55, 0, 0, 0)
                )

                Selected.TextXAlignment = Enum.TextXAlignment.Right
                Selected.TextColor3 = Novier.Theme.MutedText

                local Arrow = label(
                    MainButton,
                    "▼",
                    UDim2.fromOffset(20, 34),
                    UDim2.new(1, -25, 0, 0)
                )

                Arrow.TextXAlignment = Enum.TextXAlignment.Center
                Arrow.TextColor3 = Novier.Theme.MutedText

                local OptionsFrame = Instance.new("Frame")

                OptionsFrame.Size = UDim2.new(1, -16, 0, #options * 29)

                OptionsFrame.Position = UDim2.fromOffset(8, 39)

                OptionsFrame.BackgroundTransparency = 1

                OptionsFrame.Parent = Frame

                local OptionLayout = Instance.new("UIListLayout")

                OptionLayout.Padding = UDim.new(0, 3)

                OptionLayout.Parent = OptionsFrame

                for _, option in ipairs(options) do
                    local Option = Instance.new("TextButton")

                    Option.Size = UDim2.new(1, 0, 0, 26)

                    Option.BackgroundColor3 = Novier.Theme.WindowLight

                    Option.Text = tostring(option)

                    Option.TextColor3 = Novier.Theme.Text

                    Option.TextSize = 12
                    Option.Font = Novier.Config.Font

                    Option.AutoButtonColor = false

                    Option.Parent = OptionsFrame

                    stroke(Option, Novier.Theme.BorderDark)

                    connect(Option.MouseEnter, function()
                        tween(Option, {
                            BackgroundColor3 = Novier.Theme.Accent
                        })
                    end)

                    connect(Option.MouseLeave, function()
                        tween(Option, {
                            BackgroundColor3 = Novier.Theme.WindowLight
                        })
                    end)

                    connect(Option.MouseButton1Click, function()
                        selected = option

                        Selected.Text = tostring(option)

                        opened = false

                        Frame.Size =
                            UDim2.new(1, 0, 0, 34)

                        Arrow.Text = "▼"

                        if callback then
                            callback(option)
                        end
                    end)
                end

                connect(MainButton.MouseButton1Click, function()
                    opened = not opened

                    if opened then
                        Frame.Size = UDim2.new(
                            1,
                            0,
                            0,
                            44 + (#options * 29)
                        )

                        Arrow.Text = "▲"
                    else
                        Frame.Size =
                            UDim2.new(1, 0, 0, 34)

                        Arrow.Text = "▼"
                    end
                end)

                return {
                    Set = function(_, value)
                        if table.find(options, value) then
                            selected = value
                            Selected.Text = tostring(value)

                            if callback then
                                callback(value)
                            end
                        end
                    end,

                    Get = function()
                        return selected
                    end
                }
            end

            --================================================//
            -- TEXTBOX
            --================================================//

            function Section:CreateTextbox(text, placeholder, callback)
                local Frame = Instance.new("Frame")

                Frame.Size = UDim2.new(1, 0, 0, 58)

                Frame.BackgroundColor3 = Novier.Theme.Control

                Frame.Parent = Container

                stroke(Frame, Novier.Theme.BorderDark)

                label(
                    Frame,
                    text,
                    UDim2.new(1, -18, 0, 20),
                    UDim2.fromOffset(9, 2)
                )

                local Box = Instance.new("TextBox")

                Box.Size = UDim2.new(1, -18, 0, 27)

                Box.Position = UDim2.fromOffset(9, 26)

                Box.BackgroundColor3 = Novier.Theme.Window

                Box.TextColor3 = Novier.Theme.Text

                Box.PlaceholderColor3 = Novier.Theme.MutedText

                Box.PlaceholderText = placeholder or ""

                Box.Text = ""

                Box.TextSize = 12

                Box.Font = Novier.Config.Font

                Box.ClearTextOnFocus = false

                Box.Parent = Frame

                stroke(Box, Novier.Theme.BorderDark)

                padding(Box, 0, 0, 7, 7)

                connect(Box.FocusLost, function()
                    if callback then
                        callback(Box.Text)
                    end
                end)

                return Box
            end

            --================================================//
            -- KEYBIND
            --================================================//

            function Section:CreateKeybind(text, default, callback)
                local currentKey =
                    default or Enum.KeyCode.RightShift

                local listening = false

                local Button = Instance.new("TextButton")

                Button.Size = UDim2.new(1, 0, 0, 34)

                Button.BackgroundColor3 = Novier.Theme.Control

                Button.Text = ""

                Button.AutoButtonColor = false

                Button.Parent = Container

                stroke(Button, Novier.Theme.BorderDark)

                label(
                    Button,
                    text,
                    UDim2.new(0.65, 0, 1, 0),
                    UDim2.fromOffset(9, 0)
                )

                local Key = label(
                    Button,
                    currentKey.Name,
                    UDim2.new(0.35, -10, 1, 0),
                    UDim2.new(0.65, 0, 0, 0)
                )

                Key.TextXAlignment = Enum.TextXAlignment.Right
                Key.TextColor3 = Novier.Theme.Accent

                connect(Button.MouseButton1Click, function()
                    listening = true
                    Key.Text = "PRESS KEY"
                end)

                connect(UserInputService.InputBegan, function(input)
                    if not listening then
                        return
                    end

                    if input.UserInputType ~= Enum.UserInputType.Keyboard then
                        return
                    end

                    currentKey = input.KeyCode

                    Key.Text = currentKey.Name

                    listening = false
                end)

                connect(UserInputService.InputBegan, function(input, processed)
                    if processed or listening then
                        return
                    end

                    if input.KeyCode == currentKey then
                        if callback then
                            callback()
                        end
                    end
                end)

                return {
                    Set = function(_, newKey)
                        currentKey = newKey
                        Key.Text = newKey.Name
                    end,

                    Get = function()
                        return currentKey
                    end
                }
            end

            --================================================//
            -- LABEL
            --================================================//

            function Section:CreateLabel(text)
                local Text = label(
                    Container,
                    text,
                    UDim2.new(1, 0, 0, 25)
                )

                Text.TextColor3 = Novier.Theme.MutedText
                Text.TextSize = 12
                Text.TextWrapped = true

                return Text
            end

            --================================================//
            -- DIVIDER
            --================================================//

            function Section:CreateDivider()
                local Divider = Instance.new("Frame")

                Divider.Size = UDim2.new(1, 0, 0, 1)

                Divider.BackgroundColor3 =
                    Novier.Theme.BorderDark

                Divider.BorderSizePixel = 0

                Divider.Parent = Container

                return Divider
            end

            return Section
        end

        --================================================//
        -- TAB SELECT
        --================================================//

        connect(TabButton.MouseButton1Click, function()
            for _, existing in pairs(Novier._Tabs) do
                existing.Page.Visible = false

                existing.Button.BackgroundColor3 =
                    Novier.Theme.Sidebar

                existing.Text.TextColor3 =
                    Novier.Theme.MutedText

                existing.Icon.TextColor3 =
                    Novier.Theme.MutedText
            end

            Page.Visible = true

            TabButton.BackgroundColor3 =
                Novier.Theme.Control

            TabText.TextColor3 =
                Novier.Theme.Text

            TabIcon.TextColor3 =
                Novier.Theme.Accent

            Novier._ActiveTab = Tab
        end)

        Tab.Button = TabButton
        Tab.Page = Page
        Tab.Text = TabText
        Tab.Icon = TabIcon

        Novier._Tabs[tabName] = Tab

        if not Novier._ActiveTab then
            Page.Visible = true

            TabButton.BackgroundColor3 =
                Novier.Theme.Control

            TabText.TextColor3 =
                Novier.Theme.Text

            TabIcon.TextColor3 =
                Novier.Theme.Accent

            Novier._ActiveTab = Tab
        end

        return Tab
    end

    --====================================================--
    -- MINIMIZE
    --====================================================--

    local minimized = false
    local maximized = false

    local normalSize = UDim2.fromOffset(
        Novier.Config.Width,
        Novier.Config.Height
    )

    local normalPosition = Main.Position

    connect(Minimize.MouseButton1Click, function()
        minimized = not minimized

        if minimized then
            Body.Visible = false

            tween(Main, {
                Size = UDim2.fromOffset(
                    Novier.Config.Width,
                    30
                )
            })

            tween(Shadow, {
                Size = UDim2.fromOffset(
                    Novier.Config.Width + 8,
                    38
                )
            })
        else
            Body.Visible = true

            tween(Main, {
                Size = normalSize
            })

            tween(Shadow, {
                Size = UDim2.fromOffset(
                    normalSize.X.Offset + 8,
                    normalSize.Y.Offset + 8
                )
            })
        end
    end)

    --====================================================--
    -- MAXIMIZE
    --====================================================--

    connect(Maximize.MouseButton1Click, function()
        if minimized then
            return
        end

        maximized = not maximized

        if maximized then
            normalSize = Main.Size
            normalPosition = Main.Position

            tween(Main, {
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(1, -30, 1, -30)
            })

            Maximize.Text = "❐"
        else
            tween(Main, {
                Position = normalPosition,
                Size = normalSize
            })

            Maximize.Text = "□"
        end
    end)

    --====================================================--
    -- CLOSE
    --====================================================--

    connect(Close.MouseButton1Click, function()
        Novier:Destroy()
    end)

    --====================================================--
    -- DRAG
    --====================================================--

    makeDraggable(Main, TitleBar)

    --====================================================--
    -- RESIZE
    --====================================================--

    local ResizeHandle = Instance.new("TextButton")

    ResizeHandle.Size = UDim2.fromOffset(18, 18)

    ResizeHandle.Position = UDim2.new(1, -18, 1, -18)

    ResizeHandle.BackgroundTransparency = 1

    ResizeHandle.Text = "◢"

    ResizeHandle.TextColor3 = Novier.Theme.MutedText

    ResizeHandle.TextSize = 12

    ResizeHandle.Parent = Main

    local resizing = false
    local resizeStart
    local resizeSize

    connect(ResizeHandle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            resizeSize = Main.AbsoluteSize
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not resizing then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - resizeStart

        local width = math.max(
            Novier.Config.MinWidth,
            resizeSize.X + delta.X
        )

        local height = math.max(
            Novier.Config.MinHeight,
            resizeSize.Y + delta.Y
        )

        Main.Size = UDim2.fromOffset(
            width,
            height
        )

        Shadow.Size = UDim2.fromOffset(
            width + 8,
            height + 8
        )
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)

    --====================================================--
    -- OPEN ANIMATION
    --====================================================--

    Main.Size = UDim2.fromOffset(0, 0)

    Shadow.Size = UDim2.fromOffset(0, 0)

    tween(Main, {
        Size = normalSize
    }, 0.3)

    tween(Shadow, {
        Size = UDim2.fromOffset(
            Novier.Config.Width + 8,
            Novier.Config.Height + 8
        )
    }, 0.3)

    --====================================================--
    -- RETURN OBJECT
    --====================================================--

    function WindowObject:SetVisible(state)
        Gui.Enabled = state
    end

    function WindowObject:GetVisible()
        return Gui.Enabled
    end

    function WindowObject:SetTitle(newTitle)
        Title.Text = newTitle
    end

    function WindowObject:Destroy()
        Novier:Destroy()
    end

    return WindowObject
end

--========================================================--
-- THEME
--========================================================--

function Novier:SetTheme(theme)
    for key, value in pairs(theme) do
        if Novier.Theme[key] ~= nil then
            Novier.Theme[key] = value
        end
    end

    -- Recreate is intentionally avoided here.
    -- New controls automatically use the updated theme.
end

--========================================================--
-- DESTROY
--========================================================--

function Novier:Destroy()
    for _, connection in ipairs(Novier._Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(Novier._Connections)

    if Novier._Gui then
        Novier._Gui:Destroy()
    end

    Novier._Gui = nil
    Novier._Window = nil

    table.clear(Novier._Tabs)

    Novier._ActiveTab = nil
end

return Novier
```

### Example

```lua
local Novier = loadstring(game:HttpGet("YOUR_LIBRARY_URL"))()

local Window = Novier:CreateWindow("Novier-HB")

local PlayerTab = Window:CreateTab("PLAYER", "◆")
local VisualTab = Window:CreateTab("VISUAL", "◇")
local SettingsTab = Window:CreateTab("SETTINGS", "⚙")

local Movement = PlayerTab:CreateSection("Movement")

Movement:CreateToggle("Infinite Jump", false, function(enabled)
    print("Infinite Jump:", enabled)
end)

Movement:CreateSlider("WalkSpeed", 16, 100, 16, function(value)
    print("WalkSpeed:", value)
end)

Movement:CreateButton("Reset Character", function()
    print("Reset")
end)

local PlayerSettings = PlayerTab:CreateSection("Player")

PlayerSettings:CreateTextbox(
    "Username",
    "Enter username...",
    function(text)
        print(text)
    end
)

PlayerSettings:CreateDropdown(
    "Mode",
    {"Normal", "Fast", "Extreme"},
    "Normal",
    function(value)
        print("Mode:", value)
    end
)

local Settings = SettingsTab:CreateSection("Interface")

Settings:CreateKeybind(
    "Toggle UI",
    Enum.KeyCode.RightShift,
    function()
        Window:SetVisible(not Window:GetVisible())
    end
)

Settings:CreateButton("Test Notification", function()
    Novier:Notify(
        "Novier-HB",
        "Hello from the retro interface.",
        3,
        "Success"
    )
end)

Settings:CreateLabel(
    "Novier-HB Retro Interface v1.0.0"
)
```

The key difference here is that **Novier-HB is actually structured as a library**, rather than one giant GUI creation function. Tabs own pages, pages own sections, sections own controls, and the window handles dragging/minimizing/maximizing/resizing independently.

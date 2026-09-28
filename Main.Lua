local CustomGUI = {}

--//====================================================//
--// SERVICES
--//====================================================//

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

--//====================================================//
--// SETTINGS
--//====================================================//

local Settings = {
    Parent = nil,

    Size = UDim2.fromOffset(620, 430),
    MinSize = Vector2.new(420, 300),

    Background = Color3.fromRGB(15, 15, 20),
    Secondary = Color3.fromRGB(21, 21, 28),
    Tertiary = Color3.fromRGB(27, 27, 36),

    Accent = Color3.fromRGB(115, 85, 255),
    AccentDark = Color3.fromRGB(85, 60, 210),

    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(150, 150, 165),

    Border = Color3.fromRGB(45, 45, 58),

    AnimationSpeed = 0.15
}

local function GetParent()
    if Settings.Parent then
        return Settings.Parent
    end

    local CoreGui = game:GetService("CoreGui")

    local success = pcall(function()
        return CoreGui.Name
    end)

    if success then
        return CoreGui
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

--//====================================================//
--// UTILITIES
--//====================================================//

local function Tween(object, properties, duration)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration or Settings.AnimationSpeed,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
        properties
    )

    tween:Play()
    return tween
end

local function Corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = object
    return c
end

local function Stroke(object, color, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Settings.Border
    s.Transparency = transparency or 0
    s.Thickness = 1
    s.Parent = object
    return s
end

local function Padding(object, amount)
    local p = Instance.new("UIPadding")

    p.PaddingTop = UDim.new(0, amount)
    p.PaddingBottom = UDim.new(0, amount)
    p.PaddingLeft = UDim.new(0, amount)
    p.PaddingRight = UDim.new(0, amount)

    p.Parent = object

    return p
end

local function MakeDraggable(object, handle)
    handle = handle or object

    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        object.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

local function Hover(button, normal, hover)
    button.MouseEnter:Connect(function()
        Tween(button, {
            BackgroundColor3 = hover
        })
    end)

    button.MouseLeave:Connect(function()
        Tween(button, {
            BackgroundColor3 = normal
        })
    end)
end

local function MakeLabel(parent, text, size, color)
    local label = Instance.new("TextLabel")

    label.BackgroundTransparency = 1
    label.Size = size or UDim2.new(1, 0, 0, 25)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = color or Settings.Text
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left

    label.Parent = parent

    return label
end

--//====================================================//
--// NOTIFICATION SYSTEM
--//====================================================//

function CustomGUI.Notify(title, message, duration)
    duration = duration or 3

    local gui = CustomGUI._Gui

    if not gui then
        return
    end

    local holder = gui:FindFirstChild("Notifications")

    if not holder then
        holder = Instance.new("Frame")
        holder.Name = "Notifications"
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.fromOffset(300, 500)
        holder.Position = UDim2.new(1, -320, 1, -20)
        holder.AnchorPoint = Vector2.new(0, 1)
        holder.Parent = gui

        local layout = Instance.new("UIListLayout")
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Padding = UDim.new(0, 8)
        layout.Parent = holder
    end

    local notification = Instance.new("Frame")
    notification.Size = UDim2.fromOffset(290, 70)
    notification.BackgroundColor3 = Settings.Secondary
    notification.Parent = holder

    Corner(notification, 10)
    Stroke(notification)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, 0)
    bar.BackgroundColor3 = Settings.Accent
    bar.BorderSizePixel = 0
    bar.Parent = notification

    Corner(bar, 4)

    local titleLabel = MakeLabel(
        notification,
        title,
        UDim2.new(1, -25, 0, 24)
    )

    titleLabel.Position = UDim2.fromOffset(15, 8)
    titleLabel.Font = Enum.Font.GothamBold

    local messageLabel = MakeLabel(
        notification,
        message,
        UDim2.new(1, -25, 0, 30),
        Settings.SubText
    )

    messageLabel.Position = UDim2.fromOffset(15, 32)
    messageLabel.TextWrapped = true

    notification.Position = UDim2.new(1, 0, 0, 0)

    Tween(notification, {
        Position = UDim2.new(0, 0, 0, 0)
    })

    task.delay(duration, function()
        if notification then
            Tween(notification, {
                Position = UDim2.new(1, 0, 0, 0)
            })

            task.wait(0.2)

            if notification then
                notification:Destroy()
            end
        end
    end)
end

--//====================================================//
--// WINDOW
--//====================================================//

function CustomGUI.CreateWindow(title)
    local self = {}

    local Gui = Instance.new("ScreenGui")
    Gui.Name = title .. "_GUI"
    Gui.ResetOnSpawn = false
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Gui.Parent = GetParent()

    CustomGUI._Gui = Gui

    --// Shadow
    local Shadow = Instance.new("Frame")
    Shadow.Name = "Shadow"
    Shadow.Size = Settings.Size + UDim2.fromOffset(10, 10)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 5)
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    Shadow.BackgroundTransparency = 0.55
    Shadow.Parent = Gui

    Corner(Shadow, 12)

    --// Main
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = Settings.Size
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Settings.Background
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = Gui

    Corner(Main, 12)
    Stroke(Main)

    self.Main = Main
    self.Gui = Gui

    --// Sync shadow
    Main:GetPropertyChangedSignal("Position"):Connect(function()
        Shadow.Position = Main.Position + UDim2.fromOffset(0, 5)
    end)

    Main:GetPropertyChangedSignal("Size"):Connect(function()
        Shadow.Size = Main.Size + UDim2.fromOffset(10, 10)
    end)

    --//================================================//
    --// TOP BAR
    --//================================================//

    local Top = Instance.new("Frame")
    Top.Name = "TopBar"
    Top.Size = UDim2.new(1, 0, 0, 48)
    Top.BackgroundColor3 = Settings.Secondary
    Top.BorderSizePixel = 0
    Top.Parent = Main

    local Title = MakeLabel(
        Top,
        title,
        UDim2.new(1, -110, 1, 0)
    )

    Title.Position = UDim2.fromOffset(18, 0)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 15

    --// Minimize
    local Minimize = Instance.new("TextButton")
    Minimize.Size = UDim2.fromOffset(36, 36)
    Minimize.Position = UDim2.new(1, -78, 0, 6)
    Minimize.BackgroundColor3 = Settings.Tertiary
    Minimize.Text = "—"
    Minimize.TextColor3 = Settings.Text
    Minimize.TextSize = 20
    Minimize.Font = Enum.Font.GothamBold
    Minimize.Parent = Top

    Corner(Minimize, 8)

    --// Close
    local Close = Instance.new("TextButton")
    Close.Size = UDim2.fromOffset(36, 36)
    Close.Position = UDim2.new(1, -38, 0, 6)
    Close.BackgroundColor3 = Settings.Tertiary
    Close.Text = "×"
    Close.TextColor3 = Settings.Text
    Close.TextSize = 20
    Close.Font = Enum.Font.GothamBold
    Close.Parent = Top

    Corner(Close, 8)

    Hover(
        Minimize,
        Settings.Tertiary,
        Settings.Border
    )

    Hover(
        Close,
        Settings.Tertiary,
        Color3.fromRGB(150, 55, 65)
    )

    MakeDraggable(Main, Top)

    --//================================================//
    --// SIDEBAR
    --//================================================//

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 150, 1, -48)
    Sidebar.Position = UDim2.new(0, 0, 0, 48)
    Sidebar.BackgroundColor3 = Settings.Secondary
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Main

    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "TabList"
    TabList.Size = UDim2.new(1, 0, 1, -45)
    TabList.BackgroundTransparency = 1
    TabList.BorderSizePixel = 0
    TabList.ScrollBarThickness = 2
    TabList.ScrollBarImageColor3 = Settings.Accent
    TabList.CanvasSize = UDim2.new()
    TabList.Parent = Sidebar

    Padding(TabList, 8)

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.Parent = TabList

    --// Search
    local Search = Instance.new("TextBox")
    Search.Size = UDim2.new(1, -16, 0, 34)
    Search.Position = UDim2.new(0, 8, 1, -42)
    Search.BackgroundColor3 = Settings.Tertiary
    Search.PlaceholderText = "Search..."
    Search.PlaceholderColor3 = Settings.SubText
    Search.Text = ""
    Search.TextColor3 = Settings.Text
    Search.TextSize = 12
    Search.Font = Enum.Font.Gotham
    Search.ClearTextOnFocus = false
    Search.Parent = Sidebar

    Corner(Search, 8)

    --//================================================//
    --// CONTENT
    --//================================================//

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -150, 1, -48)
    Content.Position = UDim2.new(0, 150, 0, 48)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    self.Content = Content
    self.Tabs = {}

    --//================================================//
    --// MINIMIZE
    --//================================================//

    local minimized = false
    local normalSize = Main.Size

    Minimize.MouseButton1Click:Connect(function()
        minimized = not minimized

        if minimized then
            Tween(Main, {
                Size = UDim2.fromOffset(620, 48)
            })

            for _, child in ipairs(Main:GetChildren()) do
                if child ~= Top and child ~= Shadow then
                    if child:IsA("GuiObject") then
                        child.Visible = false
                    end
                end
            end

            Top.Visible = true
        else
            Tween(Main, {
                Size = normalSize
            })

            for _, child in ipairs(Main:GetChildren()) do
                if child ~= Top then
                    if child:IsA("GuiObject") then
                        child.Visible = true
                    end
                end
            end
        end
    end)

    --//================================================//
    --// CLOSE
    --//================================================//

    Close.MouseButton1Click:Connect(function()
        Tween(Main, {
            Size = UDim2.fromOffset(0, 0)
        })

        task.wait(Settings.AnimationSpeed)

        Gui:Destroy()
    end)

    --//================================================//
    --// CREATE TAB
    --//================================================//

    function self:CreateTab(name, icon)
        local TabObject = {}

        local Button = Instance.new("TextButton")
        Button.Name = name
        Button.Size = UDim2.new(1, 0, 0, 38)
        Button.BackgroundColor3 = Settings.Secondary
        Button.Text = ""
        Button.AutoButtonColor = false
        Button.Parent = TabList

        Corner(Button, 8)

        local Icon = MakeLabel(
            Button,
            icon or "•",
            UDim2.fromOffset(28, 38),
            Settings.SubText
        )

        Icon.Position = UDim2.fromOffset(8, 0)
        Icon.TextXAlignment = Enum.TextXAlignment.Center

        local Label = MakeLabel(
            Button,
            name,
            UDim2.new(1, -42, 1, 0),
            Settings.SubText
        )

        Label.Position = UDim2.fromOffset(38, 0)

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "_Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Settings.Accent
        Page.CanvasSize = UDim2.new()
        Page.Visible = false
        Page.Parent = Content

        Padding(Page, 15)

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.Parent = Page

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.fromOffset(
                0,
                PageLayout.AbsoluteContentSize.Y + 30
            )
        end)

        TabObject.Page = Page
        TabObject.Button = Button
        TabObject.Sections = {}

        function TabObject:CreateSection(sectionName)
            local Section = {}

            local Frame = Instance.new("Frame")
            Frame.Name = sectionName
            Frame.Size = UDim2.new(1, 0, 0, 0)
            Frame.AutomaticSize = Enum.AutomaticSize.Y
            Frame.BackgroundColor3 = Settings.Secondary
            Frame.BorderSizePixel = 0
            Frame.Parent = Page

            Corner(Frame, 10)
            Stroke(Frame)

            Padding(Frame, 12)

            local SectionTitle = MakeLabel(
                Frame,
                sectionName,
                UDim2.new(1, 0, 0, 25)
            )

            SectionTitle.Font = Enum.Font.GothamBold
            SectionTitle.TextSize = 14

            local Container = Instance.new("Frame")
            Container.Name = "Container"
            Container.Size = UDim2.new(1, 0, 0, 0)
            Container.AutomaticSize = Enum.AutomaticSize.Y
            Container.Position = UDim2.fromOffset(0, 30)
            Container.BackgroundTransparency = 1
            Container.Parent = Frame

            local Layout = Instance.new("UIListLayout")
            Layout.Padding = UDim.new(0, 7)
            Layout.Parent = Container

            --//========================================//
            --// BUTTON
            --//========================================//

            function Section:CreateButton(name, callback)
                local Button = Instance.new("TextButton")

                Button.Size = UDim2.new(1, 0, 0, 38)
                Button.BackgroundColor3 = Settings.Tertiary
                Button.TextColor3 = Settings.Text
                Button.Text = name
                Button.TextSize = 13
                Button.Font = Enum.Font.GothamMedium
                Button.AutoButtonColor = false
                Button.Parent = Container

                Corner(Button, 8)

                Hover(
                    Button,
                    Settings.Tertiary,
                    Color3.fromRGB(38, 38, 50)
                )

                Button.MouseButton1Click:Connect(function()
                    Tween(Button, {
                        Size = UDim2.new(1, -4, 0, 36)
                    }, 0.06)

                    task.delay(0.06, function()
                        Tween(Button, {
                            Size = UDim2.new(1, 0, 0, 38)
                        }, 0.06)
                    end)

                    if callback then
                        callback()
                    end
                end)

                return Button
            end

            --//========================================//
            --// TOGGLE
            --//========================================//

            function Section:CreateToggle(name, default, callback)
                local state = default or false

                local Button = Instance.new("TextButton")
                Button.Size = UDim2.new(1, 0, 0, 42)
                Button.BackgroundColor3 = Settings.Tertiary
                Button.Text = ""
                Button.AutoButtonColor = false
                Button.Parent = Container

                Corner(Button, 8)

                local Label = MakeLabel(
                    Button,
                    name,
                    UDim2.new(1, -70, 1, 0)
                )

                Label.Position = UDim2.fromOffset(12, 0)

                local Toggle = Instance.new("Frame")
                Toggle.Size = UDim2.fromOffset(42, 22)
                Toggle.Position = UDim2.new(1, -54, 0.5, -11)
                Toggle.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
                Toggle.Parent = Button

                Corner(Toggle, 20)

                local Circle = Instance.new("Frame")
                Circle.Size = UDim2.fromOffset(16, 16)
                Circle.Position = UDim2.fromOffset(3, 3)
                Circle.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
                Circle.Parent = Toggle

                Corner(Circle, 20)

                local function Update()
                    if state then
                        Tween(Toggle, {
                            BackgroundColor3 = Settings.Accent
                        })

                        Tween(Circle, {
                            Position = UDim2.new(1, -19, 0, 3)
                        })
                    else
                        Tween(Toggle, {
                            BackgroundColor3 = Color3.fromRGB(55, 55, 65)
                        })

                        Tween(Circle, {
                            Position = UDim2.fromOffset(3, 3)
                        })
                    end

                    if callback then
                        callback(state)
                    end
                end

                Button.MouseButton1Click:Connect(function()
                    state = not state
                    Update()
                end)

                Update()

                return {
                    Set = function(_, value)
                        state = value
                        Update()
                    end,

                    Get = function()
                        return state
                    end
                }
            end

            --//========================================//
            --// SLIDER
            --//========================================//

            function Section:CreateSlider(name, min, max, default, callback)
                local value = default or min

                local FrameSlider = Instance.new("Frame")
                FrameSlider.Size = UDim2.new(1, 0, 0, 62)
                FrameSlider.BackgroundColor3 = Settings.Tertiary
                FrameSlider.Parent = Container

                Corner(FrameSlider, 8)

                local Label = MakeLabel(
                    FrameSlider,
                    name,
                    UDim2.new(1, -70, 0, 25)
                )

                Label.Position = UDim2.fromOffset(12, 6)

                local ValueLabel = MakeLabel(
                    FrameSlider,
                    tostring(value),
                    UDim2.fromOffset(55, 25),
                    Settings.SubText
                )

                ValueLabel.Position = UDim2.new(1, -65, 0, 6)
                ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

                local Bar = Instance.new("Frame")
                Bar.Size = UDim2.new(1, -24, 0, 6)
                Bar.Position = UDim2.fromOffset(12, 42)
                Bar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                Bar.Parent = FrameSlider

                Corner(Bar, 10)

                local Fill = Instance.new("Frame")
                Fill.Size = UDim2.new(
                    (value - min) / (max - min),
                    0,
                    1,
                    0
                )

                Fill.BackgroundColor3 = Settings.Accent
                Fill.Parent = Bar

                Corner(Fill, 10)

                local dragging = false

                local function SetValueFromX(x)
                    local percentage = math.clamp(
                        (x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X,
                        0,
                        1
                    )

                    value = min + ((max - min) * percentage)

                    if math.floor(value) == value then
                        value = math.floor(value)
                    else
                        value = math.floor(value * 100) / 100
                    end

                    Fill.Size = UDim2.new(percentage, 0, 1, 0)
                    ValueLabel.Text = tostring(value)

                    if callback then
                        callback(value)
                    end
                end

                Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        SetValueFromX(input.Position.X)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        SetValueFromX(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                return {
                    Set = function(_, newValue)
                        value = math.clamp(newValue, min, max)

                        local percentage =
                            (value - min) / (max - min)

                        Fill.Size =
                            UDim2.new(percentage, 0, 1, 0)

                        ValueLabel.Text = tostring(value)

                        if callback then
                            callback(value)
                        end
                    end,

                    Get = function()
                        return value
                    end
                }
            end

            --//========================================//
            --// DROPDOWN
            --//========================================//

            function Section:CreateDropdown(name, options, default, callback)
                local selected = default or options[1]

                local Holder = Instance.new("Frame")
                Holder.Size = UDim2.new(1, 0, 0, 42)
                Holder.BackgroundColor3 = Settings.Tertiary
                Holder.ClipsDescendants = true
                Holder.Parent = Container

                Corner(Holder, 8)

                local Button = Instance.new("TextButton")
                Button.Size = UDim2.new(1, 0, 0, 42)
                Button.BackgroundTransparency = 1
                Button.Text = ""
                Button.Parent = Holder

                local Label = MakeLabel(
                    Button,
                    name,
                    UDim2.new(0.5, 0, 1, 0)
                )

                Label.Position = UDim2.fromOffset(12, 0)

                local Selected = MakeLabel(
                    Button,
                    tostring(selected),
                    UDim2.new(0.5, -25, 1, 0),
                    Settings.SubText
                )

                Selected.Position = UDim2.new(0.5, 0, 0, 0)
                Selected.TextXAlignment = Enum.TextXAlignment.Right

                local Arrow = MakeLabel(
                    Button,
                    "▼",
                    UDim2.fromOffset(20, 42),
                    Settings.SubText
                )

                Arrow.Position = UDim2.new(1, -25, 0, 0)
                Arrow.TextXAlignment = Enum.TextXAlignment.Center

                local OptionContainer = Instance.new("Frame")
                OptionContainer.Size = UDim2.new(1, -20, 0, #options * 30)
                OptionContainer.Position = UDim2.fromOffset(10, 47)
                OptionContainer.BackgroundTransparency = 1
                OptionContainer.Parent = Holder

                local OptionLayout = Instance.new("UIListLayout")
                OptionLayout.Padding = UDim.new(0, 4)
                OptionLayout.Parent = OptionContainer

                for _, option in ipairs(options) do
                    local Option = Instance.new("TextButton")

                    Option.Size = UDim2.new(1, 0, 0, 28)
                    Option.BackgroundColor3 = Settings.Background
                    Option.Text = tostring(option)
                    Option.TextColor3 = Settings.Text
                    Option.TextSize = 12
                    Option.Font = Enum.Font.Gotham
                    Option.AutoButtonColor = false
                    Option.Parent = OptionContainer

                    Corner(Option, 6)

                    Hover(
                        Option,
                        Settings.Background,
                        Settings.Border
                    )

                    Option.MouseButton1Click:Connect(function()
                        selected = option
                        Selected.Text = tostring(option)

                        if callback then
                            callback(option)
                        end

                        Holder.Size = UDim2.new(1, 0, 0, 42)
                    end)
                end

                local opened = false

                Button.MouseButton1Click:Connect(function()
                    opened = not opened

                    if opened then
                        Holder.Size = UDim2.new(
                            1,
                            0,
                            0,
                            55 + (#options * 30)
                        )

                        Arrow.Text = "▲"
                    else
                        Holder.Size = UDim2.new(1, 0, 0, 42)
                        Arrow.Text = "▼"
                    end
                end)

                return {
                    Set = function(_, option)
                        if table.find(options, option) then
                            selected = option
                            Selected.Text = tostring(option)

                            if callback then
                                callback(option)
                            end
                        end
                    end,

                    Get = function()
                        return selected
                    end
                }
            end

            --//========================================//
            --// TEXTBOX
            --//========================================//

            function Section:CreateTextbox(name, placeholder, callback)
                local Box = Instance.new("TextBox")

                Box.Size = UDim2.new(1, 0, 0, 42)
                Box.BackgroundColor3 = Settings.Tertiary
                Box.PlaceholderText = placeholder or "Enter text..."
                Box.PlaceholderColor3 = Settings.SubText
                Box.Text = ""
                Box.TextColor3 = Settings.Text
                Box.TextSize = 13
                Box.Font = Enum.Font.Gotham
                Box.ClearTextOnFocus = false
                Box.Parent = Container

                Corner(Box, 8)

                local PaddingBox = Instance.new("UIPadding")
                PaddingBox.PaddingLeft = UDim.new(0, 12)
                PaddingBox.PaddingRight = UDim.new(0, 12)
                PaddingBox.Parent = Box

                Box.FocusLost:Connect(function()
                    if callback then
                        callback(Box.Text)
                    end
                end)

                return Box
            end

            --//========================================//
            --// KEYBIND
            --//========================================//

            function Section:CreateKeybind(name, default, callback)
                local key = default or Enum.KeyCode.RightShift

                local Button = Instance.new("TextButton")

                Button.Size = UDim2.new(1, 0, 0, 42)
                Button.BackgroundColor3 = Settings.Tertiary
                Button.Text = ""
                Button.AutoButtonColor = false
                Button.Parent = Container

                Corner(Button, 8)

                local Label = MakeLabel(
                    Button,
                    name,
                    UDim2.new(0.6, 0, 1, 0)
                )

                Label.Position = UDim2.fromOffset(12, 0)

                local KeyLabel = MakeLabel(
                    Button,
                    key.Name,
                    UDim2.new(0.4, -12, 1, 0),
                    Settings.SubText
                )

                KeyLabel.Position = UDim2.new(0.6, 0, 0, 0)
                KeyLabel.TextXAlignment = Enum.TextXAlignment.Right

                local listening = false

                Button.MouseButton1Click:Connect(function()
                    listening = true
                    KeyLabel.Text = "Press key..."
                end)

                UserInputService.InputBegan:Connect(function(input, processed)
                    if listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            key = input.KeyCode
                            KeyLabel.Text = key.Name
                            listening = false
                        end

                        return
                    end

                    if processed then
                        return
                    end

                    if input.KeyCode == key then
                        if callback then
                            callback()
                        end
                    end
                end)

                return {
                    Set = function(_, newKey)
                        key = newKey
                        KeyLabel.Text = newKey.Name
                    end,

                    Get = function()
                        return key
                    end
                }
            end

            --//========================================//
            --// LABEL
            --//========================================//

            function Section:CreateLabel(text)
                local Label = MakeLabel(
                    Container,
                    text,
                    UDim2.new(1, 0, 0, 30),
                    Settings.SubText
                )

                Label.TextWrapped = true
                Label.AutomaticSize = Enum.AutomaticSize.Y

                return Label
            end

            --//========================================//
            --// DIVIDER
            --//========================================//

            function Section:CreateDivider()
                local Divider = Instance.new("Frame")

                Divider.Size = UDim2.new(1, 0, 0, 1)
                Divider.BackgroundColor3 = Settings.Border
                Divider.BorderSizePixel = 0
                Divider.Parent = Container

                return Divider
            end

            TabObject.Sections[sectionName] = Section

            return Section
        end

        --// TAB CLICK
        Button.MouseButton1Click:Connect(function()
            for _, tab in pairs(self.Tabs) do
                tab.Page.Visible = false

                Tween(tab.Button, {
                    BackgroundColor3 = Settings.Secondary
                })

                for _, child in ipairs(tab.Button:GetChildren()) do
                    if child:IsA("TextLabel") then
                        Tween(child, {
                            TextColor3 = Settings.SubText
                        })
                    end
                end
            end

            Page.Visible = true

            Tween(Button, {
                BackgroundColor3 = Settings.Tertiary
            })

            Tween(Label, {
                TextColor3 = Settings.Text
            })

            Tween(Icon, {
                TextColor3 = Settings.Accent
            })
        end)

        self.Tabs[name] = TabObject

        -- First tab automatically opens
        if not self.ActiveTab then
            self.ActiveTab = TabObject
            Page.Visible = true

            Button.BackgroundColor3 = Settings.Tertiary
            Label.TextColor3 = Settings.Text
            Icon.TextColor3 = Settings.Accent
        end

        return TabObject
    end

    --//================================================//
    --// TOGGLE GUI
    --//================================================//

    function self:SetVisible(state)
        Gui.Enabled = state
    end

    function self:GetVisible()
        return Gui.Enabled
    end

    function self:Destroy()
        Gui:Destroy()
    end

    --//================================================//
    --// SEARCH
    --//================================================//

    Search:GetPropertyChangedSignal("Text"):Connect(function()
        local query = Search.Text:lower()

        for _, tab in pairs(self.Tabs) do
            for _, section in pairs(tab.Sections) do
                local sectionFrame = tab.Page:FindFirstChild(section)

                if sectionFrame then
                    sectionFrame.Visible =
                        query == "" or section:lower():find(query, 1, true) ~= nil
                end
            end
        end
    end)

    --//================================================//
    --// RESIZE HANDLE
    --//================================================//

    local Resize = Instance.new("TextButton")
    Resize.Size = UDim2.fromOffset(20, 20)
    Resize.Position = UDim2.new(1, -20, 1, -20)
    Resize.BackgroundTransparency = 1
    Resize.Text = ""
    Resize.Parent = Main

    local resizing = false
    local resizeStart
    local originalSize

    Resize.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            originalSize = Main.AbsoluteSize
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart

            local width = math.max(
                Settings.MinSize.X,
                originalSize.X + delta.X
            )

            local height = math.max(
                Settings.MinSize.Y,
                originalSize.Y + delta.Y
            )

            Main.Size = UDim2.fromOffset(width, height)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)

    --//================================================//
    --// OPEN ANIMATION
    --//================================================//

    Main.Size = UDim2.fromOffset(0, 0)

    Tween(Main, {
        Size = Settings.Size
    }, 0.35)

    CustomGUI.Notify(
        "Interface",
        "GUI loaded successfully.",
        2
    )

    return self
end

return CustomGUI

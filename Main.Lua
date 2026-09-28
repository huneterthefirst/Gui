--[[
    Novier-HB
    Retro Roblox UI Library
    ========================

    Loading this module does NOT create any UI.

    Example:

        local Novier = loadstring(game:HttpGet("YOUR_URL"))()

        local Window = Novier:CreateWindow({
            Title = "My Script",
            Size = UDim2.fromOffset(700, 500),
            Theme = "Retro"
        })

        local PlayerTab = Window:CreateTab("Player")

        local Movement = PlayerTab:CreateSection("Movement")

        Movement:CreateToggle({
            Name = "Speed",
            Default = false,
            Callback = function(Value)
                print("Speed:", Value)
            end
        })
]]

local Novier = {}

Novier.Version = "1.0.0"

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

----------------------------------------------------------------
-- THEMES
----------------------------------------------------------------

Novier.Themes = {

    Retro = {
        Background = Color3.fromRGB(192, 192, 192),
        Panel = Color3.fromRGB(212, 208, 200),
        PanelDark = Color3.fromRGB(160, 160, 160),

        TitleBar = Color3.fromRGB(0, 82, 160),
        TitleBarInactive = Color3.fromRGB(128, 128, 128),

        Text = Color3.fromRGB(0, 0, 0),
        TextLight = Color3.fromRGB(255, 255, 255),

        Button = Color3.fromRGB(212, 208, 200),
        ButtonHover = Color3.fromRGB(230, 230, 230),

        Input = Color3.fromRGB(255, 255, 255),

        Accent = Color3.fromRGB(0, 82, 160),
        AccentDark = Color3.fromRGB(0, 55, 110),

        Tab = Color3.fromRGB(192, 192, 192),
        TabActive = Color3.fromRGB(255, 255, 255),

        Border = Color3.fromRGB(0, 0, 0),
        Separator = Color3.fromRGB(128, 128, 128),

        Success = Color3.fromRGB(0, 128, 0),
        Warning = Color3.fromRGB(180, 120, 0),
        Error = Color3.fromRGB(180, 0, 0),
    },

    Classic = {
        Background = Color3.fromRGB(25, 25, 25),
        Panel = Color3.fromRGB(35, 35, 35),
        PanelDark = Color3.fromRGB(20, 20, 20),

        TitleBar = Color3.fromRGB(45, 45, 45),
        TitleBarInactive = Color3.fromRGB(30, 30, 30),

        Text = Color3.fromRGB(235, 235, 235),
        TextLight = Color3.fromRGB(255, 255, 255),

        Button = Color3.fromRGB(45, 45, 45),
        ButtonHover = Color3.fromRGB(60, 60, 60),

        Input = Color3.fromRGB(20, 20, 20),

        Accent = Color3.fromRGB(0, 120, 255),
        AccentDark = Color3.fromRGB(0, 80, 180),

        Tab = Color3.fromRGB(35, 35, 35),
        TabActive = Color3.fromRGB(55, 55, 55),

        Border = Color3.fromRGB(0, 0, 0),
        Separator = Color3.fromRGB(75, 75, 75),

        Success = Color3.fromRGB(0, 200, 100),
        Warning = Color3.fromRGB(255, 180, 0),
        Error = Color3.fromRGB(255, 70, 70),
    },

    Terminal = {
        Background = Color3.fromRGB(5, 10, 5),
        Panel = Color3.fromRGB(10, 20, 10),
        PanelDark = Color3.fromRGB(3, 8, 3),

        TitleBar = Color3.fromRGB(0, 70, 0),
        TitleBarInactive = Color3.fromRGB(0, 35, 0),

        Text = Color3.fromRGB(0, 255, 80),
        TextLight = Color3.fromRGB(150, 255, 170),

        Button = Color3.fromRGB(10, 35, 10),
        ButtonHover = Color3.fromRGB(15, 60, 15),

        Input = Color3.fromRGB(0, 10, 0),

        Accent = Color3.fromRGB(0, 255, 80),
        AccentDark = Color3.fromRGB(0, 150, 40),

        Tab = Color3.fromRGB(5, 20, 5),
        TabActive = Color3.fromRGB(10, 40, 10),

        Border = Color3.fromRGB(0, 255, 80),
        Separator = Color3.fromRGB(0, 100, 30),

        Success = Color3.fromRGB(0, 255, 80),
        Warning = Color3.fromRGB(255, 200, 0),
        Error = Color3.fromRGB(255, 60, 60),
    }
}

----------------------------------------------------------------
-- DEFAULTS
----------------------------------------------------------------

local DefaultConfig = {
    Title = "Novier Window",
    Size = UDim2.fromOffset(650, 450),
    Position = nil,

    Theme = "Retro",

    ShowClose = true,
    ShowMinimize = true,

    Resizable = true,
    Draggable = true,

    TabsSide = "Left",

    Font = Enum.Font.Code,

    ToggleKey = nil,

    Parent = nil,
}

----------------------------------------------------------------
-- INTERNAL HELPERS
----------------------------------------------------------------

local function Merge(defaults, custom)

    local result = {}

    for key, value in pairs(defaults) do
        result[key] = value
    end

    if custom then
        for key, value in pairs(custom) do
            result[key] = value
        end
    end

    return result
end

local function New(className, properties)

    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    return object
end

local function Corner(parent, radius)

    local corner = New("UICorner", {
        CornerRadius = UDim.new(0, radius or 0),
        Parent = parent
    })

    return corner
end

local function Stroke(parent, color, thickness)

    local stroke = New("UIStroke", {
        Color = color or Color3.new(0, 0, 0),
        Thickness = thickness or 1,
        Parent = parent
    })

    return stroke
end

local function Tween(object, properties, duration)

    return TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.15,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        properties
    )
end

local function AddConnection(container, connection)

    container._connections = container._connections or {}

    table.insert(container._connections, connection)

    return connection
end

local function DisconnectAll(container)

    if not container._connections then
        return
    end

    for _, connection in ipairs(container._connections) do

        pcall(function()
            connection:Disconnect()
        end)

    end

    table.clear(container._connections)
end

----------------------------------------------------------------
-- BASE CONTROL
----------------------------------------------------------------

local function CreateControlFrame(parent, height)

    local frame = New("Frame", {
        Size = UDim2.new(1, -12, 0, height),
        BackgroundTransparency = 1,
        Parent = parent
    })

    return frame
end

----------------------------------------------------------------
-- SECTION
----------------------------------------------------------------

local SectionMethods = {}

function SectionMethods:_UpdateCanvas()

    if self._content then
        self._content.CanvasSize =
            UDim2.fromOffset(0, self._layout.AbsoluteContentSize.Y + 10)
    end
end

function SectionMethods:CreateLabel(text)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -12, 0, 24),
        BackgroundTransparency = 1,

        Font = self.Window.Config.Font,
        TextSize = 14,

        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,

        Text = tostring(text),

        Parent = self._content
    })

    return label
end

function SectionMethods:CreateDivider()

    local divider = New("Frame", {
        Size = UDim2.new(1, -12, 0, 1),

        BackgroundColor3 = self.Theme.Separator,

        BorderSizePixel = 0,

        Parent = self._content
    })

    return divider
end

function SectionMethods:CreateParagraph(title, text)

    local frame = CreateControlFrame(self._content, 70)

    local titleLabel = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),

        BackgroundTransparency = 1,

        Font = self.Window.Config.Font,
        TextSize = 14,

        TextColor3 = self.Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,

        Text = title,

        Parent = frame
    })

    local body = New("TextLabel", {
        Position = UDim2.fromOffset(0, 22),
        Size = UDim2.new(1, 0, 1, -22),

        BackgroundTransparency = 1,

        Font = self.Window.Config.Font,
        TextSize = 12,

        TextColor3 = self.Theme.Text,

        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,

        Text = text,

        Parent = frame
    })

    return frame
end

function SectionMethods:CreateButton(config)

    config = config or {}

    local name = config.Name or "Button"
    local callback = config.Callback or function() end

    local button = New("TextButton", {
        Size = UDim2.new(1, -12, 0, 30),

        BackgroundColor3 = self.Theme.Button,

        BorderSizePixel = 1,
        BorderColor3 = self.Theme.Border,

        AutoButtonColor = false,

        Font = self.Window.Config.Font,
        TextSize = 14,

        TextColor3 = self.Theme.Text,

        Text = name,

        Parent = self._content
    })

    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = self.Theme.ButtonHover
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = self.Theme.Button
    end)

    button.MouseButton1Click:Connect(function()

        task.spawn(function()
            callback()
        end)

    end)

    return button
end

function SectionMethods:CreateToggle(config)

    config = config or {}

    local name = config.Name or "Toggle"
    local state = config.Default == true
    local callback = config.Callback or function() end

    local button = New("TextButton", {
        Size = UDim2.new(1, -12, 0, 30),

        BackgroundColor3 = self.Theme.Button,

        BorderSizePixel = 1,
        BorderColor3 = self.Theme.Border,

        AutoButtonColor = false,

        Font = self.Window.Config.Font,
        TextSize = 14,

        TextColor3 = self.Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,

        Parent = self._content
    })

    local indicator = New("Frame", {
        Position = UDim2.new(1, -25, 0.5, -7),

        Size = UDim2.fromOffset(14, 14),

        BackgroundColor3 = self.Theme.Panel,

        BorderSizePixel = 1,
        BorderColor3 = self.Theme.Border,

        Parent = button
    })

    local label = New("TextLabel", {
        Position = UDim2.fromOffset(8, 0),

        Size = UDim2.new(1, -40, 1, 0),

        BackgroundTransparency = 1,

        Font = self.Window.Config.Font,
        TextSize = 14,

        TextColor3 = self.Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,

        Text = name,

        Parent = button
    })

    local function update()

        if state then
            indicator.BackgroundColor3 = self.Theme.Accent
            label.Text = "☑ " .. name
        else
            indicator.BackgroundColor3 = self.Theme.Panel
            label.Text = "☐ " .. name
        end

        task.spawn(function()
            callback(state)
        end)
    end

    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = self.Theme.ButtonHover
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = self.Theme.Button
    end)

    button.MouseButton1Click:Connect(function()

        state = not state

        update()

    end)

    update()

    local object = {}

    function object:GetValue()
        return state
    end

    function object:SetValue(value)

        state = value == true

        update()

    end

    function object:Destroy()
        button:Destroy()
    end

    return object
end

function SectionMethods:CreateSlider(config)

    config = config or {}

    local name = config.Name or "Slider"

    local min = config.Min or 0
    local max = config.Max or 100

    local value = config.Default or min

    local callback = config.Callback or function() end

    local frame = CreateControlFrame(self._content, 45)

    local label = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),

        BackgroundTransparency = 1,

        Font = self.Window.Config.Font,
        TextSize = 13,

        TextColor3 = self.Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,

        Parent = frame
    })

    local bar = New("Frame", {
        Position = UDim2.fromOffset(0, 25),

        Size = UDim2.new(1, 0, 0, 12),

        BackgroundColor3 = self.Theme.Panel,

        BorderSizePixel = 1,
        BorderColor3 = self.Theme.Border,

        Parent = frame
    })

    local fill = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),

        BackgroundColor3 = self.Theme.Accent,

        BorderSizePixel = 0,

        Parent = bar
    })

    local dragging = false

    local function setValue(newValue, fire)

        newValue = math.clamp(newValue, min, max)

        value = newValue

        local percent = (value - min) / (max - min)

        fill.Size = UDim2.new(percent, 0, 1, 0)

        label.Text = string.format(
            "%s: %s",
            name,
            tostring(math.floor(value * 100) / 100)
        )

        if fire then
            task.spawn(function()
                callback(value)
            end)
        end
    end

    local function fromMouse(x)

        local percent =
            math.clamp(
                (x - bar.AbsolutePosition.X) /
                bar.AbsoluteSize.X,
                0,
                1
            )

        setValue(
            min + ((max - min) * percent),
            true
        )
    end

    bar.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1 then

            dragging = true

            fromMouse(input.Position.X)

        end

    end)

    UserInputService.InputChanged:Connect(function(input)

        if dragging and
            input.UserInputType == Enum.UserInputType.MouseMovement then

            fromMouse(input.Position.X)

        end

    end)

    UserInputService.InputEnded:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end

    end)

    setValue(value, false)

    local object = {}

    function object:GetValue()
        return value
    end

    function object:SetValue(newValue)
        setValue(newValue, true)
    end

    function object:Destroy()
        frame:Destroy()
    end

    return object
end

function SectionMethods:CreateTextbox(config)

    config = config or {}

    local name = config.Name or "Textbox"

    local placeholder = config.Placeholder or ""

    local default = config.Default or ""

    local callback = config.Callback or function() end

    local frame = CreateControlFrame(self._content, 55)

    local label = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),

        BackgroundTransparency = 1,

        Font = self.Window.Config.Font,
        TextSize = 13,

        TextColor3 = self.Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,

        Text = name,

        Parent = frame
    })

    local box = New("TextBox", {
        Position = UDim2.fromOffset(0, 22),

        Size = UDim2.new(1, 0, 0, 28),

        BackgroundColor3 = self.Theme.Input,

        BorderSizePixel = 1,
        BorderColor3 = self.Theme.Border,

        Font = self.Window.Config.Font,
        TextSize = 13,

        TextColor3 = self.Theme.Text,

        PlaceholderColor3 = self.Theme.PanelDark,

        PlaceholderText = placeholder,

        Text = default,

        ClearTextOnFocus = false,

        Parent = frame
    })

    box.FocusLost:Connect(function(enterPressed)

        task.spawn(function()
            callback(box.Text, enterPressed)
        end)

    end)

    local object = {}

    function object:GetValue()
        return box.Text
    end

    function object:SetValue(value)
        box.Text = tostring(value)
    end

    function object:Destroy()
        frame:Destroy()
    end

    return object
end

function SectionMethods:CreateDropdown(config)

    config = config or {}

    local name = config.Name or "Dropdown"

    local options = config.Options or {}

    local selected = config.Default

    local callback = config.Callback or function() end

    local frame = CreateControlFrame(self._content, 32)

    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),

        BackgroundColor3 = self.Theme.Button,

        BorderSizePixel = 1,
        BorderColor3 = self.Theme.Border,

        Font = self.Window.Config.Font,
        TextSize = 13,

        TextColor3 = self.Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,

        AutoButtonColor = false,

        Parent = frame
    })

    local list

    local function updateText()

        if selected ~= nil then
            button.Text = "  " .. name .. ": " .. tostring(selected)
        else
            button.Text = "  " .. name .. ": <none>"
        end

    end

    local function close()

        if list then
            list:Destroy()
            list = nil
        end

    end

    local function open()

        close()

        list = New("Frame", {
            Position = UDim2.new(
                0,
                0,
                1,
                2
            ),

            Size = UDim2.new(
                1,
                0,
                0,
                math.min(#options * 27, 160)
            ),

            BackgroundColor3 = self.Theme.Panel,

            BorderSizePixel = 1,
            BorderColor3 = self.Theme.Border,

            ZIndex = 50,

            Parent = frame
        })

        local layout = New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = list
        })

        for _, option in ipairs(options) do

            local item = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 27),

                BackgroundColor3 = self.Theme.Button,

                BorderSizePixel = 1,
                BorderColor3 = self.Theme.Border,

                Font = self.Window.Config.Font,
                TextSize = 13,

                TextColor3 = self.Theme.Text,

                Text = tostring(option),

                ZIndex = 51,

                Parent = list
            })

            item.MouseButton1Click:Connect(function()

                selected = option

                updateText()

                close()

                task.spawn(function()
                    callback(selected)
                end)

            end)

        end
    end

    button.MouseButton1Click:Connect(function()

        if list then
            close()
        else
            open()
        end

    end)

    updateText()

    local object = {}

    function object:GetValue()
        return selected
    end

    function object:SetValue(value)

        selected = value

        updateText()

        task.spawn(function()
            callback(selected)
        end)

    end

    function object:SetOptions(newOptions)

        options = newOptions or {}

        close()

    end

    function object:Destroy()

        close()
        frame:Destroy()

    end

    return object
end

function SectionMethods:CreateKeybind(config)

    config = config or {}

    local name = config.Name or "Keybind"

    local default = config.Default or Enum.KeyCode.RightShift

    local callback = config.Callback or function() end

    local current = default

    local listening = false

    local button = New("TextButton", {
        Size = UDim2.new(1, -12, 0, 30),

        BackgroundColor3 = self.Theme.Button,

        BorderSizePixel = 1,
        BorderColor3 = self.Theme.Border,

        Font = self.Window.Config.Font,
        TextSize = 13,

        TextColor3 = self.Theme.Text,

        AutoButtonColor = false,

        Parent = self._content
    })

    local function update()

        button.Text =
            name .. ": [" .. current.Name .. "]"

    end

    button.MouseButton1Click:Connect(function()

        if listening then
            return
        end

        listening = true

        button.Text = name .. ": [...]"

        local connection

        connection = UserInputService.InputBegan:Connect(function(input)

            if input.UserInputType == Enum.UserInputType.Keyboard then

                current = input.KeyCode

                listening = false

                connection:Disconnect()

                update()

                task.spawn(function()
                    callback(current)
                end)

            end

        end)

    end)

    update()

    local object = {}

    function object:GetValue()
        return current
    end

    function object:SetValue(key)
        current = key
        update()
    end

    function object:Destroy()
        button:Destroy()
    end

    return object
end

----------------------------------------------------------------
-- TAB
----------------------------------------------------------------

local TabMethods = {}

function TabMethods:CreateSection(name)

    local section = setmetatable({
        Window = self.Window,
        Tab = self,
        Theme = self.Window.Theme,

        Name = name,

    }, {
        __index = SectionMethods
    })

    local header = New("TextLabel", {
        Size = UDim2.new(1, -12, 0, 28),

        BackgroundColor3 = self.Window.Theme.PanelDark,

        BorderSizePixel = 1,
        BorderColor3 = self.Window.Theme.Border,

        Font = self.Window.Config.Font,
        TextSize = 14,

        TextColor3 = self.Window.Theme.TextLight,

        TextXAlignment = Enum.TextXAlignment.Left,

        Text = "  " .. tostring(name),

        Parent = self._content
    })

    local content = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0),

        AutomaticCanvasSize = Enum.AutomaticSize.Y,

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        ScrollBarThickness = 5,

        ScrollBarImageColor3 = self.Window.Theme.Accent,

        CanvasSize = UDim2.new(),

        Parent = self._content
    })

    local padding = New("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),

        Parent = content
    })

    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 5),

        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = content
    })

    section._header = header
    section._content = content
    section._layout = layout

    table.insert(self.Sections, section)

    return section
end

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------

local WindowMethods = {}

function WindowMethods:SetVisible(value)

    self.Visible = value == true

    self.Gui.Enabled = self.Visible

end

function WindowMethods:IsVisible()

    return self.Visible

end

function WindowMethods:SetTitle(title)

    self.Config.Title = tostring(title)

    self._title.Text = self.Config.Title

end

function WindowMethods:SelectTab(tab)

    if type(tab) == "string" then

        for _, existing in ipairs(self.Tabs) do

            if existing.Name == tab then
                tab = existing
                break
            end

        end

    end

    if not tab then
        return
    end

    for _, existing in ipairs(self.Tabs) do

        local active = existing == tab

        existing._page.Visible = active

        if active then

            existing._button.BackgroundColor3 =
                self.Theme.TabActive

            existing._button.TextColor3 =
                self.Theme.Text

        else

            existing._button.BackgroundColor3 =
                self.Theme.Tab

            existing._button.TextColor3 =
                self.Theme.Text

        end

    end

    self.SelectedTab = tab

end

function WindowMethods:Notify(config)

    config = config or {}

    local title = config.Title or "Notification"
    local text = config.Text or ""

    local duration = config.Duration or 3

    local holder = self._notificationHolder

    local notification = New("Frame", {
        Size = UDim2.fromOffset(300, 80),

        BackgroundColor3 = self.Theme.Panel,

        BorderSizePixel = 1,
        BorderColor3 = self.Theme.Border,

        Parent = holder
    })

    local titleLabel = New("TextLabel", {
        Size = UDim2.new(1, -10, 0, 25),

        Position = UDim2.fromOffset(5, 3),

        BackgroundTransparency = 1,

        Font = self.Config.Font,
        TextSize = 14,

        TextColor3 = self.Theme.Text,

        TextXAlignment = Enum.TextXAlignment.Left,

        Text = title,

        Parent = notification
    })

    local body = New("TextLabel", {
        Position = UDim2.fromOffset(5, 28),

        Size = UDim2.new(1, -10, 1, -32),

        BackgroundTransparency = 1,

        Font = self.Config.Font,
        TextSize = 12,

        TextColor3 = self.Theme.Text,

        TextWrapped = true,

        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,

        Text = text,

        Parent = notification
    })

    task.delay(duration, function()

        if notification and notification.Parent then

            Tween(
                notification,
                {
                    BackgroundTransparency = 1
                },
                0.2
            ):Play()

            task.wait(0.2)

            notification:Destroy()

        end

    end)

    return notification
end

function WindowMethods:SetTheme(theme)

    local selected

    if type(theme) == "string" then
        selected = Novier.Themes[theme]
    elseif type(theme) == "table" then
        selected = theme
    end

    if not selected then
        return
    end

    self.Theme = selected

    -- Rebuilding is intentionally avoided here.
    -- Existing controls can still be manually themed.
end

function WindowMethods:CreateTab(name, icon)

    local tab = setmetatable({

        Window = self,

        Name = name,

        Icon = icon,

        Sections = {},

    }, {
        __index = TabMethods
    })

    local buttonText = tostring(name)

    if icon then
        buttonText = tostring(icon) .. "  " .. buttonText
    end

    local button = New("TextButton", {
        Size = UDim2.new(1, -4, 0, 32),

        BackgroundColor3 = self.Theme.Tab,

        BorderSizePixel = 1,

        BorderColor3 = self.Theme.Border,

        AutoButtonColor = false,

        Font = self.Config.Font,
        TextSize = 13,

        TextColor3 = self.Theme.Text,

        Text = buttonText,

        Parent = self._tabList
    })

    local page = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        ScrollBarThickness = 7,

        ScrollBarImageColor3 = self.Theme.Accent,

        CanvasSize = UDim2.new(),

        AutomaticCanvasSize = Enum.AutomaticSize.Y,

        Visible = false,

        Parent = self._pages
    })

    local padding = New("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),

        Parent = page
    })

    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 8),

        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = page
    })

    tab._button = button
    tab._page = page
    tab._content = page

    table.insert(self.Tabs, tab)

    button.MouseEnter:Connect(function()

        if self.SelectedTab ~= tab then
            button.BackgroundColor3 = self.Theme.ButtonHover
        end

    end)

    button.MouseLeave:Connect(function()

        if self.SelectedTab ~= tab then
            button.BackgroundColor3 = self.Theme.Tab
        end

    end)

    button.MouseButton1Click:Connect(function()

        self:SelectTab(tab)

    end)

    if not self.SelectedTab then
        self:SelectTab(tab)
    end

    return tab
end

function WindowMethods:Minimize()

    self.Minimized = not self.Minimized

    self._content.Visible = not self.Minimized

    self._tabBar.Visible = not self.Minimized

    self._resize.Visible =
        not self.Minimized and self.Config.Resizable

end

function WindowMethods:Destroy()

    DisconnectAll(self)

    if self.Gui then
        self.Gui:Destroy()
    end

    self.Destroyed = true

end

----------------------------------------------------------------
-- WINDOW CREATION
----------------------------------------------------------------

function Novier:CreateWindow(config)

    config = Merge(DefaultConfig, config)

    local theme

    if type(config.Theme) == "table" then
        theme = config.Theme
    else
        theme =
            Novier.Themes[config.Theme]
            or Novier.Themes.Retro
    end

    local parent = config.Parent

    if not parent then
        parent = CoreGui
    end

    ------------------------------------------------------------
    -- WINDOW OBJECT
    ------------------------------------------------------------

    local Window = setmetatable({

        Config = config,

        Theme = theme,

        Tabs = {},

        SelectedTab = nil,

        Visible = true,

        Minimized = false,

        Destroyed = false,

        _connections = {},

    }, {
        __index = WindowMethods
    })

    ------------------------------------------------------------
    -- SCREEN GUI
    ------------------------------------------------------------

    local gui = New("ScreenGui", {
        Name = "NovierWindow_" .. tostring(math.random(10000, 99999)),

        ResetOnSpawn = false,

        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

        Parent = parent
    })

    Window.Gui = gui

    ------------------------------------------------------------
    -- MAIN WINDOW
    ------------------------------------------------------------

    local main = New("Frame", {

        Size = config.Size,

        Position =
            config.Position
            or UDim2.new(
                0.5,
                -(config.Size.X.Offset / 2),
                0.5,
                -(config.Size.Y.Offset / 2)
            ),

        BackgroundColor3 = theme.Background,

        BorderSizePixel = 1,

        BorderColor3 = theme.Border,

        Parent = gui
    })

    Window.Main = main

    ------------------------------------------------------------
    -- TITLE BAR
    ------------------------------------------------------------

    local titleBar = New("Frame", {

        Size = UDim2.new(1, 0, 0, 28),

        BackgroundColor3 = theme.TitleBar,

        BorderSizePixel = 1,

        BorderColor3 = theme.Border,

        Parent = main
    })

    local title = New("TextLabel", {

        Position = UDim2.fromOffset(7, 0),

        Size = UDim2.new(1, -80, 1, 0),

        BackgroundTransparency = 1,

        Font = config.Font,

        TextSize = 14,

        TextColor3 = theme.TextLight,

        TextXAlignment = Enum.TextXAlignment.Left,

        Text = config.Title,

        Parent = titleBar
    })

    Window._title = title

    ------------------------------------------------------------
    -- CLOSE
    ------------------------------------------------------------

    if config.ShowClose then

        local close = New("TextButton", {

            Position = UDim2.new(1, -27, 0, 3),

            Size = UDim2.fromOffset(22, 22),

            BackgroundColor3 = theme.Button,

            BorderSizePixel = 1,

            BorderColor3 = theme.Border,

            Font = Enum.Font.Code,

            TextSize = 14,

            TextColor3 = theme.Text,

            Text = "X",

            Parent = titleBar
        })

        close.MouseButton1Click:Connect(function()

            Window:Destroy()

        end)

    end

    ------------------------------------------------------------
    -- MINIMIZE
    ------------------------------------------------------------

    if config.ShowMinimize then

        local minimize = New("TextButton", {

            Position = UDim2.new(1, -52, 0, 3),

            Size = UDim2.fromOffset(22, 22),

            BackgroundColor3 = theme.Button,

            BorderSizePixel = 1,

            BorderColor3 = theme.Border,

            Font = Enum.Font.Code,

            TextSize = 14,

            TextColor3 = theme.Text,

            Text = "_",

            Parent = titleBar
        })

        minimize.MouseButton1Click:Connect(function()

            Window:Minimize()

        end)

    end

    ------------------------------------------------------------
    -- DRAGGING
    ------------------------------------------------------------

    if config.Draggable then

        local dragging = false

        local dragStart

        local startPosition

        titleBar.InputBegan:Connect(function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1 then

                dragging = true

                dragStart = input.Position

                startPosition = main.Position

            end

        end)

        UserInputService.InputChanged:Connect(function(input)

            if not dragging then
                return
            end

            if input.UserInputType ==
                Enum.UserInputType.MouseMovement then

                local delta =
                    input.Position - dragStart

                main.Position =
                    UDim2.new(
                        startPosition.X.Scale,
                        startPosition.X.Offset + delta.X,

                        startPosition.Y.Scale,
                        startPosition.Y.Offset + delta.Y
                    )

            end

        end)

        UserInputService.InputEnded:Connect(function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1 then

                dragging = false

            end

        end)

    end

    ------------------------------------------------------------
    -- BODY
    ------------------------------------------------------------

    local body = New("Frame", {

        Position = UDim2.fromOffset(0, 28),

        Size = UDim2.new(1, 0, 1, -28),

        BackgroundColor3 = theme.Background,

        BorderSizePixel = 0,

        Parent = main
    })

    Window._content = body

    ------------------------------------------------------------
    -- TAB BAR
    ------------------------------------------------------------

    local tabBar = New("Frame", {

        Size = UDim2.new(0, 135, 1, 0),

        BackgroundColor3 = theme.PanelDark,

        BorderSizePixel = 1,

        BorderColor3 = theme.Border,

        Parent = body
    })

    Window._tabBar = tabBar

    local tabList = New("ScrollingFrame", {

        Position = UDim2.fromOffset(3, 5),

        Size = UDim2.new(1, -6, 1, -10),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        ScrollBarThickness = 4,

        ScrollBarImageColor3 = theme.Accent,

        AutomaticCanvasSize = Enum.AutomaticSize.Y,

        CanvasSize = UDim2.new(),

        Parent = tabBar
    })

    local tabLayout = New("UIListLayout", {

        Padding = UDim.new(0, 3),

        SortOrder = Enum.SortOrder.LayoutOrder,

        Parent = tabList
    })

    Window._tabList = tabList

    ------------------------------------------------------------
    -- PAGES
    ------------------------------------------------------------

    local pages = New("Frame", {

        Position = UDim2.new(0, 135, 0, 0),

        Size = UDim2.new(1, -135, 1, 0),

        BackgroundTransparency = 1,

        Parent = body
    })

    Window._pages = pages

    ------------------------------------------------------------
    -- NOTIFICATIONS
    ------------------------------------------------------------

    local notificationHolder = New("Frame", {

        Position = UDim2.new(1, -310, 1, -90),

        Size = UDim2.fromOffset(300, 80),

        BackgroundTransparency = 1,

        Parent = gui
    })

    local notificationLayout = New("UIListLayout", {

        VerticalAlignment = Enum.VerticalAlignment.Bottom,

        Padding = UDim.new(0, 6),

        Parent = notificationHolder
    })

    Window._notificationHolder = notificationHolder

    ------------------------------------------------------------
    -- RESIZE HANDLE
    ------------------------------------------------------------

    local resize = New("TextButton", {

        Position = UDim2.new(1, -15, 1, -15),

        Size = UDim2.fromOffset(15, 15),

        BackgroundColor3 = theme.PanelDark,

        BorderSizePixel = 1,

        BorderColor3 = theme.Border,

        Text = "",

        AutoButtonColor = false,

        Parent = main
    })

    Window._resize = resize

    if not config.Resizable then
        resize.Visible = false
    end

    if config.Resizable then

        local resizing = false

        local resizeStart

        local startSize

        resize.InputBegan:Connect(function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1 then

                resizing = true

                resizeStart = input.Position

                startSize = main.Size

            end

        end)

        UserInputService.InputChanged:Connect(function(input)

            if not resizing then
                return
            end

            if input.UserInputType ==
                Enum.UserInputType.MouseMovement then

                local delta =
                    input.Position - resizeStart

                local width =
                    math.max(
                        400,
                        startSize.X.Offset + delta.X
                    )

                local height =
                    math.max(
                        250,
                        startSize.Y.Offset + delta.Y
                    )

                main.Size =
                    UDim2.fromOffset(
                        width,
                        height
                    )

            end

        end)

        UserInputService.InputEnded:Connect(function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1 then

                resizing = false

            end

        end)

    end

    ------------------------------------------------------------
    -- GLOBAL TOGGLE KEY
    ------------------------------------------------------------

    if config.ToggleKey then

        AddConnection(
            Window,
            UserInputService.InputBegan:Connect(
                function(input, processed)

                    if processed then
                        return
                    end

                    if input.KeyCode ==
                        config.ToggleKey then

                        Window:SetVisible(
                            not Window:IsVisible()
                        )

                    end

                end
            )
        )

    end

    return Window
end

----------------------------------------------------------------
-- SIMPLE ALIAS
----------------------------------------------------------------

Novier.new = Novier.CreateWindow

----------------------------------------------------------------
-- RETURN LIBRARY
----------------------------------------------------------------

return Novier

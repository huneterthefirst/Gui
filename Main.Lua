local CustomGUI = {}

-- Create a new window
function CustomGUI.CreateWindow(title)
    local Window = Instance.new("ScreenGui")
    Window.Name = title
    Window.Parent = game:GetService("CoreGui")

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.Parent = Window

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Text = title
    TitleLabel.Parent = MainFrame

    return MainFrame
end

-- Create a tab section
function CustomGUI.CreateTab(frame, name)
    local Tab = Instance.new("Frame")
    Tab.Size = UDim2.new(1, 0, 0, 40)
    Tab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Tab.Parent = frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Text = name
    Label.Parent = Tab

    return Tab
end

-- Create a button
function CustomGUI.CreateButton(frame, name, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 30)
    Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Text = name
    Button.Parent = frame

    Button.MouseButton1Click:Connect(callback)
    return Button
end

-- Create a toggle
function CustomGUI.CreateToggle(frame, name, callback)
    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(1, 0, 0, 30)
    Toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    Toggle.Text = name .. ": OFF"
    Toggle.Parent = frame

    local state = false
    Toggle.MouseButton1Click:Connect(function()
        state = not state
        Toggle.Text = name .. (state and ": ON" or ": OFF")
        callback(state)
    end)

    return Toggle
end

return CustomGUI

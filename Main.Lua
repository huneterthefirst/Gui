--[[
    NOVIER // DYNAMIC ISLAND & CAPSULE ENGINE  (V5.0 "AURORA")

    WHAT'S NEW IN 5.0
    - Audio Analyzer: auto-gain, envelope followers, synthesized bass/mid/high bands,
      spring-physics spectrum with peak-hold caps, beat + BPM detection
    - Center-symmetric mirrored edge spectrum (bass in the middle, treble at the ends)
    - Beat shockwave rings, edge/top/bottom glows, rotating gradient pill border
    - Live theme system (Neon / Sakura / Sunset / Glacier / Matrix) + Novier:SetTheme(name)
    - Ripple clicks, tooltips, keybind picker, collapsible sections, labels, separators
    - Config save/load through flags (executor filesystem), built-in Settings tab
    - Mobile-aware UIScale + touch toggle button, background blur, live FPS/ping in the pill
    - Notifications rebuilt (slide-in, icon, progress bar) + Window:OnBeat(callback)
    - Bug fixes: SetVisible(false) logic, unreachable colour branch, FOV fighting the game
      camera, notification slide tween being overridden by UIListLayout

    QUICK START
        local Novier = loadstring(game:HttpGet("https://raw.githubusercontent.com/huneterthefirst/Gui/refs/heads/main/Main.Lua"))()   -- or require(module)
        local Win = Novier:CreateWindow("NOVIER // ISLAND")
        Win:CreateMediaSuite()
        Win:CreateSettingsTab()

        local Tab = Win:CreateTab("MAIN", "⚡")
        local Sec = Tab:CreateSection("Movement")
        Sec:CreateToggle("Speed", false, function(on) print(on) end, { Flag = "speed", Tooltip = "Go fast" })
        Sec:CreateSlider("WalkSpeed", 16, 120, 16, 1, function(v) end, { Flag = "ws" })
        Sec:CreateKeybind("Panic", Enum.KeyCode.P, function() Novier:Destroy() end)

        Win:OnBeat(function(strength) end)   -- fires on every detected beat

    Default keys: [RightControl] toggle UI, [RightAlt] toggle beat FOV
]]

local Novier = {}
Novier.__index = Novier
Novier.Version = "5.0.0 AURORA"

-- Services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local SoundService     = game:GetService("SoundService")
local Stats            = game:GetService("Stats")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")
local Debris           = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local NSK, CSK = NumberSequenceKeypoint.new, ColorSequenceKeypoint.new

--========================================================--
-- THEMES
--========================================================--
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local BASE_THEME = {
    PillBackground   = rgb(10, 12, 17),
    DrawerBackground = rgb(13, 16, 22),
    SurfaceElevated  = rgb(21, 26, 37),
    SurfaceHighlight = rgb(32, 40, 56),
    Accent           = rgb(0, 255, 170),
    AccentGlow       = rgb(0, 235, 255),
    SecondaryAccent  = rgb(255, 0, 110),
    TextPrimary      = rgb(255, 255, 255),
    TextSecondary    = rgb(180, 195, 210),
    TextTerminal     = rgb(0, 255, 170),
    TextDisabled     = rgb(115, 130, 145),
    Border           = rgb(0, 255, 170),
    BorderSubtle     = rgb(45, 55, 75),
    Success          = rgb(0, 255, 128),
    Warning          = rgb(255, 204, 0),
    Error            = rgb(255, 60, 90),
}

local function makeTheme(overrides)
    local t = {}
    for k, v in pairs(BASE_THEME) do t[k] = v end
    for k, v in pairs(overrides or {}) do t[k] = v end
    if not (overrides and overrides.Border) then t.Border = t.Accent end
    if not (overrides and overrides.TextTerminal) then t.TextTerminal = t.Accent end
    return t
end

Novier.Themes = {
    Neon = makeTheme({}),
    Sakura = makeTheme({
        PillBackground = rgb(17, 11, 20), DrawerBackground = rgb(21, 14, 26),
        SurfaceElevated = rgb(34, 22, 40), SurfaceHighlight = rgb(50, 32, 58),
        Accent = rgb(255, 120, 200), AccentGlow = rgb(200, 140, 255), SecondaryAccent = rgb(120, 220, 255),
        BorderSubtle = rgb(70, 48, 82),
    }),
    Sunset = makeTheme({
        PillBackground = rgb(18, 11, 10), DrawerBackground = rgb(23, 14, 12),
        SurfaceElevated = rgb(38, 24, 20), SurfaceHighlight = rgb(56, 36, 28),
        Accent = rgb(255, 150, 60), AccentGlow = rgb(255, 210, 90), SecondaryAccent = rgb(255, 60, 110),
        BorderSubtle = rgb(80, 52, 40),
    }),
    Glacier = makeTheme({
        PillBackground = rgb(9, 13, 20), DrawerBackground = rgb(11, 17, 27),
        SurfaceElevated = rgb(18, 28, 44), SurfaceHighlight = rgb(28, 44, 68),
        Accent = rgb(90, 180, 255), AccentGlow = rgb(140, 240, 255), SecondaryAccent = rgb(170, 120, 255),
        BorderSubtle = rgb(38, 58, 88),
    }),
    Matrix = makeTheme({
        PillBackground = rgb(4, 10, 6), DrawerBackground = rgb(6, 14, 9),
        SurfaceElevated = rgb(10, 24, 15), SurfaceHighlight = rgb(16, 38, 24),
        Accent = rgb(60, 255, 90), AccentGlow = rgb(170, 255, 120), SecondaryAccent = rgb(255, 230, 80),
        BorderSubtle = rgb(24, 64, 38),
    }),
}

Novier.ThemeName = "Neon"
Novier.Theme = makeTheme(Novier.Themes.Neon) -- live table (mutated by SetTheme)

Novier.Config = {
    FontNormal       = Enum.Font.GothamMedium,
    FontBold         = Enum.Font.GothamBold,
    FontCode         = Enum.Font.Code,
    PillWidth        = 780,
    PillHeight       = 46,
    DrawerWidth      = 840,
    DrawerHeight     = 560,
    DefaultToggleKey = Enum.KeyCode.RightControl,
    DefaultFovKey    = Enum.KeyCode.RightAlt,
    ConfigFolder     = "Novier",
}

-- Live-tweakable settings (all exposed in Window:CreateSettingsTab)
Novier.Settings = {
    EdgeVisuals   = true,
    Rain          = true,
    Rings         = true,
    Blur          = true,
    IdleBreathing = true,
    UISounds      = false,
    ShowStats     = true,
    AutoGain      = true,
    Sensitivity   = 1,
    VisualHz      = 60,
    UIScale       = 1,
}

Novier.FOVConfig = { Enabled = false, BaseFOV = 70, MaxKick = 24, Smoothness = 0.18 }

Novier._Connections  = {}
Novier._FlagSetters  = {}
Novier._FlagGetters  = {}
Novier._MenuClosers  = {}
local Bindings, ThemeHooks, ScaleObjects = {}, {}, {}

--========================================================--
-- CORE HELPERS
--========================================================--
local function T(key) return { __theme = key } end -- theme-bound property marker

local function create(className, properties, children)
    local inst = Instance.new(className)
    local parent
    for prop, val in pairs(properties or {}) do
        if prop == "Parent" then
            parent = val
        else
            if type(val) == "table" and val.__theme then
                table.insert(Bindings, { inst = inst, prop = prop, key = val.__theme })
                val = Novier.Theme[val.__theme]
            end
            inst[prop] = val
        end
    end
    for _, child in ipairs(children or {}) do
        if typeof(child) == "Instance" then child.Parent = inst end
    end
    if parent then inst.Parent = parent end
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

local function safe(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[Novier] callback error: " .. tostring(err)) end
end

local function follow(cur, target, dt, attack, release)
    local rate = (target > cur) and attack or release
    return cur + (target - cur) * (1 - math.exp(-rate * dt))
end

local function spectrumColor(v)
    local th = Novier.Theme
    if v < 0.6 then return th.Accent:Lerp(th.AccentGlow, v / 0.6) end
    return th.AccentGlow:Lerp(th.SecondaryAccent, math.clamp((v - 0.6) / 0.4, 0, 1))
end

local function accentSequence()
    local th = Novier.Theme
    return ColorSequence.new({ CSK(0, th.Accent), CSK(0.33, th.AccentGlow), CSK(0.66, th.SecondaryAccent), CSK(1, th.Accent) })
end

local function pointIn(gui, p)
    local a, s = gui.AbsolutePosition, gui.AbsoluteSize
    return p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y and p.Y <= a.Y + s.Y
end

local function getGuiContainer()
    local ok = pcall(function()
        local probe = Instance.new("Folder")
        probe.Parent = CoreGui
        probe:Destroy()
    end)
    if ok then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function getPing()
    local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    return ok and v or 0
end

-- Theme engine
local function reapplyTheme()
    for i = #Bindings, 1, -1 do
        local b = Bindings[i]
        if b.inst and b.inst:IsDescendantOf(game) then
            b.inst[b.prop] = Novier.Theme[b.key]
        else
            table.remove(Bindings, i)
        end
    end
    for _, fn in ipairs(ThemeHooks) do safe(fn) end
end

function Novier:SetTheme(name)
    local preset = Novier.Themes[name]
    if not preset then return false end
    for k, v in pairs(preset) do Novier.Theme[k] = v end
    Novier.ThemeName = name
    reapplyTheme()
    return true
end

-- UI scale (phones / small windows)
local function computeScale()
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local fit = math.clamp(math.min(vp.X / 900, vp.Y / 680), 0.5, 1)
    return fit * Novier.Settings.UIScale
end

local function addScale(parent)
    local s = create("UIScale", { Scale = computeScale(), Parent = parent })
    table.insert(ScaleObjects, s)
    return s
end

local function refreshScale()
    local sc = computeScale()
    for i = #ScaleObjects, 1, -1 do
        local s = ScaleObjects[i]
        if s.Parent then s.Scale = sc else table.remove(ScaleObjects, i) end
    end
end

-- Tiny UI sound effects (off by default)
local function sfx(kind)
    if not Novier.Settings.UISounds then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxasset://sounds/switch.mp3"
        s.Volume = 0.25
        s.PlaybackSpeed = (kind == "hover") and 1.7 or 1.15
        s.Parent = SoundService
        s:Play()
        Debris:AddItem(s, 1.5)
    end)
end

-- Click ripple (button must have ClipsDescendants = true)
local function ripple(btn)
    local sc = computeScale()
    local m = UserInputService:GetMouseLocation()
    local abs, size = btn.AbsolutePosition, btn.AbsoluteSize
    local x = math.clamp((m.X - abs.X) / sc, 0, size.X / sc)
    local y = math.clamp((m.Y - abs.Y) / sc, 0, size.Y / sc)
    local d = math.max(size.X, size.Y) / sc * 2.4
    local r = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Novier.Theme.Accent,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        ZIndex = btn.ZIndex + 1,
        Parent = btn,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    tween(r, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 }, 0.5, Enum.EasingStyle.Quad)
    Debris:AddItem(r, 0.6)
end

-- Tooltips
local Tip = {}
local function buildTooltip(overlay)
    local frame = create("Frame", {
        Name = "Tooltip",
        Size = UDim2.fromOffset(0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = T("PillBackground"),
        Visible = false,
        ZIndex = 900,
        Parent = overlay,
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        create("UIStroke", { Thickness = 1, Color = T("Accent") }),
        create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
    })
    local label = create("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Font = Novier.Config.FontNormal,
        TextSize = 11,
        TextColor3 = T("TextPrimary"),
        ZIndex = 901,
        Parent = frame,
    })
    function Tip.Move()
        local m = UserInputService:GetMouseLocation()
        local cam = Workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        frame.Position = UDim2.fromOffset(
            math.min(m.X + 14, vp.X - frame.AbsoluteSize.X - 8),
            math.min(m.Y + 16, vp.Y - 32)
        )
    end
    function Tip.Show(text) label.Text = text; frame.Visible = true; Tip.Move() end
    function Tip.Hide() frame.Visible = false end
end

local function attachTooltip(gui, text)
    if not text or text == "" then return end
    local id, hovering = 0, false
    track(gui.MouseEnter:Connect(function()
        hovering = true
        id = id + 1
        local mine = id
        task.delay(0.35, function()
            if hovering and id == mine and Tip.Show then Tip.Show(text) end
        end)
    end))
    track(gui.MouseMoved:Connect(function() if Tip.Move then Tip.Move() end end))
    track(gui.MouseLeave:Connect(function()
        hovering = false
        if Tip.Hide then Tip.Hide() end
    end))
end

local function registerFlag(opts, getter, setter)
    if opts and opts.Flag then
        Novier._FlagGetters[opts.Flag] = getter
        Novier._FlagSetters[opts.Flag] = setter
    end
end

--========================================================--
-- AUDIO ANALYZER
-- Roblox only exposes Sound.PlaybackLoudness (no FFT), so we fake a believable
-- spectrum: envelope followers split "body" (bass) from "transients" (mid/high),
-- and every band is a spring that chases its own target.
--========================================================--
local BAND_COUNT = 16
local Analyzer = {}
Analyzer.__index = Analyzer

function Analyzer.new()
    local self = setmetatable({}, Analyzer)
    self.peakRef = 150
    self.level, self.slow, self.fast, self.avg, self.prev = 0, 0, 0, 0, 0
    self.bass, self.mid, self.high = 0, 0, 0
    self.beat, self.beatFired, self.lastBeat, self.bpm = 0, false, 0, 0
    self.bands, self.vel, self.peaks, self.hold = {}, {}, {}, {}
    for i = 1, BAND_COUNT do
        self.bands[i], self.vel[i], self.peaks[i], self.hold[i] = 0, 0, 0, 0
    end
    return self
end

function Analyzer:Update(dt, sound, settings)
    dt = math.clamp(dt, 1 / 240, 1 / 20)
    local now = os.clock()
    local playing = sound ~= nil and sound.IsPlaying
    local raw = playing and sound.PlaybackLoudness or 0

    local norm
    if settings.AutoGain then
        self.peakRef = math.max(self.peakRef * (1 - dt * 0.04), raw, 120)
        norm = raw / self.peakRef
    else
        norm = raw / 500
    end
    norm = math.clamp(norm * settings.Sensitivity, 0, 1.25)

    self.level = follow(self.level, norm, dt, 28, 7)
    self.slow  = follow(self.slow,  norm, dt, 5, 1.6)
    self.fast  = follow(self.fast,  norm, dt, 45, 22)
    self.avg   = follow(self.avg,   norm, dt, 1.4, 1.4)

    local flux = math.max(0, norm - self.prev) / dt -- how fast loudness is rising
    self.prev = norm

    self.bass = follow(self.bass, math.clamp(self.slow * 1.25, 0, 1), dt, 18, 5)
    self.mid  = follow(self.mid,  math.clamp((self.fast - self.slow) * 3.2 + self.slow * 0.35, 0, 1), dt, 30, 9)
    self.high = follow(self.high, math.clamp(flux / 9, 0, 1), dt, 60, 12)

    -- Beat detection: loud, above the running average, rising fast, with a cooldown
    self.beatFired = false
    if playing and norm > 0.14 and norm > self.avg * 1.22 + 0.03 and flux > 1.5 and (now - self.lastBeat) > 0.17 then
        local interval = now - self.lastBeat
        if interval > 0.25 and interval < 1.5 then
            local bpm = 60 / interval
            self.bpm = (self.bpm == 0) and bpm or (self.bpm * 0.8 + bpm * 0.2)
        end
        self.lastBeat = now
        self.beat = 1
        self.beatFired = true
    end
    self.beat = self.beat * math.exp(-dt * 6.5)
    if not playing then self.bpm = self.bpm * (1 - dt * 0.5) end

    -- Spring-driven bands
    for i = 1, BAND_COUNT do
        local f = (i - 1) / (BAND_COUNT - 1) -- 0 = bass, 1 = treble
        local lowW  = (1 - f) ^ 1.4
        local midW  = math.exp(-((f - 0.45) ^ 2) / 0.05)
        local highW = f ^ 1.3
        local drive = self.bass * lowW + self.mid * midW * 0.9 + self.high * highW * 1.1
        local wob = 0.62 + 0.38 * (0.5 + 0.5 * math.sin(now * (3.1 + i * 0.53) + i * 1.9))
        local target = drive * wob + self.beat * 0.28 * lowW
        if not playing and settings.IdleBreathing then
            target = 0.05 + 0.04 * math.sin(now * 1.3 + i * 0.6)
        end
        target = math.clamp(target * (0.85 + self.level * 0.3), 0, 1)

        local v = self.vel[i] + ((target - self.bands[i]) * 340 - self.vel[i] * 19) * dt
        local raw2 = self.bands[i] + v * dt
        local val = math.clamp(raw2, 0, 1)
        if val ~= raw2 then v = 0 end
        self.vel[i], self.bands[i] = v, val

        if val >= self.peaks[i] then
            self.peaks[i], self.hold[i] = val, 0.28
        else
            self.hold[i] = self.hold[i] - dt
            if self.hold[i] <= 0 then self.peaks[i] = math.max(val, self.peaks[i] - dt * 0.55) end
        end
    end
end

-- pos: 0 = bass ... 1 = treble (linear interpolation between bands)
function Analyzer:Sample(pos, tbl)
    tbl = tbl or self.bands
    local x = math.clamp(pos, 0, 1) * (BAND_COUNT - 1) + 1
    local lo = math.floor(x)
    local hi = math.min(lo + 1, BAND_COUNT)
    return tbl[lo] + (tbl[hi] - tbl[lo]) * (x - lo)
end

--========================================================--
-- BACKGROUND: CODE RAIN (single driver, beat-reactive)
--========================================================--
local function buildRain(gui)
    local Canvas = create("Frame", {
        Name = "CodeRain", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ZIndex = 1, ClipsDescendants = true, Active = false, Parent = gui,
    })
    local snippets = {
        "local function exec(addr)", "setreadonly(mt, false)", "bit32.bxor(a, b)",
        "task.spawn(function()", "os.clock() - tick()", "getrawmetatable(game)",
        "0x7FFD98A2B", "loadstring(bytecode)()", "math.clamp(alpha, 0, 1)",
        "run_service.Heartbeat", "debug.getinfo(1).func", "table.insert(buffers)",
        "collectgarbage('count')", "for i = 1, #stack do", "return setmetatable({}, mt)",
    }
    local N, cols = 14, {}
    for i = 1, N do
        local lines = {}
        for k = 1, 70 do lines[k] = snippets[math.random(#snippets)] end
        local label = create("TextLabel", {
            Size = UDim2.new(1 / N, 0, 1, 0),
            Position = UDim2.new((i - 1) / N, 0, -1, 0),
            BackgroundTransparency = 1,
            Text = table.concat(lines, "\n"),
            Font = Novier.Config.FontCode,
            TextSize = 10,
            TextColor3 = T("Accent"),
            TextTransparency = 0.92,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextWrapped = true,
            ZIndex = 1,
            Parent = Canvas,
        })
        cols[i] = { label = label, i = i, p = math.random(), speed = 1 / math.random(24, 44) }
    end
    local function update(dt, an)
        local boost = 1 + an.bass * 1.4
        local tr = 0.93 - an.bass * 0.07 - an.beat * 0.05
        for _, c in ipairs(cols) do
            c.p = c.p + dt * c.speed * boost
            if c.p >= 1 then c.p = c.p - 1 end
            c.label.Position = UDim2.new((c.i - 1) / N, 0, -1 + 2 * c.p, 0)
            c.label.TextTransparency = tr
        end
    end
    return { Root = Canvas, Update = update }
end

--========================================================--
-- SCREEN HUD (corner brackets)
--========================================================--
local function buildScreenHUD(gui)
    local Root = create("Frame", {
        Name = "ScreenHUD", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ZIndex = 2, Active = false, Parent = gui,
    })
    local function bracket(anchor, pos, text)
        return create("TextLabel", {
            Size = UDim2.fromOffset(240, 42), AnchorPoint = anchor, Position = pos,
            BackgroundTransparency = 1, Font = Novier.Config.FontCode, TextSize = 10,
            TextColor3 = T("Accent"), TextTransparency = 0.35,
            TextXAlignment = (anchor.X == 0) and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
            TextYAlignment = (anchor.Y == 0) and Enum.TextYAlignment.Top or Enum.TextYAlignment.Bottom,
            Text = text, ZIndex = 3, Parent = Root,
        })
    end
    return {
        Root = Root,
        TL = bracket(Vector2.new(0, 0), UDim2.fromOffset(14, 14), ""),
        TR = bracket(Vector2.new(1, 0), UDim2.new(1, -14, 0, 14), ""),
        BL = bracket(Vector2.new(0, 1), UDim2.new(0, 14, 1, -14), ""),
        BR = bracket(Vector2.new(1, 1), UDim2.new(1, -14, 1, -14), ""),
    }
end

--========================================================--
-- EDGE VISUALS: mirrored center-symmetric spectrum + glows
--========================================================--
local function buildEdgeVisuals(gui)
    local BARS = 36
    local Root = create("Frame", {
        Name = "EdgeVisuals", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ZIndex = 4, Active = false, Parent = gui,
    })

    local function makeGlow(anchor, pos, size, rot)
        local grad = create("UIGradient", { Rotation = rot, Transparency = NumberSequence.new(1) })
        local frame = create("Frame", {
            AnchorPoint = anchor, Position = pos, Size = size,
            BackgroundColor3 = Novier.Theme.Accent, BorderSizePixel = 0,
            ZIndex = 3, Active = false, Parent = Root,
        }, { grad })
        return { Frame = frame, Grad = grad, Last = -1 }
    end
    local GL = makeGlow(Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.new(0, 60, 0.9, 0), 0)
    local GR = makeGlow(Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), UDim2.new(0, 60, 0.9, 0), 180)
    local GT = makeGlow(Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.new(0.7, 0, 0, 40), 90)
    local GB = makeGlow(Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.new(0.7, 0, 0, 40), 270)

    local function setGlow(g, intensity, color)
        intensity = math.clamp(intensity, 0, 0.92)
        g.Frame.BackgroundColor3 = color
        if math.abs(intensity - g.Last) > 0.008 then
            g.Last = intensity
            g.Grad.Transparency = NumberSequence.new({ NSK(0, 1 - intensity), NSK(1, 1) })
        end
    end

    local function makeSide(isRight)
        local panel = create("Frame", {
            Name = isRight and "RightSpectrum" or "LeftSpectrum",
            AnchorPoint = Vector2.new(isRight and 1 or 0, 0.5),
            Position = UDim2.new(isRight and 1 or 0, 0, 0.5, 0),
            Size = UDim2.new(0.14, 0, 0.72, 0),
            BackgroundTransparency = 1, ZIndex = 5, Active = false, Parent = Root,
        })
        local bars, caps = {}, {}
        for j = 1, BARS do
            local y = (j - 1) / BARS
            bars[j] = create("Frame", {
                AnchorPoint = Vector2.new(isRight and 1 or 0, 0),
                Position = UDim2.new(isRight and 1 or 0, 0, y, 1),
                Size = UDim2.new(0, 3, 1 / BARS, -2),
                BackgroundColor3 = Novier.Theme.Accent, BorderSizePixel = 0, ZIndex = 5, Parent = panel,
            }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
            caps[j] = create("Frame", {
                AnchorPoint = Vector2.new(isRight and 1 or 0, 0),
                Position = UDim2.new(isRight and 1 or 0, 0, y, 1),
                Size = UDim2.new(0, 2, 1 / BARS, -2),
                BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.35,
                BorderSizePixel = 0, Visible = false, ZIndex = 6, Parent = panel,
            })
        end
        return { Panel = panel, Bars = bars, Caps = caps, Right = isRight }
    end
    local Left, Right = makeSide(false), makeSide(true)

    local function update(an)
        local th = Novier.Theme
        local glowColor = th.Accent:Lerp(th.SecondaryAccent, an.beat * 0.8)
        local side = 0.08 + an.bass * 0.5 + an.beat * 0.35
        local w = math.floor(60 + an.bass * 140 + an.beat * 70)
        GL.Frame.Size = UDim2.new(0, w, 0.9, 0)
        GR.Frame.Size = UDim2.new(0, w, 0.9, 0)
        setGlow(GL, side, glowColor)
        setGlow(GR, side, glowColor)
        local flash = an.beat * 0.55 + an.high * 0.2
        local h = math.floor(36 + an.beat * 80)
        GT.Frame.Size = UDim2.new(0.7, 0, 0, h)
        GB.Frame.Size = UDim2.new(0.7, 0, 0, h)
        setGlow(GT, flash, th.AccentGlow)
        setGlow(GB, flash, th.AccentGlow)

        for j = 1, BARS do
            local y = (j - 1) / BARS
            local c = math.abs(((j - 0.5) / BARS) * 2 - 1) -- 0 = center, 1 = edges
            local v = an:Sample(c)
            local pk = an:Sample(c, an.peaks)
            local col = spectrumColor(v)
            local trans = 0.05 + (1 - v) * 0.55
            for _, s in ipairs({ Left, Right }) do
                local bar, cap = s.Bars[j], s.Caps[j]
                bar.Size = UDim2.new(v, 3, 1 / BARS, -2)
                bar.BackgroundColor3 = col
                bar.BackgroundTransparency = trans
                if pk > v + 0.02 then
                    cap.Visible = true
                    if s.Right then
                        cap.Position = UDim2.new(1 - pk, -3, y, 1)
                    else
                        cap.Position = UDim2.new(pk, 3, y, 1)
                    end
                else
                    cap.Visible = false
                end
            end
        end
    end

    return { Root = Root, Update = update }
end

-- Expanding shockwave ring behind the pill
local function spawnRing(gui, pill, strength)
    local size, pos = pill.AbsoluteSize, pill.AbsolutePosition
    local ring = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(pos.X + size.X / 2, pos.Y + size.Y / 2),
        Size = UDim2.fromOffset(size.X, size.Y),
        BackgroundTransparency = 1, ZIndex = 60, Active = false, Parent = gui,
    }, {
        create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        create("UIStroke", { Thickness = 2, Color = Novier.Theme.Accent, Transparency = 0.35 }),
    })
    local grow = 50 + strength * 90
    tween(ring, { Size = UDim2.fromOffset(size.X + grow * 2, size.Y + grow * 0.8) }, 0.55, Enum.EasingStyle.Quad)
    tween(ring:FindFirstChildOfClass("UIStroke"), { Transparency = 1, Thickness = 0.5 }, 0.55)
    Debris:AddItem(ring, 0.65)
end

--========================================================--
-- SECTION BUILDER (all controls)
--========================================================--
local function makeRow(parent, className, height, props, padTop)
    props = props or {}
    props.Size = UDim2.new(1, 0, 0, height)
    props.BackgroundColor3 = T("SurfaceHighlight")
    props.BorderSizePixel = 0
    props.ZIndex = 16
    props.Parent = parent
    local stroke = create("UIStroke", { Thickness = 1, Color = T("BorderSubtle") })
    local inst = create(className, props, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        stroke,
        create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, padTop or 0) }),
    })
    return inst, stroke
end

local function hoverFx(btn, stroke)
    track(btn.MouseEnter:Connect(function()
        sfx("hover")
        tween(stroke, { Color = Novier.Theme.Accent }, 0.15)
    end))
    track(btn.MouseLeave:Connect(function()
        tween(stroke, { Color = Novier.Theme.BorderSubtle }, 0.15)
    end))
end

local function buildSection(parentContainer, sectionName, overlayLayer)
    local Section = {}

    local Box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T("SurfaceElevated"),
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = parentContainer,
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 12) }),
        create("UIStroke", { Thickness = 1.2, Color = T("BorderSubtle") }),
        create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
    })

    local Header = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = "// " .. string.upper(sectionName),
        Font = Novier.Config.FontBold,
        TextSize = 11,
        TextColor3 = T("Accent"),
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        ZIndex = 15,
        Parent = Box,
    })
    local Chevron = create("TextLabel", {
        Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, -16, 0, 0),
        BackgroundTransparency = 1, Text = "▾", Font = Novier.Config.FontBold, TextSize = 12,
        TextColor3 = T("TextSecondary"), ZIndex = 16, Parent = Header,
    })

    local ControlsHolder = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromOffset(0, 26),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
        Parent = Box,
    }, { create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

    local collapsed = false
    track(Header.MouseButton1Click:Connect(function()
        sfx("click")
        collapsed = not collapsed
        Chevron.Text = collapsed and "▸" or "▾"
        ControlsHolder.Visible = not collapsed
        if collapsed then
            ControlsHolder.AutomaticSize = Enum.AutomaticSize.None
            ControlsHolder.Size = UDim2.new(1, 0, 0, 0)
        else
            ControlsHolder.AutomaticSize = Enum.AutomaticSize.Y
        end
    end))

    Section.Box, Section.ControlsHolder = Box, ControlsHolder

    ---------------------------------------------------------- Button
    function Section:CreateButton(name, callback, opts)
        opts = opts or {}
        local Btn, stroke = makeRow(ControlsHolder, "TextButton", 34, {
            Text = "[ " .. name .. " ]", Font = Novier.Config.FontBold, TextSize = 12,
            TextColor3 = T("TextPrimary"), AutoButtonColor = false, ClipsDescendants = true,
        })
        hoverFx(Btn, stroke)
        track(Btn.MouseEnter:Connect(function() tween(Btn, { TextColor3 = Novier.Theme.Accent }, 0.12) end))
        track(Btn.MouseLeave:Connect(function() tween(Btn, { TextColor3 = Novier.Theme.TextPrimary }, 0.12) end))
        track(Btn.MouseButton1Click:Connect(function()
            ripple(Btn); sfx("click")
            safe(callback)
        end))
        attachTooltip(Btn, opts.Tooltip)
        return Btn
    end

    ---------------------------------------------------------- Toggle
    function Section:CreateToggle(name, default, callback, opts)
        opts = opts or {}
        local state = default or false
        local Btn, stroke = makeRow(ControlsHolder, "TextButton", 34, { Text = "", AutoButtonColor = false, ClipsDescendants = true })
        hoverFx(Btn, stroke)
        create("TextLabel", {
            Size = UDim2.new(1, -52, 1, 0), BackgroundTransparency = 1, Text = name,
            Font = Novier.Config.FontNormal, TextSize = 12, TextColor3 = T("TextPrimary"),
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 17, Parent = Btn,
        })
        local Switch = create("Frame", {
            Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -40, 0.5, -10),
            BackgroundColor3 = state and Novier.Theme.Accent or Novier.Theme.SurfaceElevated, ZIndex = 17, Parent = Btn,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Thickness = 1, Color = T("BorderSubtle") }) })
        local Dot = create("Frame", {
            Size = UDim2.fromOffset(14, 14),
            Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 18, Parent = Switch,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

        local function paint(instant)
            local d = instant and 0 or 0.16
            tween(Switch, { BackgroundColor3 = state and Novier.Theme.Accent or Novier.Theme.SurfaceElevated }, d)
            tween(Dot, { Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) }, d, Enum.EasingStyle.Back)
        end
        local function set(v, silent)
            state = v and true or false
            paint(false)
            if not silent then safe(callback, state) end
        end
        table.insert(ThemeHooks, function() paint(true) end)
        track(Btn.MouseButton1Click:Connect(function() ripple(Btn); sfx("click"); set(not state) end))
        attachTooltip(Btn, opts.Tooltip)
        registerFlag(opts, function() return state end, function(v) set(v) end)
        return { Set = function(_, v) set(v) end, Get = function() return state end }
    end

    ---------------------------------------------------------- Slider
    function Section:CreateSlider(name, min, max, default, step, callback, opts)
        opts = opts or {}
        min, max, step = min or 0, max or 100, step or 1
        local current = math.clamp(default or min, min, max)
        local decimals = 0
        local frac = tostring(step):match("%.(%d+)$")
        if frac then decimals = #frac end
        local function fmt(v)
            if decimals > 0 then return string.format("%." .. decimals .. "f", v) end
            return tostring(math.floor(v + 0.5))
        end
        local range = math.max(max - min, 1e-6)

        local Frame = makeRow(ControlsHolder, "Frame", 50, {}, 6)
        create("TextLabel", {
            Size = UDim2.new(0.7, 0, 0, 18), BackgroundTransparency = 1, Text = name,
            Font = Novier.Config.FontNormal, TextSize = 12, TextColor3 = T("TextPrimary"),
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 17, Parent = Frame,
        })
        local Readout = create("TextLabel", {
            Size = UDim2.new(0.3, 0, 0, 18), Position = UDim2.new(0.7, 0, 0, 0), BackgroundTransparency = 1,
            Text = fmt(current), Font = Novier.Config.FontBold, TextSize = 12, TextColor3 = T("Accent"),
            TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 17, Parent = Frame,
        })
        local Bar = create("Frame", {
            Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 28),
            BackgroundColor3 = T("SurfaceElevated"), BorderSizePixel = 0, ZIndex = 17, Parent = Frame,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        local Fill = create("Frame", {
            Size = UDim2.fromScale((current - min) / range, 1), BackgroundColor3 = T("Accent"),
            BorderSizePixel = 0, ZIndex = 18, Parent = Bar,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        local Knob = create("Frame", {
            Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new((current - min) / range, 0, 0.5, 0),
            BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 19, Parent = Bar,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Thickness = 1.5, Color = T("Accent") }) })
        local Hit = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 18),
            BackgroundTransparency = 1, Text = "", ZIndex = 20, Parent = Frame,
        })

        local dragging = false
        local function setVal(v, emit)
            local snapped = math.floor((v - min) / step + 0.5) * step + min
            current = math.clamp(snapped, min, max)
            local a = (current - min) / range
            tween(Fill, { Size = UDim2.fromScale(a, 1) }, 0.06, Enum.EasingStyle.Linear)
            tween(Knob, { Position = UDim2.new(a, 0, 0.5, 0) }, 0.06, Enum.EasingStyle.Linear)
            Readout.Text = fmt(current)
            if emit then safe(callback, current) end
        end
        local function fromMouse(x)
            local a = math.clamp((x - Bar.AbsolutePosition.X) / math.max(Bar.AbsoluteSize.X, 1), 0, 1)
            setVal(min + (max - min) * a, true)
        end
        track(Hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                tween(Knob, { Size = UDim2.fromOffset(18, 18) }, 0.1)
                fromMouse(input.Position.X)
            end
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                fromMouse(input.Position.X)
            end
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                dragging = false
                tween(Knob, { Size = UDim2.fromOffset(14, 14) }, 0.1)
            end
        end))
        attachTooltip(Frame, opts.Tooltip)
        registerFlag(opts, function() return current end, function(v) setVal(tonumber(v) or current, true) end)
        return { Set = function(_, v) setVal(v, true) end, Get = function() return current end }
    end

    ---------------------------------------------------------- Textbox
    function Section:CreateTextbox(name, placeholder, clearOnFocus, callback, opts)
        opts = opts or {}
        local BoxFrame, stroke = makeRow(ControlsHolder, "Frame", 36, {})
        local Input = create("TextBox", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            PlaceholderText = placeholder or "Enter text...", PlaceholderColor3 = T("TextDisabled"),
            Text = "", Font = Novier.Config.FontNormal, TextSize = 12, TextColor3 = T("TextPrimary"),
            TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = clearOnFocus or false,
            ZIndex = 17, Parent = BoxFrame,
        })
        track(Input.Focused:Connect(function() tween(stroke, { Color = Novier.Theme.Accent }, 0.15) end))
        track(Input.FocusLost:Connect(function(enter)
            tween(stroke, { Color = Novier.Theme.BorderSubtle }, 0.15)
            safe(callback, Input.Text, enter)
        end))
        attachTooltip(BoxFrame, opts.Tooltip)
        registerFlag(opts, function() return Input.Text end, function(v) Input.Text = tostring(v) end)
        return { Set = function(_, t) Input.Text = t end, Get = function() return Input.Text end }
    end

    ---------------------------------------------------------- Dropdown
    function Section:CreateDropdown(name, list, default, callback, opts)
        opts = opts or {}
        list = list or {}
        local selected = default or list[1]
        local isOpen = false

        local MainBtn, stroke = makeRow(ControlsHolder, "TextButton", 34, { Text = "", AutoButtonColor = false, ClipsDescendants = true })
        hoverFx(MainBtn, stroke)
        create("TextLabel", {
            Size = UDim2.fromScale(0.5, 1), BackgroundTransparency = 1, Text = name,
            Font = Novier.Config.FontNormal, TextSize = 12, TextColor3 = T("TextPrimary"),
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 17, Parent = MainBtn,
        })
        local SelectedLbl = create("TextLabel", {
            Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.fromScale(0.5, 0), BackgroundTransparency = 1,
            Text = tostring(selected) .. "  ▾", Font = Novier.Config.FontBold, TextSize = 12, TextColor3 = T("Accent"),
            TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 17, Parent = MainBtn,
        })
        local Menu = create("Frame", {
            Size = UDim2.fromOffset(0, 0), BackgroundColor3 = T("PillBackground"),
            ClipsDescendants = true, Visible = false, ZIndex = 501, Parent = overlayLayer,
        }, { create("UICorner", { CornerRadius = UDim.new(0, 8) }), create("UIStroke", { Thickness = 1.4, Color = T("Accent") }) })
        local Scroll = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 2,
            ScrollBarImageColor3 = T("Accent"), CanvasSize = UDim2.new(), ZIndex = 502, Parent = Menu,
        }, {
            create("UIListLayout", { Padding = UDim.new(0, 3) }),
            create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
        })

        local function closeMenu()
            isOpen = false
            Menu.Visible = false
            SelectedLbl.Text = tostring(selected) .. "  ▾"
        end
        table.insert(Novier._MenuClosers, closeMenu)

        local function choose(item, silent)
            selected = item
            SelectedLbl.Text = tostring(item) .. "  ▾"
            if not silent then safe(callback, selected) end
        end

        local function populate()
            for _, c in ipairs(Scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for _, item in ipairs(list) do
                local on = (selected == item)
                local opt = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = on and Novier.Theme.SurfaceHighlight or Novier.Theme.SurfaceElevated,
                    Text = tostring(item), Font = Novier.Config.FontNormal, TextSize = 11,
                    TextColor3 = on and Novier.Theme.Accent or Novier.Theme.TextPrimary,
                    AutoButtonColor = false, ZIndex = 503, Parent = Scroll,
                }, { create("UICorner", { CornerRadius = UDim.new(0, 5) }) })
                track(opt.MouseEnter:Connect(function() tween(opt, { BackgroundColor3 = Novier.Theme.SurfaceHighlight }, 0.1) end))
                track(opt.MouseLeave:Connect(function()
                    tween(opt, { BackgroundColor3 = (selected == item) and Novier.Theme.SurfaceHighlight or Novier.Theme.SurfaceElevated }, 0.1)
                end))
                track(opt.MouseButton1Click:Connect(function()
                    sfx("click"); choose(item); closeMenu()
                end))
            end
            Scroll.CanvasSize = UDim2.fromOffset(0, #list * 29 + 8)
        end

        track(MainBtn.MouseButton1Click:Connect(function()
            sfx("click")
            if isOpen then closeMenu() return end
            isOpen = true
            populate()
            local absPos, absSize = MainBtn.AbsolutePosition, MainBtn.AbsoluteSize
            Menu.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
            Menu.Size = UDim2.fromOffset(absSize.X, math.clamp(#list * 29 + 10, 30, 170))
            Menu.Visible = true
            SelectedLbl.Text = tostring(selected) .. "  ▴"
        end))
        track(UserInputService.InputBegan:Connect(function(input)
            if isOpen and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                local m = UserInputService:GetMouseLocation()
                if not pointIn(Menu, m) and not pointIn(MainBtn, m) then closeMenu() end
            end
        end))
        attachTooltip(MainBtn, opts.Tooltip)
        registerFlag(opts, function() return selected end, function(v) choose(v) end)
        return {
            Set = function(_, v) choose(v, true) end,
            Get = function() return selected end,
            Refresh = function(_, newList, keep)
                list = newList or {}
                if not (keep and table.find(list, selected)) then selected = list[1] end
                SelectedLbl.Text = tostring(selected) .. "  ▾"
            end,
        }
    end

    ---------------------------------------------------------- Keybind
    function Section:CreateKeybind(name, default, onPress, opts)
        opts = opts or {}
        local key, listening = default, false
        local Btn, stroke = makeRow(ControlsHolder, "TextButton", 34, { Text = "", AutoButtonColor = false, ClipsDescendants = true })
        hoverFx(Btn, stroke)
        create("TextLabel", {
            Size = UDim2.fromScale(0.55, 1), BackgroundTransparency = 1, Text = name,
            Font = Novier.Config.FontNormal, TextSize = 12, TextColor3 = T("TextPrimary"),
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 17, Parent = Btn,
        })
        local KeyLbl = create("TextLabel", {
            Size = UDim2.fromScale(0.45, 1), Position = UDim2.fromScale(0.55, 0), BackgroundTransparency = 1,
            Text = "", Font = Novier.Config.FontCode, TextSize = 12, TextColor3 = T("Accent"),
            TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 17, Parent = Btn,
        })
        local function show()
            KeyLbl.Text = listening and "press a key... (Bksp = clear)" or ("[ " .. (key and key.Name or "NONE") .. " ]")
        end
        show()
        track(Btn.MouseButton1Click:Connect(function()
            ripple(Btn); sfx("click")
            listening = true
            Novier._listening = true
            show()
        end))
        track(UserInputService.InputBegan:Connect(function(input, processed)
            if listening then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    Novier._listening = false
                    Novier._listenStamp = os.clock()
                    if input.KeyCode == Enum.KeyCode.Backspace then key = nil
                    elseif input.KeyCode ~= Enum.KeyCode.Escape then key = input.KeyCode end
                    show()
                    safe(opts.OnChanged, key)
                end
            elseif not processed and key and input.KeyCode == key then
                safe(onPress, key)
            end
        end))
        attachTooltip(Btn, opts.Tooltip)
        registerFlag(opts, function() return key and key.Name or "" end, function(v)
            key = Enum.KeyCode[tostring(v)]
            show()
            safe(opts.OnChanged, key)
        end)
        return { Set = function(_, k) key = k; show() end, Get = function() return key end }
    end

    ---------------------------------------------------------- Terminal
    function Section:CreateTerminal(height)
        local TermFrame = makeRow(ControlsHolder, "Frame", height or 130, {})
        TermFrame.BackgroundColor3 = Color3.fromRGB(6, 7, 10)
        local TermScroll = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 3,
            ScrollBarImageColor3 = T("Accent"), CanvasSize = UDim2.new(), ZIndex = 17, Parent = TermFrame,
        })
        local Layout = create("UIListLayout", { Padding = UDim.new(0, 3), Parent = TermScroll })
        local count = 0
        local function append(msg, color)
            count = count + 1
            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
                Text = string.format("[%s] > %s", os.date("%X"), tostring(msg)),
                Font = Novier.Config.FontCode, TextSize = 11, TextColor3 = color or Novier.Theme.TextTerminal,
                TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = count, ZIndex = 18, Parent = TermScroll,
            })
            if count > 150 then
                local oldest
                for _, c in ipairs(TermScroll:GetChildren()) do
                    if c:IsA("TextLabel") and (not oldest or c.LayoutOrder < oldest.LayoutOrder) then oldest = c end
                end
                if oldest then oldest:Destroy() end
            end
            TermScroll.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + 16)
            TermScroll.CanvasPosition = Vector2.new(0, math.max(0, Layout.AbsoluteContentSize.Y))
        end
        append("SUB-MODULE ONLINE.", Novier.Theme.Accent)
        return {
            Log   = function(_, m) append(m, Novier.Theme.TextTerminal) end,
            Warn  = function(_, m) append(m, Novier.Theme.Warning) end,
            Error = function(_, m) append(m, Novier.Theme.Error) end,
            Clear = function(_)
                for _, c in ipairs(TermScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
                TermScroll.CanvasSize = UDim2.new()
                count = 0
            end,
        }
    end

    ---------------------------------------------------------- Label / Separator
    function Section:CreateLabel(text)
        local L = create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            Text = text, TextWrapped = true, Font = Novier.Config.FontNormal, TextSize = 12,
            TextColor3 = T("TextSecondary"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 16, Parent = ControlsHolder,
        })
        return { Set = function(_, t) L.Text = t end }
    end

    function Section:CreateSeparator()
        create("Frame", {
            Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T("BorderSubtle"),
            BorderSizePixel = 0, BackgroundTransparency = 0.3, ZIndex = 16, Parent = ControlsHolder,
        })
    end

    return Section
end

--========================================================--
-- CONFIG (needs executor filesystem functions)
--========================================================--
local function hasFS()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function configPath(name)
    name = tostring(name or "default"):gsub("[^%w_%-]", "")
    if name == "" then name = "default" end
    return Novier.Config.ConfigFolder .. "/" .. name .. ".json"
end

function Novier:SaveConfig(name)
    if not hasFS() then return false, "filesystem functions unavailable" end
    local data = {}
    for flag, getter in pairs(Novier._FlagGetters) do
        local ok, v = pcall(getter)
        if ok and (type(v) == "number" or type(v) == "string" or type(v) == "boolean") then data[flag] = v end
    end
    pcall(function()
        if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder(Novier.Config.ConfigFolder) then
            makefolder(Novier.Config.ConfigFolder)
        end
    end)
    local ok, err = pcall(function() writefile(configPath(name), HttpService:JSONEncode(data)) end)
    return ok, err
end

function Novier:LoadConfig(name)
    if not hasFS() then return false, "filesystem functions unavailable" end
    local path = configPath(name)
    if not isfile(path) then return false, "config not found" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then return false, "config corrupted" end
    for flag, value in pairs(data) do
        local setter = Novier._FlagSetters[flag]
        if setter then pcall(setter, value) end
    end
    return true
end

--========================================================--
-- WINDOW
--========================================================--
function Novier:CreateWindow(windowTitle)
    if Novier._Gui then Novier:Destroy() end

    local Window = {
        Tabs = {}, ActiveTab = nil, IsOpen = true, DrawerOpen = false,
        ToggleKey = Novier.Config.DefaultToggleKey, FovKey = Novier.Config.DefaultFovKey,
        _tickers = {}, _beatListeners = {},
    }

    local Gui = create("ScreenGui", {
        Name = "Novier_Pill_Island", ResetOnSpawn = false, DisplayOrder = 9999,
        IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = getGuiContainer(),
    })
    Novier._Gui = Gui

    local Rain = buildRain(Gui)
    local HUD = buildScreenHUD(Gui)
    local Edges = buildEdgeVisuals(Gui)

    local OverlayLayer = create("Frame", {
        Name = "OverlayLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 500, Active = false, Parent = Gui,
    })
    buildTooltip(OverlayLayer)

    local cfg = Novier.Config
    local function pillCloseY() return -(cfg.PillHeight * computeScale()) - 20 end
    local pillOpenPos = UDim2.new(0.5, 0, 0, 16)
    local function pillClosePos() return UDim2.new(0.5, 0, 0, pillCloseY()) end
    local function drawerOpenPos() return UDim2.new(0.5, 0, 0, math.floor(16 + cfg.PillHeight * computeScale() + 10)) end
    local function drawerClosePos() return UDim2.new(0.5, 0, 0, math.floor(cfg.PillHeight * computeScale() - 10)) end

    ------------------------------------------------ THE PILL
    local PillStroke = create("UIStroke", {
        Name = "PillStroke", Thickness = 1.6, Color = Color3.new(1, 1, 1),
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    local PillGradient = create("UIGradient", { Color = accentSequence(), Parent = PillStroke })

    local Pill = create("Frame", {
        Name = "PillBar",
        Size = UDim2.fromOffset(cfg.PillHeight, cfg.PillHeight), -- grows in the intro animation
        Position = pillOpenPos,
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = T("PillBackground"),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = Gui,
    }, {
        create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        PillStroke,
        create("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
    })
    addScale(Pill)

    -- Brand
    local BrandHolder = create("Frame", {
        Size = UDim2.new(0, 160, 1, 0), BackgroundTransparency = 1, ZIndex = 101, Parent = Pill,
    }, { create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8) }) })
    create("TextLabel", {
        Size = UDim2.fromOffset(26, 26), BackgroundColor3 = T("SurfaceElevated"), Text = "⚡",
        Font = Novier.Config.FontBold, TextSize = 13, TextColor3 = T("Accent"), ZIndex = 102, Parent = BrandHolder,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Thickness = 1, Color = T("Accent") }) })
    create("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0), BackgroundTransparency = 1,
        Text = string.upper(windowTitle or "NOVIER // ISLAND"), Font = Novier.Config.FontBold, TextSize = 12,
        TextColor3 = T("TextPrimary"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102, Parent = BrandHolder,
    })

    -- Live stats (FPS / ping)
    local StatsLabel = create("TextLabel", {
        Size = UDim2.new(0, 120, 1, 0), Position = UDim2.fromOffset(176, 0), BackgroundTransparency = 1,
        Text = "", Font = Novier.Config.FontCode, TextSize = 10, TextColor3 = T("TextSecondary"),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102, Parent = Pill,
    })

    -- Center visualizer
    local VisualizerHolder = create("Frame", {
        Name = "PillVisualizer", Size = UDim2.fromOffset(140, 24), Position = UDim2.new(0.5, -70, 0.5, -12),
        BackgroundTransparency = 1, ZIndex = 101, Parent = Pill,
    }, { create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 2) }) })
    local VisualizerBars = {}
    for i = 1, 16 do
        VisualizerBars[i] = create("Frame", {
            Size = UDim2.fromOffset(3, 4), BackgroundColor3 = Novier.Theme.Accent, BorderSizePixel = 0, ZIndex = 102, Parent = VisualizerHolder,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    end

    -- Tab bar
    local TabBar = create("Frame", {
        Size = UDim2.new(0.48, 0, 1, 0), Position = UDim2.new(0.52, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 101, Parent = Pill,
    }, { create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6) }) })

    ------------------------------------------------ DRAWER
    local DrawerStroke = create("UIStroke", { Thickness = 1.4, Color = T("BorderSubtle") })
    local Drawer = create("Frame", {
        Name = "PillDrawer",
        Size = UDim2.fromOffset(cfg.DrawerWidth, cfg.DrawerHeight),
        Position = drawerClosePos(),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = T("DrawerBackground"),
        BorderSizePixel = 0, ClipsDescendants = true, Visible = false, ZIndex = 10, Parent = Gui,
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 16) }),
        DrawerStroke,
        create("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16) }),
    })
    addScale(Drawer)

    -- Touch users have no keyboard: floating toggle button
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        local TouchBtn = create("TextButton", {
            Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = T("PillBackground"), Text = "⚡", Font = Novier.Config.FontBold, TextSize = 18,
            TextColor3 = T("Accent"), AutoButtonColor = false, ZIndex = 300, Parent = Gui,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Thickness = 1.5, Color = T("Accent") }) })
        track(TouchBtn.MouseButton1Click:Connect(function() Window:SetVisible() end))
    end

    ------------------------------------------------ AUDIO + BLUR
    local ActiveSound = create("Sound", {
        Name = "NovierAudioStream", Volume = 0.5, Looped = true, SoundId = "rbxassetid://9043887091", Parent = SoundService,
    })
    Window.Sound = ActiveSound

    local An = Analyzer.new()
    Window.Analyzer = An

    local Blur
    pcall(function()
        Blur = Lighting:FindFirstChild("NovierBlur") or create("BlurEffect", { Name = "NovierBlur", Size = 0, Parent = Lighting })
    end)
    Novier._Blur = Blur

    ------------------------------------------------ MAIN LOOP
    local acc, hudAcc, fpsAcc, fpsFrames = 0, 0, 0, 0
    local fps, ping = 60, 0
    local fovOffset, fovActive = 0, false
    local FOV = Novier.FOVConfig

    table.insert(ThemeHooks, function() PillGradient.Color = accentSequence() end)

    track(RunService.RenderStepped:Connect(function(dt)
        -- FPS meter
        fpsAcc = fpsAcc + dt
        fpsFrames = fpsFrames + 1
        if fpsAcc >= 0.5 then fps = fpsFrames / fpsAcc; fpsAcc, fpsFrames = 0, 0 end

        -- Beat-synced FOV kick (only touches the camera while active / easing out)
        local cam = Workspace.CurrentCamera
        if cam then
            if FOV.Enabled and ActiveSound.IsPlaying then
                local target = FOV.MaxKick * (An.bass * 0.75 + An.beat * 0.25)
                local a = 1 - (1 - FOV.Smoothness) ^ (dt * 60)
                fovOffset = fovOffset + (target - fovOffset) * a
                fovActive = true
                cam.FieldOfView = FOV.BaseFOV + fovOffset
            elseif fovActive then
                fovOffset = fovOffset * (1 - math.min(1, dt * 8))
                if fovOffset < 0.02 then
                    fovOffset, fovActive = 0, false
                    cam.FieldOfView = FOV.BaseFOV
                else
                    cam.FieldOfView = FOV.BaseFOV + fovOffset
                end
            end
        end

        -- Visual update throttle
        acc = acc + dt
        if acc < 1 / math.max(20, Novier.Settings.VisualHz) then return end
        local vdt = acc
        acc = 0

        An:Update(vdt, ActiveSound, Novier.Settings)
        local S = Novier.Settings
        local th = Novier.Theme

        if An.beatFired then
            for _, fn in ipairs(Window._beatListeners) do safe(fn, An.beat, An.bpm) end
            if S.Rings and Window.IsOpen then spawnRing(Gui, Pill, An.bass) end
        end

        -- Layers
        if Rain.Root.Visible ~= S.Rain then Rain.Root.Visible = S.Rain end
        if S.Rain then Rain.Update(vdt, An) end
        if Edges.Root.Visible ~= S.EdgeVisuals then Edges.Root.Visible = S.EdgeVisuals end
        if S.EdgeVisuals then Edges.Update(An) end

        -- Pill border: rotating gradient, speed & thickness ride the music
        PillGradient.Rotation = (PillGradient.Rotation + vdt * (35 + An.bass * 260 + An.beat * 180)) % 360
        PillStroke.Thickness = 1.6 + An.bass * 1.4 + An.beat * 0.9
        if Window.DrawerOpen then
            DrawerStroke.Color = th.BorderSubtle:Lerp(th.Accent, math.clamp(An.bass * 0.7 + An.beat * 0.3, 0, 1))
        end

        -- Pill mini waveform (center-symmetric, same source as the edges)
        for i, bar in ipairs(VisualizerBars) do
            local c = math.abs(((i - 0.5) / 16) * 2 - 1)
            local v = An:Sample(c)
            bar.Size = UDim2.fromOffset(3, math.max(3, math.floor(3 + v * 21)))
            bar.BackgroundColor3 = spectrumColor(v)
        end

        -- HUD + stats at 4 Hz
        hudAcc = hudAcc + vdt
        if hudAcc >= 0.25 then
            hudAcc = 0
            ping = getPing()
            StatsLabel.Visible = S.ShowStats
            StatsLabel.Text = string.format("%d FPS · %dms", fps, ping)

            local meter = math.clamp(math.floor(An.level * 8 + 0.5), 0, 8)
            HUD.TL.Text = "┌── [ISLAND: DYNAMIC]\n│ THEME: " .. string.upper(Novier.ThemeName)
            HUD.TR.Text = "[NOVIER // ZERO-DAY] ──┐\nBPM " .. (An.bpm > 1 and tostring(math.floor(An.bpm + 0.5)) or "--") .. " │"
            HUD.BR.Text = string.format("LVL %s%s\n%d FPS │ %dms ──┘", string.rep("▮", meter), string.rep("▯", 8 - meter), fps, ping)
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local p = hrp.Position
                HUD.BL.Text = string.format("│ POS: %.1f, %.1f, %.1f\n└── [BEAT FOV: %s]", p.X, p.Y, p.Z, FOV.Enabled and "ON" or "OFF")
            else
                HUD.BL.Text = "│ POS: --\n└── [BEAT FOV: " .. (FOV.Enabled and "ON" or "OFF") .. "]"
            end
            for _, fn in ipairs(Window._tickers) do safe(fn, An, fps, ping) end
        end
    end))

    track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refreshScale))
    do
        local cam = Workspace.CurrentCamera
        if cam then track(cam:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)) end
    end

    ------------------------------------------------ VISIBILITY / DRAWER
    function Window:SetVisible(state)
        if state == nil then state = not Window.IsOpen end
        Window.IsOpen = state
        if state then
            Pill.Visible = true
            tween(Pill, { Position = pillOpenPos }, 0.32, Enum.EasingStyle.Back)
        else
            Window:CloseDrawer()
            tween(Pill, { Position = pillClosePos() }, 0.22).Completed:Connect(function()
                if not Window.IsOpen then Pill.Visible = false end
            end)
        end
    end

    function Window:OpenDrawer()
        Window.DrawerOpen = true
        Drawer.Visible = true
        Drawer.Position = drawerClosePos()
        tween(Drawer, { Position = drawerOpenPos() }, 0.3, Enum.EasingStyle.Back)
        if Blur and Novier.Settings.Blur then tween(Blur, { Size = 12 }, 0.3) end
    end

    function Window:CloseDrawer()
        Window.DrawerOpen = false
        for _, closer in ipairs(Novier._MenuClosers) do pcall(closer) end
        for _, t in ipairs(Window.Tabs) do
            t.Page.Visible = false
            t:_paint(false)
        end
        if Blur then tween(Blur, { Size = 0 }, 0.25) end
        DrawerStroke.Color = Novier.Theme.BorderSubtle
        local tw = tween(Drawer, { Position = drawerClosePos() }, 0.22)
        tw.Completed:Connect(function()
            if not Window.DrawerOpen then Drawer.Visible = false end
        end)
    end

    function Window:SetToggleKey(k) Window.ToggleKey = k end
    function Window:SetFovKey(k) Window.FovKey = k end
    function Window:OnBeat(fn) table.insert(Window._beatListeners, fn) end
    function Window:AddTicker(fn) table.insert(Window._tickers, fn) end -- fn(analyzer, fps, ping) @ 4 Hz
    function Window:Destroy() Novier:Destroy() end

    track(UserInputService.InputBegan:Connect(function(input, processed)
        if processed or Novier._listening then return end
        if os.clock() - (Novier._listenStamp or 0) < 0.2 then return end -- key was just captured by a Keybind
        if input.KeyCode == Window.ToggleKey then
            Window:SetVisible()
        elseif input.KeyCode == Window.FovKey then
            FOV.Enabled = not FOV.Enabled
            Novier:Notify("Beat FOV", FOV.Enabled and "Camera kick activated." or "Camera kick deactivated.", 2, FOV.Enabled and "Success" or "Warning")
        end
    end))

    ------------------------------------------------ TABS
    function Window:CreateTab(tabName, iconSymbol)
        local Tab = { Active = false }
        local displayText = (iconSymbol and iconSymbol ~= "") and (iconSymbol .. " " .. tabName) or tabName

        local TabBtn = create("TextButton", {
            Name = tabName .. "_Tab", Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Novier.Theme.SurfaceElevated, Text = displayText, Font = Novier.Config.FontBold,
            TextSize = 11, TextColor3 = Novier.Theme.TextSecondary, AutoButtonColor = false,
            ClipsDescendants = true, ZIndex = 102, Parent = TabBar,
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            create("UIStroke", { Thickness = 1, Color = T("BorderSubtle") }),
            create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
        })

        local PageLayout = create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
        local Page = create("ScrollingFrame", {
            Name = tabName .. "_Page", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            ScrollBarThickness = 4, ScrollBarImageColor3 = T("Accent"), CanvasSize = UDim2.new(),
            Visible = false, ZIndex = 13, ClipsDescendants = true, Parent = Drawer,
        }, { PageLayout, create("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 14) }) })
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.fromOffset(0, PageLayout.AbsoluteContentSize.Y + 24)
        end)

        function Tab:_paint(active, instant)
            Tab.Active = active
            tween(TabBtn, {
                BackgroundColor3 = active and Novier.Theme.SurfaceHighlight or Novier.Theme.SurfaceElevated,
                TextColor3 = active and Novier.Theme.Accent or Novier.Theme.TextSecondary,
            }, instant and 0 or 0.15)
        end
        table.insert(ThemeHooks, function() Tab:_paint(Tab.Active, true) end)

        track(TabBtn.MouseEnter:Connect(function()
            sfx("hover")
            if not Tab.Active then tween(TabBtn, { TextColor3 = Novier.Theme.TextPrimary }, 0.12) end
        end))
        track(TabBtn.MouseLeave:Connect(function()
            if not Tab.Active then tween(TabBtn, { TextColor3 = Novier.Theme.TextSecondary }, 0.12) end
        end))

        local function selectTab()
            ripple(TabBtn); sfx("click")
            if Window.ActiveTab == Tab and Window.DrawerOpen then
                Window:CloseDrawer()
                Window.ActiveTab = nil
                return
            end
            for _, t in ipairs(Window.Tabs) do t.Page.Visible = false; t:_paint(false) end
            Page.Visible = true
            Window.ActiveTab = Tab
            Tab:_paint(true)
            if not Window.DrawerOpen then Window:OpenDrawer() end
        end
        track(TabBtn.MouseButton1Click:Connect(selectTab))

        Tab.Button, Tab.Page = TabBtn, Page
        table.insert(Window.Tabs, Tab)

        function Tab:CreateSection(sectionName)
            return buildSection(Page, sectionName, OverlayLayer)
        end

        -- Scrolling sub-tabs (unlimited players / pages)
        function Tab:CreateSubTabs(initialList)
            local SubTabSystem = { SubTabs = {}, ActiveSubTab = nil }

            local BarLayout = create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
            local SubTabBar = create("ScrollingFrame", {
                Name = "SubTabBar", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1,
                ScrollBarThickness = 3, ScrollBarImageColor3 = T("Accent"),
                ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.new(),
                ZIndex = 14, ClipsDescendants = true, Parent = Page,
            }, { BarLayout, create("UIPadding", { PaddingBottom = UDim.new(0, 4) }) })
            BarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SubTabBar.CanvasSize = UDim2.fromOffset(BarLayout.AbsoluteContentSize.X + 24, 0)
            end)

            local SubPageHolder = create("Frame", {
                Name = "SubPageHolder", Size = UDim2.new(1, 0, 0, 480), BackgroundTransparency = 1, ZIndex = 13, Parent = Page,
            })

            local function paintSub(sub, active, instant)
                sub.Active = active
                tween(sub.Button, {
                    BackgroundColor3 = active and Novier.Theme.SurfaceHighlight or Novier.Theme.SurfaceElevated,
                    TextColor3 = active and Novier.Theme.Accent or Novier.Theme.TextSecondary,
                }, instant and 0 or 0.12)
            end

            function SubTabSystem:AddSubTab(subName, icon)
                if SubTabSystem.SubTabs[subName] then return SubTabSystem.SubTabs[subName] end
                local SubTab = { Active = false }
                local label = (icon and icon ~= "") and (icon .. " " .. subName) or subName

                local SubBtn = create("TextButton", {
                    Name = subName .. "_SubBtn", Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = Novier.Theme.SurfaceElevated, Text = label, Font = Novier.Config.FontBold,
                    TextSize = 10, TextColor3 = Novier.Theme.TextSecondary, AutoButtonColor = false,
                    ClipsDescendants = true, ZIndex = 15, Parent = SubTabBar,
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    create("UIStroke", { Thickness = 1, Color = T("BorderSubtle") }),
                    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
                })

                local SubLayout = create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
                local SubPage = create("ScrollingFrame", {
                    Name = subName .. "_SubPage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
                    ScrollBarThickness = 3, ScrollBarImageColor3 = T("Accent"), CanvasSize = UDim2.new(),
                    Visible = false, ZIndex = 13, ClipsDescendants = true, Parent = SubPageHolder,
                }, { SubLayout, create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10) }) })
                SubLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    SubPage.CanvasSize = UDim2.fromOffset(0, SubLayout.AbsoluteContentSize.Y + 20)
                end)

                SubTab.Button, SubTab.Page = SubBtn, SubPage
                table.insert(ThemeHooks, function()
                    if SubBtn.Parent then paintSub(SubTab, SubTab.Active, true) end
                end)

                local function activate()
                    for _, s in pairs(SubTabSystem.SubTabs) do s.Page.Visible = false; paintSub(s, false) end
                    SubPage.Visible = true
                    SubTabSystem.ActiveSubTab = SubTab
                    paintSub(SubTab, true)
                    -- keep the active pill in view
                    local x = SubBtn.AbsolutePosition.X - SubTabBar.AbsolutePosition.X + SubTabBar.CanvasPosition.X
                    SubTabBar.CanvasPosition = Vector2.new(math.max(0, x - 40), 0)
                end
                track(SubBtn.MouseButton1Click:Connect(function() ripple(SubBtn); sfx("click"); activate() end))

                function SubTab:CreateSection(secName) return buildSection(SubPage, secName, OverlayLayer) end

                SubTabSystem.SubTabs[subName] = SubTab
                if not SubTabSystem.ActiveSubTab then activate() end
                return SubTab
            end

            function SubTabSystem:RemoveSubTab(subName)
                local sub = SubTabSystem.SubTabs[subName]
                if not sub then return end
                sub.Button:Destroy()
                sub.Page:Destroy()
                SubTabSystem.SubTabs[subName] = nil
                if SubTabSystem.ActiveSubTab == sub then
                    SubTabSystem.ActiveSubTab = nil
                    for _, nextSub in pairs(SubTabSystem.SubTabs) do
                        nextSub.Page.Visible = true
                        SubTabSystem.ActiveSubTab = nextSub
                        paintSub(nextSub, true)
                        break
                    end
                end
            end

            function SubTabSystem:ClearSubTabs()
                for _, sub in pairs(SubTabSystem.SubTabs) do sub.Button:Destroy(); sub.Page:Destroy() end
                table.clear(SubTabSystem.SubTabs)
                SubTabSystem.ActiveSubTab = nil
            end

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

    ------------------------------------------------ MEDIA SUITE
    function Window:CreateMediaSuite(defaultTrackTable)
        local tracks = defaultTrackTable or {
            ["Synth Loop"]        = "rbxassetid://9043887091",
            ["Action Electronic"] = "rbxassetid://1840590064",
            ["Dark Cyber"]        = "rbxassetid://1843404009",
        }
        local nowPlaying = "—"

        local MediaTab = Window:CreateTab("MEDIA", "♫")
        local MediaSec = MediaTab:CreateSection("Audio Stream Controller")
        local NowLabel = MediaSec:CreateLabel("♫ —")

        local trackNames = {}
        for name in pairs(tracks) do table.insert(trackNames, name) end
        table.sort(trackNames)

        MediaSec:CreateDropdown("Tracks", trackNames, trackNames[1], function(chosen)
            ActiveSound.SoundId = tracks[chosen]
            ActiveSound.TimePosition = 0
            ActiveSound:Play()
            nowPlaying = chosen
            Novier:Notify("Audio Driver", "Stream: " .. chosen, 2, "Success")
        end, { Flag = "media_track" })

        MediaSec:CreateButton("Play / Pause", function()
            if ActiveSound.IsPlaying then ActiveSound:Pause()
            elseif ActiveSound.IsPaused then ActiveSound:Resume()
            else ActiveSound:Play() end
        end)

        MediaSec:CreateSlider("Master Volume", 0, 200, 50, 1, function(val)
            ActiveSound.Volume = val / 100
        end, { Flag = "media_volume", Tooltip = "Above 100% boosts the stream" })

        local FovSec = MediaTab:CreateSection("Beat-Synchronized Camera FOV")
        local fovToggle = FovSec:CreateToggle("Audio Beat FOV  ([RightAlt])", FOV.Enabled, function(active)
            FOV.Enabled = active
            Novier:Notify("Camera Engine", active and "Beat FOV kick enabled." or "Beat FOV disabled.", 2, active and "Success" or "Warning")
        end, { Flag = "fov_enabled" })
        FovSec:CreateSlider("Base FOV", 50, 110, FOV.BaseFOV, 1, function(val)
            FOV.BaseFOV = val
            local cam = Workspace.CurrentCamera
            if not FOV.Enabled and cam then cam.FieldOfView = val end
        end, { Flag = "fov_base" })
        FovSec:CreateSlider("Beat Kick Intensity", 5, 45, FOV.MaxKick, 1, function(val) FOV.MaxKick = val end, { Flag = "fov_kick" })
        FovSec:CreateSlider("Kick Smoothness", 5, 60, math.floor(FOV.Smoothness * 100), 1, function(val) FOV.Smoothness = val / 100 end, {
            Flag = "fov_smooth", Tooltip = "Higher = snappier camera",
        })

        local CustomSec = MediaTab:CreateSection("Custom Sound ID")
        local Term = CustomSec:CreateTerminal(80)
        CustomSec:CreateTextbox("Audio ID", "Paste numeric ID...", false, function(txt, enter)
            if enter and txt and #txt > 0 then
                local cleanId = txt:gsub("%D", "")
                if #cleanId > 0 then
                    ActiveSound.SoundId = "rbxassetid://" .. cleanId
                    ActiveSound.TimePosition = 0
                    ActiveSound:Play()
                    nowPlaying = "ID " .. cleanId
                    Term:Log("Mounted sound: " .. cleanId)
                    Novier:Notify("Audio", "Playing ID: " .. cleanId, 2, "Success")
                end
            end
        end)

        local function clock(sec) return string.format("%d:%02d", math.floor(sec / 60), math.floor(sec % 60)) end
        Window:AddTicker(function(an)
            local len = ActiveSound.TimeLength
            local stamp = (len and len > 0) and (clock(ActiveSound.TimePosition) .. " / " .. clock(len)) or "--:--"
            NowLabel:Set(string.format("♫ %s   |   %s   |   BPM %s   |   LVL %d%%", nowPlaying, stamp,
                an.bpm > 1 and tostring(math.floor(an.bpm + 0.5)) or "--", math.floor(an.level * 100)))
        end)

        return {
            PlayCustom = function(_, id)
                local cleanId = tostring(id):gsub("%D", "")
                ActiveSound.SoundId = "rbxassetid://" .. cleanId
                ActiveSound.TimePosition = 0
                ActiveSound:Play()
                nowPlaying = "ID " .. cleanId
            end,
            FovToggle = fovToggle,
        }
    end

    ------------------------------------------------ SETTINGS TAB
    function Window:CreateSettingsTab()
        local S = Novier.Settings
        local Tab = Window:CreateTab("SETTINGS", "⚙")

        local Look = Tab:CreateSection("Appearance")
        local themeNames = {}
        for n in pairs(Novier.Themes) do table.insert(themeNames, n) end
        table.sort(themeNames)
        Look:CreateDropdown("Theme", themeNames, Novier.ThemeName, function(n) Novier:SetTheme(n) end, { Flag = "ui_theme" })
        Look:CreateSlider("UI Scale", 60, 130, math.floor(S.UIScale * 100), 5, function(v)
            S.UIScale = v / 100
            refreshScale()
        end, { Flag = "ui_scale", Tooltip = "Scales the whole island (phones: try 70%)" })
        Look:CreateToggle("Show FPS / Ping in pill", S.ShowStats, function(v) S.ShowStats = v end, { Flag = "ui_stats" })
        Look:CreateToggle("Background Blur when open", S.Blur, function(v)
            S.Blur = v
            if Blur then tween(Blur, { Size = (v and Window.DrawerOpen) and 12 or 0 }, 0.25) end
        end, { Flag = "ui_blur" })
        Look:CreateToggle("UI Sounds", S.UISounds, function(v) S.UISounds = v end, { Flag = "ui_sfx" })

        local Vis = Tab:CreateSection("Visuals")
        Vis:CreateToggle("Edge Spectrum & Glows", S.EdgeVisuals, function(v) S.EdgeVisuals = v end, { Flag = "vis_edges" })
        Vis:CreateToggle("Code Rain", S.Rain, function(v) S.Rain = v end, { Flag = "vis_rain" })
        Vis:CreateToggle("Beat Shockwave Rings", S.Rings, function(v) S.Rings = v end, { Flag = "vis_rings" })
        Vis:CreateToggle("Idle Breathing (no music)", S.IdleBreathing, function(v) S.IdleBreathing = v end, { Flag = "vis_idle" })
        Vis:CreateSlider("Visual FPS Cap", 20, 144, S.VisualHz, 1, function(v) S.VisualHz = v end, {
            Flag = "vis_hz", Tooltip = "Lower this if the visuals cost you frames",
        })

        local Aud = Tab:CreateSection("Audio Reactivity")
        Aud:CreateSlider("Sensitivity", 0.3, 2.5, S.Sensitivity, 0.05, function(v) S.Sensitivity = v end, { Flag = "aud_sens" })
        Aud:CreateToggle("Auto Gain", S.AutoGain, function(v) S.AutoGain = v end, {
            Flag = "aud_gain", Tooltip = "Normalises quiet & loud tracks so visuals always look full",
        })

        local Keys = Tab:CreateSection("Keybinds")
        Keys:CreateKeybind("Toggle UI", Window.ToggleKey, nil, { Flag = "key_toggle", OnChanged = function(k) if k then Window.ToggleKey = k end end })
        Keys:CreateKeybind("Beat FOV", Window.FovKey, nil, { Flag = "key_fov", OnChanged = function(k) if k then Window.FovKey = k end end })

        local Cfg = Tab:CreateSection("Config")
        local cfgName = "default"
        Cfg:CreateTextbox("Config name", "default", false, function(t) if t and #t > 0 then cfgName = t end end)
        Cfg:CreateButton("Save Config", function()
            local ok, err = Novier:SaveConfig(cfgName)
            Novier:Notify("Config", ok and ("Saved '" .. cfgName .. "'") or ("Save failed: " .. tostring(err)), 2.5, ok and "Success" or "Error")
        end)
        Cfg:CreateButton("Load Config", function()
            local ok, err = Novier:LoadConfig(cfgName)
            Novier:Notify("Config", ok and ("Loaded '" .. cfgName .. "'") or ("Load failed: " .. tostring(err)), 2.5, ok and "Success" or "Error")
        end)
        return Tab
    end

    ------------------------------------------------ INTRO ANIMATION
    Drawer.Visible = false
    task.defer(function()
        tween(Pill, { Size = UDim2.fromOffset(cfg.PillWidth, cfg.PillHeight) }, 0.7, Enum.EasingStyle.Back)
    end)

    return Window
end

--========================================================--
-- NOTIFICATIONS
--========================================================--
function Novier:Notify(title, message, duration, kind)
    if not Novier._Gui then return end
    duration = duration or 3

    local Holder = Novier._Gui:FindFirstChild("NotifyStack")
    if not Holder then
        Holder = create("Frame", {
            Name = "NotifyStack", Size = UDim2.fromOffset(300, 460), Position = UDim2.new(1, -16, 1, -24),
            AnchorPoint = Vector2.new(1, 1), BackgroundTransparency = 1, ZIndex = 500, Parent = Novier._Gui,
        }, {
            create("UIListLayout", {
                VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        addScale(Holder)
    end

    local th = Novier.Theme
    local edge = (kind == "Success" and th.Success) or (kind == "Warning" and th.Warning) or (kind == "Error" and th.Error) or th.Accent
    local icon = (kind == "Success" and "✓") or (kind == "Warning" and "!") or (kind == "Error" and "✕") or "◆"

    -- The slot is what UIListLayout positions; the card inside it is what we tween.
    local Slot = create("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, ZIndex = 501, Parent = Holder })
    local Card = create("Frame", {
        Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(1.3, 0),
        BackgroundColor3 = th.PillBackground, ClipsDescendants = true, ZIndex = 501, Parent = Slot,
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        create("UIStroke", { Thickness = 1.3, Color = edge }),
    })
    create("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = edge, BorderSizePixel = 0, ZIndex = 502, Parent = Card })
    create("TextLabel", {
        Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(12, 10), BackgroundColor3 = edge, BackgroundTransparency = 0.82,
        Text = icon, Font = Novier.Config.FontBold, TextSize = 14, TextColor3 = edge, ZIndex = 502, Parent = Card,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 16), Position = UDim2.fromOffset(50, 8), BackgroundTransparency = 1,
        Text = string.upper(tostring(title)), Font = Novier.Config.FontBold, TextSize = 11, TextColor3 = edge,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 502, Parent = Card,
    })
    create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 28), Position = UDim2.fromOffset(50, 24), BackgroundTransparency = 1,
        Text = tostring(message), Font = Novier.Config.FontNormal, TextSize = 11, TextColor3 = th.TextPrimary,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 502, Parent = Card,
    })
    local Progress = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = edge,
        BorderSizePixel = 0, ZIndex = 503, Parent = Card,
    })

    tween(Card, { Position = UDim2.fromScale(0, 0) }, 0.3, Enum.EasingStyle.Back)
    tween(Progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        if not (Card and Card.Parent) then return end
        tween(Card, { Position = UDim2.fromScale(1.3, 0) }, 0.22).Completed:Connect(function()
            if Slot and Slot.Parent then
                tween(Slot, { Size = UDim2.new(1, 0, 0, 0) }, 0.15).Completed:Connect(function() Slot:Destroy() end)
            end
        end)
    end)
end

--========================================================--
-- CLEANUP
--========================================================--
function Novier:Destroy()
    for _, conn in ipairs(Novier._Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(Novier._Connections)
    table.clear(Novier._FlagSetters)
    table.clear(Novier._FlagGetters)
    table.clear(Novier._MenuClosers)
    table.clear(Bindings)
    table.clear(ThemeHooks)
    table.clear(ScaleObjects)
    Novier._listening = false

    local s = SoundService:FindFirstChild("NovierAudioStream")
    if s then s:Destroy() end
    if Novier._Blur then pcall(function() Novier._Blur:Destroy() end); Novier._Blur = nil end

    local cam = Workspace.CurrentCamera
    if cam then cam.FieldOfView = Novier.FOVConfig.BaseFOV end
    if Novier._Gui then Novier._Gui:Destroy(); Novier._Gui = nil end
end

return Novier

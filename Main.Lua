--[[
    NOVIER // DYNAMIC ISLAND & CAPSULE ENGINE  (V6.0 "GNOME")

    WHAT'S NEW IN 6.0
    - THEME FAMILIES: a theme now changes the whole look, not just colors
        Adwaita  -> GNOME / libadwaita: boxed lists, flat rows, soft radii, calm pulse, no rain/HUD
        Cyber    -> the original neon look: bracket buttons, "//" titles, rain, HUD
        Terminal -> monospace, square corners, "$ title", rain + HUD
      20 themes: Adwaita Dark/Light + 7 accents, Catppuccin, Nord, Dracula, Gruvbox, Tokyo Night,
      Rose Pine, Neon, Sakura, Sunset, Glacier, Matrix, Amber.  Live-switch: Novier:SetTheme(name)
    - Tab bar is now a scroller with arrow buttons on the right (no more overlapping the synth)
    - Drawer got a GNOME-style header bar (title + close button)
    - Section:CreatePlayerList(cfg) / Tab:CreatePlayerList(cfg): dynamic, searchable, expandable player
      list with avatars that refreshes on join/leave AND every time its tab is opened
    - Tab:OnOpen(fn) / SubTab:OnOpen(fn): run code whenever a tab is opened (dynamic tabs)
    - ClearSubTabs(keepNames) can keep specific sub-tabs
    - Media suite rebuilt: now-playing card with art pulse, mini spectrum, seekable progress bar,
      prev/play/next/loop, boxed track library
    - Edge spectrum is smaller (Settings: Edge Size, Pulse Strength); pulse rings/glows/border kept
    - Theme swatch grid in Settings, Section:CreateCustom(height) for your own widgets

    QUICK START
        local Novier = loadstring(game:HttpGet("YOUR_URL"))()
        local Win = Novier:CreateWindow("NOVIER // ISLAND")
        Win:CreateMediaSuite()
        local Tab = Win:CreateTab("MAIN", "⚡")
        local Sec = Tab:CreateSection("Movement")
        Sec:CreateToggle("Speed", false, function(on) end, { Flag = "speed", Tooltip = "Go fast" })
        Win:CreatePlayersTab({ Actions = { {"Teleport", function(plr) end} } })
        Win:CreateSettingsTab()

    Default keys: [RightControl] toggle UI, [RightAlt] toggle beat FOV
]]

local Novier = {}
Novier.__index = Novier
Novier.Version = "6.0.0 GNOME"

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
local Fnt = Enum.Font

--========================================================--
-- THEMES  (colors + a "Family" that decides the look)
--========================================================--
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local BASE_THEME = { -- Neon (Cyber) is the default color base
    PillBackground = rgb(10, 12, 17), DrawerBackground = rgb(13, 16, 22), HeaderBackground = rgb(13, 16, 22),
    SurfaceElevated = rgb(21, 26, 37), SurfaceHighlight = rgb(32, 40, 56), Divider = rgb(45, 55, 75),
    Accent = rgb(0, 255, 170), AccentGlow = rgb(0, 235, 255), SecondaryAccent = rgb(255, 0, 110), AccentText = rgb(8, 10, 14),
    TextPrimary = rgb(255, 255, 255), TextSecondary = rgb(180, 195, 210), TextTerminal = rgb(0, 255, 170), TextDisabled = rgb(115, 130, 145),
    Border = rgb(0, 255, 170), BorderSubtle = rgb(45, 55, 75),
    Success = rgb(0, 255, 128), Warning = rgb(255, 204, 0), Error = rgb(255, 60, 90),
}

local ADW_BASE = { -- libadwaita dark palette
    PillBackground = rgb(18, 18, 18), DrawerBackground = rgb(36, 36, 36), HeaderBackground = rgb(46, 46, 46),
    SurfaceElevated = rgb(50, 50, 50), SurfaceHighlight = rgb(68, 68, 68), Divider = rgb(64, 64, 64),
    Accent = rgb(98, 160, 234), AccentGlow = rgb(153, 193, 241), SecondaryAccent = rgb(192, 216, 246), AccentText = rgb(255, 255, 255),
    TextPrimary = rgb(255, 255, 255), TextSecondary = rgb(178, 178, 176), TextTerminal = rgb(255, 255, 255), TextDisabled = rgb(125, 125, 130),
    Border = rgb(98, 160, 234), BorderSubtle = rgb(64, 64, 64),
    Success = rgb(143, 240, 164), Warning = rgb(248, 228, 92), Error = rgb(255, 123, 99),
}

local function build(family, base, o)
    o = o or {}
    local t = {}
    for k, v in pairs(base) do t[k] = v end
    for k, v in pairs(o) do t[k] = v end
    t.Family = family
    if o.Accent and not o.Border then t.Border = t.Accent end
    if o.Accent and family ~= "Adwaita" and not o.TextTerminal then t.TextTerminal = t.Accent end
    if o.DrawerBackground and not o.HeaderBackground then t.HeaderBackground = t.DrawerBackground end
    if o.BorderSubtle and not o.Divider then t.Divider = t.BorderSubtle end
    return t
end
local function adw(o) return build("Adwaita", ADW_BASE, o) end
local function cyber(o) return build("Cyber", BASE_THEME, o) end
local function term(o) return build("Terminal", BASE_THEME, o) end

Novier.Themes = {
    -- GNOME / Adwaita family
    ["Adwaita Dark"]   = adw({}),
    ["Adwaita Light"]  = adw({
        PillBackground = rgb(246, 245, 244), DrawerBackground = rgb(250, 250, 250), HeaderBackground = rgb(235, 235, 235),
        SurfaceElevated = rgb(255, 255, 255), SurfaceHighlight = rgb(236, 236, 236), Divider = rgb(224, 224, 224),
        Accent = rgb(53, 132, 228), AccentGlow = rgb(98, 160, 234), SecondaryAccent = rgb(153, 193, 241),
        TextPrimary = rgb(46, 52, 54), TextSecondary = rgb(100, 104, 108), TextTerminal = rgb(46, 52, 54), TextDisabled = rgb(160, 160, 165),
        BorderSubtle = rgb(216, 216, 216), Success = rgb(38, 162, 105), Warning = rgb(205, 147, 9), Error = rgb(224, 27, 36),
    }),
    ["Adwaita Purple"] = adw({ Accent = rgb(200, 120, 220), AccentGlow = rgb(220, 138, 221), SecondaryAccent = rgb(246, 190, 246) }),
    ["Adwaita Teal"]   = adw({ Accent = rgb(64, 186, 190), AccentGlow = rgb(147, 221, 194), SecondaryAccent = rgb(190, 240, 225), AccentText = rgb(12, 36, 38) }),
    ["Adwaita Green"]  = adw({ Accent = rgb(80, 200, 130), AccentGlow = rgb(143, 240, 164), SecondaryAccent = rgb(200, 250, 210), AccentText = rgb(10, 40, 22) }),
    ["Adwaita Orange"] = adw({ Accent = rgb(255, 140, 60), AccentGlow = rgb(255, 163, 72), SecondaryAccent = rgb(255, 205, 150), AccentText = rgb(50, 22, 0) }),
    ["Adwaita Pink"]   = adw({ Accent = rgb(240, 110, 170), AccentGlow = rgb(250, 150, 195), SecondaryAccent = rgb(255, 200, 225) }),
    ["Adwaita Red"]    = adw({ Accent = rgb(240, 100, 90), AccentGlow = rgb(255, 130, 110), SecondaryAccent = rgb(255, 190, 170) }),
    ["Catppuccin"]     = adw({
        PillBackground = rgb(17, 17, 27), DrawerBackground = rgb(30, 30, 46), HeaderBackground = rgb(24, 24, 37),
        SurfaceElevated = rgb(42, 43, 60), SurfaceHighlight = rgb(69, 71, 90), Divider = rgb(60, 62, 80),
        Accent = rgb(203, 166, 247), AccentGlow = rgb(245, 194, 231), SecondaryAccent = rgb(180, 190, 254), AccentText = rgb(30, 30, 46),
        TextPrimary = rgb(205, 214, 244), TextSecondary = rgb(166, 173, 200), TextTerminal = rgb(205, 214, 244), TextDisabled = rgb(108, 112, 134),
        BorderSubtle = rgb(60, 62, 80), Success = rgb(166, 227, 161), Warning = rgb(249, 226, 175), Error = rgb(243, 139, 168),
    }),
    ["Nord"]           = adw({
        PillBackground = rgb(36, 41, 51), DrawerBackground = rgb(46, 52, 64), HeaderBackground = rgb(52, 58, 73),
        SurfaceElevated = rgb(59, 66, 82), SurfaceHighlight = rgb(67, 76, 94), Divider = rgb(72, 80, 98),
        Accent = rgb(136, 192, 208), AccentGlow = rgb(143, 188, 187), SecondaryAccent = rgb(129, 161, 193), AccentText = rgb(46, 52, 64),
        TextPrimary = rgb(236, 239, 244), TextSecondary = rgb(170, 178, 192), TextTerminal = rgb(236, 239, 244), TextDisabled = rgb(110, 120, 138),
        BorderSubtle = rgb(72, 80, 98), Success = rgb(163, 190, 140), Warning = rgb(235, 203, 139), Error = rgb(191, 97, 106),
    }),
    ["Dracula"]        = adw({
        PillBackground = rgb(30, 31, 41), DrawerBackground = rgb(40, 42, 54), HeaderBackground = rgb(33, 34, 44),
        SurfaceElevated = rgb(48, 50, 66), SurfaceHighlight = rgb(68, 71, 90), Divider = rgb(62, 65, 84),
        Accent = rgb(189, 147, 249), AccentGlow = rgb(255, 121, 198), SecondaryAccent = rgb(139, 233, 253), AccentText = rgb(40, 42, 54),
        TextPrimary = rgb(248, 248, 242), TextSecondary = rgb(170, 175, 205), TextTerminal = rgb(248, 248, 242), TextDisabled = rgb(98, 114, 164),
        BorderSubtle = rgb(62, 65, 84), Success = rgb(80, 250, 123), Warning = rgb(241, 250, 140), Error = rgb(255, 85, 85),
    }),
    ["Gruvbox"]        = adw({
        PillBackground = rgb(29, 32, 33), DrawerBackground = rgb(40, 40, 40), HeaderBackground = rgb(50, 48, 47),
        SurfaceElevated = rgb(60, 56, 54), SurfaceHighlight = rgb(80, 73, 69), Divider = rgb(76, 70, 66),
        Accent = rgb(250, 189, 47), AccentGlow = rgb(254, 128, 25), SecondaryAccent = rgb(211, 134, 155), AccentText = rgb(40, 40, 40),
        TextPrimary = rgb(235, 219, 178), TextSecondary = rgb(189, 174, 147), TextTerminal = rgb(235, 219, 178), TextDisabled = rgb(146, 131, 116),
        BorderSubtle = rgb(76, 70, 66), Success = rgb(184, 187, 38), Warning = rgb(250, 189, 47), Error = rgb(251, 73, 52),
    }),
    ["Tokyo Night"]    = adw({
        PillBackground = rgb(22, 22, 30), DrawerBackground = rgb(26, 27, 38), HeaderBackground = rgb(31, 35, 53),
        SurfaceElevated = rgb(36, 40, 59), SurfaceHighlight = rgb(52, 59, 88), Divider = rgb(47, 53, 80),
        Accent = rgb(122, 162, 247), AccentGlow = rgb(125, 207, 255), SecondaryAccent = rgb(187, 154, 247), AccentText = rgb(26, 27, 38),
        TextPrimary = rgb(192, 202, 245), TextSecondary = rgb(154, 165, 206), TextTerminal = rgb(192, 202, 245), TextDisabled = rgb(86, 95, 137),
        BorderSubtle = rgb(47, 53, 80), Success = rgb(158, 206, 106), Warning = rgb(224, 175, 104), Error = rgb(247, 118, 142),
    }),
    ["Rose Pine"]      = adw({
        PillBackground = rgb(16, 15, 24), DrawerBackground = rgb(25, 23, 36), HeaderBackground = rgb(31, 29, 46),
        SurfaceElevated = rgb(38, 35, 58), SurfaceHighlight = rgb(57, 53, 82), Divider = rgb(52, 48, 74),
        Accent = rgb(196, 167, 231), AccentGlow = rgb(235, 188, 186), SecondaryAccent = rgb(156, 207, 216), AccentText = rgb(25, 23, 36),
        TextPrimary = rgb(224, 222, 244), TextSecondary = rgb(144, 140, 170), TextTerminal = rgb(224, 222, 244), TextDisabled = rgb(110, 106, 134),
        BorderSubtle = rgb(52, 48, 74), Success = rgb(156, 207, 216), Warning = rgb(246, 193, 119), Error = rgb(235, 111, 146),
    }),
    -- Cyber family (the original neon look)
    ["Neon"]    = cyber({}),
    ["Sakura"]  = cyber({
        PillBackground = rgb(17, 11, 20), DrawerBackground = rgb(21, 14, 26), SurfaceElevated = rgb(34, 22, 40), SurfaceHighlight = rgb(50, 32, 58),
        Accent = rgb(255, 120, 200), AccentGlow = rgb(200, 140, 255), SecondaryAccent = rgb(120, 220, 255), BorderSubtle = rgb(70, 48, 82),
    }),
    ["Sunset"]  = cyber({
        PillBackground = rgb(18, 11, 10), DrawerBackground = rgb(23, 14, 12), SurfaceElevated = rgb(38, 24, 20), SurfaceHighlight = rgb(56, 36, 28),
        Accent = rgb(255, 150, 60), AccentGlow = rgb(255, 210, 90), SecondaryAccent = rgb(255, 60, 110), BorderSubtle = rgb(80, 52, 40),
    }),
    ["Glacier"] = cyber({
        PillBackground = rgb(9, 13, 20), DrawerBackground = rgb(11, 17, 27), SurfaceElevated = rgb(18, 28, 44), SurfaceHighlight = rgb(28, 44, 68),
        Accent = rgb(90, 180, 255), AccentGlow = rgb(140, 240, 255), SecondaryAccent = rgb(170, 120, 255), BorderSubtle = rgb(38, 58, 88),
    }),
    -- Terminal family (monospace, square, matrix rain)
    ["Matrix"]  = term({
        PillBackground = rgb(4, 10, 6), DrawerBackground = rgb(6, 14, 9), SurfaceElevated = rgb(10, 24, 15), SurfaceHighlight = rgb(16, 38, 24),
        Accent = rgb(60, 255, 90), AccentGlow = rgb(170, 255, 120), SecondaryAccent = rgb(255, 230, 80), BorderSubtle = rgb(24, 64, 38),
    }),
    ["Amber"]   = term({
        PillBackground = rgb(14, 9, 3), DrawerBackground = rgb(20, 13, 4), SurfaceElevated = rgb(34, 22, 8), SurfaceHighlight = rgb(54, 36, 12),
        Accent = rgb(255, 176, 0), AccentGlow = rgb(255, 214, 102), SecondaryAccent = rgb(255, 94, 0), BorderSubtle = rgb(80, 54, 16),
        TextPrimary = rgb(255, 224, 160), TextSecondary = rgb(200, 160, 100),
    }),
}

--[[ Style families: how things LOOK (radii, spacing, fonts, decoration) ]]
local FAMILIES = {
    Adwaita = {
        Font = Fnt.Ubuntu, FontBold = Fnt.Ubuntu, FontCode = Fnt.RobotoMono,
        TextSize = 14, SmallSize = 12, TitleSize = 15,
        CardRadius = 14, RowRadius = 0, ButtonRadius = 10, InputRadius = 9, DrawerRadius = 18, PillRadius = 999,
        RowExtra = 14, RowGap = 0, CardPad = 0, RowFlat = true, RowStroke = 0, CardStroke = 1, DrawerStroke = 1, Dividers = true,
        TitlePrefix = "", Upper = false, TitleAccent = false, Brackets = false, ButtonChevron = true, ButtonAlign = "Left",
        TabFlat = true, TabAccent = false, Pulse = 0.6, EdgeRound = true, Rain = false, HUD = false, PillStroke = 1.2,
        Ripple = false, BrandIcon = "✦",
    },
    Cyber = {
        Font = Fnt.GothamMedium, FontBold = Fnt.GothamBold, FontCode = Fnt.Code,
        TextSize = 12, SmallSize = 10, TitleSize = 11,
        CardRadius = 12, RowRadius = 8, ButtonRadius = 8, InputRadius = 8, DrawerRadius = 16, PillRadius = 999,
        RowExtra = 0, RowGap = 8, CardPad = 12, RowFlat = false, RowStroke = 1, CardStroke = 1.2, DrawerStroke = 1.4, Dividers = false,
        TitlePrefix = "// ", Upper = true, TitleAccent = true, Brackets = true, ButtonChevron = false, ButtonAlign = "Center",
        TabFlat = false, TabAccent = true, Pulse = 1, EdgeRound = true, Rain = true, HUD = true, PillStroke = 1.6,
        Ripple = true, BrandIcon = "⚡",
    },
    Terminal = {
        Font = Fnt.Code, FontBold = Fnt.Code, FontCode = Fnt.Code,
        TextSize = 12, SmallSize = 11, TitleSize = 12,
        CardRadius = 3, RowRadius = 2, ButtonRadius = 2, InputRadius = 2, DrawerRadius = 4, PillRadius = 8,
        RowExtra = 0, RowGap = 4, CardPad = 8, RowFlat = false, RowStroke = 1, CardStroke = 1, DrawerStroke = 1, Dividers = false,
        TitlePrefix = "$ ", Upper = false, TitleAccent = true, Brackets = true, ButtonChevron = false, ButtonAlign = "Center",
        TabFlat = false, TabAccent = true, Pulse = 1.15, EdgeRound = false, Rain = true, HUD = true, PillStroke = 1,
        Ripple = true, BrandIcon = ">_",
    },
}

Novier.Theme, Novier.Style = {}, {}
Novier.ThemeName = "Adwaita Dark"

local function applyPreset(name)
    local preset = Novier.Themes[name]
    if not preset then return false end
    local fam = FAMILIES[preset.Family or "Cyber"] or FAMILIES.Cyber
    for k, v in pairs(BASE_THEME) do Novier.Theme[k] = v end
    for k, v in pairs(preset) do
        if type(v) ~= "string" then Novier.Theme[k] = v end
    end
    for k, v in pairs(fam) do Novier.Style[k] = v end
    Novier.Style.Family = preset.Family or "Cyber"
    Novier.ThemeName = name
    return true
end
applyPreset("Adwaita Dark")

function Novier:AddTheme(name, colors, family)
    family = family or "Cyber"
    local base = (family == "Adwaita" and Novier.Themes["Adwaita Dark"]) or (family == "Terminal" and Novier.Themes["Matrix"]) or Novier.Themes["Neon"]
    local t = {}
    for k, v in pairs(base) do t[k] = v end
    for k, v in pairs(colors or {}) do t[k] = v end
    t.Family = family
    Novier.Themes[name] = t
    return t
end

Novier.Config = {
    PillWidth        = 820,
    PillHeight       = 46,
    DrawerWidth      = 760,
    DrawerHeight     = 500,
    DefaultToggleKey = Enum.KeyCode.RightControl,
    DefaultFovKey    = Enum.KeyCode.RightAlt,
    ConfigFolder     = "Novier",
}

Novier.Settings = {
    EdgeVisuals = true, Rain = Novier.Style.Rain, Rings = true, Blur = true,
    IdleBreathing = true, UISounds = false, ShowStats = true, AutoGain = true,
    Sensitivity = 1, VisualHz = 60, UIScale = 1, EdgeSize = 1, Pulse = 1,
}

Novier.FOVConfig = { Enabled = false, BaseFOV = 70, MaxKick = 24, Smoothness = 0.18 }

Novier._Connections = {}
Novier._FlagSetters = {}
Novier._FlagGetters = {}
Novier._MenuClosers = {}
local Bindings, ThemeHooks, ScaleObjects = {}, {}, {}

--========================================================--
-- CORE HELPERS
-- Property markers: T("Key") = theme color, S("Key") = style value, F(fn) = fn(theme, style)
-- create() binds them, so SetTheme re-colors AND re-styles everything live.
--========================================================--
local function T(key) return { __theme = key } end
local function S(key) return { __style = key } end
local function F(fn) return { __fn = fn } end
local function rad(key) return F(function(_, s) return UDim.new(0, s[key]) end) end
local function tsize(delta) return F(function(_, s) return s.TextSize + (delta or 0) end) end

local function create(className, properties, children)
    local inst = Instance.new(className)
    local parent
    for prop, val in pairs(properties or {}) do
        if prop == "Parent" then
            parent = val
        else
            if type(val) == "table" then
                if val.__theme then
                    table.insert(Bindings, { inst = inst, prop = prop, kind = "theme", ref = val.__theme })
                    val = Novier.Theme[val.__theme]
                elseif val.__style then
                    table.insert(Bindings, { inst = inst, prop = prop, kind = "style", ref = val.__style })
                    val = Novier.Style[val.__style]
                elseif val.__fn then
                    table.insert(Bindings, { inst = inst, prop = prop, kind = "fn", ref = val.__fn })
                    val = val.__fn(Novier.Theme, Novier.Style)
                end
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

local function resolveBinding(b)
    if b.kind == "theme" then return Novier.Theme[b.ref] end
    if b.kind == "style" then return Novier.Style[b.ref] end
    return b.ref(Novier.Theme, Novier.Style)
end

local function reapplyTheme()
    for i = #Bindings, 1, -1 do
        local b = Bindings[i]
        if b.inst and b.inst:IsDescendantOf(game) then
            pcall(function() b.inst[b.prop] = resolveBinding(b) end)
        else
            table.remove(Bindings, i)
        end
    end
    for _, fn in ipairs(ThemeHooks) do safe(fn) end
end

function Novier:SetTheme(name)
    local prevFamily = Novier.Style.Family
    if not applyPreset(name) then return false end
    if Novier.Style.Family ~= prevFamily then -- new family: adopt its default for code rain
        local set = Novier._FlagSetters["vis_rain"]
        if set then pcall(set, Novier.Style.Rain) else Novier.Settings.Rain = Novier.Style.Rain end
    end
    reapplyTheme()
    return true
end

-- UI scale (phones / small windows)
local function computeScale()
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local fit = math.clamp(math.min(vp.X / 900, vp.Y / 660), 0.5, 1)
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

-- Click ripple (only in families with Ripple = true; button needs ClipsDescendants)
local function ripple(btn)
    if not Novier.Style.Ripple then return end
    local sc = computeScale()
    local m = UserInputService:GetMouseLocation()
    local abs, size = btn.AbsolutePosition, btn.AbsoluteSize
    local x = math.clamp((m.X - abs.X) / sc, 0, size.X / sc)
    local y = math.clamp((m.Y - abs.Y) / sc, 0, size.Y / sc)
    local d = math.max(size.X, size.Y) / sc * 2.4
    local r = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Novier.Theme.Accent, BackgroundTransparency = 0.7, BorderSizePixel = 0,
        ZIndex = btn.ZIndex + 1, Parent = btn,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    tween(r, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 }, 0.5, Enum.EasingStyle.Quad)
    Debris:AddItem(r, 0.6)
end

-- Tooltips
local Tip = {}
local function buildTooltip(overlay)
    local frame = create("Frame", {
        Name = "Tooltip", Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = T("PillBackground"), Visible = false, ZIndex = 900, Parent = overlay,
    }, {
        create("UICorner", { CornerRadius = rad("InputRadius") }),
        create("UIStroke", { Thickness = 1, Color = T("BorderSubtle") }),
        create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
    })
    local label = create("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
        Font = S("Font"), TextSize = tsize(-1), TextColor3 = T("TextPrimary"), ZIndex = 901, Parent = frame,
    })
    function Tip.Move()
        local m = UserInputService:GetMouseLocation()
        local cam = Workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        frame.Position = UDim2.fromOffset(
            math.min(m.X + 14, vp.X - frame.AbsoluteSize.X - 8),
            math.min(m.Y + 16, vp.Y - 34)
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
-- Roblox only exposes Sound.PlaybackLoudness (no FFT), so the spectrum is synthesized:
-- envelope followers split body (bass) from transients (mid/high); each band is a spring.
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

    local flux = math.max(0, norm - self.prev) / dt
    self.prev = norm

    self.bass = follow(self.bass, math.clamp(self.slow * 1.25, 0, 1), dt, 18, 5)
    self.mid  = follow(self.mid,  math.clamp((self.fast - self.slow) * 3.2 + self.slow * 0.35, 0, 1), dt, 30, 9)
    self.high = follow(self.high, math.clamp(flux / 9, 0, 1), dt, 60, 12)

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

    for i = 1, BAND_COUNT do
        local f = (i - 1) / (BAND_COUNT - 1)
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

function Analyzer:Sample(pos, tbl)
    tbl = tbl or self.bands
    local x = math.clamp(pos, 0, 1) * (BAND_COUNT - 1) + 1
    local lo = math.floor(x)
    local hi = math.min(lo + 1, BAND_COUNT)
    return tbl[lo] + (tbl[hi] - tbl[lo]) * (x - lo)
end

--========================================================--
-- BACKGROUND LAYERS
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
            Size = UDim2.new(1 / N, 0, 1, 0), Position = UDim2.new((i - 1) / N, 0, -1, 0),
            BackgroundTransparency = 1, Text = table.concat(lines, "\n"), Font = S("FontCode"), TextSize = 10,
            TextColor3 = T("Accent"), TextTransparency = 0.92, TextYAlignment = Enum.TextYAlignment.Top,
            TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, ZIndex = 1, Parent = Canvas,
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

local function buildScreenHUD(gui)
    local Root = create("Frame", {
        Name = "ScreenHUD", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ZIndex = 2, Active = false, Parent = gui,
    })
    local function bracket(anchor, pos)
        return create("TextLabel", {
            Size = UDim2.fromOffset(240, 42), AnchorPoint = anchor, Position = pos, BackgroundTransparency = 1,
            Font = S("FontCode"), TextSize = 10, TextColor3 = T("Accent"), TextTransparency = 0.35,
            TextXAlignment = (anchor.X == 0) and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
            TextYAlignment = (anchor.Y == 0) and Enum.TextYAlignment.Top or Enum.TextYAlignment.Bottom,
            Text = "", ZIndex = 3, Parent = Root,
        })
    end
    return {
        Root = Root,
        TL = bracket(Vector2.new(0, 0), UDim2.fromOffset(14, 14)),
        TR = bracket(Vector2.new(1, 0), UDim2.new(1, -14, 0, 14)),
        BL = bracket(Vector2.new(0, 1), UDim2.new(0, 14, 1, -14)),
        BR = bracket(Vector2.new(1, 1), UDim2.new(1, -14, 1, -14)),
    }
end

--========================================================--
-- EDGE VISUALS (smaller than v5): mirrored, center-symmetric spectrum + soft glows
--========================================================--
local function buildEdgeVisuals(gui)
    local BARS = 26
    local BASE_W, BASE_H = 0.055, 0.48
    local Root = create("Frame", {
        Name = "EdgeVisuals", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ZIndex = 4, Active = false, Parent = gui,
    })

    local function makeGlow(anchor, pos, size, rot)
        local grad = create("UIGradient", { Rotation = rot, Transparency = NumberSequence.new(1) })
        local frame = create("Frame", {
            AnchorPoint = anchor, Position = pos, Size = size, BackgroundColor3 = Novier.Theme.Accent,
            BorderSizePixel = 0, ZIndex = 3, Active = false, Parent = Root,
        }, { grad })
        return { Frame = frame, Grad = grad, Last = -1 }
    end
    local GL = makeGlow(Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.new(0, 40, 0.8, 0), 0)
    local GR = makeGlow(Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), UDim2.new(0, 40, 0.8, 0), 180)
    local GT = makeGlow(Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.new(0.5, 0, 0, 26), 90)
    local GB = makeGlow(Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.new(0.5, 0, 0, 26), 270)

    local function setGlow(g, intensity, color)
        intensity = math.clamp(intensity, 0, 0.8)
        g.Frame.BackgroundColor3 = color
        if math.abs(intensity - g.Last) > 0.008 then
            g.Last = intensity
            g.Grad.Transparency = NumberSequence.new({ NSK(0, 1 - intensity), NSK(1, 1) })
        end
    end

    local function makeSide(isRight)
        local panel = create("Frame", {
            Name = isRight and "RightSpectrum" or "LeftSpectrum",
            AnchorPoint = Vector2.new(isRight and 1 or 0, 0.5), Position = UDim2.new(isRight and 1 or 0, 0, 0.5, 0),
            Size = UDim2.new(BASE_W, 0, BASE_H, 0), BackgroundTransparency = 1, ZIndex = 5, Active = false, Parent = Root,
        })
        local bars, caps = {}, {}
        for j = 1, BARS do
            local y = (j - 1) / BARS
            bars[j] = create("Frame", {
                AnchorPoint = Vector2.new(isRight and 1 or 0, 0), Position = UDim2.new(isRight and 1 or 0, 0, y, 1),
                Size = UDim2.new(0, 2, 1 / BARS, -2), BackgroundColor3 = Novier.Theme.Accent, BorderSizePixel = 0,
                ZIndex = 5, Parent = panel,
            }, { create("UICorner", { CornerRadius = F(function(_, s) return UDim.new(s.EdgeRound and 1 or 0, 0) end) }) })
            caps[j] = create("Frame", {
                AnchorPoint = Vector2.new(isRight and 1 or 0, 0), Position = UDim2.new(isRight and 1 or 0, 0, y, 1),
                Size = UDim2.new(0, 2, 1 / BARS, -2), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.4,
                BorderSizePixel = 0, Visible = false, ZIndex = 6, Parent = panel,
            })
        end
        return { Panel = panel, Bars = bars, Caps = caps, Right = isRight, LastW = BASE_W }
    end
    local Left, Right = makeSide(false), makeSide(true)

    local function update(an, pulse, edgeScale)
        local th = Novier.Theme
        local glowColor = th.Accent:Lerp(th.SecondaryAccent, an.beat * 0.7)
        local side = (0.05 + an.bass * 0.3 + an.beat * 0.22) * pulse
        local w = math.floor(36 + an.bass * 60 + an.beat * 34)
        GL.Frame.Size = UDim2.new(0, w, 0.8, 0)
        GR.Frame.Size = UDim2.new(0, w, 0.8, 0)
        setGlow(GL, side, glowColor)
        setGlow(GR, side, glowColor)
        local flash = (an.beat * 0.4 + an.high * 0.12) * pulse
        local h = math.floor(24 + an.beat * 40)
        GT.Frame.Size = UDim2.new(0.5, 0, 0, h)
        GB.Frame.Size = UDim2.new(0.5, 0, 0, h)
        setGlow(GT, flash, th.AccentGlow)
        setGlow(GB, flash, th.AccentGlow)

        local pw = BASE_W * edgeScale
        for _, s in ipairs({ Left, Right }) do
            if math.abs(s.LastW - pw) > 0.0005 then
                s.LastW = pw
                s.Panel.Size = UDim2.new(pw, 0, BASE_H, 0)
            end
        end

        for j = 1, BARS do
            local y = (j - 1) / BARS
            local c = math.abs(((j - 0.5) / BARS) * 2 - 1)
            local v = an:Sample(c)
            local pk = an:Sample(c, an.peaks)
            local col = spectrumColor(v)
            local trans = 0.08 + (1 - v) * 0.55
            for _, s in ipairs({ Left, Right }) do
                local bar, cap = s.Bars[j], s.Caps[j]
                bar.Size = UDim2.new(v, 2, 1 / BARS, -2)
                bar.BackgroundColor3 = col
                bar.BackgroundTransparency = trans
                if pk > v + 0.02 then
                    cap.Visible = true
                    if s.Right then cap.Position = UDim2.new(1 - pk, -3, y, 1)
                    else cap.Position = UDim2.new(pk, 3, y, 1) end
                else
                    cap.Visible = false
                end
            end
        end
    end

    return { Root = Root, Update = update }
end

local function spawnRing(gui, pill, strength, pulse)
    local size, pos = pill.AbsoluteSize, pill.AbsolutePosition
    local ring = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(pos.X + size.X / 2, pos.Y + size.Y / 2),
        Size = UDim2.fromOffset(size.X, size.Y), BackgroundTransparency = 1, ZIndex = 60, Active = false, Parent = gui,
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, Novier.Style.PillRadius) }),
        create("UIStroke", { Thickness = 2, Color = Novier.Theme.Accent, Transparency = 0.4 }),
    })
    local grow = 36 + strength * 70 * pulse
    tween(ring, { Size = UDim2.fromOffset(size.X + grow * 2, size.Y + grow * 0.8) }, 0.55, Enum.EasingStyle.Quad)
    tween(ring:FindFirstChildOfClass("UIStroke"), { Transparency = 1, Thickness = 0.5 }, 0.55)
    Debris:AddItem(ring, 0.65)
end

--========================================================--
-- SECTION BUILDER (GNOME boxed lists / cyber cards, decided by Style)
--========================================================--
--[[ makeRow: one list row. custom = { parent, height, count, divider, order } ]]
local function makeRow(section, className, base, props, custom)
    props = props or {}
    custom = custom or {}
    local order = custom.order or 0
    if custom.count ~= false then
        section._n = section._n + 1
        order = section._n
    end
    props.Size = custom.height and UDim2.new(1, 0, 0, custom.height)
        or F(function(_, s) return UDim2.new(1, 0, 0, base + s.RowExtra) end)
    props.BackgroundColor3 = T("SurfaceHighlight")
    props.BackgroundTransparency = F(function(_, s) return s.RowFlat and 1 or 0 end)
    props.BorderSizePixel = 0
    props.ZIndex = 16
    props.LayoutOrder = order
    props.Parent = custom.parent or section.ControlsHolder

    local stroke = create("UIStroke", {
        Thickness = F(function(_, s) return s.RowStroke end), Color = T("BorderSubtle"),
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    local hover = create("Frame", {
        Name = "Hover", Position = UDim2.fromOffset(-10, 3), Size = UDim2.new(1, 20, 1, -6),
        BackgroundColor3 = T("TextPrimary"), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 15,
    }, { create("UICorner", { CornerRadius = rad("ButtonRadius") }) })

    local inst = create(className, props, {
        create("UICorner", { CornerRadius = rad("RowRadius") }),
        stroke,
        create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
        hover,
    })
    if custom.divider ~= false and order > 1 then
        create("Frame", {
            Name = "Divider", Position = UDim2.fromOffset(-14, 0), Size = UDim2.new(1, 28, 0, 1),
            BackgroundColor3 = T("Divider"), BorderSizePixel = 0, ZIndex = 17,
            Visible = F(function(_, s) return s.Dividers end), Parent = inst,
        })
    end
    return inst, stroke, hover
end

local function hoverFx(btn, stroke, hover)
    track(btn.MouseEnter:Connect(function()
        sfx("hover")
        if Novier.Style.RowFlat then tween(hover, { BackgroundTransparency = 0.92 }, 0.12)
        else tween(stroke, { Color = Novier.Theme.Accent }, 0.15) end
    end))
    track(btn.MouseLeave:Connect(function()
        tween(hover, { BackgroundTransparency = 1 }, 0.15)
        tween(stroke, { Color = Novier.Theme.BorderSubtle }, 0.15)
    end))
end

local function rowLabel(parent, text, width, font)
    return create("TextLabel", {
        Size = UDim2.new(width or 0.6, 0, 1, 0), BackgroundTransparency = 1, Text = text,
        Font = font or S("Font"), TextSize = tsize(0), TextColor3 = T("TextPrimary"),
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 17, Parent = parent,
    })
end

local function buildSection(parentContainer, sectionName, overlayLayer, owner)
    local Section = { _n = 0, _owner = owner }

    local Root = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        ZIndex = 14, Parent = parentContainer,
    }, { create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

    local Header = create("TextButton", {
        LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Text = F(function(_, s) return s.TitlePrefix .. (s.Upper and string.upper(sectionName) or sectionName) end),
        Font = S("FontBold"), TextSize = F(function(_, s) return s.TitleSize end),
        TextColor3 = F(function(th, s) return s.TitleAccent and th.Accent or th.TextPrimary end),
        TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 15, Parent = Root,
    }, { create("UIPadding", { PaddingLeft = UDim.new(0, 4) }) })
    local Chevron = create("TextLabel", {
        Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, Text = "▾",
        Font = S("FontBold"), TextSize = 12, TextColor3 = T("TextSecondary"), ZIndex = 16, Parent = Header,
    })

    local Box = create("Frame", {
        LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T("SurfaceElevated"), BorderSizePixel = 0, ZIndex = 14, Parent = Root,
    }, {
        create("UICorner", { CornerRadius = rad("CardRadius") }),
        create("UIStroke", { Thickness = F(function(_, s) return s.CardStroke end), Color = T("BorderSubtle"), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
    })
    local Controls = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 15, Parent = Box,
    }, {
        create("UIListLayout", { Padding = F(function(_, s) return UDim.new(0, s.RowGap) end), SortOrder = Enum.SortOrder.LayoutOrder }),
        create("UIPadding", {
            PaddingTop = F(function(_, s) return UDim.new(0, s.CardPad) end), PaddingBottom = F(function(_, s) return UDim.new(0, s.CardPad) end),
            PaddingLeft = F(function(_, s) return UDim.new(0, s.CardPad) end), PaddingRight = F(function(_, s) return UDim.new(0, s.CardPad) end),
        }),
    })
    Section.ControlsHolder, Section.Box = Controls, Box

    local collapsed = false
    track(Header.MouseButton1Click:Connect(function()
        sfx("click")
        collapsed = not collapsed
        Chevron.Text = collapsed and "▸" or "▾"
        Box.Visible = not collapsed
    end))

    ---------------------------------------------------------- Button
    function Section:CreateButton(name, callback, opts)
        opts = opts or {}
        local text = name
        local Btn, stroke, hover = makeRow(Section, "TextButton", 34, { Text = "", AutoButtonColor = false, ClipsDescendants = true })
        local Title = create("TextLabel", {
            Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
            Text = F(function(_, s) return s.Brackets and ("[ " .. text .. " ]") or text end),
            Font = S("FontBold"), TextSize = tsize(0), TextColor3 = T("TextPrimary"), TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = F(function(_, s) return s.ButtonAlign == "Center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left end),
            ZIndex = 17, Parent = Btn,
        })
        create("TextLabel", {
            Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, Text = "›",
            Font = S("FontBold"), TextSize = 20, TextColor3 = T("TextSecondary"), ZIndex = 17,
            Visible = F(function(_, s) return s.ButtonChevron end), Parent = Btn,
        })
        hoverFx(Btn, stroke, hover)
        track(Btn.MouseEnter:Connect(function()
            if Novier.Style.Brackets then tween(Title, { TextColor3 = Novier.Theme.Accent }, 0.12) end
        end))
        track(Btn.MouseLeave:Connect(function() tween(Title, { TextColor3 = Novier.Theme.TextPrimary }, 0.12) end))
        track(Btn.MouseButton1Click:Connect(function()
            ripple(Btn); sfx("click")
            safe(callback)
        end))
        attachTooltip(Btn, opts.Tooltip)
        return {
            Instance = Btn,
            SetText = function(_, t)
                text = t
                Title.Text = Novier.Style.Brackets and ("[ " .. text .. " ]") or text
            end,
        }
    end

    ---------------------------------------------------------- Toggle
    function Section:CreateToggle(name, default, callback, opts)
        opts = opts or {}
        local state = default or false
        local Btn, stroke, hover = makeRow(Section, "TextButton", 34, { Text = "", AutoButtonColor = false, ClipsDescendants = true })
        hoverFx(Btn, stroke, hover)
        rowLabel(Btn, name, 0.75)
        local function offColor() return Novier.Style.RowFlat and Novier.Theme.SurfaceHighlight or Novier.Theme.SurfaceElevated end
        local Switch = create("Frame", {
            Size = UDim2.fromOffset(44, 24), Position = UDim2.new(1, -44, 0.5, -12),
            BackgroundColor3 = state and Novier.Theme.Accent or offColor(), ZIndex = 17, Parent = Btn,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        local Dot = create("Frame", {
            Size = UDim2.fromOffset(18, 18), Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 18, Parent = Switch,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        local function paint(instant)
            local d = instant and 0 or 0.16
            tween(Switch, { BackgroundColor3 = state and Novier.Theme.Accent or offColor() }, d)
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

        local Row = makeRow(Section, "Frame", 50, {})
        local Content = create("Frame", {
            Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1, ZIndex = 16, Parent = Row,
        })
        local NameLbl = rowLabel(Content, name, 0.7)
        NameLbl.Size = UDim2.new(0.7, 0, 0, 18)
        local Readout = create("TextLabel", {
            Size = UDim2.new(0.3, 0, 0, 18), Position = UDim2.new(0.7, 0, 0, 0), BackgroundTransparency = 1, Text = fmt(current),
            Font = S("FontBold"), TextSize = tsize(0), TextColor3 = T("Accent"), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 17, Parent = Content,
        })
        local Bar = create("Frame", {
            Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 28), BackgroundColor3 = T("SurfaceHighlight"),
            BorderSizePixel = 0, ZIndex = 17, Parent = Content,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        local BarBg = create("UIStroke", { Thickness = F(function(_, s) return s.RowFlat and 0 or 1 end), Color = T("BorderSubtle"), Parent = Bar })
        local Fill = create("Frame", {
            Size = UDim2.fromScale((current - min) / range, 1), BackgroundColor3 = T("Accent"), BorderSizePixel = 0, ZIndex = 18, Parent = Bar,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        local Knob = create("Frame", {
            Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((current - min) / range, 0, 0.5, 0),
            BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 19, Parent = Bar,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Thickness = 1.5, Color = T("Accent") }) })
        local Hit = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 18), BackgroundTransparency = 1, Text = "", ZIndex = 20, Parent = Content,
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
                tween(Knob, { Size = UDim2.fromOffset(20, 20) }, 0.1)
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
                tween(Knob, { Size = UDim2.fromOffset(16, 16) }, 0.1)
            end
        end))
        attachTooltip(Row, opts.Tooltip)
        registerFlag(opts, function() return current end, function(v) setVal(tonumber(v) or current, true) end)
        return { Set = function(_, v) setVal(v, true) end, Get = function() return current end }
    end

    ---------------------------------------------------------- Textbox
    function Section:CreateTextbox(name, placeholder, clearOnFocus, callback, opts)
        opts = opts or {}
        local Row = makeRow(Section, "Frame", 36, {})
        rowLabel(Row, name, 0.38)
        local Entry = create("Frame", {
            Size = UDim2.new(0.6, 0, 0, 28), Position = UDim2.new(0.4, 0, 0.5, -14),
            BackgroundColor3 = F(function(th, s) return s.RowFlat and th.SurfaceHighlight or th.SurfaceElevated end),
            BorderSizePixel = 0, ZIndex = 17, Parent = Row,
        }, {
            create("UICorner", { CornerRadius = rad("InputRadius") }),
            create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
        })
        local stroke = create("UIStroke", { Thickness = 1, Color = T("BorderSubtle"), Parent = Entry })
        local Input = create("TextBox", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, PlaceholderText = placeholder or "Enter text...",
            PlaceholderColor3 = T("TextDisabled"), Text = "", Font = S("Font"), TextSize = tsize(-1), TextColor3 = T("TextPrimary"),
            TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = clearOnFocus or false, ZIndex = 18, Parent = Entry,
        })
        track(Input.Focused:Connect(function() tween(stroke, { Color = Novier.Theme.Accent }, 0.15) end))
        track(Input.FocusLost:Connect(function(enter)
            tween(stroke, { Color = Novier.Theme.BorderSubtle }, 0.15)
            safe(callback, Input.Text, enter)
        end))
        attachTooltip(Row, opts.Tooltip)
        registerFlag(opts, function() return Input.Text end, function(v) Input.Text = tostring(v) end)
        return { Set = function(_, t) Input.Text = t end, Get = function() return Input.Text end }
    end

    ---------------------------------------------------------- Dropdown
    function Section:CreateDropdown(name, list, default, callback, opts)
        opts = opts or {}
        list = list or {}
        local selected = default or list[1]
        local isOpen = false

        local MainBtn, stroke, hover = makeRow(Section, "TextButton", 34, { Text = "", AutoButtonColor = false, ClipsDescendants = true })
        hoverFx(MainBtn, stroke, hover)
        rowLabel(MainBtn, name, 0.5)
        local SelectedLbl = create("TextLabel", {
            Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.fromScale(0.5, 0), BackgroundTransparency = 1,
            Text = tostring(selected) .. "  ▾", Font = S("FontBold"), TextSize = tsize(0), TextColor3 = T("Accent"),
            TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 17, Parent = MainBtn,
        })
        local Menu = create("Frame", {
            Size = UDim2.fromOffset(0, 0), BackgroundColor3 = T("SurfaceElevated"), ClipsDescendants = true,
            Visible = false, ZIndex = 501, Parent = overlayLayer,
        }, {
            create("UICorner", { CornerRadius = rad("ButtonRadius") }),
            create("UIStroke", { Thickness = 1.2, Color = T("BorderSubtle") }),
        })
        local Scroll = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 2,
            ScrollBarImageColor3 = T("Accent"), CanvasSize = UDim2.new(), ZIndex = 502, Parent = Menu,
        }, {
            create("UIListLayout", { Padding = UDim.new(0, 2) }),
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
                    Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Novier.Theme.SurfaceHighlight,
                    BackgroundTransparency = on and 0.4 or 1, Text = tostring(item), Font = S("Font"), TextSize = tsize(-1),
                    TextColor3 = on and Novier.Theme.Accent or Novier.Theme.TextPrimary, AutoButtonColor = false,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 503, Parent = Scroll,
                }, { create("UICorner", { CornerRadius = rad("InputRadius") }), create("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
                track(opt.MouseEnter:Connect(function() tween(opt, { BackgroundTransparency = 0.5 }, 0.1) end))
                track(opt.MouseLeave:Connect(function() tween(opt, { BackgroundTransparency = (selected == item) and 0.4 or 1 }, 0.1) end))
                track(opt.MouseButton1Click:Connect(function() sfx("click"); choose(item); closeMenu() end))
            end
            Scroll.CanvasSize = UDim2.fromOffset(0, #list * 30 + 8)
        end

        track(MainBtn.MouseButton1Click:Connect(function()
            sfx("click")
            if isOpen then closeMenu() return end
            isOpen = true
            populate()
            local absPos, absSize = MainBtn.AbsolutePosition, MainBtn.AbsoluteSize
            Menu.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
            Menu.Size = UDim2.fromOffset(math.max(absSize.X, 180), math.clamp(#list * 30 + 12, 34, 190))
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
        local Btn, stroke, hover = makeRow(Section, "TextButton", 34, { Text = "", AutoButtonColor = false, ClipsDescendants = true })
        hoverFx(Btn, stroke, hover)
        rowLabel(Btn, name, 0.5)
        local KeyLbl = create("TextLabel", {
            Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(0.5, 0), BackgroundTransparency = 1, Text = "",
            Font = S("FontCode"), TextSize = tsize(0), TextColor3 = T("Accent"), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 17, Parent = Btn,
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
        Section._n = Section._n + 1
        local Wrap = create("Frame", {
            Size = UDim2.new(1, 0, 0, (height or 130) + 20), BackgroundTransparency = 1, LayoutOrder = Section._n, ZIndex = 16, Parent = Controls,
        }, { create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
        local TermFrame = create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 11, 14), ZIndex = 16, Parent = Wrap,
        }, {
            create("UICorner", { CornerRadius = rad("InputRadius") }),
            create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
        })
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
                Text = string.format("[%s] > %s", os.date("%X"), tostring(msg)), Font = S("FontCode"), TextSize = 11,
                TextColor3 = color or Novier.Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = count, ZIndex = 18, Parent = TermScroll,
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
            Log   = function(_, m) append(m, Novier.Theme.Accent) end,
            Warn  = function(_, m) append(m, Novier.Theme.Warning) end,
            Error = function(_, m) append(m, Novier.Theme.Error) end,
            Clear = function(_)
                for _, c in ipairs(TermScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
                TermScroll.CanvasSize = UDim2.new()
                count = 0
            end,
        }
    end

    ---------------------------------------------------------- Label / Separator / Custom
    function Section:CreateLabel(text)
        Section._n = Section._n + 1
        local L = create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = text,
            TextWrapped = true, Font = S("Font"), TextSize = tsize(-1), TextColor3 = T("TextSecondary"),
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = Section._n, ZIndex = 16, Parent = Controls,
        }, { create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) })
        return { Set = function(_, t) L.Text = t end }
    end

    function Section:CreateSeparator()
        Section._n = Section._n + 1
        create("Frame", {
            Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T("Divider"), BorderSizePixel = 0,
            LayoutOrder = Section._n, ZIndex = 16, Parent = Controls,
        })
    end

    -- A padded empty frame for your own widgets
    function Section:CreateCustom(height)
        Section._n = Section._n + 1
        local Holder = create("Frame", {
            Size = UDim2.new(1, 0, 0, height or 100), BackgroundTransparency = 1, LayoutOrder = Section._n, ZIndex = 16, Parent = Controls,
        }, { create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) })
        return Holder
    end

    ---------------------------------------------------------- Theme swatch grid
    function Section:CreateThemeGrid(opts)
        Section._n = Section._n + 1
        local Grid = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            LayoutOrder = Section._n, ZIndex = 16, Parent = Controls,
        }, {
            create("UIGridLayout", { CellSize = UDim2.new(0.245, -6, 0, 64), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
            create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
        })
        local order = { Adwaita = 1, Cyber = 2, Terminal = 3 }
        local names = {}
        for n in pairs(Novier.Themes) do table.insert(names, n) end
        table.sort(names, function(a, b)
            local fa, fb = order[Novier.Themes[a].Family or "Cyber"] or 9, order[Novier.Themes[b].Family or "Cyber"] or 9
            if fa ~= fb then return fa < fb end
            return a < b
        end)

        local cells = {}
        for i, n in ipairs(names) do
            local t = Novier.Themes[n]
            local Cell = create("TextButton", {
                LayoutOrder = i, BackgroundColor3 = t.DrawerBackground, Text = "", AutoButtonColor = false, ZIndex = 17, Parent = Grid,
            }, { create("UICorner", { CornerRadius = rad("ButtonRadius") }) })
            local stroke = create("UIStroke", { Thickness = 1, Color = t.BorderSubtle, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = Cell })
            create("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(9, 9), BackgroundColor3 = t.Accent, BorderSizePixel = 0, ZIndex = 18, Parent = Cell },
                { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
            create("TextLabel", {
                Size = UDim2.new(1, -30, 0, 14), Position = UDim2.fromOffset(25, 7), BackgroundTransparency = 1, Text = n,
                Font = S("FontBold"), TextSize = 11, TextColor3 = t.TextPrimary, TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 18, Parent = Cell,
            })
            create("Frame", { Size = UDim2.new(0.6, 0, 0, 9), Position = UDim2.new(0, 9, 1, -32), BackgroundColor3 = t.SurfaceElevated, BorderSizePixel = 0, ZIndex = 18, Parent = Cell },
                { create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
            create("Frame", { Size = UDim2.new(0.35, 0, 0, 9), Position = UDim2.new(0, 9, 1, -19), BackgroundColor3 = t.SurfaceHighlight, BorderSizePixel = 0, ZIndex = 18, Parent = Cell },
                { create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
            create("Frame", { Size = UDim2.fromOffset(22, 9), Position = UDim2.new(1, -31, 1, -19), BackgroundColor3 = t.AccentGlow, BorderSizePixel = 0, ZIndex = 18, Parent = Cell },
                { create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
            cells[n] = stroke
            track(Cell.MouseButton1Click:Connect(function() sfx("click"); Novier:SetTheme(n) end))
        end
        local function mark()
            for n, stroke in pairs(cells) do
                local sel = (n == Novier.ThemeName)
                stroke.Thickness = sel and 2.5 or 1
                stroke.Color = sel and Novier.Themes[n].Accent or Novier.Themes[n].BorderSubtle
            end
        end
        mark()
        table.insert(ThemeHooks, mark)
        registerFlag(opts, function() return Novier.ThemeName end, function(v) Novier:SetTheme(tostring(v)) end)
    end

    ---------------------------------------------------------- Player list (dynamic)
    -- cfg = { IncludeSelf = true, Actions = { {"Name", function(player) end}, ... },
    --         OnSelect = function(player) end, Subtitle = function(player) return "text" end }
    function Section:CreatePlayerList(cfg)
        cfg = cfg or {}
        local includeSelf = cfg.IncludeSelf ~= false
        local actions = cfg.Actions or {}
        local List = { Entries = {}, Selected = nil }

        local SearchRow = makeRow(Section, "Frame", 36, {})
        create("TextLabel", {
            Size = UDim2.fromOffset(22, 22), Position = UDim2.new(0, 0, 0.5, -11), BackgroundTransparency = 1, Text = "🔍",
            Font = S("Font"), TextSize = 13, TextColor3 = T("TextSecondary"), ZIndex = 17, Parent = SearchRow,
        })
        local Search = create("TextBox", {
            Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(30, 0), BackgroundTransparency = 1, PlaceholderText = "Search players",
            PlaceholderColor3 = T("TextDisabled"), Text = "", ClearTextOnFocus = false, Font = S("Font"), TextSize = tsize(0),
            TextColor3 = T("TextPrimary"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 17, Parent = SearchRow,
        })

        Section._n = Section._n + 1
        local Holder = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = Section._n, ZIndex = 16, Parent = Controls,
        }, { create("UIListLayout", { Padding = F(function(_, s) return UDim.new(0, s.RowGap) end), SortOrder = Enum.SortOrder.LayoutOrder }) })
        local Empty = create("TextLabel", {
            LayoutOrder = 99999, Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Text = "No other players in this server yet.",
            Font = S("Font"), TextSize = tsize(-1), TextColor3 = T("TextSecondary"), Visible = false, ZIndex = 16, Parent = Holder,
        })

        local function layout()
            local idx = 0
            local list = {}
            for _, e in pairs(List.Entries) do table.insert(list, e) end
            table.sort(list, function(a, b) return a.Root.LayoutOrder < b.Root.LayoutOrder end)
            for _, e in ipairs(list) do
                idx = idx + 1
                e.Divider.Visible = idx > 1 and Novier.Style.Dividers
            end
        end

        local function select(uid)
            local prev = List.Entries[List.Selected]
            if prev then prev.Actions.Visible = false; prev.Arrow.Text = "▸" end
            if List.Selected == uid then List.Selected = nil return end
            local e = List.Entries[uid]
            if not e then return end
            List.Selected = uid
            e.Actions.Visible = true
            e.Arrow.Text = "▾"
            safe(cfg.OnSelect, e.Player)
        end

        local function buildEntry(p)
            local E = { Player = p }
            E.Root = create("Frame", {
                Name = tostring(p.UserId), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, ZIndex = 16, Parent = Holder,
            }, { create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })
            local Head, stroke, hover = makeRow(Section, "TextButton", 56, { Text = "", AutoButtonColor = false },
                { parent = E.Root, height = 56, count = false, divider = false, order = 1 })
            E.Divider = create("Frame", {
                Position = UDim2.fromOffset(-14, 0), Size = UDim2.new(1, 28, 0, 1), BackgroundColor3 = T("Divider"),
                BorderSizePixel = 0, ZIndex = 17, Visible = false, Parent = Head,
            })
            hoverFx(Head, stroke, hover)
            create("ImageLabel", {
                Size = UDim2.fromOffset(36, 36), Position = UDim2.new(0, 0, 0.5, -18), BackgroundColor3 = T("SurfaceHighlight"),
                Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=100&h=100", ZIndex = 17, Parent = Head,
            }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
            create("TextLabel", {
                Size = UDim2.new(1, -120, 0, 18), Position = UDim2.fromOffset(46, 9), BackgroundTransparency = 1, Text = p.DisplayName,
                Font = S("FontBold"), TextSize = tsize(0), TextColor3 = T("TextPrimary"), TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 17, Parent = Head,
            })
            local subText = cfg.Subtitle and cfg.Subtitle(p) or ("@" .. p.Name .. "  ·  " .. p.UserId)
            create("TextLabel", {
                Size = UDim2.new(1, -120, 0, 14), Position = UDim2.fromOffset(46, 28), BackgroundTransparency = 1, Text = subText,
                Font = S("Font"), TextSize = tsize(-2), TextColor3 = T("TextSecondary"), TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 17, Parent = Head,
            })
            if p == LocalPlayer then
                create("TextLabel", {
                    Size = UDim2.fromOffset(40, 18), Position = UDim2.new(1, -64, 0.5, -9), BackgroundColor3 = T("Accent"), BackgroundTransparency = 0.8,
                    Text = "YOU", Font = S("FontBold"), TextSize = 10, TextColor3 = T("Accent"), ZIndex = 17, Parent = Head,
                }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
            end
            E.Arrow = create("TextLabel", {
                Size = UDim2.fromOffset(16, 56), Position = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, Text = "▸",
                Font = S("FontBold"), TextSize = 12, TextColor3 = T("TextSecondary"), ZIndex = 17, Parent = Head,
            })
            E.Actions = create("Frame", {
                LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
                Visible = false, ZIndex = 16, Parent = E.Root,
            }, {
                create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
                create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
            })
            for i, a in ipairs(actions) do
                local label, fn = a.Name or a[1], a.Callback or a[2]
                local b = create("TextButton", {
                    LayoutOrder = i, Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T("SurfaceHighlight"),
                    Text = tostring(label), Font = S("FontBold"), TextSize = tsize(-1), TextColor3 = T("TextPrimary"), AutoButtonColor = false, ZIndex = 18, Parent = E.Actions,
                }, { create("UICorner", { CornerRadius = rad("ButtonRadius") }), create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) })
                track(b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = Novier.Theme.Accent, TextColor3 = Novier.Theme.AccentText }, 0.12) end))
                track(b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Novier.Theme.SurfaceHighlight, TextColor3 = Novier.Theme.TextPrimary }, 0.12) end))
                track(b.MouseButton1Click:Connect(function() sfx("click"); safe(fn, p) end))
            end
            track(Head.MouseButton1Click:Connect(function() sfx("click"); select(p.UserId) end))
            List.Entries[p.UserId] = E
            return E
        end

        local function applyFilter()
            local q = string.lower(Search.Text)
            for _, e in pairs(List.Entries) do
                local hay = string.lower(e.Player.DisplayName .. " " .. e.Player.Name)
                e.Root.Visible = (q == "") or (string.find(hay, q, 1, true) ~= nil)
            end
        end

        local function refresh()
            local plrs = Players:GetPlayers()
            table.sort(plrs, function(a, b)
                if a == LocalPlayer then return true end
                if b == LocalPlayer then return false end
                return string.lower(a.DisplayName) < string.lower(b.DisplayName)
            end)
            local seen, idx = {}, 0
            for _, p in ipairs(plrs) do
                if includeSelf or p ~= LocalPlayer then
                    idx = idx + 1
                    seen[p.UserId] = true
                    local e = List.Entries[p.UserId] or buildEntry(p)
                    e.Root.LayoutOrder = idx
                end
            end
            for uid, e in pairs(List.Entries) do
                if not seen[uid] then
                    e.Root:Destroy()
                    List.Entries[uid] = nil
                    if List.Selected == uid then List.Selected = nil end
                end
            end
            Empty.Visible = idx == 0 or (idx == 1 and includeSelf and plrs[1] == LocalPlayer)
            Search.PlaceholderText = "Search " .. idx .. " player" .. (idx == 1 and "" or "s")
            layout()
            applyFilter()
        end

        track(Search:GetPropertyChangedSignal("Text"):Connect(applyFilter))
        track(Players.PlayerAdded:Connect(function() task.delay(0.15, refresh) end))
        track(Players.PlayerRemoving:Connect(function() task.delay(0.2, refresh) end))
        table.insert(ThemeHooks, layout)
        if Section._owner and Section._owner.OnOpen then Section._owner:OnOpen(refresh) end -- refresh on every tab open

        List.Refresh = function(_) refresh() end
        List.GetSelected = function(_) local e = List.Entries[List.Selected]; return e and e.Player or nil end
        List.Select = function(_, plr) if plr then select(plr.UserId) end end
        refresh()
        return List
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
    if data.ui_theme and Novier._FlagSetters.ui_theme then pcall(Novier._FlagSetters.ui_theme, data.ui_theme) end -- theme first
    for flag, value in pairs(data) do
        local setter = Novier._FlagSetters[flag]
        if setter and flag ~= "ui_theme" then pcall(setter, value) end
    end
    return true
end

--========================================================--
-- WINDOW
--========================================================--
function Novier:CreateWindow(windowTitle)
    if Novier._Gui then Novier:Destroy() end
    windowTitle = windowTitle or "NOVIER // ISLAND"

    local Window = {
        Tabs = {}, ActiveTab = nil, IsOpen = true, DrawerOpen = false,
        ToggleKey = Novier.Config.DefaultToggleKey, FovKey = Novier.Config.DefaultFovKey,
        _tickers = {}, _frameHooks = {}, _beatListeners = {},
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
    local function pillClosePos() return UDim2.new(0.5, 0, 0, -(cfg.PillHeight * computeScale()) - 20) end
    local pillOpenPos = UDim2.new(0.5, 0, 0, 16)
    local function drawerOpenPos() return UDim2.new(0.5, 0, 0, math.floor(16 + cfg.PillHeight * computeScale() + 10)) end
    local function drawerClosePos() return UDim2.new(0.5, 0, 0, math.floor(cfg.PillHeight * computeScale() - 10)) end

    ------------------------------------------------ THE PILL
    local PillStroke = create("UIStroke", { Name = "PillStroke", Thickness = 1.4, Color = Color3.new(1, 1, 1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local PillGradient = create("UIGradient", { Color = accentSequence(), Parent = PillStroke })

    local Pill = create("Frame", {
        Name = "PillBar", Size = UDim2.fromOffset(cfg.PillHeight, cfg.PillHeight), Position = pillOpenPos,
        AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = T("PillBackground"), BorderSizePixel = 0,
        ClipsDescendants = true, ZIndex = 100, Parent = Gui,
    }, {
        create("UICorner", { CornerRadius = rad("PillRadius") }),
        PillStroke,
        create("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 12) }),
    })
    addScale(Pill)

    -- Brand + live stats (left)
    local Brand = create("Frame", { Size = UDim2.new(0, 160, 1, 0), BackgroundTransparency = 1, ZIndex = 101, Parent = Pill })
    create("TextLabel", {
        Size = UDim2.fromOffset(28, 28), Position = UDim2.new(0, 0, 0.5, -14), BackgroundColor3 = T("SurfaceElevated"),
        Text = S("BrandIcon"), Font = S("FontBold"), TextSize = 14, TextColor3 = T("Accent"), ZIndex = 102, Parent = Brand,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Thickness = 1, Color = T("Accent") }) })
    create("TextLabel", {
        Size = UDim2.new(1, -38, 0, 18), Position = UDim2.fromOffset(38, 6), BackgroundTransparency = 1,
        Text = F(function(_, s) return s.Upper and string.upper(windowTitle) or windowTitle end),
        Font = S("FontBold"), TextSize = 12, TextColor3 = T("TextPrimary"), TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 102, Parent = Brand,
    })
    local StatsLabel = create("TextLabel", {
        Size = UDim2.new(1, -38, 0, 14), Position = UDim2.fromOffset(38, 24), BackgroundTransparency = 1, Text = "",
        Font = S("FontCode"), TextSize = 10, TextColor3 = T("TextSecondary"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102, Parent = Brand,
    })

    -- Mini synth (fixed on the left so tabs can never overlap it)
    local VN = 14
    local VisualizerHolder = create("Frame", {
        Name = "PillVisualizer", Size = UDim2.fromOffset(92, 24), Position = UDim2.new(0, 170, 0.5, -12), BackgroundTransparency = 1, ZIndex = 101, Parent = Pill,
    })
    local VisualizerBars = {}
    for i = 1, VN do
        VisualizerBars[i] = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, (i - 1) * 6.5, 0.5, 0), Size = UDim2.fromOffset(4, 4),
            BackgroundColor3 = Novier.Theme.Accent, BorderSizePixel = 0, ZIndex = 102, Parent = VisualizerHolder,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    end

    -- Scrolling tab region (right): scroller + arrow buttons
    local TabRegion = create("Frame", {
        Name = "TabRegion", Size = UDim2.new(1, -274, 1, 0), Position = UDim2.fromOffset(274, 0),
        BackgroundTransparency = 1, ZIndex = 101, Parent = Pill,
    })
    local Scroller = create("ScrollingFrame", {
        Name = "TabScroller", Size = UDim2.new(1, -58, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(),
        ClipsDescendants = true, ZIndex = 101, Parent = TabRegion,
    }, {
        create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
        create("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2) }),
    })
    local function arrow(text, xOff)
        return create("TextButton", {
            Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, xOff, 0.5, -12), BackgroundColor3 = T("SurfaceElevated"),
            Text = text, Font = S("FontBold"), TextSize = 16, TextColor3 = T("TextPrimary"), AutoButtonColor = false, Visible = false, ZIndex = 103, Parent = TabRegion,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    end
    local LeftArrow, RightArrow = arrow("‹", -54), arrow("›", -26)

    local function maxScroll() return math.max(0, Scroller.AbsoluteCanvasSize.X - Scroller.AbsoluteWindowSize.X) / computeScale() end
    local function updateArrows()
        local m = maxScroll()
        local x = Scroller.CanvasPosition.X
        local overflow = m > 1
        LeftArrow.Visible, RightArrow.Visible = overflow, overflow
        LeftArrow.TextTransparency = (x > 1) and 0 or 0.65
        RightArrow.TextTransparency = (x < m - 1) and 0 or 0.65
    end
    local function scrollBy(dx)
        local target = math.clamp(Scroller.CanvasPosition.X + dx, 0, maxScroll())
        tween(Scroller, { CanvasPosition = Vector2.new(target, 0) }, 0.25)
    end
    track(Scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(updateArrows))
    track(Scroller:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateArrows))
    track(Scroller:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateArrows))
    track(LeftArrow.MouseButton1Click:Connect(function() sfx("click"); scrollBy(-160) end))
    track(RightArrow.MouseButton1Click:Connect(function() sfx("click"); scrollBy(160) end))
    track(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel and Pill.Visible then
            if pointIn(TabRegion, UserInputService:GetMouseLocation()) then scrollBy(-input.Position.Z * 90) end
        end
    end))

    local function ensureVisible(btn)
        task.defer(function()
            local sc = computeScale()
            local left = (btn.AbsolutePosition.X - Scroller.AbsolutePosition.X) / sc + Scroller.CanvasPosition.X
            local w = btn.AbsoluteSize.X / sc
            local view = Scroller.AbsoluteWindowSize.X / sc
            local cur = Scroller.CanvasPosition.X
            local target = cur
            if left < cur then target = left - 8 elseif left + w > cur + view then target = left + w - view + 8 end
            if target ~= cur then tween(Scroller, { CanvasPosition = Vector2.new(math.max(0, target), 0) }, 0.25) end
        end)
    end

    ------------------------------------------------ DRAWER (GNOME header bar + content)
    local DrawerStroke = create("UIStroke", { Thickness = F(function(_, s) return s.DrawerStroke end), Color = T("BorderSubtle"), ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local Drawer = create("Frame", {
        Name = "PillDrawer", Size = UDim2.fromOffset(cfg.DrawerWidth, cfg.DrawerHeight), Position = drawerClosePos(),
        AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = T("DrawerBackground"), BorderSizePixel = 0,
        ClipsDescendants = true, Visible = false, ZIndex = 10, Parent = Gui,
    }, { create("UICorner", { CornerRadius = rad("DrawerRadius") }), DrawerStroke })
    addScale(Drawer)

    local HeaderBar = create("Frame", {
        Name = "HeaderBar", Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = T("HeaderBackground"), BorderSizePixel = 0, ZIndex = 20, Parent = Drawer,
    }, { create("UICorner", { CornerRadius = rad("DrawerRadius") }) })
    create("Frame", { -- squares off the header's lower corners
        Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, -22), BackgroundColor3 = T("HeaderBackground"), BorderSizePixel = 0, ZIndex = 20, Parent = HeaderBar,
    })
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T("Divider"), BorderSizePixel = 0, ZIndex = 21, Parent = HeaderBar,
    })
    local currentTabName = ""
    local function titleText()
        local s = Novier.Style
        return s.TitlePrefix .. (s.Upper and string.upper(currentTabName) or currentTabName)
    end
    local DrawerTitle = create("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(18, 0), BackgroundTransparency = 1, Text = "",
        Font = S("FontBold"), TextSize = F(function(_, s) return s.TitleSize + 4 end),
        TextColor3 = F(function(th, s) return s.TitleAccent and th.Accent or th.TextPrimary end),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22, Parent = HeaderBar,
    })
    local CloseBtn = create("TextButton", {
        Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -40, 0.5, -14), BackgroundColor3 = T("SurfaceHighlight"),
        BackgroundTransparency = 0.4, Text = "✕", Font = S("FontBold"), TextSize = 12, TextColor3 = T("TextPrimary"), AutoButtonColor = false, ZIndex = 22, Parent = HeaderBar,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    track(CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, { BackgroundTransparency = 0 }, 0.12) end))
    track(CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, { BackgroundTransparency = 0.4 }, 0.12) end))
    table.insert(ThemeHooks, function() DrawerTitle.Text = titleText() end)

    local Content = create("Frame", {
        Name = "Content", Size = UDim2.new(1, 0, 1, -46), Position = UDim2.fromOffset(0, 46), BackgroundTransparency = 1, ZIndex = 11, Parent = Drawer,
    })

    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then -- touch toggle button
        local TouchBtn = create("TextButton", {
            Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = T("PillBackground"), Text = S("BrandIcon"), Font = S("FontBold"), TextSize = 18,
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
        fpsAcc = fpsAcc + dt
        fpsFrames = fpsFrames + 1
        if fpsAcc >= 0.5 then fps = fpsFrames / fpsAcc; fpsAcc, fpsFrames = 0, 0 end

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

        acc = acc + dt
        if acc < 1 / math.max(20, Novier.Settings.VisualHz) then return end
        local vdt = acc
        acc = 0

        local Opt, st, th = Novier.Settings, Novier.Style, Novier.Theme
        An:Update(vdt, ActiveSound, Opt)
        local pulse = st.Pulse * Opt.Pulse

        if An.beatFired then
            for _, fn in ipairs(Window._beatListeners) do safe(fn, An.beat, An.bpm) end
            if Opt.Rings and Window.IsOpen then spawnRing(Gui, Pill, An.bass, pulse) end
        end

        if Rain.Root.Visible ~= Opt.Rain then Rain.Root.Visible = Opt.Rain end
        if Opt.Rain then Rain.Update(vdt, An) end
        if HUD.Root.Visible ~= st.HUD then HUD.Root.Visible = st.HUD end
        if Edges.Root.Visible ~= Opt.EdgeVisuals then Edges.Root.Visible = Opt.EdgeVisuals end
        if Opt.EdgeVisuals then Edges.Update(An, pulse, Opt.EdgeSize) end

        PillGradient.Rotation = (PillGradient.Rotation + vdt * (25 + (An.bass * 200 + An.beat * 140) * pulse)) % 360
        PillStroke.Thickness = st.PillStroke + (An.bass * 1.2 + An.beat * 0.8) * pulse
        if Window.DrawerOpen then
            DrawerStroke.Color = th.BorderSubtle:Lerp(th.Accent, math.clamp((An.bass * 0.6 + An.beat * 0.3) * pulse, 0, 1))
        end

        for i, bar in ipairs(VisualizerBars) do
            local v = An:Sample((i - 1) / (VN - 1))
            bar.Size = UDim2.fromOffset(4, math.max(4, math.floor(4 + v * 20)))
            bar.BackgroundColor3 = spectrumColor(v)
        end

        for _, fn in ipairs(Window._frameHooks) do safe(fn, An, vdt) end

        hudAcc = hudAcc + vdt
        if hudAcc >= 0.25 then
            hudAcc = 0
            ping = getPing()
            StatsLabel.Visible = Opt.ShowStats
            StatsLabel.Text = string.format("%d FPS · %dms", fps, ping)
            if st.HUD then
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
        if Blur and Novier.Settings.Blur then tween(Blur, { Size = 10 }, 0.3) end
    end

    function Window:CloseDrawer()
        Window.DrawerOpen = false
        for _, closer in ipairs(Novier._MenuClosers) do pcall(closer) end
        for _, t in ipairs(Window.Tabs) do
            t.Page.Visible = false
            t:_paint(false)
        end
        Window.ActiveTab = nil
        if Blur then tween(Blur, { Size = 0 }, 0.25) end
        DrawerStroke.Color = Novier.Theme.BorderSubtle
        tween(Drawer, { Position = drawerClosePos() }, 0.22).Completed:Connect(function()
            if not Window.DrawerOpen then Drawer.Visible = false end
        end)
    end
    track(CloseBtn.MouseButton1Click:Connect(function() sfx("click"); Window:CloseDrawer() end))

    function Window:SetToggleKey(k) Window.ToggleKey = k end
    function Window:SetFovKey(k) Window.FovKey = k end
    function Window:OnBeat(fn) table.insert(Window._beatListeners, fn) end
    function Window:AddTicker(fn) table.insert(Window._tickers, fn) end       -- fn(analyzer, fps, ping) @ 4 Hz
    function Window:AddFrameHook(fn) table.insert(Window._frameHooks, fn) end  -- fn(analyzer, dt) every visual frame
    function Window:Destroy() Novier:Destroy() end

    track(UserInputService.InputBegan:Connect(function(input, processed)
        if processed or Novier._listening then return end
        if os.clock() - (Novier._listenStamp or 0) < 0.2 then return end
        if input.KeyCode == Window.ToggleKey then
            Window:SetVisible()
        elseif input.KeyCode == Window.FovKey then
            FOV.Enabled = not FOV.Enabled
            Novier:Notify("Beat FOV", FOV.Enabled and "Camera kick activated." or "Camera kick deactivated.", 2, FOV.Enabled and "Success" or "Warning")
        end
    end))

    ------------------------------------------------ TABS
    local function paintTab(btn, active, instant)
        local s, th = Novier.Style, Novier.Theme
        tween(btn, {
            BackgroundColor3 = active and th.SurfaceHighlight or th.SurfaceElevated,
            BackgroundTransparency = (s.TabFlat and not active) and 1 or 0,
            TextColor3 = active and (s.TabAccent and th.Accent or th.TextPrimary) or th.TextSecondary,
        }, instant and 0 or 0.15)
    end

    function Window:CreateTab(tabName, iconSymbol)
        local Tab = { Active = false, _open = {} }
        local displayText = (iconSymbol and iconSymbol ~= "") and (iconSymbol .. " " .. tabName) or tabName

        local TabBtn = create("TextButton", {
            Name = tabName .. "_Tab", Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = #Window.Tabs + 1,
            BackgroundColor3 = Novier.Theme.SurfaceElevated, Text = displayText, Font = S("FontBold"), TextSize = F(function(_, s) return s.TextSize - 1 end),
            TextColor3 = Novier.Theme.TextSecondary, AutoButtonColor = false, ClipsDescendants = true, ZIndex = 102, Parent = Scroller,
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            create("UIStroke", { Thickness = F(function(_, s) return s.TabFlat and 0 or 1 end), Color = T("BorderSubtle") }),
            create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
        })
        paintTab(TabBtn, false, true)

        local PageLayout = create("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder })
        local Page = create("ScrollingFrame", {
            Name = tabName .. "_Page", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 3,
            ScrollBarImageColor3 = T("Accent"), CanvasSize = UDim2.new(), Visible = false, ZIndex = 13, ClipsDescendants = true, Parent = Content,
        }, { PageLayout, create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 18) }) })
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.fromOffset(0, PageLayout.AbsoluteContentSize.Y + 32)
        end)

        function Tab:_paint(active, instant)
            Tab.Active = active
            paintTab(TabBtn, active, instant)
        end
        table.insert(ThemeHooks, function() Tab:_paint(Tab.Active, true) end)

        track(TabBtn.MouseEnter:Connect(function()
            sfx("hover")
            if not Tab.Active then tween(TabBtn, { TextColor3 = Novier.Theme.TextPrimary }, 0.12) end
        end))
        track(TabBtn.MouseLeave:Connect(function()
            if not Tab.Active then tween(TabBtn, { TextColor3 = Novier.Theme.TextSecondary }, 0.12) end
        end))

        function Tab:OnOpen(fn) table.insert(Tab._open, fn) end

        local function selectTab()
            ripple(TabBtn); sfx("click")
            if Window.ActiveTab == Tab and Window.DrawerOpen then
                Window:CloseDrawer()
                return
            end
            for _, t in ipairs(Window.Tabs) do t.Page.Visible = false; t:_paint(false) end
            Page.Visible = true
            Window.ActiveTab = Tab
            Tab:_paint(true)
            currentTabName = tabName
            DrawerTitle.Text = titleText()
            ensureVisible(TabBtn)
            if not Window.DrawerOpen then Window:OpenDrawer() end
            for _, fn in ipairs(Tab._open) do safe(fn) end
        end
        track(TabBtn.MouseButton1Click:Connect(selectTab))

        Tab.Button, Tab.Page = TabBtn, Page
        table.insert(Window.Tabs, Tab)

        function Tab:CreateSection(sectionName) return buildSection(Page, sectionName, OverlayLayer, Tab) end

        -- Convenience: a section holding a dynamic player list
        function Tab:CreatePlayerList(listCfg, sectionName)
            local sec = Tab:CreateSection(sectionName or "Players")
            return sec:CreatePlayerList(listCfg), sec
        end

        -- Scrolling sub-tabs
        function Tab:CreateSubTabs(initialList)
            local SubTabSystem = { SubTabs = {}, ActiveSubTab = nil }
            local BarLayout = create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
            local SubTabBar = create("ScrollingFrame", {
                Name = "SubTabBar", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, ScrollBarThickness = 3,
                ScrollBarImageColor3 = T("Accent"), ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.new(),
                ZIndex = 14, ClipsDescendants = true, Parent = Page,
            }, { BarLayout, create("UIPadding", { PaddingBottom = UDim.new(0, 4) }) })
            BarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SubTabBar.CanvasSize = UDim2.fromOffset(BarLayout.AbsoluteContentSize.X + 24, 0)
            end)
            local SubPageHolder = create("Frame", {
                Name = "SubPageHolder", Size = UDim2.new(1, 0, 0, cfg.DrawerHeight - 150), BackgroundTransparency = 1, ZIndex = 13, Parent = Page,
            })

            local function paintSub(sub, active, instant)
                sub.Active = active
                paintTab(sub.Button, active, instant)
            end

            function SubTabSystem:AddSubTab(subName, icon)
                if SubTabSystem.SubTabs[subName] then return SubTabSystem.SubTabs[subName] end
                local SubTab = { Active = false, _open = {} }
                local label = (icon and icon ~= "") and (icon .. " " .. subName) or subName

                local SubBtn = create("TextButton", {
                    Name = subName .. "_SubBtn", Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = Novier.Theme.SurfaceElevated, Text = label, Font = S("FontBold"),
                    TextSize = F(function(_, s) return s.TextSize - 2 end), TextColor3 = Novier.Theme.TextSecondary, AutoButtonColor = false,
                    ClipsDescendants = true, ZIndex = 15, Parent = SubTabBar,
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    create("UIStroke", { Thickness = F(function(_, s) return s.TabFlat and 0 or 1 end), Color = T("BorderSubtle") }),
                    create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
                })
                paintTab(SubBtn, false, true)

                local SubLayout = create("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder })
                local SubPage = create("ScrollingFrame", {
                    Name = subName .. "_SubPage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 3,
                    ScrollBarImageColor3 = T("Accent"), CanvasSize = UDim2.new(), Visible = false, ZIndex = 13, ClipsDescendants = true, Parent = SubPageHolder,
                }, { SubLayout, create("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }) })
                SubLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    SubPage.CanvasSize = UDim2.fromOffset(0, SubLayout.AbsoluteContentSize.Y + 24)
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
                    local x = SubBtn.AbsolutePosition.X - SubTabBar.AbsolutePosition.X + SubTabBar.CanvasPosition.X
                    SubTabBar.CanvasPosition = Vector2.new(math.max(0, x - 40), 0)
                    for _, fn in ipairs(SubTab._open) do safe(fn) end
                end
                track(SubBtn.MouseButton1Click:Connect(function() ripple(SubBtn); sfx("click"); activate() end))

                function SubTab:OnOpen(fn) table.insert(SubTab._open, fn) end
                function SubTab:CreateSection(secName) return buildSection(SubPage, secName, OverlayLayer, SubTab) end

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

            -- keep: optional list of sub-tab names to leave alone
            function SubTabSystem:ClearSubTabs(keep)
                local keepSet = {}
                for _, n in ipairs(keep or {}) do keepSet[n] = true end
                local names = {}
                for name in pairs(SubTabSystem.SubTabs) do
                    if not keepSet[name] then table.insert(names, name) end
                end
                for _, name in ipairs(names) do SubTabSystem:RemoveSubTab(name) end
            end

            if type(initialList) == "table" then
                for _, item in ipairs(initialList) do
                    if type(item) == "table" then SubTabSystem:AddSubTab(item.Name or item[1], item.Icon or item[2])
                    else SubTabSystem:AddSubTab(tostring(item)) end
                end
            end
            return SubTabSystem
        end

        return Tab
    end

    ------------------------------------------------ PLAYERS TAB (one call)
    function Window:CreatePlayersTab(listCfg, tabName)
        local Tab = Window:CreateTab(tabName or "PLAYERS", "👤")
        local List, Sec = Tab:CreatePlayerList(listCfg, "Players in this server")
        return Tab, List, Sec
    end

    ------------------------------------------------ MEDIA SUITE (now-playing card)
    function Window:CreateMediaSuite(defaultTrackTable)
        local tracks = defaultTrackTable or {
            ["Synth Loop"]        = "rbxassetid://9043887091",
            ["Action Electronic"] = "rbxassetid://1840590064",
            ["Dark Cyber"]        = "rbxassetid://1843404009",
        }
        local names = {}
        for n in pairs(tracks) do table.insert(names, n) end
        table.sort(names)
        local index, loop = 1, true
        local buttons = {}

        local Tab = Window:CreateTab("MEDIA", "♫")
        local NP = Tab:CreateSection("Now Playing")
        local Card = NP:CreateCustom(196)

        local function accentPair()
            return ColorSequence.new(Novier.Theme.Accent, Novier.Theme.SecondaryAccent)
        end
        local ArtGrad = create("UIGradient", { Rotation = 45, Color = accentPair() })
        local Art = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(56, 56), Size = UDim2.fromOffset(112, 112),
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 17, Parent = Card,
        }, { create("UICorner", { CornerRadius = rad("CardRadius") }), ArtGrad })
        create("TextLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "♫", Font = S("FontBold"), TextSize = 46,
            TextColor3 = T("AccentText"), ZIndex = 18, Parent = Art,
        })
        table.insert(ThemeHooks, function() ArtGrad.Color = accentPair() end)

        local Col = create("Frame", { Position = UDim2.fromOffset(128, 0), Size = UDim2.new(1, -128, 1, 0), BackgroundTransparency = 1, ZIndex = 17, Parent = Card })
        local TitleLbl = create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "Nothing playing", Font = S("FontBold"),
            TextSize = F(function(_, s) return s.TextSize + 5 end), TextColor3 = T("TextPrimary"), TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 18, Parent = Col,
        })
        local SubLbl = create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 26), BackgroundTransparency = 1, Text = "Pick a track below",
            Font = S("Font"), TextSize = tsize(-1), TextColor3 = T("TextSecondary"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 18, Parent = Col,
        })

        local MN = 48
        local Viz = create("Frame", { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, ZIndex = 18, Parent = Col })
        local vbars = {}
        for i = 1, MN do
            vbars[i] = create("Frame", {
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / MN, 0, 1, 0), Size = UDim2.new(1 / MN, -2, 0.06, 0),
                BackgroundColor3 = Novier.Theme.Accent, BorderSizePixel = 0, ZIndex = 18, Parent = Viz,
            }, { create("UICorner", { CornerRadius = UDim.new(0, 2) }) })
        end

        local Bar = create("Frame", {
            Position = UDim2.fromOffset(0, 106), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = T("SurfaceHighlight"), BorderSizePixel = 0, ZIndex = 18, Parent = Col,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        local Fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = T("Accent"), BorderSizePixel = 0, ZIndex = 19, Parent = Bar },
            { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        local SeekKnob = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(12, 12),
            BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 20, Parent = Bar,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        local SeekHit = create("TextButton", { Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", ZIndex = 21, Parent = Col })
        local TimeL = create("TextLabel", {
            Position = UDim2.fromOffset(0, 116), Size = UDim2.new(0.5, 0, 0, 14), BackgroundTransparency = 1, Text = "0:00",
            Font = S("FontCode"), TextSize = tsize(-2), TextColor3 = T("TextSecondary"), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 18, Parent = Col,
        })
        local TimeR = create("TextLabel", {
            Position = UDim2.new(0.5, 0, 0, 116), Size = UDim2.new(0.5, 0, 0, 14), BackgroundTransparency = 1, Text = "--:--",
            Font = S("FontCode"), TextSize = tsize(-2), TextColor3 = T("TextSecondary"), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 18, Parent = Col,
        })

        local Controls = create("Frame", {
            Position = UDim2.fromOffset(0, 138), Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 18, Parent = Col,
        }, { create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10) }) })
        local function circle(text, size, filled, order)
            return create("TextButton", {
                LayoutOrder = order, Size = UDim2.fromOffset(size, size), BackgroundColor3 = filled and T("Accent") or T("SurfaceHighlight"), Text = text,
                Font = S("FontBold"), TextSize = filled and 16 or 15, TextColor3 = filled and T("AccentText") or T("TextPrimary"), AutoButtonColor = false, ZIndex = 19, Parent = Controls,
            }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        end
        local PrevBtn, PlayBtn, NextBtn, LoopBtn = circle("«", 34, false, 1), circle("▶", 42, true, 2), circle("»", 34, false, 3), circle("↻", 34, false, 4)

        local function clock(sec) return string.format("%d:%02d", math.floor(sec / 60), math.floor(sec % 60)) end

        local function setNow(i, label)
            index = i
            TitleLbl.Text = label or names[i] or "Nothing playing"
            for j, b in ipairs(buttons) do b:SetText((j == i and "▶  " or "     ") .. names[j]) end
        end
        local function play(i)
            if #names == 0 then return end
            i = ((i - 1) % #names) + 1
            ActiveSound.SoundId = tracks[names[i]]
            ActiveSound.TimePosition = 0
            ActiveSound.Looped = loop
            ActiveSound:Play()
            setNow(i)
        end
        local function paintLoop() tween(LoopBtn, { BackgroundColor3 = loop and Novier.Theme.Accent or Novier.Theme.SurfaceHighlight, TextColor3 = loop and Novier.Theme.AccentText or Novier.Theme.TextPrimary }, 0.15) end
        paintLoop()
        table.insert(ThemeHooks, paintLoop)

        track(PrevBtn.MouseButton1Click:Connect(function() sfx("click"); play(index - 1) end))
        track(NextBtn.MouseButton1Click:Connect(function() sfx("click"); play(index + 1) end))
        track(PlayBtn.MouseButton1Click:Connect(function()
            sfx("click")
            if ActiveSound.IsPlaying then ActiveSound:Pause()
            elseif ActiveSound.IsPaused then ActiveSound:Resume()
            else play(index) end
        end))
        track(LoopBtn.MouseButton1Click:Connect(function() sfx("click"); loop = not loop; ActiveSound.Looped = loop; paintLoop() end))
        track(ActiveSound.Ended:Connect(function() if not loop then play(index + 1) end end))

        local seeking = false
        local function seekTo(x)
            local a = math.clamp((x - Bar.AbsolutePosition.X) / math.max(Bar.AbsoluteSize.X, 1), 0, 1)
            if ActiveSound.TimeLength > 0 then ActiveSound.TimePosition = a * ActiveSound.TimeLength end
        end
        track(SeekHit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                seeking = true
                seekTo(input.Position.X)
            end
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if seeking and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then seekTo(input.Position.X) end
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if seeking and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then seeking = false end
        end))

        local lastSec = -1
        Window:AddFrameHook(function(an)
            local pulse = Novier.Style.Pulse * Novier.Settings.Pulse
            local sz = 112 + (an.beat * 10 + an.bass * 4) * pulse
            Art.Size = UDim2.fromOffset(sz, sz)
            for i = 1, MN do
                local v = an:Sample((i - 1) / (MN - 1))
                vbars[i].Size = UDim2.new(1 / MN, -2, math.max(0.06, v), 0)
                vbars[i].BackgroundColor3 = spectrumColor(v)
            end
            local len = ActiveSound.TimeLength
            local a = len > 0 and math.clamp(ActiveSound.TimePosition / len, 0, 1) or 0
            Fill.Size = UDim2.fromScale(a, 1)
            SeekKnob.Position = UDim2.new(a, 0, 0.5, 0)
            local sec = math.floor(ActiveSound.TimePosition)
            if sec ~= lastSec then
                lastSec = sec
                TimeL.Text = clock(ActiveSound.TimePosition)
                TimeR.Text = len > 0 and clock(len) or "--:--"
            end
            PlayBtn.Text = ActiveSound.IsPlaying and "II" or "▶"
        end)
        Window:AddTicker(function(an)
            SubLbl.Text = string.format("BPM %s   ·   LVL %d%%", an.bpm > 1 and tostring(math.floor(an.bpm + 0.5)) or "--", math.floor(an.level * 100))
        end)

        local Lib = Tab:CreateSection("Library")
        for i, n in ipairs(names) do
            buttons[i] = Lib:CreateButton("     " .. n, function() play(i) end)
        end

        local Play = Tab:CreateSection("Playback")
        Play:CreateSlider("Volume", 0, 200, 50, 1, function(v) ActiveSound.Volume = v / 100 end, { Flag = "media_volume", Tooltip = "Above 100% boosts the stream" })
        Play:CreateToggle("Loop track", true, function(v) loop = v; ActiveSound.Looped = v; paintLoop() end, { Flag = "media_loop" })
        Play:CreateTextbox("Custom sound ID", "Paste numeric ID...", false, function(txt, enter)
            if enter and txt and #txt > 0 then
                local cleanId = txt:gsub("%D", "")
                if #cleanId > 0 then
                    ActiveSound.SoundId = "rbxassetid://" .. cleanId
                    ActiveSound.TimePosition = 0
                    ActiveSound.Looped = loop
                    ActiveSound:Play()
                    setNow(index, "Custom ID " .. cleanId)
                    Novier:Notify("Audio", "Playing ID: " .. cleanId, 2, "Success")
                end
            end
        end)

        local FovSec = Tab:CreateSection("Beat-Synchronized Camera FOV")
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
        FovSec:CreateSlider("Kick Smoothness", 5, 60, math.floor(FOV.Smoothness * 100), 1, function(val) FOV.Smoothness = val / 100 end,
            { Flag = "fov_smooth", Tooltip = "Higher = snappier camera" })

        return {
            PlayCustom = function(_, id)
                local cleanId = tostring(id):gsub("%D", "")
                ActiveSound.SoundId = "rbxassetid://" .. cleanId
                ActiveSound.TimePosition = 0
                ActiveSound.Looped = loop
                ActiveSound:Play()
                setNow(index, "Custom ID " .. cleanId)
            end,
            Play = function(_, nameOrIndex)
                if type(nameOrIndex) == "string" then nameOrIndex = table.find(names, nameOrIndex) end
                play(nameOrIndex or index)
            end,
            Next = function() play(index + 1) end,
            Prev = function() play(index - 1) end,
            FovToggle = fovToggle,
        }
    end

    ------------------------------------------------ SETTINGS TAB
    function Window:CreateSettingsTab()
        local Opt = Novier.Settings
        local Tab = Window:CreateTab("SETTINGS", "⚙")

        local Look = Tab:CreateSection("Appearance")
        Look:CreateThemeGrid({ Flag = "ui_theme" })
        Look:CreateSlider("UI Scale", 60, 130, math.floor(Opt.UIScale * 100), 5, function(v)
            Opt.UIScale = v / 100
            refreshScale()
        end, { Flag = "ui_scale", Tooltip = "Scales the whole island (phones: try 70%)" })
        Look:CreateToggle("Show FPS / Ping in pill", Opt.ShowStats, function(v) Opt.ShowStats = v end, { Flag = "ui_stats" })
        Look:CreateToggle("Background blur when open", Opt.Blur, function(v)
            Opt.Blur = v
            if Blur then tween(Blur, { Size = (v and Window.DrawerOpen) and 10 or 0 }, 0.25) end
        end, { Flag = "ui_blur" })
        Look:CreateToggle("UI sounds", Opt.UISounds, function(v) Opt.UISounds = v end, { Flag = "ui_sfx" })

        local Vis = Tab:CreateSection("Visuals")
        Vis:CreateToggle("Edge spectrum & glows", Opt.EdgeVisuals, function(v) Opt.EdgeVisuals = v end, { Flag = "vis_edges" })
        Vis:CreateSlider("Edge spectrum size", 0.4, 2, Opt.EdgeSize, 0.1, function(v) Opt.EdgeSize = v end, { Flag = "vis_edge_size", Tooltip = "How far the side bars reach" })
        Vis:CreateSlider("Pulse strength", 0, 2, Opt.Pulse, 0.1, function(v) Opt.Pulse = v end, { Flag = "vis_pulse", Tooltip = "Glows, rings and border pulse" })
        Vis:CreateToggle("Code rain", Opt.Rain, function(v) Opt.Rain = v end, { Flag = "vis_rain" })
        Vis:CreateToggle("Beat shockwave rings", Opt.Rings, function(v) Opt.Rings = v end, { Flag = "vis_rings" })
        Vis:CreateToggle("Idle breathing (no music)", Opt.IdleBreathing, function(v) Opt.IdleBreathing = v end, { Flag = "vis_idle" })
        Vis:CreateSlider("Visual FPS cap", 20, 144, Opt.VisualHz, 1, function(v) Opt.VisualHz = v end, { Flag = "vis_hz", Tooltip = "Lower this if the visuals cost you frames" })

        local Aud = Tab:CreateSection("Audio Reactivity")
        Aud:CreateSlider("Sensitivity", 0.3, 2.5, Opt.Sensitivity, 0.05, function(v) Opt.Sensitivity = v end, { Flag = "aud_sens" })
        Aud:CreateToggle("Auto gain", Opt.AutoGain, function(v) Opt.AutoGain = v end, { Flag = "aud_gain", Tooltip = "Normalises quiet and loud tracks" })

        local Keys = Tab:CreateSection("Keybinds")
        Keys:CreateKeybind("Toggle UI", Window.ToggleKey, nil, { Flag = "key_toggle", OnChanged = function(k) if k then Window.ToggleKey = k end end })
        Keys:CreateKeybind("Beat FOV", Window.FovKey, nil, { Flag = "key_fov", OnChanged = function(k) if k then Window.FovKey = k end end })

        local Cfg = Tab:CreateSection("Config")
        local cfgName = "default"
        Cfg:CreateTextbox("Config name", "default", false, function(t) if t and #t > 0 then cfgName = t end end)
        Cfg:CreateButton("Save config", function()
            local ok, err = Novier:SaveConfig(cfgName)
            Novier:Notify("Config", ok and ("Saved '" .. cfgName .. "'") or ("Save failed: " .. tostring(err)), 2.5, ok and "Success" or "Error")
        end)
        Cfg:CreateButton("Load config", function()
            local ok, err = Novier:LoadConfig(cfgName)
            Novier:Notify("Config", ok and ("Loaded '" .. cfgName .. "'") or ("Load failed: " .. tostring(err)), 2.5, ok and "Success" or "Error")
        end)
        return Tab
    end

    ------------------------------------------------ INTRO
    Window:AddFrameHook(function() end)
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
            Name = "NotifyStack", Size = UDim2.fromOffset(310, 460), Position = UDim2.new(1, -16, 1, -24),
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

    local Slot = create("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, ZIndex = 501, Parent = Holder })
    local Card = create("Frame", {
        Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(1.3, 0), BackgroundColor3 = th.SurfaceElevated,
        ClipsDescendants = true, ZIndex = 501, Parent = Slot,
    }, {
        create("UICorner", { CornerRadius = rad("CardRadius") }),
        create("UIStroke", { Thickness = 1.2, Color = edge, Transparency = Novier.Style.Family == "Adwaita" and 0.6 or 0 }),
    })
    create("Frame", {
        Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = edge, BorderSizePixel = 0, ZIndex = 502,
        Visible = Novier.Style.Family ~= "Adwaita", Parent = Card,
    })
    create("TextLabel", {
        Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(14, 18), BackgroundColor3 = edge, BackgroundTransparency = 0.82,
        Text = icon, Font = S("FontBold"), TextSize = 15, TextColor3 = edge, ZIndex = 502, Parent = Card,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    create("TextLabel", {
        Size = UDim2.new(1, -66, 0, 16), Position = UDim2.fromOffset(54, 9), BackgroundTransparency = 1,
        Text = Novier.Style.Upper and string.upper(tostring(title)) or tostring(title), Font = S("FontBold"), TextSize = 12,
        TextColor3 = edge, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 502, Parent = Card,
    })
    create("TextLabel", {
        Size = UDim2.new(1, -66, 0, 30), Position = UDim2.fromOffset(54, 26), BackgroundTransparency = 1, Text = tostring(message),
        Font = S("Font"), TextSize = 11, TextColor3 = th.TextPrimary, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 502, Parent = Card,
    })
    local Progress = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = edge, BorderSizePixel = 0, ZIndex = 503, Parent = Card,
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

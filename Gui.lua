-- LynxGUI_v2.3.lua - Optimized Edition with Anti-Duplica
-- FREE NOT FOR SALE

repeat task.wait() until game:IsLoaded()

-- ============================================
-- ANTI-DUPLICATE SYSTEM - Destroy old GUI first
-- ============================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer
repeat task.wait() until localPlayer:FindFirstChild("PlayerGui")

-- Check and destroy existing GUI in CoreGui
local existingGUI = CoreGui:FindFirstChild("LynxGUI_Galaxy")
if existingGUI then
    existingGUI:Destroy()
    task.wait(0.1) -- Small delay untuk ensure cleanup
end

-- ============================================
-- PERFORMANCE OPTIMIZATION SETTINGS
-- ============================================
local TWEEN_SPEED = 0.15
local HOVER_SPEED = 0.1
local USE_TWEEN = false  -- Disabled for Global Low Power Mode

-- ============================================
-- SERVICES - Cache untuk performa
-- ============================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Detect if mobile
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================
-- OPTIMIZED INSTANCE CREATOR
-- ============================================
local function new(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do 
        inst[k] = v 
    end
    return inst
end

-- ============================================
-- CONFIG SYSTEM - INTEGRATED AUTO SAVE
-- ============================================
local HttpService = game:GetService("HttpService")

local ConfigSystem = {}
ConfigSystem.Version = "1.1"

-- CONFIG SETTINGS
local CONFIG_FOLDER = "LynxGUI_Configs"
local CONFIG_FILE = CONFIG_FOLDER .. "/lynx_config.json"

-- DEFAULT CONFIG STRUCTURE
local DefaultConfig = {
    -- Main Page - Auto Fishing
    InstantFishing = {
        Mode = "Fast", -- "Fast", "Perfect"
        Enabled = false,
        FishingDelay = 1.30,
        CancelDelay = 0.19
    },
    
    -- Blatant Tester
    BlatantTester = {
        Enabled = false,
        CompleteDelay = 0.5,
        CancelDelay = 0.1
    },
    
    -- Blatant V1
    BlatantV1 = {
        Enabled = false,
        CompleteDelay = 0.05,
        CancelDelay = 0.1
    },
    
    -- Ultra Blatant (Blatant V2)
    UltraBlatant = {
        Enabled = false,
        CompleteDelay = 0.05,
        CancelDelay = 0.1
    },
    
    -- Fast Auto Fishing Perfect
    FastAutoPerfect = {
        Enabled = false,
        FishingDelay = 0.05,
        CancelDelay = 0.01,
        TimeoutDelay = 0.8
    },
    
    -- Support Features
    Support = {
        NoFishingAnimation = false,
        PingFPSMonitor = false,
        LockPosition = false,
        AutoEquipRod = false,
        DisableCutscenes = false,
        DisableObtainedNotif = false,
        DisableSkinEffect = false,
        WalkOnWater = false,
        GoodPerfectionStable = false,
        SkinAnimation = {
            Enabled = false,
            Current = "Eclipse"
        }
    },
    
    -- Auto Favorite
    AutoFavorite = {
        EnabledTiers = {},
        EnabledVariants = {}
    },
    
    -- Teleport
    Teleport = {
        SavedLocation = nil,
        LastEventSelected = nil,
        AutoTeleportEvent = false
    },
    
    -- Shop
    Shop = {
        AutoSellTimer = {
            Enabled = false,
            Interval = 5
        },
        AutoBuyWeather = {
            Enabled = false,
            SelectedWeathers = {}
        }
    },
    
    -- Webhook
    Webhook = {
        Enabled = false,
        URL = "",
        DiscordID = "",
        EnabledRarities = {}
    },
    
    -- Camera View
    CameraView = {
        UnlimitedZoom = false,
        Freecam = {
            Enabled = false,
            Speed = 50,
            Sensitivity = 0.3
        }
    },
    
    -- Settings
    Settings = {
        AntiAFK = false,
        Sprint = false,
        InfiniteJump = false,
        FPSBooster = false,
        DisableRendering = false,
        FPSLimit = 60,
        HideStats = {
            Enabled = false,
            FakeName = "Guest",
            FakeLevel = "1"
        }
    }
}

local CurrentConfig = {}

-- UTILITY FUNCTIONS
local function DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function MergeTables(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            MergeTables(target[k], v)
        else
            target[k] = v
        end
    end
end

local function EnsureFolderExists()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

function ConfigSystem.Save()
    local success, err = pcall(function()
        EnsureFolderExists()
        local jsonData = HttpService:JSONEncode(CurrentConfig)
        writefile(CONFIG_FILE, jsonData)
    end)
    return success, err and tostring(err) or nil
end

function ConfigSystem.Load()
    EnsureFolderExists()
    CurrentConfig = DeepCopy(DefaultConfig)
    
    if isfile(CONFIG_FILE) then
        local success, result = pcall(function()
            local jsonData = readfile(CONFIG_FILE)
            local loadedConfig = HttpService:JSONDecode(jsonData)
            MergeTables(CurrentConfig, loadedConfig)
        end)
        return success, CurrentConfig
    end
    return false, CurrentConfig
end

function ConfigSystem.GetConfig()
    return CurrentConfig
end

function ConfigSystem.Get(path, defaultValue)
    if not path or type(path) ~= "string" then
        return defaultValue
    end
    
    local keys = {}
    for key in string.gmatch(path, "[^.]+") do
        table.insert(keys, key)
    end
    
    local value = CurrentConfig
    for _, key in ipairs(keys) do
        if type(value) == "table" then
            value = value[key]
        else
            return defaultValue
        end
    end
    return value ~= nil and value or defaultValue
end

function ConfigSystem.Set(path, value)
    if not path or type(path) ~= "string" then
        return -- Silently ignore if path is nil
    end
    
    local keys = {}
    for key in string.gmatch(path, "[^.]+") do
        table.insert(keys, key)
    end
    
    local target = CurrentConfig
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(target[key]) ~= "table" then
            target[key] = {}
        end
        target = target[key]
    end
    target[keys[#keys]] = value
end

-- Initialize with default config
CurrentConfig = DeepCopy(DefaultConfig)

-- ============================================
-- DIRTY FLAG AUTO SAVE SYSTEM
-- ============================================
local isDirty = false
local saveScheduled = false

local function ScheduleSave()
    if saveScheduled then return end
    saveScheduled = true
    
    task.delay(5, function()  -- Save after 5 seconds of no changes
        if isDirty then
            ConfigSystem.Save()
            isDirty = false
        end
        saveScheduled = false
    end)
end

local function MarkDirty()
    isDirty = true
    ScheduleSave()
end

-- ============================================
-- SECURITY LOADER
-- ============================================
local SecurityLoader = loadstring(game:HttpGet("https://raw.githubusercontent.com/cyaahekel/pemerintah/refs/heads/main/SecurityLoader.lua"))()

-- Load all modules
local instant = SecurityLoader.LoadModule("instant")
local instant2 = SecurityLoader.LoadModule("instant2")
local blatantv1 = SecurityLoader.LoadModule("blatantv1")
local UltraBlatant = SecurityLoader.LoadModule("UltraBlatant")
local blatantv2 = SecurityLoader.LoadModule("blatantv2")
local blatantv2fix = SecurityLoader.LoadModule("blatantv2fix")
local NoFishingAnimation = SecurityLoader.LoadModule("NoFishingAnimation")
local LockPosition = SecurityLoader.LoadModule("LockPosition")
local DisableCutscenes = SecurityLoader.LoadModule("DisableCutscenes")
local DisableExtras = SecurityLoader.LoadModule("DisableExtras")
local AutoTotem3X = SecurityLoader.LoadModule("AutoTotem3X")
local SkinAnimation = SecurityLoader.LoadModule("SkinAnimation")
local WalkOnWater = SecurityLoader.LoadModule("WalkOnWater")
local TeleportModule = SecurityLoader.LoadModule("TeleportModule")
local TeleportToPlayer = SecurityLoader.LoadModule("TeleportToPlayer")
local SavedLocation = SecurityLoader.LoadModule("SavedLocation")
local AutoSellSystem = SecurityLoader.LoadModule("AutoSellSystem")
local MerchantSystem = SecurityLoader.LoadModule("MerchantSystem")
local RemoteBuyer = SecurityLoader.LoadModule("RemoteBuyer")
local FreecamModule = SecurityLoader.LoadModule("FreecamModule")
local UnlimitedZoomModule = SecurityLoader.LoadModule("UnlimitedZoomModule")
local AntiAFK = SecurityLoader.LoadModule("AntiAFK")
local UnlockFPS = SecurityLoader.LoadModule("UnlockFPS")
local FPSBooster = SecurityLoader.LoadModule("FPSBooster")
local AutoBuyWeather = SecurityLoader.LoadModule("AutoBuyWeather")
local Notify = SecurityLoader.LoadModule("Notify")
local GoodPerfectionStable = SecurityLoader.LoadModule("GoodPerfectionStable")
local PingFPSMonitor = SecurityLoader.LoadModule("PingFPSMonitor")
local DisableRendering = SecurityLoader.LoadModule("DisableRendering")
local MovementModule = SecurityLoader.LoadModule("MovementModule")
local AutoFavorite = SecurityLoader.LoadModule("AutoFavorite")
local WebhookModule = SecurityLoader.LoadModule("Webhook")
local HideStats = SecurityLoader.LoadModule("HideStats")

-- ============================================
-- MODERN COLOR PALETTE - CLEAN & COMPACT
-- ============================================
local colors = {
    primary = Color3.fromRGB(59, 130, 246),    -- Modern blue
    secondary = Color3.fromRGB(16, 185, 129),  -- Modern green
    accent = Color3.fromRGB(139, 92, 246),     -- Modern purple
    success = Color3.fromRGB(34, 197, 94),
    warning = Color3.fromRGB(251, 191, 36),
    error = Color3.fromRGB(239, 68, 68),
    
    bg1 = Color3.fromRGB(15, 23, 42),          -- Dark slate
    bg2 = Color3.fromRGB(30, 41, 59),          -- Slate
    bg3 = Color3.fromRGB(51, 65, 85),          -- Light slate
    bg4 = Color3.fromRGB(71, 85, 105),         -- Lighter slate
    
    text = Color3.fromRGB(248, 250, 252),      -- Off-white
    textDim = Color3.fromRGB(203, 213, 225),   -- Light gray
    textDimmer = Color3.fromRGB(148, 163, 184), -- Medium gray
    
    border = Color3.fromRGB(51, 65, 85),       -- Subtle border
    hover = Color3.fromRGB(59, 130, 246),      -- Blue hover
}

-- ============================================
-- WINDOW CONFIGURATION - MORE COMPACT
-- ============================================
local windowSize = UDim2.new(0, 380, 0, 260)
local minWindowSize = Vector2.new(350, 240)
local maxWindowSize = Vector2.new(500, 350)
local sidebarWidth = 120

-- ============================================
-- MAIN GUI CONTAINER
-- ============================================
local gui = new("ScreenGui",{
    Name="LynxGUI_Galaxy",
    Parent=CoreGui,
    IgnoreGuiInset=true,
    ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    DisplayOrder=2147483647
})

-- ============================================
-- OPTIMIZED: Bring to Front Function
-- ============================================
local function bringToFront()
    gui.DisplayOrder = 2147483647
end

-- ============================================
-- MAIN WINDOW
-- ============================================
local win = new("Frame",{
    Parent=gui,
    Size=windowSize,
    Position=UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
    BackgroundColor3=colors.bg1,
    BackgroundTransparency=0.3,
    BorderSizePixel=0,
    ClipsDescendants=false,
    ZIndex=3
})
new("UICorner",{Parent=win, CornerRadius=UDim.new(0, 12)})

-- REMOVED: UIStroke untuk performa lebih ringan

-- ============================================
-- SIDEBAR
-- ============================================
local sidebar = new("Frame",{
    Parent=win,
    Size=UDim2.new(0, sidebarWidth, 1, -45),
    Position=UDim2.new(0, 0, 0, 45),
    BackgroundColor3=colors.bg2,
    BackgroundTransparency=0.8,
    BorderSizePixel=0,
    ClipsDescendants=true,
    ZIndex=4
})
new("UICorner",{Parent=sidebar, CornerRadius=UDim.new(0, 12)})

-- ============================================
-- HEADER - REDESIGNED WITH BETTER LAYOUT
-- ============================================
local scriptHeader = new("Frame",{
    Parent=win,
    Size=UDim2.new(1, 0, 0, 35),
    Position=UDim2.new(0, 0, 0, 0),
    BackgroundColor3=colors.bg2,
    BorderSizePixel=0,
    ZIndex=5
})
new("UICorner",{Parent=scriptHeader, CornerRadius=UDim.new(0, 8)})

-- REMOVED: Gradient effect untuk performa lebih ringan

-- Drag Handle
local headerDragHandle = new("Frame",{
    Parent=scriptHeader,
    Size=UDim2.new(0, 40, 0, 3),
    Position=UDim2.new(0.5, -20, 0, 8),
    BackgroundColor3=colors.primary,
    BackgroundTransparency=0.85,
    BorderSizePixel=0,
    ZIndex=6
})
new("UICorner",{Parent=headerDragHandle, CornerRadius=UDim.new(1, 0)})

-- ============================================
-- TITLE WITH VERSION - REDESIGNED LAYOUT
-- ============================================
-- Main title "LynX"
local titleLabel = new("TextLabel",{
    Parent=scriptHeader,
    Text="LynX",
    Size=UDim2.new(0, 70, 1, 0),
    Position=UDim2.new(0, 12, 0, 0),
    BackgroundTransparency=1,
    Font=Enum.Font.GothamBlack,
    TextSize=16,
    TextColor3=colors.primary,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=6
})

-- Version label - minimalist style, no background
local versionLabel = new("TextLabel",{
    Parent=scriptHeader,
    Text="v2.3",
    Size=UDim2.new(0, 35, 1, 0),
    Position=UDim2.new(0, 82, 0, 0),
    BackgroundTransparency=1,
    Font=Enum.Font.GothamMedium,
    TextSize=10,
    TextColor3=colors.textDim,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=6
})

-- Separator with better positioning
local separator = new("Frame",{
    Parent=scriptHeader,
    Size=UDim2.new(0, 1, 0, 20),
    Position=UDim2.new(0, 125, 0.5, -10),
    BackgroundColor3=colors.border,
    BorderSizePixel=0,
    ZIndex=6
})

-- Subtitle with better alignment
local subtitleLabel = new("TextLabel",{
    Parent=scriptHeader,
    Text="Free Not For Sale",
    Size=UDim2.new(0, 140, 1, 0),
    Position=UDim2.new(0, 135, 0, 0),
    BackgroundTransparency=1,
    Font=Enum.Font.GothamMedium,
    TextSize=9,
    TextColor3=colors.textDim,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=6
})

-- ============================================
-- MINIMIZE BUTTON
-- ============================================
local btnMinHeader = new("TextButton",{
    Parent=scriptHeader,
    Size=UDim2.new(0, 30, 0, 30),
    Position=UDim2.new(1, -38, 0.5, -15),
    BackgroundColor3=colors.bg4,
    BackgroundTransparency=0.6,
    BorderSizePixel=0,
    Text="─",
    Font=Enum.Font.GothamBold,
    TextSize=18,
    TextColor3=colors.textDim,
    TextTransparency=0.3,
    AutoButtonColor=false,
    ZIndex=7
})
new("UICorner",{Parent=btnMinHeader, CornerRadius=UDim.new(0, 8)})

-- REMOVED: btnStroke dan hover animations untuk performa maksimal

-- ============================================
-- NAVIGATION CONTAINER
-- ============================================
local navContainer = new("ScrollingFrame",{
    Parent=sidebar,
    Size=UDim2.new(1, -8, 1, -12),
    Position=UDim2.new(0, 4, 0, 6),
    BackgroundTransparency=1,
    ScrollBarThickness=2,
    ScrollBarImageColor3=colors.primary,
    BorderSizePixel=0,
    CanvasSize=UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    -- REMOVED: ClipsDescendants untuk performa
    ZIndex=5
})
new("UIListLayout",{
    Parent=navContainer,
    Padding=UDim.new(0, 4),
    SortOrder=Enum.SortOrder.LayoutOrder
})

-- ============================================
-- CONTENT AREA
-- ============================================
local contentBg = new("Frame",{
    Parent=win,
    Size=UDim2.new(1, -(sidebarWidth + 10), 1, -52),
    Position=UDim2.new(0, sidebarWidth + 5, 0, 47),
    BackgroundColor3=colors.bg2,
    BackgroundTransparency=0.85,
    BorderSizePixel=0,
    ClipsDescendants=true,
    ZIndex=4
})
new("UICorner",{Parent=contentBg, CornerRadius=UDim.new(0, 12)})

-- ============================================
-- TOP BAR (Page Title)
-- ============================================
local topBar = new("Frame",{
    Parent=contentBg,
    Size=UDim2.new(1, -8, 0, 32),
    Position=UDim2.new(0, 4, 0, 4),
    BackgroundColor3=colors.bg3,
    BackgroundTransparency=0.85,
    BorderSizePixel=0,
    ZIndex=5
})
new("UICorner",{Parent=topBar, CornerRadius=UDim.new(0, 10)})

local pageTitle = new("TextLabel",{
    Parent=topBar,
    Text="Main Dashboard",
    Size=UDim2.new(1, -20, 1, 0),
    Position=UDim2.new(0, 12, 0, 0),
    Font=Enum.Font.GothamBold,
    TextSize=11,
    BackgroundTransparency=1,
    TextColor3=colors.text,
    TextTransparency=0.2,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=6
})

-- ============================================
-- RESIZE HANDLE
-- ============================================
local resizing = false
local resizeStart, startSize = nil, nil

local resizeHandle = new("TextButton",{
    Parent=win,
    Size=UDim2.new(0, 18, 0, 18),
    Position=UDim2.new(1, -18, 1, -18),
    BackgroundColor3=colors.bg3,
    BackgroundTransparency=0.7,
    BorderSizePixel=0,
    Text="⋰",
    Font=Enum.Font.GothamBold,
    TextSize=11,
    TextColor3=colors.textDim,
    TextTransparency=0.4,
    AutoButtonColor=false,
    ZIndex=100
})
new("UICorner",{Parent=resizeHandle, CornerRadius=UDim.new(0, 6)})

-- REMOVED: resizeStroke untuk performa lebih ringan

-- REMOVED: Hover animations untuk performa maksimal

-- ============================================
-- PAGES SYSTEM
-- ============================================
local pages = {}
local currentPage = "Main"
local navButtons = {}

local function createPage(name)
    local page = new("ScrollingFrame",{
        Parent=contentBg,
        Size=UDim2.new(1, -16, 1, -44),
        Position=UDim2.new(0, 8, 0, 40),
        BackgroundTransparency=1,
        ScrollBarThickness=3,
        ScrollBarImageColor3=colors.primary,
        BorderSizePixel=0,
        CanvasSize=UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false,
        -- REMOVED: ClipsDescendants untuk performa
        ZIndex=5
    })
    new("UIListLayout",{
        Parent=page,
        Padding=UDim.new(0, 8),
        SortOrder=Enum.SortOrder.LayoutOrder
    })
    new("UIPadding",{
        Parent=page,
        PaddingTop=UDim.new(0, 4),
        PaddingBottom=UDim.new(0, 4)
    })
    pages[name] = page
    return page
end

-- Create all pages
local mainPage = createPage("Main")
local teleportPage = createPage("Teleport")
local shopPage = createPage("Shop")
local webhookPage = createPage("Webhook")
local cameraViewPage = createPage("CameraView")
local settingsPage = createPage("Settings")
local infoPage = createPage("Info")
mainPage.Visible = true

-- ============================================
-- LOAD CONFIG ON STARTUP
-- ============================================
local configLoaded, loadedConfig = ConfigSystem.Load()
if configLoaded then
    print("✅ [LynxGUI] Configuration loaded successfully!")
else
    print("⚠️ [LynxGUI] Using default configuration")
end

-- ============================================
-- CALLBACK REGISTRY FOR CONFIG LOADING
-- ============================================
local CallbackRegistry = {}

local function RegisterCallback(configPath, callback, componentType, defaultValue)
    if configPath then
        table.insert(CallbackRegistry, {
            path = configPath,
            callback = callback,
            type = componentType,
            default = defaultValue
        })
    end
end

local function ExecuteConfigCallbacks()
    for _, entry in ipairs(CallbackRegistry) do
        local value = ConfigSystem.Get(entry.path, entry.default)
        if entry.type == "toggle" then
            -- For toggles, call callback with boolean value
            if entry.callback then entry.callback(value) end
        elseif entry.type == "input" then
            -- For inputs, call callback with numeric value
            if entry.callback then entry.callback(value) end
        elseif entry.type == "dropdown" then
            -- For dropdowns, call callback with selected value
            if entry.callback then entry.callback(value) end
        end
    end
end

-- ============================================
-- INITIALIZE MODULE SETTINGS FROM CONFIG
-- ============================================
local function InitializeModuleSettings()
    -- Initialize Instant Fishing settings
    local instantFishingDelay = ConfigSystem.Get("InstantFishing.FishingDelay", 1.30)
    local instantCancelDelay = ConfigSystem.Get("InstantFishing.CancelDelay", 0.19)
    if instant and instant.Settings then
        instant.Settings.MaxWaitTime = instantFishingDelay
        instant.Settings.CancelDelay = instantCancelDelay
    end
    if instant2 and instant2.Settings then
        instant2.Settings.MaxWaitTime = instantFishingDelay
        instant2.Settings.CancelDelay = instantCancelDelay
    end
    
    -- Initialize Blatant Tester settings
    local blatantTesterCompleteDelay = ConfigSystem.Get("BlatantTester.CompleteDelay", 0.5)
    local blatantTesterCancelDelay = ConfigSystem.Get("BlatantTester.CancelDelay", 0.1)
    if blatantv2fix and blatantv2fix.Settings then
        blatantv2fix.Settings.CompleteDelay = blatantTesterCompleteDelay
        blatantv2fix.Settings.CancelDelay = blatantTesterCancelDelay
    end
    
    -- Initialize Blatant V1 settings
    local blatantV1CompleteDelay = ConfigSystem.Get("BlatantV1.CompleteDelay", 0.05)
    local blatantV1CancelDelay = ConfigSystem.Get("BlatantV1.CancelDelay", 0.1)
    if blatantv1 and blatantv1.Settings then
        blatantv1.Settings.CompleteDelay = blatantV1CompleteDelay
        blatantv1.Settings.CancelDelay = blatantV1CancelDelay
    end
    
    -- Initialize Ultra Blatant settings
    local ultraBlatantCompleteDelay = ConfigSystem.Get("UltraBlatant.CompleteDelay", 0.05)
    local ultraBlatantCancelDelay = ConfigSystem.Get("UltraBlatant.CancelDelay", 0.1)
    if UltraBlatant and UltraBlatant.UpdateSettings then
        UltraBlatant.UpdateSettings(ultraBlatantCompleteDelay, ultraBlatantCancelDelay, nil)
    end
    
    -- Initialize Fast Auto Perfect settings
    local fastAutoFishingDelay = ConfigSystem.Get("FastAutoPerfect.FishingDelay", 0.05)
    local fastAutoCancelDelay = ConfigSystem.Get("FastAutoPerfect.CancelDelay", 0.01)
    local fastAutoTimeoutDelay = ConfigSystem.Get("FastAutoPerfect.TimeoutDelay", 0.8)
    if blatantv2 and blatantv2.Settings then
        blatantv2.Settings.FishingDelay = fastAutoFishingDelay
        blatantv2.Settings.CancelDelay = fastAutoCancelDelay
        blatantv2.Settings.TimeoutDelay = fastAutoTimeoutDelay
    end
end

-- ============================================
-- NAV BUTTON - ULTRA OPTIMIZED
-- ============================================
local function createNavButton(text, icon, page, order)
    local btn = new("TextButton",{
        Parent=navContainer,
        Size=UDim2.new(1, 0, 0, 38),
        BackgroundColor3=page == currentPage and colors.bg3 or Color3.fromRGB(0, 0, 0),
        BackgroundTransparency=page == currentPage and 0.75 or 1,
        BorderSizePixel=0,
        Text="",
        AutoButtonColor=false,
        LayoutOrder=order,
        ZIndex=6
    })
    new("UICorner",{Parent=btn, CornerRadius=UDim.new(0, 9)})
    
    local indicator = new("Frame",{
        Parent=btn,
        Size=UDim2.new(0, 3, 0, 20),
        Position=UDim2.new(0, 0, 0.5, -10),
        BackgroundColor3=colors.primary,
        BorderSizePixel=0,
        Visible=page == currentPage,
        ZIndex=7
    })
    new("UICorner",{Parent=indicator, CornerRadius=UDim.new(1, 0)})
    
    local iconLabel = new("TextLabel",{
        Parent=btn,
        Text=icon,
        Size=UDim2.new(0, 30, 1, 0),
        Position=UDim2.new(0, 10, 0, 0),
        BackgroundTransparency=1,
        Font=Enum.Font.GothamBold,
        TextSize=15,
        TextColor3=page == currentPage and colors.primary or colors.textDim,
        TextTransparency=page == currentPage and 0 or 0.3,
        ZIndex=7
    })
    
    local textLabel = new("TextLabel",{
        Parent=btn,
        Text=text,
        Size=UDim2.new(1, -45, 1, 0),
        Position=UDim2.new(0, 40, 0, 0),
        BackgroundTransparency=1,
        Font=Enum.Font.GothamBold,
        TextSize=10,
        TextColor3=page == currentPage and colors.text or colors.textDim,
        TextTransparency=page == currentPage and 0.1 or 0.4,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=7
    })
    
    -- REMOVED: Hover animations untuk performa maksimal
    
    navButtons[page] = {btn=btn, icon=iconLabel, text=textLabel, indicator=indicator}
    return btn
end

-- ============================================
-- OPTIMIZED PAGE SWITCHING
-- ============================================
local function switchPage(pageName, pageTitle_text)
    if currentPage == pageName then return end
    
    -- Hide all pages instantly (no fade)
    for _, page in pairs(pages) do 
        page.Visible = false 
    end
    
    -- Update buttons (use tween only if enabled)
    for name, btnData in pairs(navButtons) do
        local isActive = name == pageName
        
        if USE_TWEEN then
            TweenService:Create(btnData.btn, TweenInfo.new(TWEEN_SPEED), {
                BackgroundColor3=isActive and colors.bg3 or Color3.fromRGB(0, 0, 0),
                BackgroundTransparency=isActive and 0.75 or 1
            }):Play()
            TweenService:Create(btnData.icon, TweenInfo.new(TWEEN_SPEED), {
                TextColor3=isActive and colors.primary or colors.textDim,
                TextTransparency=isActive and 0 or 0.3
            }):Play()
            TweenService:Create(btnData.text, TweenInfo.new(TWEEN_SPEED), {
                TextColor3=isActive and colors.text or colors.textDim,
                TextTransparency=isActive and 0.1 or 0.4
            }):Play()
        else
            btnData.btn.BackgroundColor3 = isActive and colors.bg3 or Color3.fromRGB(0, 0, 0)
            btnData.btn.BackgroundTransparency = isActive and 0.75 or 1
            btnData.icon.TextColor3 = isActive and colors.primary or colors.textDim
            btnData.icon.TextTransparency = isActive and 0 or 0.3
            btnData.text.TextColor3 = isActive and colors.text or colors.textDim
            btnData.text.TextTransparency = isActive and 0.1 or 0.4
        end
        
        btnData.indicator.Visible = isActive
    end
    
    -- Show new page instantly
    pages[pageName].Visible = true
    pageTitle.Text = pageTitle_text
    currentPage = pageName
end

-- Create navigation buttons
local btnMain = createNavButton("Dashboard", "🏠", "Main", 1)
local btnTeleport = createNavButton("Teleport", "🌍", "Teleport", 2)
local btnShop = createNavButton("Shop", "🛒", "Shop", 3)
local btnWebhook = createNavButton("Webhook", "🔗", "Webhook", 4)
local btnCameraView = createNavButton("Camera View", "📷", "CameraView", 5)
local btnSettings = createNavButton("Settings", "⚙️", "Settings", 6)
local btnInfo = createNavButton("About", "ℹ️", "Info", 7)

-- Connect buttons
btnMain.MouseButton1Click:Connect(function() switchPage("Main", "Main Dashboard") end)
btnTeleport.MouseButton1Click:Connect(function() switchPage("Teleport", "Teleport System") end)
btnShop.MouseButton1Click:Connect(function() switchPage("Shop", "Shop Features") end)
btnWebhook.MouseButton1Click:Connect(function() switchPage("Webhook", "Webhook Page") end)
btnCameraView.MouseButton1Click:Connect(function() switchPage("CameraView", "Camera View Settings") end)
btnSettings.MouseButton1Click:Connect(function() switchPage("Settings", "Settings") end)
btnInfo.MouseButton1Click:Connect(function() switchPage("Info", "About Lynx") end)

-- ============================================
-- UI COMPONENTS - OPTIMIZED
-- ============================================

-- CATEGORY - OPTIMIZED
local function makeCategory(parent, title, icon)
    local categoryFrame = new("Frame",{
        Parent=parent,
        Size=UDim2.new(1, 0, 0, 36),
        BackgroundColor3=colors.bg3,
        BackgroundTransparency=0.7,
        BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.Y,
        ClipsDescendants=false,
        ZIndex=6
    })
    new("UICorner",{Parent=categoryFrame, CornerRadius=UDim.new(0, 6)})
    
    local header = new("TextButton",{
        Parent=categoryFrame,
        Size=UDim2.new(1, 0, 0, 36),
        BackgroundTransparency=1,
        Text="",
        AutoButtonColor=false,
        ClipsDescendants=true,
        ZIndex=7
    })
    
    local titleLabel = new("TextLabel",{
        Parent=header,
        Text=title,
        Size=UDim2.new(1, -50, 1, 0),
        Position=UDim2.new(0, 8, 0, 0),
        BackgroundTransparency=1,
        Font=Enum.Font.GothamBold,
        TextSize=11,
        TextColor3=colors.text,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=8
    })
    
    local arrow = new("TextLabel",{
        Parent=header,
        Text="▼",
        Size=UDim2.new(0, 20, 1, 0),
        Position=UDim2.new(1, -24, 0, 0),
        BackgroundTransparency=1,
        Font=Enum.Font.GothamBold,
        TextSize=10,
        TextColor3=colors.primary,
        ZIndex=8
    })
    
    local contentContainer = new("Frame",{
        Parent=categoryFrame,
        Size=UDim2.new(1, -16, 0, 0),
        Position=UDim2.new(0, 8, 0, 38),
        BackgroundTransparency=1,
        Visible=false,
        AutomaticSize=Enum.AutomaticSize.Y,
        ClipsDescendants=true,
        ZIndex=7
    })
    new("UIListLayout",{Parent=contentContainer, Padding=UDim.new(0, 6)})
    new("UIPadding",{Parent=contentContainer, PaddingBottom=UDim.new(0, 8)})
    
    local isOpen = false
    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        contentContainer.Visible = isOpen
        
        if USE_TWEEN then
            TweenService:Create(arrow, TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Back), {
                Rotation=isOpen and 180 or 0
            }):Play()
            TweenService:Create(categoryFrame, TweenInfo.new(TWEEN_SPEED), {
                BackgroundTransparency=isOpen and 0.5 or 0.7
            }):Play()
        else
            arrow.Rotation = isOpen and 180 or 0
            categoryFrame.BackgroundTransparency = isOpen and 0.5 or 0.7
        end
    end)
    
    return contentContainer
end

-- TOGGLE - OPTIMIZED
local function makeToggle(parent, label, param3, param4)
    -- Detect if param3 is configPath (string) or callback (function)
    local configPath = type(param3) == "string" and param3 or nil
    local callback = type(param3) == "function" and param3 or param4
    
    local frame = new("Frame",{
        Parent=parent,
        Size=UDim2.new(1, 0, 0, 32),
        BackgroundTransparency=1,
        ZIndex=7
    })
    
    local labelText = new("TextLabel",{
        Parent=frame,
        Text=label,
        Size=UDim2.new(0.68, 0, 1, 0),
        Position=UDim2.new(0, 0, 0, 0),
        TextXAlignment=Enum.TextXAlignment.Left,
        BackgroundTransparency=1,
        TextColor3=colors.text,
        Font=Enum.Font.GothamBold,
        TextSize=9,
        TextWrapped=true,
        ZIndex=8
    })
    
    local toggleBg = new("Frame",{
        Parent=frame,
        Size=UDim2.new(0, 38, 0, 20),
        Position=UDim2.new(1, -38, 0.5, -10),
        BackgroundColor3=colors.bg4,
        BorderSizePixel=0,
        ZIndex=8
    })
    new("UICorner",{Parent=toggleBg, CornerRadius=UDim.new(1, 0)})
    
    local toggleCircle = new("Frame",{
        Parent=toggleBg,
        Size=UDim2.new(0, 16, 0, 16),
        Position=UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3=colors.textDim,
        BorderSizePixel=0,
        ZIndex=9
    })
    new("UICorner",{Parent=toggleCircle, CornerRadius=UDim.new(1, 0)})
    
    local btn = new("TextButton",{
        Parent=toggleBg,
        Size=UDim2.new(1, 0, 1, 0),
        BackgroundTransparency=1,
        Text="",
        ZIndex=10
    })
    
    -- Load initial value from config
    local on = ConfigSystem.Get(configPath, false)
    
    -- Set initial visual state
    toggleBg.BackgroundColor3 = on and colors.primary or colors.bg4
    toggleCircle.Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    toggleCircle.BackgroundColor3 = on and colors.text or colors.textDim
    
    btn.MouseButton1Click:Connect(function()
        local newState = not on
        on = newState
        
        if USE_TWEEN then
            TweenService:Create(toggleBg, TweenInfo.new(TWEEN_SPEED), {
                BackgroundColor3=on and colors.primary or colors.bg4
            }):Play()
            TweenService:Create(toggleCircle, TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Back), {
                Position=on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3=on and colors.text or colors.textDim
            }):Play()
        else
            toggleBg.BackgroundColor3 = on and colors.primary or colors.bg4
            toggleCircle.Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            toggleCircle.BackgroundColor3 = on and colors.text or colors.textDim
        end
        
        -- Save to config and mark dirty
        ConfigSystem.Set(configPath, on)
        MarkDirty()
        
        -- Call original callback
        if callback then callback(on) end
    end)
    
    -- Register callback for config loading
    RegisterCallback(configPath, callback, "toggle", false)
end

-- INPUT HORIZONTAL - OPTIMIZED
local function makeInput(parent, label, param3, param4, param5)
    -- Detect parameters: makeInput(parent, label, configPath, defaultValue, callback) or makeInput(parent, label, defaultValue, callback)
    local configPath, defaultValue, callback
    if type(param3) == "string" then
        configPath = param3
        defaultValue = param4
        callback = param5
    else
        configPath = nil
        defaultValue = param3
        callback = param4
    end
    
    local frame = new("Frame",{
        Parent=parent,
        Size=UDim2.new(1, 0, 0, 32),
        BackgroundTransparency=1,
        ZIndex=7
    })
    
    local lbl = new("TextLabel",{
        Parent=frame,
        Text=label,
        Size=UDim2.new(0.55, 0, 1, 0),
        Position=UDim2.new(0, 0, 0, 0),
        BackgroundTransparency=1,
        TextColor3=colors.text,
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamBold,
        TextSize=9,
        ZIndex=8
    })
    
    local inputBg = new("Frame",{
        Parent=frame,
        Size=UDim2.new(0.42, 0, 0, 28),
        Position=UDim2.new(0.58, 0, 0.5, -14),
        BackgroundColor3=colors.bg4,
        BackgroundTransparency=0.5,
        BorderSizePixel=0,
        ZIndex=8
    })
    new("UICorner",{Parent=inputBg, CornerRadius=UDim.new(0, 6)})
    
    -- REMOVED: inputStroke untuk performa lebih ringan
    
    -- Load initial value from config
    local initialValue = ConfigSystem.Get(configPath, defaultValue)
    
    local inputBox = new("TextBox",{
        Parent=inputBg,
        Size=UDim2.new(1, -12, 1, 0),
        Position=UDim2.new(0, 6, 0, 0),
        BackgroundTransparency=1,
        Text=tostring(initialValue),
        PlaceholderText="0.00",
        Font=Enum.Font.GothamBold,
        TextSize=9,
        TextColor3=colors.text,
        PlaceholderColor3=colors.textDimmer,
        TextXAlignment=Enum.TextXAlignment.Center,
        ClearTextOnFocus=false,
        ZIndex=9
    })
    
    inputBox.Focused:Connect(function()
        -- REMOVED: inputStroke tween untuk performa
    end)
    
    inputBox.FocusLost:Connect(function()
        -- REMOVED: inputStroke tween untuk performa
        
        local value = tonumber(inputBox.Text)
        if value then
            -- Save to config and mark dirty
            ConfigSystem.Set(configPath, value)
            MarkDirty()
            
            -- Call original callback
            if callback then callback(value) end
        else
            inputBox.Text = tostring(initialValue)
        end
    end)
    
    -- Register callback for config loading
    RegisterCallback(configPath, callback, "input", defaultValue)
end

-- DROPDOWN - OPTIMIZED
local function makeDropdown(parent, title, icon, items, param5, param6, param7)
    -- Detect parameters: makeDropdown(parent, title, icon, items, configPath, onSelect, uniqueId) or makeDropdown(parent, title, icon, items, onSelect, uniqueId)
    local configPath, onSelect, uniqueId
    if type(param5) == "string" then
        configPath = param5
        onSelect = param6
        uniqueId = param7
    else
        configPath = nil
        onSelect = param5
        uniqueId = param6
    end
    
    local dropdownFrame = new("Frame",{
        Parent=parent,
        Size=UDim2.new(1, 0, 0, 40),
        BackgroundColor3=colors.bg4,
        BackgroundTransparency=0.6,
        BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.Y,
        ZIndex=7,
        Name=uniqueId or "Dropdown"
    })
    new("UICorner",{Parent=dropdownFrame, CornerRadius=UDim.new(0, 6)})
    
    local header = new("TextButton",{
        Parent=dropdownFrame,
        Size=UDim2.new(1, -12, 0, 36),
        Position=UDim2.new(0, 6, 0, 2),
        BackgroundTransparency=1,
        Text="",
        AutoButtonColor=false,
        ZIndex=8
    })
    
    local iconLabel = new("TextLabel",{
        Parent=header,
        Text=icon,
        Size=UDim2.new(0, 24, 1, 0),
        BackgroundTransparency=1,
        Font=Enum.Font.GothamBold,
        TextSize=12,
        TextColor3=colors.primary,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=9
    })
    
    local titleLabel = new("TextLabel",{
        Parent=header,
        Text=title,
        Size=UDim2.new(1, -70, 0, 14),
        Position=UDim2.new(0, 26, 0, 4),
        BackgroundTransparency=1,
        Font=Enum.Font.GothamBold,
        TextSize=9,
        TextColor3=colors.text,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=9
    })
    
    -- Load initial selected from config if configPath provided
    local initialSelected = configPath and ConfigSystem.Get(configPath, nil) or nil
    local selectedItem = initialSelected
    
    local statusLabel = new("TextLabel",{
        Parent=header,
        Text=selectedItem or "None Selected",
        Size=UDim2.new(1, -70, 0, 12),
        Position=UDim2.new(0, 26, 0, 20),
        BackgroundTransparency=1,
        Font=Enum.Font.GothamBold,
        TextSize=8,
        TextColor3=colors.textDimmer,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=9
    })
    
    local arrow = new("TextLabel",{
        Parent=header,
        Text="▼",
        Size=UDim2.new(0, 24, 1, 0),
        Position=UDim2.new(1, -24, 0, 0),
        BackgroundTransparency=1,
        Font=Enum.Font.GothamBold,
        TextSize=10,
        TextColor3=colors.primary,
        ZIndex=9
    })
    
    local listContainer = new("ScrollingFrame",{
        Parent=dropdownFrame,
        Size=UDim2.new(1, -12, 0, 0),
        Position=UDim2.new(0, 6, 0, 42),
        BackgroundTransparency=1,
        Visible=false,
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.new(0, 0, 0, 0),
        ScrollBarThickness=2,
        ScrollBarImageColor3=colors.primary,
        BorderSizePixel=0,
        ClipsDescendants=true,
        ZIndex=10
    })
    new("UIListLayout",{Parent=listContainer, Padding=UDim.new(0, 4)})
    new("UIPadding",{Parent=listContainer, PaddingBottom=UDim.new(0, 8)})
    
    local isOpen = false
    
    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        listContainer.Visible = isOpen
        
        if USE_TWEEN then
            TweenService:Create(arrow, TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Back), {
                Rotation=isOpen and 180 or 0
            }):Play()
            TweenService:Create(dropdownFrame, TweenInfo.new(TWEEN_SPEED), {
                BackgroundTransparency=isOpen and 0.45 or 0.6
            }):Play()
        else
            arrow.Rotation = isOpen and 180 or 0
            dropdownFrame.BackgroundTransparency = isOpen and 0.45 or 0.6
        end
        
        if isOpen then
            listContainer.Size = UDim2.new(1, -12, 0, math.min(#items * 28, 140))
        end
    end)
    
    for _, itemName in ipairs(items) do
        local itemBtn = new("TextButton",{
            Parent=listContainer,
            Size=UDim2.new(1, 0, 0, 26),
            BackgroundColor3=colors.bg4,
            BackgroundTransparency=0.7,
            BorderSizePixel=0,
            Text="",
            AutoButtonColor=false,
            ZIndex=11
        })
        new("UICorner",{Parent=itemBtn, CornerRadius=UDim.new(0, 5)})
        
        local btnLabel = new("TextLabel",{
            Parent=itemBtn,
            Text=itemName,
            Size=UDim2.new(1, -12, 1, 0),
            Position=UDim2.new(0, 6, 0, 0),
            BackgroundTransparency=1,
            Font=Enum.Font.GothamBold,
            TextSize=8,
            TextColor3=colors.textDim,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd,
            ZIndex=12
        })
        
        -- REMOVED: Hover animations untuk performa maksimal
        
        itemBtn.MouseButton1Click:Connect(function()
            selectedItem = itemName
            statusLabel.Text = "✓ " .. itemName
            statusLabel.TextColor3 = colors.success
            
            -- Save to config and mark dirty if configPath provided
            if configPath then
                ConfigSystem.Set(configPath, itemName)
                MarkDirty()
            end
            
            onSelect(itemName)
            
            task.wait(0.1)
            isOpen = false
            listContainer.Visible = false
            if USE_TWEEN then
                TweenService:Create(arrow, TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Back), {Rotation=0}):Play()
                TweenService:Create(dropdownFrame, TweenInfo.new(TWEEN_SPEED), {BackgroundTransparency=0.6}):Play()
            else
                arrow.Rotation = 0
                dropdownFrame.BackgroundTransparency = 0.6
            end
        end)
    end
    
    -- Register callback for config loading
    RegisterCallback(configPath, onSelect, "dropdown", nil)
    
    return dropdownFrame
end

-- BUTTON - OPTIMIZED
local function makeButton(parent, label, callback)
    local btnFrame = new("Frame",{
        Parent=parent,
        Size=UDim2.new(1, 0, 0, 32),
        BackgroundColor3=colors.primary,
        BackgroundTransparency=0.4,
        BorderSizePixel=0,
        ZIndex=8
    })
    new("UICorner",{Parent=btnFrame, CornerRadius=UDim.new(0, 6)})
    
    local button = new("TextButton",{
        Parent=btnFrame,
        Size=UDim2.new(1, 0, 1, 0),
        BackgroundTransparency=1,
        Text=label,
        Font=Enum.Font.GothamBold,
        TextSize=10,
        TextColor3=colors.text,
        AutoButtonColor=false,
        ZIndex=9
    })
    
    -- REMOVED: Hover animations untuk performa maksimal
    
    button.MouseButton1Click:Connect(function()
        if USE_TWEEN then
            TweenService:Create(btnFrame, TweenInfo.new(0.05), {Size=UDim2.new(0.98, 0, 0, 30)}):Play()
            task.wait(0.05)
            TweenService:Create(btnFrame, TweenInfo.new(0.05), {Size=UDim2.new(1, 0, 0, 32)}):Play()
        end
        pcall(callback)
    end)
    
    return btnFrame
end

-- ============================================
-- MULTI-SELECT DROPDOWN - OPTIMIZED & FIXED
-- ============================================
local function makeMultiSelectDropdown(parent, label, options, callback, configPath)
    local dropdownFrame = new("Frame",{
        Parent=parent,
        Size=UDim2.new(1, 0, 0, 40),
        BackgroundColor3=colors.bg4,
        BackgroundTransparency=0.6,
        BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.Y,
        ZIndex=7
    })
    new("UICorner",{Parent=dropdownFrame, CornerRadius=UDim.new(0, 6)})
    
    local lbl = new("TextLabel",{
        Parent=dropdownFrame,
        Text=label,
        Size=UDim2.new(0.5, -10, 0, 36),
        Position=UDim2.new(0, 8, 0, 2),
        BackgroundTransparency=1,
        TextColor3=colors.text,
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamBold,
        TextSize=9,
        ZIndex=8
    })
    
    local dropdownButton = new("TextButton",{
        Parent=dropdownFrame,
        Size=UDim2.new(0.48, 0, 0, 28),
        Position=UDim2.new(0.52, 0, 0, 6),
        BackgroundColor3=colors.bg3,
        BackgroundTransparency=0.5,
        BorderSizePixel=0,
        Text="Select... (0)",
        TextColor3=colors.textDim,
        TextSize=9,
        Font=Enum.Font.GothamBold,
        AutoButtonColor=false,
        ZIndex=8
    })
    new("UICorner",{Parent=dropdownButton, CornerRadius=UDim.new(0, 6)})
    
    local arrow = new("TextLabel",{
        Parent=dropdownButton,
        Size=UDim2.new(0, 20, 1, 0),
        Position=UDim2.new(1, -22, 0, 0),
        BackgroundTransparency=1,
        Text="▼",
        TextColor3=colors.primary,
        TextSize=10,
        Font=Enum.Font.GothamBold,
        ZIndex=9
    })
    
    local optionsContainer = new("ScrollingFrame",{
        Parent=dropdownFrame,
        Size=UDim2.new(1, -16, 0, 0),
        Position=UDim2.new(0, 8, 0, 44),
        BackgroundColor3=colors.bg2,
        BackgroundTransparency=0.4,
        BorderSizePixel=0,
        Visible=false,
        ScrollBarThickness=3,
        ScrollBarImageColor3=colors.primary,
        CanvasSize=UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ClipsDescendants=true,
        ZIndex=10
    })
    new("UICorner",{Parent=optionsContainer, CornerRadius=UDim.new(0, 6)})
    
    local listLayout = new("UIListLayout",{
        Parent=optionsContainer,
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0, 2)
    })
    new("UIPadding",{
        Parent=optionsContainer,
        PaddingTop=UDim.new(0, 5),
        PaddingBottom=UDim.new(0, 5),
        PaddingLeft=UDim.new(0, 5),
        PaddingRight=UDim.new(0, 5)
    })
    
    local selectedItems = {}

    -- Load saved selection if configPath provided
    if configPath then
        local saved = ConfigSystem.Get(configPath, {})
        if type(saved) == "table" then
            for _, item in ipairs(saved) do
                selectedItems[item] = true
            end
        end
    end

    local function updateButtonText()
        local count = 0
        for _ in pairs(selectedItems) do count = count + 1 end
        
        if count == 0 then
            dropdownButton.Text = "Select... (0)"
            dropdownButton.TextColor3 = colors.textDim
        elseif count == 1 then
            for item in pairs(selectedItems) do
                dropdownButton.Text = item
                break
            end
            dropdownButton.TextColor3 = colors.text
        else
            dropdownButton.Text = string.format("Selected (%d)", count)
            dropdownButton.TextColor3 = colors.text
        end
    end
    
    for _, option in ipairs(options) do
        local optionButton = new("TextButton",{
            Parent=optionsContainer,
            Size=UDim2.new(1, -10, 0, 28),
            BackgroundColor3=colors.bg3,
            BackgroundTransparency=0.7,
            BorderSizePixel=0,
            Text="",
            AutoButtonColor=false,
            ZIndex=11
        })
        new("UICorner",{Parent=optionButton, CornerRadius=UDim.new(0, 5)})
        
        local checkbox = new("Frame",{
            Parent=optionButton,
            Size=UDim2.new(0, 18, 0, 18),
            Position=UDim2.new(1, -23, 0.5, -9),
            BackgroundColor3=colors.bg1,
            BackgroundTransparency=0.5,
            BorderSizePixel=0,
            ZIndex=12
        })
        new("UICorner",{Parent=checkbox, CornerRadius=UDim.new(0, 4)})
        
        local checkmark = new("TextLabel",{
            Parent=checkbox,
            Size=UDim2.new(1, 0, 1, 0),
            BackgroundTransparency=1,
            Text="✓",
            Font=Enum.Font.GothamBold,
            TextSize=14,
            TextColor3=colors.text,
            Visible=false,
            ZIndex=13
        })
        
        local optionLabel = new("TextLabel",{
            Parent=optionButton,
            Text="  " .. option,
            Size=UDim2.new(1, -30, 1, 0),
            BackgroundTransparency=1,
            Font=Enum.Font.GothamBold,
            TextSize=9,
            TextColor3=colors.textDim,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd,
            ZIndex=12
        })
        
        -- Apply initial visuals if this option was previously selected
        if selectedItems[option] then
            checkmark.Visible = true
            checkbox.BackgroundColor3 = colors.primary
            checkbox.BackgroundTransparency = 0.3
            optionButton.BackgroundTransparency = 0.5
        end

        optionButton.MouseButton1Click:Connect(function()
            if selectedItems[option] then
                selectedItems[option] = nil
                checkmark.Visible = false
                if USE_TWEEN then
                    TweenService:Create(checkbox, TweenInfo.new(TWEEN_SPEED), {
                        BackgroundColor3=colors.bg1,
                        BackgroundTransparency=0.5
                    }):Play()
                    TweenService:Create(optionButton, TweenInfo.new(TWEEN_SPEED), {
                        BackgroundTransparency=0.7
                    }):Play()
                else
                    checkbox.BackgroundColor3 = colors.bg1
                    checkbox.BackgroundTransparency = 0.5
                    optionButton.BackgroundTransparency = 0.7
                end
            else
                selectedItems[option] = true
                checkmark.Visible = true
                if USE_TWEEN then
                    TweenService:Create(checkbox, TweenInfo.new(TWEEN_SPEED), {
                        BackgroundColor3=colors.primary,
                        BackgroundTransparency=0.3
                    }):Play()
                    TweenService:Create(optionButton, TweenInfo.new(TWEEN_SPEED), {
                        BackgroundTransparency=0.5
                    }):Play()
                else
                    checkbox.BackgroundColor3 = colors.primary
                    checkbox.BackgroundTransparency = 0.3
                    optionButton.BackgroundTransparency = 0.5
                end
            end
            
            updateButtonText()
            
            local selected = {}
            for item in pairs(selectedItems) do
                table.insert(selected, item)
            end
            -- Save selection if config path provided
            if configPath then
                ConfigSystem.Set(configPath, selected)
                MarkDirty()
            end
            callback(selected)
        end)
    end
    
    -- PERBAIKAN: Update button text dan trigger callback saat load awal
    updateButtonText()
    
    -- Trigger callback dengan data yang sudah di-load dari config
    task.spawn(function()
        task.wait(0.1) -- Delay kecil untuk memastikan semua module sudah ready
        local selected = {}
        for item in pairs(selectedItems) do
            table.insert(selected, item)
        end
        if #selected > 0 then
            callback(selected)
            print("✅ Loaded saved selection:", table.concat(selected, ", "))
        end
    end)
    
    local isOpen = false
    dropdownButton.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        optionsContainer.Visible = isOpen
        
        if USE_TWEEN then
            TweenService:Create(arrow, TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Back), {
                Rotation=isOpen and 180 or 0
            }):Play()
            TweenService:Create(dropdownFrame, TweenInfo.new(TWEEN_SPEED), {
                BackgroundTransparency=isOpen and 0.45 or 0.6
            }):Play()
        else
            arrow.Rotation = isOpen and 180 or 0
            dropdownFrame.BackgroundTransparency = isOpen and 0.45 or 0.6
        end
        
        if isOpen then
            local maxHeight = math.min(150, #options * 30 + 10)
            optionsContainer.Size = UDim2.new(1, -16, 0, maxHeight)
        else
            optionsContainer.Size = UDim2.new(1, -16, 0, 0)
        end
    end)
    
    return {
        Frame = dropdownFrame,
        GetSelected = function()
            local selected = {}
            for item in pairs(selectedItems) do
                table.insert(selected, item)
            end
            return selected
        end,
        Clear = function()
            selectedItems = {}
            updateButtonText()
            for _, child in ipairs(optionsContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    local checkbox = child:FindFirstChildOfClass("Frame")
                    if checkbox then
                        local checkmark = checkbox:FindFirstChild("TextLabel")
                        if checkmark then checkmark.Visible = false end
                        checkbox.BackgroundColor3 = colors.bg1
                        checkbox.BackgroundTransparency = 0.5
                    end
                    child.BackgroundTransparency = 0.7
                end
            end
            -- Trigger callback dengan array kosong
            callback({})
        end
    }
end

-- ALTERNATIF: Tanpa border sama sekali
local function makeTextBox(parent, label, placeholder, defaultValue, callback)
    local container = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = colors.bg2,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        ZIndex = 7
    })
    
    new("UICorner", {
        Parent = container,
        CornerRadius = UDim.new(0, 8)
    })
    
    local labelText = new("TextLabel", {
        Parent = container,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 8),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = colors.text,
        TextTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    
    local textBox = new("TextBox", {
        Parent = container,
        Size = UDim2.new(1, -20, 0, 32),
        Position = UDim2.new(0, 10, 0, 32),
        BackgroundColor3 = colors.bg3,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Text = defaultValue or "",
        PlaceholderText = placeholder or "",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = colors.text,
        TextTransparency = 0, -- Text 100% solid
        PlaceholderColor3 = colors.textDimmer,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 8
    })
    
    new("UICorner", {
        Parent = textBox,
        CornerRadius = UDim.new(0, 6)
    })
    
    new("UIPadding", {
        Parent = textBox,
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8)
    })
    
    local lastSavedValue = defaultValue or ""
    
    textBox.Focused:Connect(function()
        if USE_TWEEN then
            TweenService:Create(textBox, TweenInfo.new(TWEEN_SPEED), {
                BackgroundTransparency = 0.5
            }):Play()
        else
            textBox.BackgroundTransparency = 0.5
        end
    end)
    
    textBox.FocusLost:Connect(function(enterPressed)
        if USE_TWEEN then
            TweenService:Create(textBox, TweenInfo.new(TWEEN_SPEED), {
                BackgroundTransparency = 0.7
            }):Play()
        else
            textBox.BackgroundTransparency = 0.7
        end
        
        local value = textBox.Text
        
        if value and value ~= "" and value ~= lastSavedValue then
            lastSavedValue = value
            callback(value)
        end
    end)
    
    return {
        Container = container,
        TextBox = textBox,
        GetValue = function()
            return textBox.Text
        end,
        SetValue = function(value)
            textBox.Text = tostring(value)
            lastSavedValue = tostring(value)
        end
    }
end

-- ============================================
-- MAIN PAGE FEATURES - OPTIMIZED
-- ============================================
local catAutoFishing = makeCategory(mainPage, "Auto Fishing", "🎣")
local currentInstantMode = "None"
local fishingDelayValue = 1.30
local cancelDelayValue = 0.19
local isInstantFishingEnabled = false

makeDropdown(catAutoFishing, "Instant Fishing Mode", "⚡", {"Fast", "Perfect"}, "InstantFishing.Mode", function(mode)
    currentInstantMode = mode
    instant.Stop()
    instant2.Stop()
    
    if isInstantFishingEnabled then
        if mode == "Fast" then
            instant.Settings.MaxWaitTime = fishingDelayValue
            instant.Settings.CancelDelay = cancelDelayValue
            instant.Start()
        elseif mode == "Perfect" then
            instant2.Settings.MaxWaitTime = fishingDelayValue
            instant2.Settings.CancelDelay = cancelDelayValue
            instant2.Start()
        end
    else
        instant.Settings.MaxWaitTime = fishingDelayValue
        instant.Settings.CancelDelay = cancelDelayValue
        instant2.Settings.MaxWaitTime = fishingDelayValue
        instant2.Settings.CancelDelay = cancelDelayValue
    end
end, "InstantFishingMode")

makeToggle(catAutoFishing, "Enable Instant Fishing", "InstantFishing.Enabled", function(on)
    isInstantFishingEnabled = on
    
    if on then
        if currentInstantMode == "Fast" then
            instant.Start()
        elseif currentInstantMode == "Perfect" then
            instant2.Start()
        end
    else
        instant.Stop()
        instant2.Stop()
    end
end)

makeInput(catAutoFishing, "Fishing Delay", "InstantFishing.FishingDelay", 1.30, function(v)
    fishingDelayValue = v
    instant.Settings.MaxWaitTime = v
    instant2.Settings.MaxWaitTime = v
end)

makeInput(catAutoFishing, "Cancel Delay", "InstantFishing.CancelDelay", 0.19, function(v)
    cancelDelayValue = v
    instant.Settings.CancelDelay = v
    instant2.Settings.CancelDelay = v
end)

-- Blatant Tester
local catBlatantV2 = makeCategory(mainPage, "Blatant Tester", "🎯")
makeToggle(catBlatantV2, "Blatant Tester", "BlatantTester.Enabled", function(on) 
    if on then 
        blatantv2fix.Start() 
    else 
        blatantv2fix.Stop() 
    end 
end)

makeInput(catBlatantV2, "Complete Delay", "BlatantTester.CompleteDelay", 0.5, function(v)
    blatantv2fix.Settings.CompleteDelay = v
end)

makeInput(catBlatantV2, "Cancel Delay", "BlatantTester.CancelDelay", 0.1, function(v)
    blatantv2fix.Settings.CancelDelay = v
end)

-- Blatant V1
local catBlatantV1 = makeCategory(mainPage, "Blatant V1", "💀")

makeToggle(catBlatantV1, "Blatant Mode", "BlatantV1.Enabled", function(on) 
    if on then 
        blatantv1.Start() 
    else 
        blatantv1.Stop() 
    end 
end)

makeInput(catBlatantV1, "Complete Delay", "BlatantV1.CompleteDelay", 0.05, function(v)
    blatantv1.Settings.CompleteDelay = v
end)

makeInput(catBlatantV1, "Cancel Delay", "BlatantV1.CancelDelay", 0.1, function(v)
    blatantv1.Settings.CancelDelay = v
end)

-- Ultra Blatant V2
local catUltraBlatant = makeCategory(mainPage, "Blatant V2", "⚡")

makeToggle(catUltraBlatant, "Ultra Blatant Mode", "UltraBlatant.Enabled", function(on) 
    if on then 
        UltraBlatant.Start() 
    else 
        UltraBlatant.Stop() 
    end 
end)

makeInput(catUltraBlatant, "Complete Delay", "UltraBlatant.CompleteDelay", 0.05, function(v)
    UltraBlatant.UpdateSettings(v, nil, nil)
end)

makeInput(catUltraBlatant, "Cancel Delay", "UltraBlatant.CancelDelay", 0.1, function(v)
    UltraBlatant.UpdateSettings(nil, v, nil)
end)

-- Fast Auto Fishing Perfect
local catBlatantV2Alt = makeCategory(mainPage, "Fast auto fishing perfect", "🔥")

makeToggle(catBlatantV2Alt, "Blatant Features", "FastAutoPerfect.Enabled", function(on) 
    if on then 
        blatantv2.Start() 
    else 
        blatantv2.Stop() 
    end 
end)

makeInput(catBlatantV2Alt, "Fishing Delay", "FastAutoPerfect.FishingDelay", 0.05, function(v) 
    blatantv2.Settings.FishingDelay = v 
end)

makeInput(catBlatantV2Alt, "Cancel Delay", "FastAutoPerfect.CancelDelay", 0.01, function(v) 
    blatantv2.Settings.CancelDelay = v 
end)

makeInput(catBlatantV2Alt, "Timeout Delay", "FastAutoPerfect.TimeoutDelay", 0.8, function(v) 
    blatantv2.Settings.TimeoutDelay = v 
end)

-- Support Features
local catSupport = makeCategory(mainPage, "Support Features", "🛠️")

makeToggle(catSupport, "No Fishing Animation", "Support.NoFishingAnimation", function(on)
    if on then
        NoFishingAnimation.StartWithDelay()
    else
        NoFishingAnimation.Stop()
    end
end)

makeToggle(catSupport, "Show Real Ping Panel", "Support.PingFPSMonitor", function(on)
    if on then
        PingFPSMonitor:Show()
        Notify.Send("Lynx Monitor", "✓ Monitor aktif!", 4)
    else
        PingFPSMonitor:Hide()
        Notify.Send("Lynx Monitor", "✓ Monitor disembunyikan!", 4)
    end
end)

makeToggle(catSupport, "Lock Position", "Support.LockPosition", function(on)
    if on then
        LockPosition.Start()
        Notify.Send("Lock Position", "Posisi kamu dikunci!", 4)
    else
        LockPosition.Stop()
        Notify.Send("Lock Position", "Posisi kamu dilepas!", 4)
    end
end)

makeToggle(catSupport, "Disable Cutscenes", "Support.DisableCutscenes", function(on)
    if on then
        local success = DisableCutscenes.Start()
        if success then
            Notify.Send("Disable Cutscenes", "✓ Semua cutscenes dimatikan!", 4)
        else
            Notify.Send("Disable Cutscenes", "⚠ Sudah aktif!", 3)
        end
    else
        local success = DisableCutscenes.Stop()
        if success then
            Notify.Send("Disable Cutscenes", "✓ Cutscenes kembali normal.", 4)
        else
            Notify.Send("Disable Cutscenes", "⚠ Sudah nonaktif!", 3)
        end
    end
end)

makeToggle(catSupport, "Disable Obtained Fish Notification", "Support.DisableObtainedNotif", function(on)
    if on then
        DisableExtras.StartSmallNotification()
        Notify.Send("Disable Small Notification", "✓ Small Notification dinonaktifkan!", 4)
    else
        DisableExtras.StopSmallNotification()
        Notify.Send("Disable Small Notification", "Small Notification bisa muncul kembali.", 3)
    end
end)

makeToggle(catSupport, "Disable Skin Effect", "Support.DisableSkinEffect", function(on)
    if on then
        DisableExtras.StartSkinEffect()
        Notify.Send("Disable Skin Effect", "✓ Skin effect dihapus!", 4)
    else
        DisableExtras.StopSkinEffect()
        Notify.Send("Disable Skin Effect", "Skin effect bisa muncul kembali.", 3)
    end
end)

makeToggle(catSupport, "Walk On Water", "Support.WalkOnWater", function(on)
    if on then
        WalkOnWater.Start()
        Notify.Send("Walk On Water", "✓ Kamu bisa berjalan di atas air!", 4)
    else
        WalkOnWater.Stop()
        Notify.Send("Walk On Water", "Walk on water dimatikan.", 3)
    end
end)

makeToggle(catSupport, "Good/Perfection Stable Mode", "Support.GoodPerfectionStable", function(on)
    if on then
        GoodPerfectionStable.Start()
        Notify.Send("Good/Perfection Stable", "Fitur dihidupkan!", 4)
    else
        GoodPerfectionStable.Stop()
        Notify.Send("Good/Perfection Stable", "Fitur dimatikan!", 4)
    end
end)

-- Auto Favorite
local catAutoFav = makeCategory(mainPage, "Auto Favorite", "⭐")

local autoFavEnabled = false
local selectedTiers = {}
local selectedVariants = {}

local tierDropdown = makeMultiSelectDropdown(
    catAutoFav,
    "Auto Favorite Tiers",
    AutoFavorite.GetAllTiers(),
    function(selected)
        selectedTiers = selected
    end,
    "AutoFavorite.EnabledTiers"
)

local variantDropdown = makeMultiSelectDropdown(
    catAutoFav,
    "Auto Favorite Variants",
    AutoFavorite.GetAllVariants(),
    function(selected)
        selectedVariants = selected
    end,
    "AutoFavorite.EnabledVariants"
)

makeToggle(catAutoFav, "Enable Auto Favorite", "AutoFavorite.Enabled", function(on)
    autoFavEnabled = on
    
    if on then
        AutoFavorite.ClearTiers()
        AutoFavorite.ClearVariants()
        
        if #selectedTiers > 0 then
            AutoFavorite.EnableTiers(selectedTiers)
        end
        
        if #selectedVariants > 0 then
            AutoFavorite.EnableVariants(selectedVariants)
        end
        
        AutoFavorite.Start()
        
        local tierCount = #selectedTiers
        local variantCount = #selectedVariants
        Notify.Send(
            "Auto Favorite", 
            string.format("✓ Aktif! (%d tier, %d variant)", tierCount, variantCount), 
            4
        )
    else
        AutoFavorite.Stop()
        AutoFavorite.ClearTiers()
        AutoFavorite.ClearVariants()
        Notify.Send("Auto Favorite", "✓ Dimatikan!", 3)
    end
end)

-- Auto Totem 3X
local catAutoTotem = makeCategory(mainPage, "Auto Spawn 3X Totem", "🛠️")

makeButton(catAutoTotem, "Auto Totem 3X", function()
    if AutoTotem3X.IsRunning() then
        local success, message = AutoTotem3X.Stop()
        if success then
            Notify.Send("Auto Totem 3X", "⏹ " .. message, 4)
        end
    else
        local success, message = AutoTotem3X.Start()
        if success then
            Notify.Send("Auto Totem 3X", "▶ " .. message, 4)
        else
            Notify.Send("Auto Totem 3X", "⚠ " .. message, 3)
        end
    end
end)

-- Skin Animation (Updated)
local catSkin = makeCategory(mainPage, "Skin Animation", "")
local skinAnimEnabled = false
local selectedSkin = nil

local skinInfo = {
    ["Eclipse Katana"] = {
        id = "Eclipse",
        description = "RodThrow: 1.4x (FASTEST CAST!)"
    },
    ["Holy Trident"] = {
        id = "HolyTrident",
        description = "RodThrow: 1.3x | FishCaught: 1.2x"
    },
    ["Soul Scythe"] = {
        id = "SoulScythe",
        description = "StartRodCharge: 1.4x (FASTEST CHARGE!) | FishCaught: 1.2x"
    },
    ["Oceanic Harpoon"] = {
        id = "OceanicHarpoon",
        description = "Balanced ocean-themed animation"
    },
    ["Binary Edge"] = {
        id = "BinaryEdge",
        description = "Digital glitch effects"
    },
    ["The Vanquisher"] = {
        id = "Vanquisher",
        description = "Powerful strike animation"
    },
    ["Frozen Krampus Scythe"] = {
        id = "KrampusScythe",
        description = "Icy winter effects"
    },
    ["1x1x1x1 Ban Hammer"] = {
        id = "BanHammer",
        description = "Legendary ban hammer swing"
    },
    ["Corruption Edge"] = {
        id = "CorruptionEdge",
        description = "Dark corruption effects"
    },
    ["Princess Parasol"] = {
        id = "PrincessParasol",
        description = "Elegant parasol spin"
    }
}

makeDropdown(
    catSkin,
    "Select Skin",
    "⚡",
    {
        "Eclipse Katana",
        "Holy Trident", 
        "Soul Scythe",
        "Oceanic Harpoon",
        "Binary Edge",
        "The Vanquisher",
        "Frozen Krampus Scythe",
        "1x1x1x1 Ban Hammer",
        "Corruption Edge",
        "Princess Parasol"
    },
    "Support.SkinAnimation.Current",
    function(selected)
        selectedSkin = selected
        
        if skinAnimEnabled then
            local skinData = skinInfo[selectedSkin]
            if skinData then
                local success = SkinAnimation.SwitchSkin(skinData.id)
                if success then
                    Notify.Send(
                        "Skin Animation", 
                        "Switched to " .. selected .. "\n" .. skinData.description, 
                        4
                    )
                else
                    Notify.Send("Skin Animation", "Gagal mengganti skin!", 3)
                end
            end
        end
    end,
    "SkinAnimationDropdown"
)

makeToggle(catSkin, "Enable Skin Animation", "Support.SkinAnimation.Enabled", function(on)
    skinAnimEnabled = on
    
    if on then
        if not selectedSkin then
            Notify.Send("Skin Animation", "Pilih skin terlebih dahulu!", 3)
            return
        end
        
        local skinData = skinInfo[selectedSkin]
        if not skinData then
            Notify.Send("Skin Animation", "Skin tidak valid!", 3)
            return
        end
        
        local success = SkinAnimation.SwitchSkin(skinData.id)
        if not success then
            Notify.Send("Skin Animation", "Gagal mengganti skin!", 3)
            return
        end
        
        local enableSuccess = SkinAnimation.Enable()
        if enableSuccess then
            Notify.Send(
                "Skin Animation", 
                selectedSkin .. " diaktifkan!\n" .. skinData.description, 
                4
            )
        else
            Notify.Send("Skin Animation", "Sudah aktif!", 3)
        end
    else
        local success = SkinAnimation.Disable()
        if success then
            Notify.Send("Skin Animation", "Skin Animation dimatikan!", 4)
        else
            Notify.Send("Skin Animation", "Sudah nonaktif!", 3)
        end
    end
end)

-- ============================================
-- TELEPORT PAGE - OPTIMIZED
-- ============================================

-- Location Teleport
local locationItems = {}
for name, _ in pairs(TeleportModule.Locations) do
    table.insert(locationItems, name)
end
table.sort(locationItems)

makeDropdown(teleportPage, "Teleport to Location", "📍", locationItems, function(selectedLocation)
    TeleportModule.TeleportTo(selectedLocation)
end, "LocationTeleport")

-- Player Teleport with Auto Refresh - OPTIMIZED
local playerDropdown
local playerItems = {}

local function updatePlayerList()
    table.clear(playerItems)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            table.insert(playerItems, player.Name)
        end
    end
    table.sort(playerItems)
    
    if playerDropdown and playerDropdown.Parent then
        playerDropdown:Destroy()
    end
    
    playerDropdown = makeDropdown(teleportPage, "Teleport to Player", "👤", playerItems, function(selectedPlayer)
        TeleportToPlayer.TeleportTo(selectedPlayer)
    end, "PlayerTeleport")
end

updatePlayerList()

-- Optimized: Debounce player list updates
local lastUpdate = 0
local updateCooldown = 0.5

Players.PlayerAdded:Connect(function(player)
    local now = tick()
    if now - lastUpdate < updateCooldown then return end
    lastUpdate = now
    
    task.wait(0.5)
    updatePlayerList()
end)

Players.PlayerRemoving:Connect(function(player)
    local now = tick()
    if now - lastUpdate < updateCooldown then return end
    lastUpdate = now
    
    task.wait(0.1)
    updatePlayerList()
end)

-- Saved Location
local catSaved = makeCategory(teleportPage, "Saved Location", "⭐")

makeButton(catSaved, "Save Current Location", function()
    SavedLocation.Save()
    Notify.Send("Saved", "Lokasi berhasil disimpan.", 3)
end)

makeButton(catSaved, "Teleport Saved Location", function()
    if SavedLocation.Teleport() then
        Notify.Send("Teleported", "Berhasil teleport ke lokasi tersimpan.", 3)
    else
        Notify.Send("Error", "Tidak ada lokasi yang disimpan!", 3)
    end
end)

makeButton(catSaved, "Reset Saved Location", function()
    SavedLocation.Reset()
    Notify.Send("Reset", "Lokasi tersimpan telah dihapus.", 3)
end)

-- Event Teleport - FIXED
local selectedEventName = nil
local EventTeleport = SecurityLoader.LoadModule("EventTeleportDynamic")

if not EventTeleport then
    EventTeleport = {
        GetEventNames = function() return {"- Module Not Loaded -"} end,
        HasCoords = function() return false end,
        Start = function() return false end,
        Stop = function() return true end,
        TeleportNow = function() return false end,
        SetDebugMode = function() end,
        IsEventActive = function() return false end,
        RefreshEventPosition = function() return false end
    }
end

local eventNames = EventTeleport.GetEventNames()
local catTeleport = makeCategory(teleportPage, "Event Teleport", "🎯")

makeDropdown(catTeleport, "Pilih Event", "📌", eventNames, function(selected)
    selectedEventName = selected
    Notify.Send("Event", "Event dipilih: " .. tostring(selected), 3)
end, "EventTeleport")

makeToggle(catTeleport, "Enable Auto Teleport", "Teleport.AutoTeleportEvent", function(on)
    if on then
        if selectedEventName and EventTeleport.HasCoords(selectedEventName) then
            local success = EventTeleport.Start(selectedEventName)
            if success then
                Notify.Send("Auto Teleport", "Mulai auto teleport ke " .. selectedEventName, 4)
            else
                Notify.Send("Auto Teleport", "Gagal memulai - event belum aktif", 3)
            end
        else
            Notify.Send("Auto Teleport", "Pilih event yang memiliki koordinat dulu!", 3)
        end
    else
        EventTeleport.Stop()
        Notify.Send("Auto Teleport", "Auto teleport dihentikan.", 3)
    end
end)

-- ============================================
-- SHOP PAGE - OPTIMIZED
-- ============================================

-- Sell All
local catSell = makeCategory(shopPage, "Sell All", "💰")

makeButton(catSell, "Sell All Now", function()
    if AutoSellSystem.SellOnce() then
        Notify.Send("Sell All", "✓ Sold successfully!", 2)
    else
        Notify.Send("Sell Error", "Failed to sell!", 3)
    end
end)

-- Auto Sell Timer
local catTimer = makeCategory(shopPage, "Auto Sell Timer", "⏰")

makeInput(catTimer, "Sell Interval (seconds)", "Shop.AutoSellTimer.Interval", 5, function(value)
    AutoSellSystem.Timer.SetInterval(value)
end)

makeToggle(catTimer, "Enable Auto Sell Timer", "Shop.AutoSellTimer.Enabled", function(on)
    if on then
        if AutoSellSystem.Timer.Start() then
            Notify.Send("Auto Sell Timer", "✓ Started! Interval: " .. AutoSellSystem.Timer.Interval .. "s", 4)
        else
            Notify.Send("Error", "Failed to start!", 3)
        end
    else
        if AutoSellSystem.Timer.Stop() then
            local status = AutoSellSystem.Timer.GetStatus()
            Notify.Send("Auto Sell Timer", "✓ Stopped! Total: " .. status.sellCount, 4)
        end
    end
end)

-- Auto Sell By Count
local catCount = makeCategory(shopPage, "Auto Sell By Count", "🎣")

makeInput(catCount, "Target Fish Count", "Shop.AutoSellByCount.Target", 235, function(value)
    AutoSellSystem.Count.SetTarget(value)
end)

makeToggle(catCount, "Enable Auto Sell By Count", "Shop.AutoSellByCount.Enabled", function(on)
    if on then
        if AutoSellSystem.Count.Start() then
            Notify.Send("Auto Sell Count", "✓ Started! Target: " .. AutoSellSystem.Count.Target, 4)
        else
            Notify.Send("Error", "Failed to start!", 3)
        end
    else
        if AutoSellSystem.Count.Stop() then
            Notify.Send("Auto Sell Count", "✓ Stopped!", 3)
        end
    end
end)

-- Auto Buy Weather - OPTIMIZED
local catWeather = makeCategory(shopPage, "Auto Buy Weather", "🌦️")

local selectedWeathers = {}
local autoWeatherEnabled = false

local weatherDropdown = makeMultiSelectDropdown(
    catWeather,
    "Select Weather Types",
    AutoBuyWeather.AllWeathers,
    function(selected)
        selectedWeathers = selected
        AutoBuyWeather.SetSelected(selectedWeathers)
    end,
    "Shop.AutoBuyWeather.SelectedWeathers"
)

makeToggle(catWeather, "Enable Auto Weather", "Shop.AutoBuyWeather.Enabled", function(on)
    autoWeatherEnabled = on
    
    if on then
        if #selectedWeathers == 0 then
            Notify.Send("Auto Weather ⚠️", "Pilih minimal 1 cuaca terlebih dahulu!", 3)
            return
        end
        
        AutoBuyWeather.Start()
        
        local weatherList = table.concat(selectedWeathers, ", ")
        Notify.Send(
            "Auto Weather 🌦️", 
            string.format("✓ Aktif! (%d weather)\n%s", #selectedWeathers, weatherList), 
            4
        )
    else
        AutoBuyWeather.Stop()
        Notify.Send("Auto Weather 🌦️", "✓ Dimatikan!", 3)
    end
end)

-- Remote Merchant
local catMerchant = makeCategory(shopPage, "Remote Merchant", "🛒")

makeButton(catMerchant, "Open Merchant", function()
    MerchantSystem.Open()
    Notify.Send("Merchant 🛒", "Merchant dibuka!", 3)
end)

makeButton(catMerchant, "Close Merchant", function()
    MerchantSystem.Close()
    Notify.Send("Merchant 🛒", "Merchant ditutup!", 3)
end)

-- Buy Rod - OPTIMIZED
local catRod = makeCategory(shopPage, "Buy Rod", "🎣")

local RodData = {
    ["Chrome Rod"] = {id = 7, price = 437000},
    ["Lucky Rod"] = {id = 4, price = 15000},
    ["Starter Rod"] = {id = 1, price = 50},
    ["Steampunk Rod"] = {id = 6, price = 215000},
    ["Carbon Rod"] = {id = 76, price = 750},
    ["Ice Rod"] = {id = 78, price = 5000},
    ["Luck Rod"] = {id = 79, price = 325},
    ["Midnight Rod"] = {id = 80, price = 50000},
    ["Grass Rod"] = {id = 85, price = 1500},
    ["Demascus Rod"] = {id = 77, price = 3000},
    ["Astral Rod"] = {id = 5, price = 1000000},
    ["Ares Rod"] = {id = 126, price = 3000000},
    ["Angler Rod"] = {id = 168, price = 8000000},
    ["Fluorescent Rod"] = {id = 255, price = 715000},
    ["Bamboo Rod"] = {id = 258, price = 12000000},
}

local RodList = {}
local RodMap = {}

for rodName, info in pairs(RodData) do
    local price = info.price and tostring(info.price) or "Unknown Price"
    local display = rodName .. " (" .. price .. ")"
    table.insert(RodList, display)
    RodMap[display] = rodName
end

local SelectedRod = nil

makeDropdown(catRod, "Select Rod", "🎣", RodList, function(displayName)
    local rodName = RodMap[displayName]
    SelectedRod = rodName

    local info = RodData[rodName]
    local priceTxt = info.price and tostring(info.price) or "Unknown Price"

    Notify.Send("Rod Selected",
        "Rod: " .. rodName .. "\nPrice: " .. priceTxt, 3)
end, "RodDropdown")

makeButton(catRod, "BUY SELECTED ROD", function()
    if not SelectedRod then
        Notify.Send("Buy Rod", "Pilih rod dulu!", 3)
        return
    end

    local rod = RodData[SelectedRod]
    RemoteBuyer.BuyRod(rod.id)

    Notify.Send("Buy Rod", "Membeli " .. SelectedRod .. "...", 3)
end)

-- Buy Bait - OPTIMIZED
local catBait = makeCategory(shopPage, "Buy Bait", "🪱")

local BaitData = {
    ["Chroma Bait"]       = {id = 6,  price = 290000},
    ["Luck Bait"]         = {id = 2,  price = 1000},
    ["Midnight Bait"]     = {id = 3,  price = 3000},
    ["Topwater Bait"]     = {id = 10, price = 100},
    ["Dark Matter Bait"]  = {id = 8,  price = 630000},
    ["Nature Bait"]       = {id = 17, price = 83500},
    ["Aether Bait"]       = {id = 16, price = 3700000},
    ["Corrupt Bait"]      = {id = 15, price = 1148484},
    ["Floral Bait"]       = {id = 20, price = 4000000},
}

local BaitList = {}
local BaitMap = {}

for baitName, info in pairs(BaitData) do
    local price = info.price and tostring(info.price) or "Unknown Price"
    local display = baitName .. " (" .. price .. ")"
    table.insert(BaitList, display)
    BaitMap[display] = baitName
end

local SelectedBait = nil

makeDropdown(catBait, "Select Bait", "🪱", BaitList, function(displayName)
    local baitName = BaitMap[displayName]
    SelectedBait = baitName

    local info = BaitData[baitName]
    local priceTxt = info.price and tostring(info.price) or "Unknown Price"

    Notify.Send("Bait Selected",
        "Bait: " .. baitName .. "\nPrice: " .. priceTxt, 3)
end, "BaitDropdown")

makeButton(catBait, "BUY SELECTED BAIT", function()
    if not SelectedBait then
        Notify.Send("Buy Bait", "Pilih bait dulu!", 3)
        return
    end

    local bait = BaitData[SelectedBait]
    RemoteBuyer.BuyBait(bait.id)

    Notify.Send("Buy Bait", "Membeli " .. SelectedBait .. "...", 3)
end)

-- ============================================
-- CAMERA VIEW PAGE - OPTIMIZED
-- ============================================

-- Unlimited Zoom
local catZoom = makeCategory(cameraViewPage, "Unlimited Zoom", "🔭")

makeToggle(catZoom, "Enable Unlimited Zoom", "CameraView.UnlimitedZoom", function(on)
    if not UnlimitedZoomModule then
        Notify.Send("Error ❌", "UnlimitedZoomModule belum di-load!", 3)
        warn("❌ UnlimitedZoomModule is nil!")
        return
    end
    
    if type(UnlimitedZoomModule.Enable) ~= "function" then
        Notify.Send("Error ❌", "UnlimitedZoomModule.Enable bukan function!", 3)
        warn("❌ UnlimitedZoomModule.Enable is not a function")
        return
    end
    
    if on then
        local success, result = pcall(function()
            return UnlimitedZoomModule.Enable()
        end)
        
        if success and result then
            Notify.Send("Zoom 🔭", "Unlimited Zoom aktif! Scroll atau pinch untuk zoom.", 4)
        elseif not success then
            Notify.Send("Error ❌", "Gagal mengaktifkan: " .. tostring(result), 3)
            warn("❌ Enable error:", result)
        end
    else
        local success, result = pcall(function()
            return UnlimitedZoomModule.Disable()
        end)
        
        if success and result then
            Notify.Send("Zoom 🔭", "Unlimited Zoom nonaktif.", 3)
        elseif not success then
            Notify.Send("Error ❌", "Gagal menonaktifkan: " .. tostring(result), 3)
            warn("❌ Disable error:", result)
        end
    end
end)

-- Freecam
FreecamModule.SetMainGuiName("LynxGUI_Galaxy")

local catFreecam = makeCategory(cameraViewPage, "Freecam Camera", "📷")

-- PC Controls Info - OPTIMIZED (Only show on PC)
if not isMobile then
    local noteContainer = new("Frame", {
        Parent = catFreecam,
        Size = UDim2.new(1, 0, 0, 85),
        BackgroundColor3 = colors.bg3,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        ZIndex = 7
    })
    
    new("UICorner", {
        Parent = noteContainer,
        CornerRadius = UDim.new(0, 8)
    })
    
    local noteText = new("TextLabel", {
        Parent = noteContainer,
        Size = UDim2.new(1, -24, 1, -24),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        Text = [[📌 FREECAM CONTROLS (PC)
━━━━━━━━━━━━━━━━━━━━━━
1. Aktifkan toggle "Enable Freecam"
2. Tekan F3 untuk ON/OFF freecam
3. WASD - Gerak | Mouse - Rotasi
4. Space/E - Naik | Shift/Q - Turun]],
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = colors.text,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 8
    })
end

makeToggle(catFreecam, "Enable Freecam", "CameraView.Freecam.Enabled", function(on)
    if on then
        if not isMobile then
            if FreecamModule and type(FreecamModule.EnableF3Keybind) == "function" then
                FreecamModule.EnableF3Keybind(true)
                if Notify and type(Notify.Send) == "function" then
                    Notify.Send("Freecam", "Freecam siap! Tekan F3 untuk mengaktifkan.", 4)
                end
            end
        else
            if FreecamModule and type(FreecamModule.Start) == "function" then
                FreecamModule.Start()
                if Notify and type(Notify.Send) == "function" then
                    Notify.Send("Freecam", "Freecam aktif! Kontrol dengan touch.", 4)
                end
            end
        end
    else
        if FreecamModule and type(FreecamModule.EnableF3Keybind) == "function" then
            FreecamModule.EnableF3Keybind(false)
            if Notify and type(Notify.Send) == "function" then
                Notify.Send("Freecam", "Freecam nonaktif.", 3)
            end
        end
    end
end)

makeInput(catFreecam, "Movement Speed", "CameraView.Freecam.Speed", 50, function(value)
    local speed = tonumber(value) or 50
    if FreecamModule and type(FreecamModule.SetSpeed) == "function" then
        FreecamModule.SetSpeed(speed)
    end
end)

makeInput(catFreecam, "Mouse Sensitivity", "CameraView.Freecam.Sensitivity", 0.3, function(value)
    local sens = tonumber(value) or 0.3
    if FreecamModule and type(FreecamModule.SetSensitivity) == "function" then
        FreecamModule.SetSensitivity(sens)
    end
end)

makeButton(catFreecam, "Reset Settings", function()
    if FreecamModule then
        if type(FreecamModule.SetSpeed) == "function" then
            FreecamModule.SetSpeed(50)
        end
        if type(FreecamModule.SetSensitivity) == "function" then
            FreecamModule.SetSensitivity(0.3)
        end
        if Notify and type(Notify.Send) == "function" then
            Notify.Send("Reset", "Freecam settings direset!", 3)
        end
    end
end)

-- ============================================
-- WEBHOOK PAGE - FINAL FIX
-- ============================================
local catWebhook = makeCategory(webhookPage, "Discord Webhook Fish Caught", "🔔")

local currentWebhookURL = ""
local currentDiscordID = ""
local selectedRarities = {}

-- Load saved values from config on startup
local savedURL = ConfigSystem.Get("Webhook.URL") or ""
local savedID = ConfigSystem.Get("Webhook.DiscordID") or ""
local savedRarities = ConfigSystem.Get("Webhook.EnabledRarities") or {}

currentWebhookURL = savedURL
currentDiscordID = savedID
selectedRarities = savedRarities

-- Set ke WebhookModule saat startup
if WebhookModule then
    if savedURL and savedURL ~= "" then
        WebhookModule:SetWebhookURL(savedURL)
    end
    if savedID and savedID ~= "" then
        WebhookModule:SetDiscordUserID(savedID)
    end
    if savedRarities and #savedRarities > 0 then
        WebhookModule:SetEnabledRarities(savedRarities)
    end
end

local webhookTextBox = makeTextBox(
    catWebhook,
    "Discord Webhook URL",
    "https://discord.com/api/webhooks/...",
    savedURL,
    function(value)
        -- Trim whitespace
        value = value:gsub("^%s*(.-)%s*$", "%1")
        
        currentWebhookURL = value
        
        if WebhookModule and WebhookModule.SetWebhookURL then
            -- Langsung set ke module
            WebhookModule:SetWebhookURL(value)
            
            -- Save ke config
            ConfigSystem.Set("Webhook.URL", value)
            MarkDirty()
            
            -- Validasi URL Discord
            if value and value ~= "" and value:match("^https://discord%.com/api/webhooks/%d+/[%w%-_]+") then
                Notify.Send("Webhook 🔔", "Webhook URL berhasil disimpan!", 2)
                
                -- Debug print
                print("✅ Webhook URL updated:", value)
            elseif value and value ~= "" then
                Notify.Send("Warning ⚠️", "Format URL mungkin tidak valid!", 3)
            end
        else
            Notify.Send("Error ❌", "Webhook module belum siap!", 3)
        end
    end
)

local discordIDTextBox = makeTextBox(
    catWebhook,
    "Discord User ID (Optional - untuk mention)",
    "123456789012345678",
    savedID,
    function(value)
        -- Trim whitespace
        value = value:gsub("^%s*(.-)%s*$", "%1")
        
        currentDiscordID = value
        
        if WebhookModule and WebhookModule.SetDiscordUserID then
            WebhookModule:SetDiscordUserID(value)
            ConfigSystem.Set("Webhook.DiscordID", value)
            MarkDirty()
            
            if value and value ~= "" and value:match("^%d+$") then
                Notify.Send("Webhook 🔔", "Discord ID berhasil disimpan!", 2)
                print("✅ Discord ID updated:", value)
            end
        end
    end
)

local rarityDropdown = makeMultiSelectDropdown(
    catWebhook,
    "Filter Rarity (kosongkan untuk semua)",
    {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
    function(selected)
        selectedRarities = selected
        if WebhookModule and WebhookModule.SetEnabledRarities then
            WebhookModule:SetEnabledRarities(selectedRarities)
        end
        ConfigSystem.Set("Webhook.EnabledRarities", selected)
        MarkDirty()
    end,
    "Webhook.EnabledRarities"
)

makeToggle(catWebhook, "Enable Webhook", "Webhook.Enabled", function(on)
    if not WebhookModule then
        Notify.Send("Error ❌", "Webhook module tidak ditemukan!", 3)
        return
    end
    
    if not WebhookModule.Start or not WebhookModule.Stop then
        Notify.Send("Error ❌", "Webhook module tidak valid!", 3)
        return
    end
    
    if on then
        -- Ambil URL terbaru (prioritas: variabel -> config)
        local webhookURL = currentWebhookURL
        if not webhookURL or webhookURL == "" then
            webhookURL = ConfigSystem.Get("Webhook.URL") or ""
        end
        
        -- Validasi URL
        if not webhookURL or webhookURL == "" or webhookURL == "https://discord.com/api/webhooks/..." then
            Notify.Send("Error ❌", "Masukkan Webhook URL terlebih dahulu!", 3)
            return
        end
        
        -- Set ulang ke module untuk memastikan
        WebhookModule:SetWebhookURL(webhookURL)
        print("🔔 Starting webhook with URL:", webhookURL)
        
        local success = WebhookModule:Start()
        if success then
            local filterInfo = #selectedRarities > 0 
                and " (Filter: " .. table.concat(selectedRarities, ", ") .. ")"
                or " (All rarities)"
            Notify.Send("Webhook 🔔", "Webhook logging aktif!" .. filterInfo, 4)
        else
            Notify.Send("Error ❌", "Gagal mengaktifkan webhook!", 3)
        end
    else
        local success = WebhookModule:Stop()
        if success then
            Notify.Send("Webhook 🔔", "Webhook logging dinonaktifkan.", 3)
        end
    end
end)

makeButton(catWebhook, "Test Webhook Connection", function()
    if not WebhookModule then
        Notify.Send("Error ❌", "Webhook module tidak ditemukan!", 3)
        return
    end
    
    -- Ambil URL terbaru
    local webhookURL = currentWebhookURL
    if not webhookURL or webhookURL == "" then
        webhookURL = ConfigSystem.Get("Webhook.URL") or ""
    end
    
    -- Validasi
    if not webhookURL or webhookURL == "" or webhookURL == "https://discord.com/api/webhooks/..." then
        Notify.Send("Error ❌", "Masukkan Webhook URL terlebih dahulu!", 3)
        return
    end
    
    -- Set ke module
    WebhookModule:SetWebhookURL(webhookURL)
    print("🧪 Testing webhook with URL:", webhookURL)
    
    local HttpService = game:GetService("HttpService")
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    
    if requestFunc then
        local filterText = #selectedRarities > 0 
            and "\n**Filter Active:** " .. table.concat(selectedRarities, ", ")
            or "\n**Filter:** All rarities enabled"
            
        local testPayload = {
            embeds = {{
                title = "🎣 Webhook Test Successful!",
                description = "Your Discord webhook is working correctly!\n\nLynx GUI is ready to send fish notifications." .. filterText,
                color = 3447003,
                footer = {
                    text = "Lynx Webhook Test • " .. os.date("%m/%d/%Y %H:%M"),
                    icon_url = "https://i.imgur.com/shnNZuT.png"
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        
        local success, err = pcall(function()
            requestFunc({
                Url = webhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(testPayload)
            })
        end)
        
        if success then
            Notify.Send("Success ✅", "Test message sent! Check Discord.", 4)
        else
            Notify.Send("Error ❌", "Test failed: " .. tostring(err), 4)
        end
    else
        Notify.Send("Error ❌", "HTTP request function tidak ditemukan!", 3)
    end
end)

-- ============================================
-- SETTINGS PAGE - OPTIMIZED
-- ============================================

-- Anti-AFK
local catAFK = makeCategory(settingsPage, "Anti-AFK Protection", "🧍‍♂️")

makeToggle(catAFK, "Enable Anti-AFK", "Settings.AntiAFK", function(on)
    if on then
        AntiAFK.Start()
    else
        AntiAFK.Stop()
    end
end)

local catUtility = makeCategory(settingsPage, "Player Utility", "⚙️")

-- Sprint Speed Input
makeInput(catUtility, "Sprint Speed", "Settings.SprintSpeed", 50, function(value)
    local speed = tonumber(value) or 50
    MovementModule.SetSprintSpeed(speed)
end)

-- Sprint Toggle
makeToggle(catUtility, "Enable Sprint", "Settings.Sprint", function(on)
    if on then
        MovementModule.EnableSprint()
        Notify.Send("Sprint", "Sprint diaktifkan!", 2)
    else
        MovementModule.DisableSprint()
        Notify.Send("Sprint", "Sprint dimatikan", 2)
    end
end)

-- Infinite Jump Toggle
makeToggle(catUtility, "Enable Infinite Jump", "Settings.InfiniteJump", function(on)
    if on then
        MovementModule.EnableInfiniteJump()
        Notify.Send("Infinite Jump", "Infinite Jump diaktifkan!", 2)
    else
        MovementModule.DisableInfiniteJump()
        Notify.Send("Infinite Jump", "Infinite Jump dimatikan", 2)
    end
end)

-- Server Management
local catServer = makeCategory(settingsPage, "Server Features", "🔄")

makeButton(catServer, "Rejoin Server", function()
    local TeleportService = game:GetService("TeleportService")
    
    local success, err = pcall(function()
        TeleportService:Teleport(game.PlaceId, localPlayer)
    end)
    
    if success then
        if Notify then
            Notify.Send("Rejoin", "Teleporting to new server...", 3)
        end
    else
        warn("❌ Rejoin failed:", err)
        if Notify then
            Notify.Send("Error ❌", "Rejoin failed!", 3)
        end
    end
end)

-- FPS Booster
local catBoost = makeCategory(settingsPage, "FPS Booster", "⚡")

makeToggle(catBoost, "Enable FPS Booster", "Settings.FPSBooster", function(on)
    if not FPSBooster then
        Notify.Send("FPS Booster", "Module FPSBooster gagal dimuat!", 3)
        return
    end

    if on then
        FPSBooster.Enable()
        Notify.Send("FPS Booster", "FPS Booster diaktifkan!", 3)
    else
        FPSBooster.Disable()
        Notify.Send("FPS Booster", "FPS Booster dimatikan.", 3)
    end
end)

makeToggle(catBoost, "Disable 3D Rendering", "Settings.DisableRendering", function(on)
    if not DisableRendering then
        Notify.Send("Error ❌", "Module DisableRendering belum dimuat!", 3)
        return
    end
    
    if on then
        local success, message = DisableRendering.Start()
        if success then
            Notify.Send("Disable Rendering", "✓ 3D Rendering dimatikan!", 4)
        else
            Notify.Send("Disable Rendering", "⚠ Sudah aktif!", 3)
        end
    else
        local success, message = DisableRendering.Stop()
        if success then
            Notify.Send("Disable Rendering", "✓ 3D Rendering dihidupkan!", 3)
        else
            Notify.Send("Disable Rendering", "⚠ Sudah nonaktif!", 3)
        end
    end
end)

-- FPS Unlocker
local catFPS = makeCategory(settingsPage, "FPS Unlocker", "🎞️")

makeDropdown(catFPS, "Select FPS Limit", "⚙️", {"60 FPS", "90 FPS", "120 FPS", "240 FPS"}, function(selected)
    local fpsValue = tonumber(selected:match("%d+"))
    if fpsValue and UnlockFPS and UnlockFPS.SetCap then
        UnlockFPS.SetCap(fpsValue)
        ConfigSystem.Set("Settings.FPSLimit", fpsValue)
        MarkDirty()
    end
end, "FPSDropdown")

-- Hide Stats
local catHideStats = makeCategory(settingsPage, "Hide Stats Identifier", "👤")

local currentFakeName = "Guest"
local currentFakeLevel = "1"

makeToggle(catHideStats, "Enable Hide Stats", "Settings.HideStats.Enabled", function(on)
    if not HideStats then
        Notify.Send("Error ❌", "Hide Stats module tidak ditemukan!", 3)
        warn("❌ HideStats module is nil")
        return
    end
    
    if not HideStats.Enable or not HideStats.Disable then
        Notify.Send("Error ❌", "Hide Stats module tidak valid!", 3)
        warn("❌ HideStats missing Enable/Disable functions")
        return
    end
    
    if on then
        HideStats.Enable()
        Notify.Send("Hide Stats ✨", "Hide Stats aktif! '-LynX-' berkilau di atas nama.", 3)
    else
        HideStats.Disable()
        Notify.Send("Hide Stats", "Hide Stats dimatikan.", 3)
    end
end)

makeTextBox(
    catHideStats,
    "Fake Name",
    "Enter fake name...",
    "",
    function(value)
        currentFakeName = value
        
        if HideStats and HideStats.SetFakeName then
            HideStats.SetFakeName(value)
            Notify.Send("Hide Stats 👤", "Fake name: " .. value, 2)
            ConfigSystem.Set("Settings.HideStats.FakeName", value)
            MarkDirty()
        else
            Notify.Send("Warning ⚠️", "Hide Stats module belum siap!", 3)
        end
    end
)

makeTextBox(
    catHideStats,
    "Fake Level",
    "Enter fake level...",
    "",
    function(value)
        currentFakeLevel = value
        
        if HideStats and HideStats.SetFakeLevel then
            HideStats.SetFakeLevel(value)
            Notify.Send("Hide Stats 📊", "Fake level: " .. value, 2)
            ConfigSystem.Set("Settings.HideStats.FakeLevel", value)
            MarkDirty()
        else
            Notify.Send("Warning ⚠️", "Hide Stats module belum siap!", 3)
        end
    end
)

-- ============================================
-- INFO PAGE - OPTIMIZED
-- ============================================
local infoContainer = new("Frame",{
    Parent=infoPage,
    Size=UDim2.new(1, 0, 0, 420),
    BackgroundColor3=colors.bg3,
    BackgroundTransparency=0.7,
    BorderSizePixel=0,
    ZIndex=6
})
new("UICorner",{Parent=infoContainer, CornerRadius=UDim.new(0, 8)})

local infoText = new("TextLabel",{
    Parent=infoContainer,
    Size=UDim2.new(1, -24, 0, 80),
    Position=UDim2.new(0, 12, 0, 12),
    BackgroundTransparency=1,
    Text=[[
# LynX v2.3 
Free Not For Sale
━━━━━━━━━━━━━━━━━━━━━━
━━━━━━━━━━━━━━━━━━━━━━
Created with by Beee
Refined Edition 2024
    ]],
    Font=Enum.Font.Gotham,
    TextSize=9,
    TextColor3=colors.text,
    TextWrapped=true,
    TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top,
    ZIndex=7
})

local linkButton = new("TextButton",{
    Parent=infoContainer,
    Size=UDim2.new(1, -24, 0, 20),
    Position=UDim2.new(0, 12, 0, 90),
    BackgroundTransparency=1,
    Text="🔗 Discord: https://discord.gg/lynxx",
    Font=Enum.Font.GothamBold,
    TextSize=9,
    TextColor3=Color3.fromRGB(88, 101, 242),
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=7
})

linkButton.MouseButton1Click:Connect(function()
    setclipboard("https://discord.gg/lynxx")
    linkButton.Text = "✅ Link copied to clipboard!"
    task.wait(2)
    linkButton.Text = "🔗 Discord: https://discord.gg/lynxx"
end)

-- ============================================
-- MINIMIZE SYSTEM - OPTIMIZED
-- ============================================
local minimized = false
local icon
local savedIconPos = UDim2.new(0, 20, 0, 100)

local function createMinimizedIcon()
    if icon then return end
    
    icon = new("ImageLabel",{
        Parent=gui,
        Size=UDim2.new(0, 50, 0, 50),
        Position=savedIconPos,
        BackgroundColor3=colors.bg2,
        BackgroundTransparency=0.4,
        BorderSizePixel=0,
        Image="rbxassetid://118176705805619",
        ScaleType=Enum.ScaleType.Fit,
        ZIndex=50
    })
    new("UICorner",{Parent=icon, CornerRadius=UDim.new(0, 10)})
    -- REMOVED: UIStroke untuk performa maksimal
    
    local logoText = new("TextLabel",{
        Parent=icon,
        Text="L",
        Size=UDim2.new(1, 0, 1, 0),
        Font=Enum.Font.GothamBold,
        TextSize=28,
        BackgroundTransparency=1,
        TextColor3=colors.primary,
        Visible=icon.Image == "",
        ZIndex=51
    })
    
    local dragging, dragStart, startPos, dragMoved = false, nil, nil, false
    
    icon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragMoved, dragStart, startPos = true, false, input.Position, icon.Position
        end
    end)
    
    icon.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.sqrt(delta.X^2 + delta.Y^2) > 5 then 
                dragMoved = true 
            end
            -- OPTIMIZED: Direct position update, no tween
            icon.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    icon.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                savedIconPos = icon.Position
                if not dragMoved then
                    bringToFront()
                    win.Visible = true
                    if USE_TWEEN then
                        TweenService:Create(win, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            Size=windowSize,
                            Position=UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
                        }):Play()
                    else
                        win.Size = windowSize
                        win.Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
                    end
                    if icon then 
                        icon:Destroy() 
                        icon = nil 
                    end
                    minimized = false
                end
            end
        end
    end)
end

btnMinHeader.MouseButton1Click:Connect(function()
    if not minimized then
        local targetPos = UDim2.new(0.5, 0, 0.5, 0)
        if USE_TWEEN then
            TweenService:Create(win, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size=UDim2.new(0, 0, 0, 0),
                Position=targetPos
            }):Play()
            task.wait(0.3)
        else
            win.Size = UDim2.new(0, 0, 0, 0)
            win.Position = targetPos
        end
        win.Visible = false
        createMinimizedIcon()
        minimized = true
    end
end)

-- ============================================
-- DRAGGING SYSTEM - ULTRA OPTIMIZED
-- ============================================
local dragging, dragStart, startPos = false, nil, nil

scriptHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        bringToFront()
        dragging, dragStart, startPos = true, input.Position, win.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        -- OPTIMIZED: Direct update if tween disabled
        if USE_TWEEN then
            TweenService:Create(win, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {Position=newPos}):Play()
        else
            win.Position = newPos
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        dragging = false 
    end
end)

-- ============================================
-- RESIZING SYSTEM - ULTRA OPTIMIZED
-- ============================================
local resizeStart, startSize = nil, nil

resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing, resizeStart, startSize = true, input.Position, win.Size
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStart
        
        local newWidth = math.clamp(
            startSize.X.Offset + delta.X,
            minWindowSize.X,
            maxWindowSize.X
        )
        local newHeight = math.clamp(
            startSize.Y.Offset + delta.Y,
            minWindowSize.Y,
            maxWindowSize.Y
        )
        
        local newSize = UDim2.new(0, newWidth, 0, newHeight)
        
        -- OPTIMIZED: Direct update if tween disabled
        if USE_TWEEN then
            TweenService:Create(win, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {Size=newSize}):Play()
        else
            win.Size = newSize
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        resizing = false 
    end
end)

-- REMOVED: Opening animation task untuk performa maksimal
win.Size = windowSize
win.BackgroundTransparency = 0.3

-- ============================================
-- EXECUTE CONFIG CALLBACKS AFTER UI CREATION
-- ============================================
InitializeModuleSettings()
ExecuteConfigCallbacks()

-- REMOVED: Print statements untuk performa lebih ringan

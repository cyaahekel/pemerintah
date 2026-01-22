local modules = {}
modules["instant"] = (function()
-- ⚡ ULTRA SPEED AUTO FISHING v29.4 (Fast Mode - Safe Config Loading)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local Character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Hentikan script lama jika masih aktif
if _G.FishingScriptFast then
    _G.FishingScriptFast.Stop()
    task.wait(0.1)
end

-- Inisialisasi koneksi network
local netFolder = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = netFolder:WaitForChild("RF/UpdateAutoFishingState")
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")
local RE_FishCaught = netFolder:WaitForChild("RE/FishCaught")

-- ⭐ SAFE CONFIG LOADING - Check if function exists
local function safeGetConfig(key, default)
    -- Check if GetConfigValue exists in _G
    if _G.GetConfigValue and type(_G.GetConfigValue) == "function" then
        local success, value = pcall(function()
            return _G.GetConfigValue(key, default)
        end)
        if success and value ~= nil then
            return value
        end
    end
    -- Return default if function doesn't exist or fails
    return default
end

-- ⭐ AUTO-LOAD SETTINGS FROM CONFIG (with safety check)
local function loadConfigSettings()
    local maxWait = safeGetConfig("InstantFishing.FishingDelay", 1.30)
    local cancelDelay = safeGetConfig("InstantFishing.CancelDelay", 0.19)
    
    return maxWait, cancelDelay
end

-- Load settings saat module pertama kali diinisialisasi
local initialMaxWait, initialCancelDelay = loadConfigSettings()

-- Modul utama
local fishing = {
    Running = false,
    WaitingHook = false,
    CurrentCycle = 0,
    TotalFish = 0,
    Connections = {},
    -- ⭐ Settings langsung dari config (dengan safety check)
    Settings = {
        FishingDelay = 0.01,
        CancelDelay = initialCancelDelay,
        HookDetectionDelay = 0.05,
        RetryDelay = 0.1,
        MaxWaitTime = initialMaxWait,
    }
}

_G.FishingScriptFast = fishing

-- ⭐ Auto-refresh settings setiap kali akan Start (dengan safety check)
local function refreshSettings()
    local maxWait = safeGetConfig("InstantFishing.FishingDelay", fishing.Settings.MaxWaitTime)
    local cancelDelay = safeGetConfig("InstantFishing.CancelDelay", fishing.Settings.CancelDelay)
    
    fishing.Settings.MaxWaitTime = maxWait
    fishing.Settings.CancelDelay = cancelDelay
end

-- Nonaktifkan animasi
local function disableFishingAnim()
    pcall(function()
        for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
            local name = track.Name:lower()
            if name:find("fish") or name:find("rod") or name:find("cast") or name:find("reel") then
                track:Stop(0)
            end
        end
    end)

    task.spawn(function()
        local rod = Character:FindFirstChild("Rod") or Character:FindFirstChildWhichIsA("Tool")
        if rod and rod:FindFirstChild("Handle") then
            local handle = rod.Handle
            local weld = handle:FindFirstChildOfClass("Weld") or handle:FindFirstChildOfClass("Motor6D")
            if weld then
                weld.C0 = CFrame.new(0, -1, -1.2) * CFrame.Angles(math.rad(-10), 0, 0)
            end
        end
    end)
end

-- Fungsi cast (⭐ Menggunakan Settings.MaxWaitTime dan Settings.CancelDelay)
function fishing.Cast()
    if not fishing.Running or fishing.WaitingHook then return end

    disableFishingAnim()
    fishing.CurrentCycle += 1

    local castSuccess = pcall(function()
        RF_ChargeFishingRod:InvokeServer({[10] = tick()})
        task.wait(0.07)
        RF_RequestMinigame:InvokeServer(9, 0, tick())
        fishing.WaitingHook = true

        task.delay(fishing.Settings.MaxWaitTime * 0.7, function()
            if fishing.WaitingHook and fishing.Running then
                pcall(function()
                    RE_FishingCompleted:FireServer()
                end)
            end
        end)

        task.delay(fishing.Settings.MaxWaitTime, function()
            if fishing.WaitingHook and fishing.Running then
                fishing.WaitingHook = false
                pcall(function()
                    RE_FishingCompleted:FireServer()
                end)

                task.wait(fishing.Settings.RetryDelay)
                pcall(function()
                    RF_CancelFishingInputs:InvokeServer()
                end)

                task.wait(fishing.Settings.FishingDelay)
                if fishing.Running then
                    fishing.Cast()
                end
            end
        end)
    end)

    if not castSuccess then
        task.wait(fishing.Settings.RetryDelay)
        if fishing.Running then
            fishing.Cast()
        end
    end
end

-- Start (⭐ Auto-refresh settings sebelum start)
function fishing.Start()
    if fishing.Running then return end
    
    -- ⭐ Refresh settings dari config sebelum start
    refreshSettings()
    
    fishing.Running = true
    fishing.CurrentCycle = 0
    fishing.TotalFish = 0

    disableFishingAnim()

    fishing.Connections.Minigame = RE_MinigameChanged.OnClientEvent:Connect(function(state)
        if fishing.WaitingHook and typeof(state) == "string" then
            local s = string.lower(state)
            if string.find(s, "hook") or string.find(s, "bite") or string.find(s, "catch") then
                fishing.WaitingHook = false
                task.wait(fishing.Settings.HookDetectionDelay)

                pcall(function()
                    RE_FishingCompleted:FireServer()
                end)

                task.wait(fishing.Settings.CancelDelay)
                pcall(function()
                    RF_CancelFishingInputs:InvokeServer()
                end)

                task.wait(fishing.Settings.FishingDelay)
                if fishing.Running then
                    fishing.Cast()
                end
            end
        end
    end)

    fishing.Connections.Caught = RE_FishCaught.OnClientEvent:Connect(function(_, data)
        if fishing.Running then
            fishing.WaitingHook = false
            fishing.TotalFish += 1

            pcall(function()
                task.wait(fishing.Settings.CancelDelay)
                RF_CancelFishingInputs:InvokeServer()
            end)

            task.wait(fishing.Settings.FishingDelay)
            if fishing.Running then
                fishing.Cast()
            end
        end
    end)

    fishing.Connections.AnimDisabler = task.spawn(function()
        while fishing.Running do
            disableFishingAnim()
            task.wait(0.15)
        end
    end)

    task.wait(0.5)
    fishing.Cast()
end

-- Stop
function fishing.Stop()
    if not fishing.Running then return end
    fishing.Running = false
    fishing.WaitingHook = false

    for _, conn in pairs(fishing.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        elseif typeof(conn) == "thread" then
            task.cancel(conn)
        end
    end
    fishing.Connections = {}
    
    pcall(function()
        RF_UpdateAutoFishingState:InvokeServer(true)
    end)
    
    task.wait(0.2)
    
    pcall(function()
        RF_CancelFishingInputs:InvokeServer()
    end)
end

-- ⭐ Function untuk update settings dari GUI (tetap ada untuk backward compatibility)
function fishing.UpdateSettings(maxWaitTime, cancelDelay)
    if maxWaitTime then
        fishing.Settings.MaxWaitTime = maxWaitTime
    end
    if cancelDelay then
        fishing.Settings.CancelDelay = cancelDelay
    end
end

return fishing
end)()
modules["instant2"] = (function()
-- ⚡ ULTRA PERFECT CAST AUTO FISHING v35.2 (Safe Config Loading)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local Character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

if _G.FishingScript then
    _G.FishingScript.Stop()
    task.wait(0.1)
end

local netFolder = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = netFolder:WaitForChild("RF/UpdateAutoFishingState")
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")
local RE_FishCaught = netFolder:WaitForChild("RE/FishCaught")
local RE_FishingStopped = netFolder:WaitForChild("RE/FishingStopped")

-- ⭐ SAFE CONFIG LOADING - Check if function exists
local function safeGetConfig(key, default)
    -- Check if GetConfigValue exists in _G
    if _G.GetConfigValue and type(_G.GetConfigValue) == "function" then
        local success, value = pcall(function()
            return _G.GetConfigValue(key, default)
        end)
        if success and value ~= nil then
            return value
        end
    end
    -- Return default if function doesn't exist or fails
    return default
end

-- ⭐ SAFE: Load saved settings dari GUI config
local function loadSavedSettings()
    local maxWait = safeGetConfig("InstantFishing.FishingDelay", 1.5)
    local cancelDelay = safeGetConfig("InstantFishing.CancelDelay", 0.19)
    
    return {
        MaxWaitTime = maxWait,
        CancelDelay = cancelDelay
    }
end

local savedSettings = loadSavedSettings()

local fishing = {
    Running = false,
    WaitingHook = false,
    CurrentCycle = 0,
    TotalFish = 0,
    PerfectCasts = 0,
    AmazingCasts = 0,
    FailedCasts = 0,
    Connections = {},
    Settings = {
        FishingDelay = 0.07,
        CancelDelay = savedSettings.CancelDelay,  -- ⭐ Use saved value
        HookDetectionDelay = 0.03,
        RetryDelay = 0.04,
        MaxWaitTime = savedSettings.MaxWaitTime,  -- ⭐ Use saved value
        FailTimeout = 2.5,
        PerfectChargeTime = 0.34,
        PerfectReleaseDelay = 0.005,
        PerfectPower = 0.95,
        UseMultiDetection = true,
        UseVisualDetection = true,
        UseSoundDetection = false,
    }
}

_G.FishingScript = fishing

-- ⭐ Auto-refresh settings setiap kali akan Start (dengan safety check)
local function refreshSettings()
    local maxWait = safeGetConfig("InstantFishing.FishingDelay", fishing.Settings.MaxWaitTime)
    local cancelDelay = safeGetConfig("InstantFishing.CancelDelay", fishing.Settings.CancelDelay)
    
    fishing.Settings.MaxWaitTime = maxWait
    fishing.Settings.CancelDelay = cancelDelay
end

local function disableFishingAnim()
    pcall(function()
        for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
            local name = track.Name:lower()
            if name:find("fish") or name:find("rod") or name:find("cast") or name:find("reel") then
                track:Stop(0)
                track.TimePosition = 0
            end
        end
    end)

    task.spawn(function()
        local rod = Character:FindFirstChild("Rod") or Character:FindFirstChildWhichIsA("Tool")
        if rod and rod:FindFirstChild("Handle") then
            local handle = rod.Handle
            local weld = handle:FindFirstChildOfClass("Weld") or handle:FindFirstChildOfClass("Motor6D")
            if weld then
                weld.C0 = CFrame.new(0, -1, -1.2) * CFrame.Angles(math.rad(-10), 0, 0)
            end
        end
    end)
end

local function handleFailedCast()
    fishing.WaitingHook = false
    fishing.FailedCasts += 1
    
    pcall(function()
        RF_CancelFishingInputs:InvokeServer()
    end)
    
    task.wait(fishing.Settings.RetryDelay)
    
    if fishing.Running then
        fishing.PerfectCast()
    end
end

function fishing.PerfectCast()
    if not fishing.Running or fishing.WaitingHook then 
        return 
    end

    disableFishingAnim()
    fishing.CurrentCycle += 1

    local castSuccess = pcall(function()
        local startTime = tick()
        local chargeData = {[1] = startTime}
        
        local chargeResult = RF_ChargeFishingRod:InvokeServer(chargeData)
        if not chargeResult then 
            error("Charge fishing rod failed") 
        end

        local waitTime = fishing.Settings.PerfectChargeTime
        local endTime = tick() + waitTime
        while tick() < endTime and fishing.Running do
            task.wait(0.01)
        end

        task.wait(fishing.Settings.PerfectReleaseDelay)

        local releaseTime = tick()
        local perfectPower = fishing.Settings.PerfectPower

        local minigameResult = RF_RequestMinigame:InvokeServer(
            perfectPower,
            0,
            releaseTime
        )
        
        if not minigameResult then 
            handleFailedCast()
            return
        end

        fishing.WaitingHook = true
        local hookDetected = false
        local castStartTime = tick()
        local eventDetection

        eventDetection = RE_MinigameChanged.OnClientEvent:Connect(function(state)
            if fishing.WaitingHook and typeof(state) == "string" then
                local s = state:lower()
                if s:find("hook") or s:find("bite") or s:find("catch") or s == "!" then
                    hookDetected = true
                    eventDetection:Disconnect()
                    
                    fishing.WaitingHook = false

                    task.wait(fishing.Settings.HookDetectionDelay)
                    pcall(function()
                        RE_FishingCompleted:FireServer()
                    end)

                    task.wait(fishing.Settings.CancelDelay)
                    pcall(function()
                        RF_CancelFishingInputs:InvokeServer()
                    end)

                    task.wait(fishing.Settings.FishingDelay)
                    if fishing.Running then
                        fishing.PerfectCast()
                    end
                end
            end
        end)

        task.delay(fishing.Settings.MaxWaitTime, function()
            if fishing.WaitingHook and fishing.Running then
                if not hookDetected then
                    fishing.WaitingHook = false
                    eventDetection:Disconnect()

                    pcall(function()
                        RE_FishingCompleted:FireServer()
                    end)

                    task.wait(fishing.Settings.RetryDelay)
                    pcall(function()
                        RF_CancelFishingInputs:InvokeServer()
                    end)

                    task.wait(fishing.Settings.FishingDelay)
                    if fishing.Running then
                        fishing.PerfectCast()
                    end
                end
            end
        end)
        
        task.delay(fishing.Settings.FailTimeout, function()
            if fishing.WaitingHook and fishing.Running then
                local elapsedTime = tick() - castStartTime
                
                if elapsedTime >= fishing.Settings.FailTimeout then
                    if eventDetection then
                        eventDetection:Disconnect()
                    end
                    
                    handleFailedCast()
                end
            end
        end)
    end)

    if not castSuccess then
        task.wait(fishing.Settings.RetryDelay)
        if fishing.Running then
            fishing.PerfectCast()
        end
    end
end

function fishing.Start()
    if fishing.Running then return end
    
    -- ⭐ Refresh settings dari config sebelum start
    refreshSettings()
    
    fishing.Running = true
    fishing.CurrentCycle = 0
    fishing.TotalFish = 0
    fishing.PerfectCasts = 0
    fishing.AmazingCasts = 0
    fishing.FailedCasts = 0

    disableFishingAnim()

    fishing.Connections.FishingStopped = RE_FishingStopped.OnClientEvent:Connect(function()
        if fishing.Running and fishing.WaitingHook then
            handleFailedCast()
        end
    end)

    fishing.Connections.Caught = RE_FishCaught.OnClientEvent:Connect(function(name, data)
        if fishing.Running then
            fishing.WaitingHook = false
            fishing.TotalFish += 1

            local castResult = data and data.CastResult or "Unknown"
            if castResult == "Perfect" then
                fishing.PerfectCasts += 1
            elseif castResult == "Amazing" then
                fishing.AmazingCasts += 1
            end

            task.wait(fishing.Settings.CancelDelay)
            pcall(function()
                RF_CancelFishingInputs:InvokeServer()
            end)

            task.wait(fishing.Settings.FishingDelay)
            if fishing.Running then
                fishing.PerfectCast()
            end
        end
    end)

    fishing.Connections.AnimDisabler = task.spawn(function()
        while fishing.Running do
            disableFishingAnim()
            task.wait(0.1)
        end
    end)

    fishing.Connections.StatsReporter = task.spawn(function()
        while fishing.Running do
            task.wait(30)
        end
    end)

    task.wait(0.3)
    fishing.PerfectCast()
end

function fishing.Stop()
    if not fishing.Running then return end
    fishing.Running = false
    fishing.WaitingHook = false

    for _, conn in pairs(fishing.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        elseif typeof(conn) == "thread" then
            task.cancel(conn)
        end
    end

    fishing.Connections = {}
    
    pcall(function()
        RF_UpdateAutoFishingState:InvokeServer(true)
    end)
    
    task.wait(0.2)
    
    pcall(function()
        RF_CancelFishingInputs:InvokeServer()
    end)
end

-- ⭐ Function untuk update settings dari GUI (tetap ada untuk backward compatibility)
function fishing.UpdateSettings(maxWaitTime, cancelDelay)
    if maxWaitTime then
        fishing.Settings.MaxWaitTime = maxWaitTime
    end
    if cancelDelay then
        fishing.Settings.CancelDelay = cancelDelay
    end
end

return fishing
end)()

modules["TeleportModule"] = (function()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local netFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")
local RE_FishCaught = netFolder:WaitForChild("RE/FishCaught")

local fishing = {
    Running = false,
    WaitingHook = false,
    CurrentCycle = 0,
    TotalFish = 0,
    Settings = {
        FishingDelay = 0.05,
        CancelDelay = 0.01,
        HookWaitTime = 0.01,
        CastDelay = 0.25,
        TimeoutDelay = 0.8,
    },
}

_G.FishingScript = fishing

-- Event handler optimized dengan spawn untuk non-blocking
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if fishing.WaitingHook and typeof(state) == "string" and string.find(string.lower(state), "hook") then
        fishing.WaitingHook = false
        
        task.spawn(function()
            task.wait(fishing.Settings.HookWaitTime)
            RE_FishingCompleted:FireServer()
            
            task.wait(fishing.Settings.CancelDelay)
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
            
            task.wait(fishing.Settings.FishingDelay)
            if fishing.Running then fishing.Cast() end
        end)
    end
end)

RE_FishCaught.OnClientEvent:Connect(function(name, data)
    if fishing.Running then
        fishing.WaitingHook = false
        fishing.TotalFish = fishing.TotalFish + 1
        
        task.spawn(function()
            task.wait(fishing.Settings.CancelDelay)
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
            
            task.wait(fishing.Settings.FishingDelay)
            if fishing.Running then fishing.Cast() end
        end)
    end
end)

function fishing.Cast()
    if not fishing.Running or fishing.WaitingHook then return end
    
    fishing.CurrentCycle = fishing.CurrentCycle + 1
    
    task.spawn(function()
        pcall(function()
            -- Charge dan request dalam satu batch untuk kecepatan maksimal
            RF_ChargeFishingRod:InvokeServer({[10] = tick()})
            task.wait(fishing.Settings.CastDelay)
            RF_RequestMinigame:InvokeServer(10, 0, tick())
            
            fishing.WaitingHook = true
            
            -- Timeout handler yang lebih cepat
            task.delay(fishing.Settings.TimeoutDelay, function()
                if fishing.WaitingHook and fishing.Running then
                    fishing.WaitingHook = false
                    RE_FishingCompleted:FireServer()
                    
                    task.wait(fishing.Settings.CancelDelay)
                    pcall(function() RF_CancelFishingInputs:InvokeServer() end)
                    
                    task.wait(fishing.Settings.FishingDelay)
                    if fishing.Running then fishing.Cast() end
                end
            end)
        end)
    end)
end

function fishing.Start()
    if fishing.Running then return end
    fishing.Running = true
    fishing.CurrentCycle = 0
    fishing.TotalFish = 0
    fishing.Cast()
end

function fishing.Stop()
    fishing.Running = false
    fishing.WaitingHook = false
end

return fishing
end)()
modules["TeleportModule"] = (function()
-- 🌍 TeleportModule.lua
-- Modul fungsi teleport + daftar lokasi

local TeleportModule = {}

TeleportModule.Locations = {
    ["Ancient Jungle"] = Vector3.new(1467.8480224609375, 7.447117328643799, -327.5971984863281),
    ["Ancient Ruin"] = Vector3.new(6045.40234375, -588.600830078125, 4608.9375),
    ["Coral Reefs"] = Vector3.new(-2921.858154296875, 3.249999761581421, 2083.2978515625),
    ["Crater Island"] = Vector3.new(1078.454345703125, 5.0720038414001465, 5099.396484375),
    ["Classic Island"] = Vector3.new(1253.974853515625, 9.999999046325684, 2816.7646484375),
    ["Christmas Island"] = Vector3.new(1130.576904, 23.854950, 1554.231567),
    ["Christmas Cave"] = Vector3.new(535.279724121093750, -580.581359863281250, 8900.060546875000000),
    ["Iron Cavern"] = Vector3.new(-8881.52734375, -581.7500610351562, 156.1653289794922),
    ["The Iron Cafe"] = Vector3.new(-8642.7265625, -547.5001831054688, 159.8160400390625),
    ["Esoteric Depths"] = Vector3.new(3224.075927734375, -1302.85498046875, 1404.9346923828125),
    ["Fisherman Island"] = Vector3.new(92.80695343017578, 9.531265258789062, 2762.082275390625),
    ["Kohana"] = Vector3.new(-643.3051147460938, 16.03544807434082, 622.3605346679688),
    ["Kohana Volcano"] = Vector3.new(-572.0244750976562, 39.4923210144043, 112.49259185791016),
    ["Lost Isle"] = Vector3.new(-3701.1513671875, 5.425841808319092, -1058.9107666015625),
    ["Sysiphus Statue"] = Vector3.new(-3656.56201171875, -134.5314178466797, -964.3167724609375),
    ["Sacred Temple"] = Vector3.new(1476.30810546875, -21.8499755859375, -630.8220825195312),
    ["Treasure Room"] = Vector3.new(-3601.568359375, -266.57373046875, -1578.998779296875),
    ["Tropical Grove"] = Vector3.new(-2104.467041015625, 6.268016815185547, 3718.2548828125),
    ["Underground Cellar"] = Vector3.new(2162.577392578125, -91.1981430053711, -725.591552734375),
    ["Weather Machine"] = Vector3.new(-1513.9249267578125, 6.499999523162842, 1892.10693359375)
}

function TeleportModule.TeleportTo(name)
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    local target = TeleportModule.Locations[name]
    if not target then
        warn("⚠️ Lokasi '" .. tostring(name) .. "' tidak ditemukan!")
        return
    end

    root.CFrame = CFrame.new(target)
    print("✅ Teleported to:", name)
end

return TeleportModule
end)()

modules["blatantv1"] = (function()
-- ⚠️ ULTRA BLATANT AUTO FISHING - GUI COMPATIBLE MODULE
-- DESIGNED TO WORK WITH EXTERNAL GUI SYSTEM
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Network initialization
local netFolder = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = netFolder:WaitForChild("RF/UpdateAutoFishingState")  -- ⭐ ADDED untuk stop function
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")

-- Module table
local UltraBlatant = {}
UltraBlatant.Active = false
UltraBlatant.Stats = {
    castCount = 0,
    startTime = 0
}

-- Settings (sesuai dengan pattern GUI kamu)
UltraBlatant.Settings = {
    CompleteDelay = 0.001,    -- Delay sebelum complete
    CancelDelay = 0.001       -- Delay setelah complete sebelum cancel
}

----------------------------------------------------------------
-- CORE FUNCTIONS
----------------------------------------------------------------

local function safeFire(func)
    task.spawn(function()
        pcall(func)
    end)
end

-- MAIN SPAM LOOP
local function ultraSpamLoop()
    while UltraBlatant.Active do
        local currentTime = tick()
        
        -- 1x CHARGE & REQUEST (CASTING)
        safeFire(function()
            RF_ChargeFishingRod:InvokeServer({[1] = currentTime})
        end)
        safeFire(function()
            RF_RequestMinigame:InvokeServer(1, 0, currentTime)
        end)
        
        UltraBlatant.Stats.castCount = UltraBlatant.Stats.castCount + 1
        
        -- Wait CompleteDelay then fire complete once
        task.wait(UltraBlatant.Settings.CompleteDelay)
        
        safeFire(function()
            RE_FishingCompleted:FireServer()
        end)
        
        -- Cancel with CancelDelay
        task.wait(UltraBlatant.Settings.CancelDelay)
        safeFire(function()
            RF_CancelFishingInputs:InvokeServer()
        end)
    end
end

-- BACKUP LISTENER
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not UltraBlatant.Active then return end
    
    task.spawn(function()
        task.wait(UltraBlatant.Settings.CompleteDelay)
        
        safeFire(function()
            RE_FishingCompleted:FireServer()
        end)
        
        task.wait(UltraBlatant.Settings.CancelDelay)
        safeFire(function()
            RF_CancelFishingInputs:InvokeServer()
        end)
    end)
end)

----------------------------------------------------------------
-- PUBLIC API (Compatible dengan pattern GUI kamu)
----------------------------------------------------------------

-- ⭐ NEW: Update Settings function
function UltraBlatant.UpdateSettings(completeDelay, cancelDelay)
    if completeDelay ~= nil then
        UltraBlatant.Settings.CompleteDelay = completeDelay
        print("✅ UltraBlatant CompleteDelay updated:", completeDelay)
    end
    
    if cancelDelay ~= nil then
        UltraBlatant.Settings.CancelDelay = cancelDelay
        print("✅ UltraBlatant CancelDelay updated:", cancelDelay)
    end
end

-- Start function
function UltraBlatant.Start()
    if UltraBlatant.Active then 
        print("⚠️ Ultra Blatant already running!")
        return
    end
    
    UltraBlatant.Active = true
    UltraBlatant.Stats.castCount = 0
    UltraBlatant.Stats.startTime = tick()
    
    task.spawn(ultraSpamLoop)
end

-- ⭐ ENHANCED Stop function - Nyalakan auto fishing game
function UltraBlatant.Stop()
    if not UltraBlatant.Active then 
        return
    end
    
    UltraBlatant.Active = false
    
    -- ⭐ Nyalakan auto fishing game (biarkan tetap nyala)
    safeFire(function()
        RF_UpdateAutoFishingState:InvokeServer(true)
    end)
    
    -- Wait sebentar untuk game process
    task.wait(0.2)
    
    -- Cancel fishing inputs untuk memastikan karakter berhenti
    safeFire(function()
        RF_CancelFishingInputs:InvokeServer()
    end)
    
    print("✅ Ultra Blatant stopped - Game auto fishing enabled, can change rod/skin")
end

-- Return module
return UltraBlatant
end)()

modules["blatantv2"] = (function()
-- ULTRA SPEED AUTO FISHING V2 - OPTIMIZED FOR MAXIMUM SPEED
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local netFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")
local RE_FishCaught = netFolder:WaitForChild("RE/FishCaught")

local fishing = {
    Running = false,
    WaitingHook = false,
    CurrentCycle = 0,
    TotalFish = 0,
    Settings = {
        FishingDelay = 0.05,
        CancelDelay = 0.01,
        HookWaitTime = 0.01,
        CastDelay = 0.25,
        TimeoutDelay = 0.8,
    },
}

_G.FishingScript = fishing

-- Event handler optimized dengan spawn untuk non-blocking
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if fishing.WaitingHook and typeof(state) == "string" and string.find(string.lower(state), "hook") then
        fishing.WaitingHook = false
        
        task.spawn(function()
            task.wait(fishing.Settings.HookWaitTime)
            RE_FishingCompleted:FireServer()
            
            task.wait(fishing.Settings.CancelDelay)
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
            
            task.wait(fishing.Settings.FishingDelay)
            if fishing.Running then fishing.Cast() end
        end)
    end
end)

RE_FishCaught.OnClientEvent:Connect(function(name, data)
    if fishing.Running then
        fishing.WaitingHook = false
        fishing.TotalFish = fishing.TotalFish + 1
        
        task.spawn(function()
            task.wait(fishing.Settings.CancelDelay)
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
            
            task.wait(fishing.Settings.FishingDelay)
            if fishing.Running then fishing.Cast() end
        end)
    end
end)

function fishing.Cast()
    if not fishing.Running or fishing.WaitingHook then return end
    
    fishing.CurrentCycle = fishing.CurrentCycle + 1
    
    task.spawn(function()
        pcall(function()
            -- Charge dan request dalam satu batch untuk kecepatan maksimal
            RF_ChargeFishingRod:InvokeServer({[10] = tick()})
            task.wait(fishing.Settings.CastDelay)
            RF_RequestMinigame:InvokeServer(10, 0, tick())
            
            fishing.WaitingHook = true
            
            -- Timeout handler yang lebih cepat
            task.delay(fishing.Settings.TimeoutDelay, function()
                if fishing.WaitingHook and fishing.Running then
                    fishing.WaitingHook = false
                    RE_FishingCompleted:FireServer()
                    
                    task.wait(fishing.Settings.CancelDelay)
                    pcall(function() RF_CancelFishingInputs:InvokeServer() end)
                    
                    task.wait(fishing.Settings.FishingDelay)
                    if fishing.Running then fishing.Cast() end
                end
            end)
        end)
    end)
end

function fishing.Start()
    if fishing.Running then return end
    fishing.Running = true
    fishing.CurrentCycle = 0
    fishing.TotalFish = 0
    fishing.Cast()
end

function fishing.Stop()
    fishing.Running = false
    fishing.WaitingHook = false
end

return fishing
end)()

modules["NoFishingAnimation"] = (function()
-- NoFishingAnimation.lua
-- Auto freeze karakter di pose fishing dengan ZERO animasi
-- Ready untuk diintegrasikan ke GUI

local NoFishingAnimation = {}
NoFishingAnimation.Enabled = false
NoFishingAnimation.Connection = nil
NoFishingAnimation.SavedPose = {}
NoFishingAnimation.ReelingTrack = nil
NoFishingAnimation.AnimationBlocker = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- Fungsi untuk find ReelingIdle animation
local function getOrCreateReelingAnimation()
    local success, result = pcall(function()
        local character = localPlayer.Character
        if not character then return nil end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return nil end
        
        -- Cari animasi ReelingIdle yang sudah ada
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            local name = track.Name
            if name:find("Reel") and name:find("Idle") then
                return track
            end
        end
        
        -- Cari di semua loaded animations
        for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
            if track.Animation then
                if track.Name:find("Reel") then
                    return track
                end
            end
        end
        
        -- Jika tidak ada, coba cari di character tools
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                for _, anim in pairs(tool:GetDescendants()) do
                    if anim:IsA("Animation") then
                        local name = anim.Name
                        if name:find("Reel") and name:find("Idle") then
                            local track = animator:LoadAnimation(anim)
                            return track
                        end
                    end
                end
            end
        end
        
        return nil
    end)
    
    if success then
        return result
    end
    return nil
end

-- Fungsi untuk capture pose dari Motor6D
local function capturePose()
    NoFishingAnimation.SavedPose = {}
    local count = 0
    
    pcall(function()
        local character = localPlayer.Character
        if not character then return end
        
        -- Simpan SEMUA Motor6D
        for _, descendant in pairs(character:GetDescendants()) do
            if descendant:IsA("Motor6D") then
                NoFishingAnimation.SavedPose[descendant.Name] = {
                    Part = descendant,
                    C0 = descendant.C0,
                    C1 = descendant.C1,
                    Transform = descendant.Transform
                }
                count = count + 1
            end
        end
    end)
    
    return count > 0
end

-- Fungsi untuk STOP SEMUA animasi secara permanent
local function killAllAnimations()
    pcall(function()
        local character = localPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return nil end
        
        -- STOP semua playing animations
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop(0)
            track:Destroy()
        end
        
        -- STOP semua humanoid animations
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop(0)
            track:Destroy()
        end
    end)
end

-- Fungsi untuk BLOCK animasi baru agar tidak play
local function blockNewAnimations()
    if NoFishingAnimation.AnimationBlocker then
        NoFishingAnimation.AnimationBlocker:Disconnect()
    end
    
    pcall(function()
        local character = localPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return nil end
        
        -- Hook semua animasi baru yang mau play
        NoFishingAnimation.AnimationBlocker = animator.AnimationPlayed:Connect(function(animTrack)
            if NoFishingAnimation.Enabled then
                animTrack:Stop(0)
                animTrack:Destroy()
            end
        end)
    end)
end

-- Fungsi untuk freeze pose
local function freezePose()
    if NoFishingAnimation.Connection then
        NoFishingAnimation.Connection:Disconnect()
    end
    
    NoFishingAnimation.Connection = RunService.RenderStepped:Connect(function()
        if not NoFishingAnimation.Enabled then return end
        
        pcall(function()
            local character = localPlayer.Character
            if not character then return end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            
            -- FORCE STOP semua animasi setiap frame
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
            
            -- APPLY SAVED POSE setiap frame
            for jointName, poseData in pairs(NoFishingAnimation.SavedPose) do
                local motor = character:FindFirstChild(jointName, true)
                if motor and motor:IsA("Motor6D") then
                    motor.C0 = poseData.C0
                    motor.C1 = poseData.C1
                end
            end
        end)
    end)
end

-- Fungsi Stop
local function stopFreeze()
    if NoFishingAnimation.Connection then
        NoFishingAnimation.Connection:Disconnect()
        NoFishingAnimation.Connection = nil
    end
    
    if NoFishingAnimation.AnimationBlocker then
        NoFishingAnimation.AnimationBlocker:Disconnect()
        NoFishingAnimation.AnimationBlocker = nil
    end
    
    if NoFishingAnimation.ReelingTrack then
        NoFishingAnimation.ReelingTrack:Stop()
        NoFishingAnimation.ReelingTrack = nil
    end
    
    NoFishingAnimation.SavedPose = {}
end

-- ============================================
-- PUBLIC FUNCTIONS (untuk GUI)
-- ============================================

-- Fungsi Start (AUTO - tanpa perlu memancing dulu)
function NoFishingAnimation.Start()
    if NoFishingAnimation.Enabled then
        return false, "Already enabled"
    end
    
    local character = localPlayer.Character
    if not character then 
        return false, "Character not found"
    end
    
    -- 1. Cari atau buat ReelingIdle animation
    local reelingTrack = getOrCreateReelingAnimation()
    
    if reelingTrack then
        -- 2. Play animasi (pause setelah beberapa frame)
        reelingTrack:Play()
        reelingTrack:AdjustSpeed(0) -- Pause animasi di frame pertama
        
        NoFishingAnimation.ReelingTrack = reelingTrack
        
        -- 3. Tunggu animasi apply ke Motor6D
        task.wait(0.2)
        
        -- 4. Capture pose
        local success = capturePose()
        
        if success then
            -- 5. KILL semua animasi
            killAllAnimations()
            
            -- 6. Block animasi baru
            blockNewAnimations()
            
            -- 7. Enable freeze
            NoFishingAnimation.Enabled = true
            freezePose()
            
            return true, "Pose frozen successfully"
        else
            reelingTrack:Stop()
            return false, "Failed to capture pose"
        end
    else
        return false, "Reeling animation not found"
    end
end

-- Fungsi Start dengan delay (RECOMMENDED)
function NoFishingAnimation.StartWithDelay(delay, callback)
    if NoFishingAnimation.Enabled then
        return false, "Already enabled"
    end
    
    delay = delay or 2
    
    -- Jalankan di coroutine agar tidak blocking
    task.spawn(function()
        task.wait(delay)
        
        local success = capturePose()
        
        if success then
            -- KILL semua animasi
            killAllAnimations()
            
            -- Block animasi baru
            blockNewAnimations()
            
            -- Enable freeze
            NoFishingAnimation.Enabled = true
            freezePose()
            
            -- Callback jika ada
            if callback then
                callback(true, "Pose frozen successfully")
            end
        else
            -- Callback error
            if callback then
                callback(false, "Failed to capture pose")
            end
        end
    end)
    
    return true, "Starting with delay..."
end

-- Fungsi Stop
function NoFishingAnimation.Stop()
    if not NoFishingAnimation.Enabled then
        return false, "Already disabled"
    end
    
    NoFishingAnimation.Enabled = false
    stopFreeze()
    
    return true, "Pose unfrozen"
end

-- Fungsi untuk cek status
function NoFishingAnimation.IsEnabled()
    return NoFishingAnimation.Enabled
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

-- Handle respawn
localPlayer.CharacterAdded:Connect(function(character)
    if NoFishingAnimation.Enabled then
        NoFishingAnimation.Enabled = false
        stopFreeze()
    end
end)

-- Cleanup
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == localPlayer then
        if NoFishingAnimation.Enabled then
            NoFishingAnimation.Stop()
        end
    end
end)

return NoFishingAnimation
end)()

modules["LockPosition"] = (function()
-- LockPosition.lua
local RunService = game:GetService("RunService")

local LockPosition = {}
LockPosition.Enabled = false
LockPosition.LockedPos = nil
LockPosition.Connection = nil

-- Aktifkan Lock Position
function LockPosition.Start()
    if LockPosition.Enabled then return end
    LockPosition.Enabled = true

    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    LockPosition.LockedPos = hrp.CFrame

    -- Loop untuk menjaga posisi
    LockPosition.Connection = RunService.Heartbeat:Connect(function()
        if not LockPosition.Enabled then return end

        local c = player.Character
        if not c then return end
        
        local hrp2 = c:FindFirstChild("HumanoidRootPart")
        if not hrp2 then return end

        -- Selalu kembalikan ke posisi yang dikunci
        hrp2.CFrame = LockPosition.LockedPos
    end)

    print("Lock Position: Activated")
end

-- Nonaktifkan Lock Position
function LockPosition.Stop()
    LockPosition.Enabled = false

    if LockPosition.Connection then
        LockPosition.Connection:Disconnect()
        LockPosition.Connection = nil
    end

    print("Lock Position: Deactivated")
end

return LockPosition
end)()

modules["DisableCutscenes"] = (function()
--=====================================================
-- DisableCutscenes.lua (FINAL MODULE VERSION)
-- Memiliki: Start(), Stop()
--=====================================================

local DisableCutscenes = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Index = Packages:WaitForChild("_Index")
local NetFolder = Index:WaitForChild("sleitnick_net@0.2.0")
local net = NetFolder:WaitForChild("net")

local ReplicateCutscene = net:FindFirstChild("ReplicateCutscene")
local StopCutscene = net:FindFirstChild("StopCutscene")
local BlackoutScreen = net:FindFirstChild("BlackoutScreen")

local running = false
local _connections = {}
local _loopThread = nil

local function connect(event, fn)
    if event then
        local c = event.OnClientEvent:Connect(fn)
        table.insert(_connections, c)
    end
end

-----------------------------------------------------
-- START
-----------------------------------------------------
function DisableCutscenes.Start()
    if running then return end
    running = true

    -- Block ReplicateCutscene
    connect(ReplicateCutscene, function(...)
        if running and StopCutscene then
            StopCutscene:FireServer()
        end
    end)

    -- Block BlackoutScreen
    connect(BlackoutScreen, function(...)
        -- just ignore
    end)

    -- Loop paksa StopCutscene tiap 1 detik
    _loopThread = task.spawn(function()
        while running do
            if StopCutscene then
                StopCutscene:FireServer()
            end
            task.wait(1)
        end
    end)
end

-----------------------------------------------------
-- STOP
-----------------------------------------------------
function DisableCutscenes.Stop()
    if not running then return end
    running = false

    -- Hapus semua koneksi listener
    for _, c in ipairs(_connections) do
        c:Disconnect()
    end

    _connections = {}

    -- Stop loop
    if _loopThread then
        task.cancel(_loopThread)
        _loopThread = nil
    end
end

-----------------------------------------------------
return DisableCutscenes
end)()

modules["DisableExtras"] = (function()
-- DisableExtras.lua
local module = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local VFXFolder = ReplicatedStorage:WaitForChild("VFX")

local activeSmallNotif = false
local activeSkinEffect = false

-- =========================
-- Small Notification
-- =========================
local function disableNotifications()
    if not player or not player:FindFirstChild("PlayerGui") then return end
    local gui = player.PlayerGui
    local existing = gui:FindFirstChild("Small Notification")
    if existing then
        existing:Destroy()
    end
end

-- =========================
-- Skin Effect Dive
-- =========================
local function disableDiveEffects()
    for _, child in pairs(VFXFolder:GetChildren()) do
        if child.Name:match("Dive$") then
            child:Destroy()
        end
    end
end

-- =========================
-- Start / Stop Small Notification
-- =========================
function module.StartSmallNotification()
    if activeSmallNotif then return end
    activeSmallNotif = true

    -- Loop setiap frame
    RunService.Heartbeat:Connect(function()
        if activeSmallNotif then
            disableNotifications()
        end
    end)

    -- Deteksi GUI baru
    player.PlayerGui.ChildAdded:Connect(function(child)
        if activeSmallNotif and child.Name == "Small Notification" then
            child:Destroy()
        end
    end)
end

function module.StopSmallNotification()
    activeSmallNotif = false
end

-- =========================
-- Start / Stop Skin Effect
-- =========================
function module.StartSkinEffect()
    if activeSkinEffect then return end
    activeSkinEffect = true

    -- Hapus efek yang sudah ada
    disableDiveEffects()

    -- Loop setiap frame
    RunService.Heartbeat:Connect(function()
        if activeSkinEffect then
            disableDiveEffects()
        end
    end)

    -- Pantau child baru di VFX
    VFXFolder.ChildAdded:Connect(function(child)
        if activeSkinEffect and child.Name:match("Dive$") then
            child:Destroy()
        end
    end)
end

function module.StopSkinEffect()
    activeSkinEffect = false
end

return module
end)()

modules["AutoTotem3X"] = (function()
-- AUTO TOTEM 3X (CLEAN VERSION - FOR GUI INTEGRATION)
local AutoTotem3X = {}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer
local Net = RS.Packages["_Index"]["sleitnick_net@0.2.0"].net
local RE_EquipToolFromHotbar = Net["RE/EquipToolFromHotbar"]

-- Settings
local HOTBAR_SLOT = 2
local CLICK_COUNT = 5
local CLICK_DELAY = 0.2
local TRIANGLE_RADIUS = 58
local CENTER_OFFSET = Vector3.new(0, 0, -7.25)

local isRunning = false

-- Teleport Function
local function tp(pos)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
        task.wait(0.5)
    end
end

-- Equip Totem
local function equipTotem()
    pcall(function()
        RE_EquipToolFromHotbar:FireServer(HOTBAR_SLOT)
    end)
    task.wait(1.5)
end

-- Auto Click
local function autoClick()
    for i = 1, CLICK_COUNT do
        pcall(function()
            VirtualUser:Button1Down(Vector2.new(0, 0))
            task.wait(0.05)
            VirtualUser:Button1Up(Vector2.new(0, 0))
        end)
        task.wait(CLICK_DELAY)
        
        local char = LP.Character
        if char then
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    pcall(function()
                        tool:Activate()
                    end)
                end
            end
        end
        task.wait(CLICK_DELAY)
    end
end

-- Main Function
function AutoTotem3X.Start()
    if isRunning then
        return false
    end
    
    isRunning = true
    
    task.spawn(function()
        local char = LP.Character or LP.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")
        
        local centerPos = root.Position
        local adjustedCenter = centerPos + CENTER_OFFSET
        
        -- Calculate 3 totem positions (Triangle pattern)
        local angles = {90, 210, 330}
        local totemPositions = {}
        
        for i, angleDeg in ipairs(angles) do
            local angleRad = math.rad(angleDeg)
            local offsetX = TRIANGLE_RADIUS * math.cos(angleRad)
            local offsetZ = TRIANGLE_RADIUS * math.sin(angleRad)
            table.insert(totemPositions, adjustedCenter + Vector3.new(offsetX, 0, offsetZ))
        end
        
        -- Place totems
        for i, pos in ipairs(totemPositions) do
            if not isRunning then break end
            
            tp(pos)
            equipTotem()
            autoClick()
            task.wait(2)
        end
        
        -- Return to start position
        tp(centerPos)
        task.wait(1)
        
        isRunning = false
    end)
    
    return true
end

function AutoTotem3X.Stop()
    isRunning = false
    return true
end

function AutoTotem3X.IsRunning()
    return isRunning
end

return AutoTotem3X
end)()

modules["WalkOnWater"] = (function()
-- ULTRA STABLE WALK ON WATER V3.2 (MODULE EDITION)
-- AUTO SURFACE LIFT
-- NO CHAT COMMAND
-- GUI / TOGGLE FRIENDLY
-- CLIENT SAFE | RAYCAST ONLY

repeat task.wait() until game:IsLoaded()

----------------------------------------------------------
-- SERVICES
----------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------
-- STATE
----------------------------------------------------------
local WalkOnWater = {
	Enabled = false,
	Platform = nil,
	AlignPos = nil,
	Connection = nil
}

local PLATFORM_SIZE = 14
local OFFSET = 3
local LAST_WATER_Y = nil

----------------------------------------------------------
-- CHARACTER
----------------------------------------------------------
local function GetCharacterReferences()
	local char = LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	return char, humanoid, hrp
end

----------------------------------------------------------
-- FORCE SURFACE LIFT (ANTI STUCK)
----------------------------------------------------------
local function ForceSurfaceLift()
	local _, humanoid, hrp = GetCharacterReferences()
	if not humanoid or not hrp then return end

	if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
		return
	end

	for _ = 1, 60 do
		hrp.Velocity = Vector3.new(0, 80, 0)
		task.wait(0.03)

		if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
			break
		end
	end

	hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
end

----------------------------------------------------------
-- WATER DETECTION (RAYCAST ONLY)
----------------------------------------------------------
local function GetWaterHeight()
	local _, _, hrp = GetCharacterReferences()
	if not hrp then return LAST_WATER_Y end

	local origin = hrp.Position + Vector3.new(0, 5, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { LocalPlayer.Character }
	params.IgnoreWater = false

	local result = Workspace:Raycast(
		origin,
		Vector3.new(0, -600, 0),
		params
	)

	if result then
		LAST_WATER_Y = result.Position.Y
		return LAST_WATER_Y
	end

	return LAST_WATER_Y
end

----------------------------------------------------------
-- PLATFORM
----------------------------------------------------------
local function CreatePlatform()
	if WalkOnWater.Platform then
		WalkOnWater.Platform:Destroy()
	end

	local p = Instance.new("Part")
	p.Size = Vector3.new(PLATFORM_SIZE, 1, PLATFORM_SIZE)
	p.Anchored = true
	p.CanCollide = true
	p.Transparency = 1
	p.CanQuery = false
	p.CanTouch = false
	p.Name = "WaterLockPlatform"
	p.Parent = Workspace

	WalkOnWater.Platform = p
end

----------------------------------------------------------
-- ALIGN POSITION
----------------------------------------------------------
local function SetupAlign()
	local _, _, hrp = GetCharacterReferences()
	if not hrp then return false end

	if WalkOnWater.AlignPos then
		WalkOnWater.AlignPos:Destroy()
	end

	local att = hrp:FindFirstChild("RootAttachment")
	if not att then
		att = Instance.new("Attachment")
		att.Name = "RootAttachment"
		att.Parent = hrp
	end

	local ap = Instance.new("AlignPosition")
	ap.Attachment0 = att
	ap.MaxForce = math.huge
	ap.MaxVelocity = math.huge
	ap.Responsiveness = 200
	ap.RigidityEnabled = true
	ap.Parent = hrp

	WalkOnWater.AlignPos = ap
	return true
end

----------------------------------------------------------
-- CLEANUP
----------------------------------------------------------
local function Cleanup()
	if WalkOnWater.Connection then
		WalkOnWater.Connection:Disconnect()
		WalkOnWater.Connection = nil
	end

	if WalkOnWater.AlignPos then
		WalkOnWater.AlignPos:Destroy()
		WalkOnWater.AlignPos = nil
	end

	if WalkOnWater.Platform then
		WalkOnWater.Platform:Destroy()
		WalkOnWater.Platform = nil
	end
end

----------------------------------------------------------
-- START
----------------------------------------------------------
function WalkOnWater.Start()
	if WalkOnWater.Enabled then return end

	local char, humanoid, hrp = GetCharacterReferences()
	if not char or not humanoid or not hrp then return end

	ForceSurfaceLift()

	WalkOnWater.Enabled = true
	LAST_WATER_Y = nil

	CreatePlatform()
	if not SetupAlign() then
		WalkOnWater.Enabled = false
		Cleanup()
		return
	end

	WalkOnWater.Connection = RunService.Heartbeat:Connect(function()
		if not WalkOnWater.Enabled then return end

		local _, _, currentHRP = GetCharacterReferences()
		if not currentHRP then return end

		local waterY = GetWaterHeight()
		if not waterY then return end

		if WalkOnWater.Platform then
			WalkOnWater.Platform.CFrame = CFrame.new(
				currentHRP.Position.X,
				waterY - 0.5,
				currentHRP.Position.Z
			)
		end

		if WalkOnWater.AlignPos then
			WalkOnWater.AlignPos.Position = Vector3.new(
				currentHRP.Position.X,
				waterY + OFFSET,
				currentHRP.Position.Z
			)
		end
	end)
end

----------------------------------------------------------
-- STOP
----------------------------------------------------------
function WalkOnWater.Stop()
	WalkOnWater.Enabled = false
	Cleanup()
end

----------------------------------------------------------
-- RESPAWN SAFE
----------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
	if WalkOnWater.Enabled then
		task.wait(0.5)
		Cleanup()
		WalkOnWater.Enabled = false
		WalkOnWater.Start()
	end
end)

----------------------------------------------------------
return WalkOnWater
end)()

modules["UltraBlatant"] = (function()
-- ⚠️ ULTRA BLATANT AUTO FISHING - GUI COMPATIBLE MODULE
-- DESIGNED TO WORK WITH EXTERNAL GUI SYSTEM
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Network initialization
local netFolder = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = netFolder:WaitForChild("RF/UpdateAutoFishingState")  -- ⭐ ADDED untuk stop function
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")

-- Module table
local UltraBlatant = {}
UltraBlatant.Active = false
UltraBlatant.Stats = {
    castCount = 0,
    startTime = 0
}

-- Settings (sesuai dengan pattern GUI kamu)
UltraBlatant.Settings = {
    CompleteDelay = 0.001,    -- Delay sebelum complete
    CancelDelay = 0.001       -- Delay setelah complete sebelum cancel
}

----------------------------------------------------------------
-- CORE FUNCTIONS
----------------------------------------------------------------

local function safeFire(func)
    task.spawn(function()
        pcall(func)
    end)
end

-- MAIN SPAM LOOP
local function ultraSpamLoop()
    while UltraBlatant.Active do
        local currentTime = tick()
        
        -- 1x CHARGE & REQUEST (CASTING)
        safeFire(function()
            RF_ChargeFishingRod:InvokeServer({[1] = currentTime})
        end)
        safeFire(function()
            RF_RequestMinigame:InvokeServer(1, 0, currentTime)
        end)
        
        UltraBlatant.Stats.castCount = UltraBlatant.Stats.castCount + 1
        
        -- Wait CompleteDelay then fire complete once
        task.wait(UltraBlatant.Settings.CompleteDelay)
        
        safeFire(function()
            RE_FishingCompleted:FireServer()
        end)
        
        -- Cancel with CancelDelay
        task.wait(UltraBlatant.Settings.CancelDelay)
        safeFire(function()
            RF_CancelFishingInputs:InvokeServer()
        end)
    end
end

-- BACKUP LISTENER
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not UltraBlatant.Active then return end
    
    task.spawn(function()
        task.wait(UltraBlatant.Settings.CompleteDelay)
        
        safeFire(function()
            RE_FishingCompleted:FireServer()
        end)
        
        task.wait(UltraBlatant.Settings.CancelDelay)
        safeFire(function()
            RF_CancelFishingInputs:InvokeServer()
        end)
    end)
end)

----------------------------------------------------------------
-- PUBLIC API (Compatible dengan pattern GUI kamu)
----------------------------------------------------------------

-- ⭐ NEW: Update Settings function
function UltraBlatant.UpdateSettings(completeDelay, cancelDelay)
    if completeDelay ~= nil then
        UltraBlatant.Settings.CompleteDelay = completeDelay
        print("✅ UltraBlatant CompleteDelay updated:", completeDelay)
    end
    
    if cancelDelay ~= nil then
        UltraBlatant.Settings.CancelDelay = cancelDelay
        print("✅ UltraBlatant CancelDelay updated:", cancelDelay)
    end
end

-- Start function
function UltraBlatant.Start()
    if UltraBlatant.Active then 
        print("⚠️ Ultra Blatant already running!")
        return
    end
    
    UltraBlatant.Active = true
    UltraBlatant.Stats.castCount = 0
    UltraBlatant.Stats.startTime = tick()
    
    task.spawn(ultraSpamLoop)
end

-- ⭐ ENHANCED Stop function - Nyalakan auto fishing game
function UltraBlatant.Stop()
    if not UltraBlatant.Active then 
        return
    end
    
    UltraBlatant.Active = false
    
    -- ⭐ Nyalakan auto fishing game (biarkan tetap nyala)
    safeFire(function()
        RF_UpdateAutoFishingState:InvokeServer(true)
    end)
    
    -- Wait sebentar untuk game process
    task.wait(0.2)
    
    -- Cancel fishing inputs untuk memastikan karakter berhenti
    safeFire(function()
        RF_CancelFishingInputs:InvokeServer()
    end)
    
    print("✅ Ultra Blatant stopped - Game auto fishing enabled, can change rod/skin")
end

-- Return module
return UltraBlatant
end)()

-- Placeholder modules - Add actual code from Project_code folder
modules["blatantv2fix"] = (function() return {Settings = {CompleteDelay = 0.5, CancelDelay = 0.1}} end)()
modules["SkinAnimation"] = (function()
--====================================================--
-- ⚡ SKIN ANIMATION REPLACER MODULE
-- Optimized for GUI integration
--====================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

local Animator = humanoid:FindFirstChildOfClass("Animator")
if not Animator then
    Animator = Instance.new("Animator", humanoid)
end

--====================================================--
-- 📦 MODULE
--====================================================--

local SkinAnimation = {}

--====================================================--
-- 🎨 SKIN DATABASE
--====================================================--

local SkinDatabase = {
    ["Eclipse"] = "rbxassetid://107940819382815",
    ["HolyTrident"] = "rbxassetid://128167068291703",
    ["SoulScythe"] = "rbxassetid://82259219343456",
    ["OceanicHarpoon"] = "rbxassetid://76325124055693",
    ["BinaryEdge"] = "rbxassetid://109653945741202",
    ["Vanquisher"] = "rbxassetid://93884986836266",
    ["KrampusScythe"] = "rbxassetid://134934781977605",
    ["BanHammer"] = "rbxassetid://96285280763544",
    ["CorruptionEdge"] = "rbxassetid://126613975718573",
    ["PrincessParasol"] = "rbxassetid://99143072029495"
}

--====================================================--
-- 🎬 CORE VARIABLES
--====================================================--

local CurrentSkin = nil
local AnimationPool = {}
local IsEnabled = false
local POOL_SIZE = 3

local killedTracks = {}
local replaceCount = 0
local currentPoolIndex = 1

--====================================================--
-- 🔄 LOAD ANIMATION POOL
--====================================================--

local function LoadAnimationPool(skinId)
    local animId = SkinDatabase[skinId]
    if not animId then
        return false
    end
    
    -- Clear old pool
    for _, track in ipairs(AnimationPool) do
        pcall(function()
            track:Stop(0)
            track:Destroy()
        end)
    end
    AnimationPool = {}
    
    -- Create animation
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    anim.Name = "CUSTOM_SKIN_ANIM"
    
    -- Load pool of tracks
    for i = 1, POOL_SIZE do
        local track = Animator:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = false
        track.Name = "SKIN_POOL_" .. i
        
        -- Pre-cache
        task.spawn(function()
            pcall(function()
                track:Play(0, 1, 0)
                task.wait(0.05)
                track:Stop(0)
            end)
        end)
        
        table.insert(AnimationPool, track)
    end
    
    currentPoolIndex = 1
    return true
end

--====================================================--
-- 🎯 GET NEXT TRACK
--====================================================--

local function GetNextTrack()
    for i = 1, POOL_SIZE do
        local track = AnimationPool[i]
        if track and not track.IsPlaying then
            return track
        end
    end
    
    currentPoolIndex = currentPoolIndex % POOL_SIZE + 1
    return AnimationPool[currentPoolIndex]
end

--====================================================--
-- 🛡️ DETECTION
--====================================================--

local function IsFishCaughtAnimation(track)
    if not track or not track.Animation then return false end
    
    local trackName = string.lower(track.Name or "")
    local animName = string.lower(track.Animation.Name or "")
    
    if string.find(trackName, "fishcaught") or 
       string.find(animName, "fishcaught") or
       string.find(trackName, "caught") or 
       string.find(animName, "caught") then
        return true
    end
    
    return false
end

--====================================================--
-- ⚡ INSTANT REPLACE
--====================================================--

local function InstantReplace(originalTrack)
    local nextTrack = GetNextTrack()
    if not nextTrack then return end
    
    replaceCount = replaceCount + 1
    killedTracks[originalTrack] = tick()
    
    -- Kill original
    task.spawn(function()
        for i = 1, 10 do
            pcall(function()
                if originalTrack.IsPlaying then
                    originalTrack:Stop(0)
                    originalTrack:AdjustSpeed(0)
                    originalTrack.TimePosition = 0
                end
            end)
            task.wait()
        end
    end)
    
    -- Play custom
    pcall(function()
        if nextTrack.IsPlaying then
            nextTrack:Stop(0)
        end
        nextTrack:Play(0, 1, 1)
        nextTrack:AdjustSpeed(1)
    end)
    
    -- Cleanup
    task.delay(1, function()
        killedTracks[originalTrack] = nil
    end)
end

--====================================================--
-- 🔥 MONITORING LOOPS
--====================================================--

-- AnimationPlayed Hook
humanoid.AnimationPlayed:Connect(function(track)
    if not IsEnabled then return end
    
    if IsFishCaughtAnimation(track) then
        task.spawn(function()
            InstantReplace(track)
        end)
    end
end)

-- RenderStepped Monitor
RunService.RenderStepped:Connect(function()
    if not IsEnabled then return end
    
    local tracks = humanoid:GetPlayingAnimationTracks()
    
    for _, track in ipairs(tracks) do
        if string.find(string.lower(track.Name or ""), "skin_pool") then
            continue
        end
        
        if killedTracks[track] then
            if track.IsPlaying then
                pcall(function()
                    track:Stop(0)
                    track:AdjustSpeed(0)
                end)
            end
            continue
        end
        
        if track.IsPlaying and IsFishCaughtAnimation(track) then
            task.spawn(function()
                InstantReplace(track)
            end)
        end
    end
end)

-- Heartbeat Backup
RunService.Heartbeat:Connect(function()
    if not IsEnabled then return end
    
    local tracks = humanoid:GetPlayingAnimationTracks()
    
    for _, track in ipairs(tracks) do
        if string.find(string.lower(track.Name or ""), "skin_pool") then
            continue
        end
        
        if killedTracks[track] and track.IsPlaying then
            pcall(function()
                track:Stop(0)
                track:AdjustSpeed(0)
            end)
        end
    end
end)

-- Stepped Ultra Aggressive
RunService.Stepped:Connect(function()
    if not IsEnabled then return end
    
    for track, _ in pairs(killedTracks) do
        if track and track.IsPlaying then
            pcall(function()
                track:Stop(0)
                track:AdjustSpeed(0)
            end)
        end
    end
end)

--====================================================--
-- 🔄 RESPAWN HANDLER
--====================================================--

player.CharacterAdded:Connect(function(newChar)
    task.wait(1.5)
    
    char = newChar
    humanoid = char:WaitForChild("Humanoid")
    Animator = humanoid:FindFirstChildOfClass("Animator")
    if not Animator then
        Animator = Instance.new("Animator", humanoid)
    end
    
    killedTracks = {}
    replaceCount = 0
    
    if IsEnabled and CurrentSkin then
        task.wait(0.5)
        LoadAnimationPool(CurrentSkin)
    end
end)

--====================================================--
-- 📡 PUBLIC API
--====================================================--

function SkinAnimation.SwitchSkin(skinId)
    if not SkinDatabase[skinId] then
        return false
    end
    
    CurrentSkin = skinId
    
    if IsEnabled then
        return LoadAnimationPool(skinId)
    end
    
    return true
end

function SkinAnimation.Enable()
    if IsEnabled then
        return false
    end
    
    if not CurrentSkin then
        return false
    end
    
    local success = LoadAnimationPool(CurrentSkin)
    if success then
        IsEnabled = true
        killedTracks = {}
        replaceCount = 0
        return true
    end
    
    return false
end

function SkinAnimation.Disable()
    if not IsEnabled then
        return false
    end
    
    IsEnabled = false
    killedTracks = {}
    replaceCount = 0
    
    for _, track in ipairs(AnimationPool) do
        pcall(function()
            track:Stop(0)
        end)
    end
    
    return true
end

function SkinAnimation.IsEnabled()
    return IsEnabled
end

function SkinAnimation.GetCurrentSkin()
    return CurrentSkin
end

function SkinAnimation.GetReplaceCount()
    return replaceCount
end

--====================================================--
-- 🚀 RETURN MODULE
--====================================================--

return SkinAnimation
end)()
modules["FreecamModule"] = (function()
-- ============================================
-- FREECAM MODULE - UNIVERSAL PC & MOBILE
-- ============================================
-- File: FreecamModule.lua

local FreecamModule = {}

-- Services
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Variables
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = Player:WaitForChild("PlayerGui")

local freecam = false
local camPos = Vector3.new()
local camRot = Vector3.new()
local speed = 50
local sensitivity = 0.3
local hiddenGuis = {}

-- Mobile detection
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- Mobile joystick variables
local mobileJoystickInput = Vector3.new(0, 0, 0)
local joystickConnections = {}
local dynamicThumbstick = nil
local thumbstickCenter = Vector2.new(0, 0)
local thumbstickRadius = 60

-- Touch input for camera rotation
local cameraTouch = nil
local cameraTouchStartPos = nil
local joystickTouch = nil

-- Connections
local renderConnection = nil
local inputChangedConnection = nil
local inputEndedConnection = nil
local inputBeganConnection = nil

-- Character references
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
end)

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function LockCharacter(state)
    if not Humanoid then return end
    
    if state then
        Humanoid.WalkSpeed = 0
        Humanoid.JumpPower = 0
        Humanoid.AutoRotate = false
        if Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.Anchored = true
        end
    else
        Humanoid.WalkSpeed = 16
        Humanoid.JumpPower = 50
        Humanoid.AutoRotate = true
        if Character:FindFirstChild("HumanoidRootPart") then
            Character.HumanoidRootPart.Anchored = false
        end
    end
end

local function HideAllGuis()
    hiddenGuis = {}
    
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            if mainGuiName and gui.Name == mainGuiName then
                continue
            end
            
            local guiName = gui.Name:lower()
            if guiName:find("main") or guiName:find("hub") or guiName:find("menu") or guiName:find("ui") then
                continue
            end
            
            table.insert(hiddenGuis, gui)
            gui.Enabled = false
        end
    end
end

local function ShowAllGuis()
    for _, gui in pairs(hiddenGuis) do
        if gui and gui:IsA("ScreenGui") then
            gui.Enabled = true
        end
    end
    
    hiddenGuis = {}
end

local function GetMovement()
    local move = Vector3.zero
    
    if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, 1) end
    if UIS:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, -1) end
    if UIS:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then 
        move = move + Vector3.new(0, 1, 0) 
    end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.Q) then 
        move = move + Vector3.new(0, -1, 0) 
    end
    
    if isMobile then
        move = move + mobileJoystickInput
    end
    
    return move
end

-- ============================================
-- MOBILE JOYSTICK DETECTION
-- ============================================

local function DetectDynamicThumbstick()
    if not isMobile then return end
    
    local function searchForThumbstick(parent, depth)
        depth = depth or 0
        if depth > 10 then return end
        
        for _, child in pairs(parent:GetChildren()) do
            local name = child.Name:lower()
            if name:find("thumbstick") or name:find("joystick") then
                if child:IsA("Frame") then
                    return child
                end
            end
            local result = searchForThumbstick(child, depth + 1)
            if result then return result end
        end
        return nil
    end
    
    pcall(function()
        dynamicThumbstick = searchForThumbstick(PlayerGui)
        
        if dynamicThumbstick then
            print("✅ DynamicThumbstick terdeteksi: " .. dynamicThumbstick.Name)
            
            -- Hitung center dan radius thumbstick
            local pos = dynamicThumbstick.AbsolutePosition
            local size = dynamicThumbstick.AbsoluteSize
            thumbstickCenter = pos + (size / 2)
            thumbstickRadius = math.min(size.X, size.Y) / 2
            
            print("📍 Thumbstick Center: " .. tostring(thumbstickCenter))
            print("📏 Thumbstick Radius: " .. thumbstickRadius)
        end
    end)
end

local function IsPositionInThumbstick(pos)
    if not dynamicThumbstick then return false end
    
    -- Fallback: check absolute position dari thumbstick frame
    local thumbPos = dynamicThumbstick.AbsolutePosition
    local thumbSize = dynamicThumbstick.AbsoluteSize
    
    -- Check apakah pos berada dalam bounding box thumbstick
    local isWithinX = pos.X >= thumbPos.X - 50 and pos.X <= (thumbPos.X + thumbSize.X + 50)
    local isWithinY = pos.Y >= thumbPos.Y - 50 and pos.Y <= (thumbPos.Y + thumbSize.Y + 50)
    
    return isWithinX and isWithinY
end

local function GetJoystickInput(touchPos)
    if not dynamicThumbstick then return Vector3.new(0, 0, 0) end
    
    -- Convert to Vector2
    local touchPos2D = Vector2.new(touchPos.X, touchPos.Y)
    local delta = touchPos2D - thumbstickCenter
    local magnitude = delta.Magnitude
    
    if magnitude < 5 then
        return Vector3.new(0, 0, 0)
    end
    
    -- Normalize joystick input
    local maxDist = thumbstickRadius
    local normalized = delta / maxDist
    
    -- Clamp nilai
    normalized = Vector2.new(
        math.max(-1, math.min(1, normalized.X)),
        math.max(-1, math.min(1, normalized.Y))
    )
    
    -- Convert to movement direction (X = strafe, Z = forward)
    return Vector3.new(normalized.X, 0, normalized.Y)
end

-- ============================================
-- MAIN FREECAM FUNCTIONS
-- ============================================

function FreecamModule.Start()
    if freecam then return end
    
    freecam = true
    
    local currentCF = Camera.CFrame
    camPos = currentCF.Position
    local x, y, z = currentCF:ToEulerAnglesYXZ()
    camRot = Vector3.new(x, y, z)
    
    LockCharacter(true)
    HideAllGuis()
    Camera.CameraType = Enum.CameraType.Scriptable
    
    task.wait()
    
    if not isMobile then
        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
        UIS.MouseIconEnabled = false
    else
        DetectDynamicThumbstick()
    end
    
    -- Mobile input handling
    if isMobile then
        inputBeganConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
            if not freecam then return end
            
            if input.UserInputType == Enum.UserInputType.Touch then
                local pos = input.Position
                
                -- Gunakan pcall untuk avoid error dari script game lain
                local isInThumbstick = false
                pcall(function()
                    isInThumbstick = IsPositionInThumbstick(pos)
                end)
                
                if isInThumbstick then
                    joystickTouch = input
                else
                    -- Camera touch di area lain
                    cameraTouch = input
                    cameraTouchStartPos = input.Position
                end
            end
        end)
        
        inputChangedConnection = UIS.InputChanged:Connect(function(input, gameProcessed)
            if not freecam then return end
            
            if input.UserInputType == Enum.UserInputType.Touch then
                -- Handle joystick touch
                if input == joystickTouch then
                    pcall(function()
                        mobileJoystickInput = GetJoystickInput(input.Position)
                    end)
                end
                
                -- Handle camera touch
                if input == cameraTouch and cameraTouch then
                    local delta = input.Position - cameraTouchStartPos
                    
                    if delta.Magnitude > 0 then
                        camRot = camRot + Vector3.new(
                            -delta.Y * sensitivity * 0.003,
                            -delta.X * sensitivity * 0.003,
                            0
                        )
                        
                        cameraTouchStartPos = input.Position
                    end
                end
            end
        end)
        
        inputEndedConnection = UIS.InputEnded:Connect(function(input, gameProcessed)
            if not freecam then return end
            
            if input.UserInputType == Enum.UserInputType.Touch then
                if input == joystickTouch then
                    joystickTouch = nil
                    mobileJoystickInput = Vector3.new(0, 0, 0)
                end
                
                if input == cameraTouch then
                    cameraTouch = nil
                    cameraTouchStartPos = nil
                end
            end
        end)
    end
    
    renderConnection = RunService.RenderStepped:Connect(function(dt)
        if not freecam then return end
        
        if not isMobile then
            local mouseDelta = UIS:GetMouseDelta()
            
            if mouseDelta.Magnitude > 0 then
                camRot = camRot + Vector3.new(
                    -mouseDelta.Y * sensitivity * 0.01,
                    -mouseDelta.X * sensitivity * 0.01,
                    0
                )
            end
        end
        
        local rotationCF = CFrame.fromEulerAnglesYXZ(camRot.X, camRot.Y, camRot.Z)
        
        local moveInput = GetMovement()
        if moveInput.Magnitude > 0 then
            moveInput = moveInput.Unit
            
            local moveCF = CFrame.new(camPos) * rotationCF
            local velocity = (moveCF.LookVector * moveInput.Z) +
                             (moveCF.RightVector * moveInput.X) +
                             (moveCF.UpVector * moveInput.Y)
            
            camPos = camPos + velocity * speed * dt
        end
        
        Camera.CFrame = CFrame.new(camPos) * rotationCF
    end)
    
    return true
end

function FreecamModule.Stop()
    if not freecam then return end
    
    freecam = false
    
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    
    if inputChangedConnection then
        inputChangedConnection:Disconnect()
        inputChangedConnection = nil
    end
    
    if inputEndedConnection then
        inputEndedConnection:Disconnect()
        inputEndedConnection = nil
    end
    
    if inputBeganConnection then
        inputBeganConnection:Disconnect()
        inputBeganConnection = nil
    end
    
    for _, conn in pairs(joystickConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    joystickConnections = {}
    
    LockCharacter(false)
    ShowAllGuis()
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = Humanoid
    
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    UIS.MouseIconEnabled = true
    
    cameraTouch = nil
    cameraTouchStartPos = nil
    joystickTouch = nil
    mobileJoystickInput = Vector3.new(0, 0, 0)
    
    return true
end

function FreecamModule.Toggle()
    if freecam then
        return FreecamModule.Stop()
    else
        return FreecamModule.Start()
    end
end

function FreecamModule.IsActive()
    return freecam
end

function FreecamModule.SetSpeed(newSpeed)
    speed = math.max(1, newSpeed)
end

function FreecamModule.SetSensitivity(newSensitivity)
    sensitivity = math.max(0.01, math.min(5, newSensitivity))
end

function FreecamModule.GetSpeed()
    return speed
end

function FreecamModule.GetSensitivity()
    return sensitivity
end

-- ============================================
-- SET MAIN GUI NAME
-- ============================================
local mainGuiName = nil

function FreecamModule.SetMainGuiName(guiName)
    mainGuiName = guiName
    print("✅ Main GUI set to: " .. guiName)
end

function FreecamModule.GetMainGuiName()
    return mainGuiName
end

-- ============================================
-- F3 KEYBIND - PC ONLY (MASTER SWITCH LOGIC)
-- ============================================
local f3KeybindActive = false

function FreecamModule.EnableF3Keybind(enable)
    f3KeybindActive = enable
    
    -- Jika toggle GUI dimatikan, matikan freecam juga
    if not enable and freecam then
        FreecamModule.Stop()
        print("🔴 Freecam disabled (Toggle GUI OFF)")
    end
    
    if not isMobile then
        local status = f3KeybindActive and "ENABLED (Press F3 to activate)" or "DISABLED"
        print("⚙️ F3 Keybind: " .. status)
    end
end

function FreecamModule.IsF3KeybindActive()
    return f3KeybindActive
end

-- F3 Input Handler (PC Only)
if not isMobile then
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Cek apakah F3 ditekan DAN toggle GUI aktif
        if input.KeyCode == Enum.KeyCode.F3 and f3KeybindActive then
            FreecamModule.Toggle()
            
            if freecam then
                print("🎥 Freecam ACTIVATED via F3")
            else
                print("🔴 Freecam DEACTIVATED via F3")
            end
        end
    end)
end


return FreecamModule
end)()
modules["UnlimitedZoomModule"] = (function()
-- ============================================
-- UNLIMITED ZOOM CAMERA MODULE
-- ============================================
-- Character can walk normally, camera can zoom unlimited

local UnlimitedZoomModule = {}

-- Services
local Players = game:GetService("Players")

-- Variables
local Player = Players.LocalPlayer

-- Save original zoom settings
local originalMinZoom = Player.CameraMinZoomDistance
local originalMaxZoom = Player.CameraMaxZoomDistance

-- State
local unlimitedZoomActive = false

-- ============================================
-- MAIN FUNCTIONS
-- ============================================

function UnlimitedZoomModule.Enable()
    if unlimitedZoomActive then return false end
    
    unlimitedZoomActive = true
    
    -- Remove zoom limits (character can still move)
    Player.CameraMinZoomDistance = 0.5
    Player.CameraMaxZoomDistance = 9999
    
    print("✅ Unlimited Zoom: ENABLED")
    print("📷 Scroll to zoom in/out without limits")
    print("🏃 Character can move normally")
    
    return true
end

function UnlimitedZoomModule.Disable()
    if not unlimitedZoomActive then return false end
    
    unlimitedZoomActive = false
    
    -- Restore original zoom limits
    Player.CameraMinZoomDistance = originalMinZoom
    Player.CameraMaxZoomDistance = originalMaxZoom
    
    print("🔴 Unlimited Zoom: DISABLED")
    print("📷 Zoom limits restored")
    
    return true
end

function UnlimitedZoomModule.IsActive()
    return unlimitedZoomActive
end


return UnlimitedZoomModule
end)()
modules["TeleportToPlayer"] = (function()
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local TeleportToPlayer = {}

function TeleportToPlayer.TeleportTo(playerName)
    local target = Players:FindFirstChild(playerName)
    local myChar = localPlayer.Character
    if not target or not target.Character then return end

    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if targetHRP and myHRP then
        myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        print("[Teleport] 🚀 Teleported to player: " .. playerName)
    else
        warn("[Teleport] ❌ Gagal teleport, HRP tidak ditemukan.")
    end
end

return TeleportToPlayer
end)()
modules["AutoSellSystem"] = (function()
-- AutoSellSystem.lua
-- COMBINED: Sell All, Auto Sell Timer, Auto Sell By Count
-- Clean module version - no GUI, no logs

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ===== FIND SELL REMOTE =====
local function findSellRemote()
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	if not packages then return nil end
	
	local index = packages:FindFirstChild("_Index")
	if not index then return nil end
	
	local sleitnick = index:FindFirstChild("sleitnick_net@0.2.0")
	if not sleitnick then return nil end
	
	local net = sleitnick:FindFirstChild("net")
	if not net then return nil end
	
	local sellRemote = net:FindFirstChild("RF/SellAllItems")
	if sellRemote then return sellRemote end
	
	local rf = net:FindFirstChild("RF")
	if rf then
		sellRemote = rf:FindFirstChild("SellAllItems")
		if sellRemote then return sellRemote end
	end
	
	for _, child in ipairs(net:GetDescendants()) do
		if child.Name == "SellAllItems" or child.Name == "RF/SellAllItems" then
			return child
		end
	end
	
	return nil
end

local SellRemote = findSellRemote()

-- ===== BAG PARSER (for Auto Sell By Count) =====
local function parseNumber(text)
	if not text or text == "" then return 0 end
	local cleaned = tostring(text):gsub("%D", "")
	if cleaned == "" then return 0 end
	return tonumber(cleaned) or 0
end

local function getBagCount()
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then return 0, 0 end

	local inv = gui:FindFirstChild("Inventory")
	if not inv then return 0, 0 end

	local label = inv:FindFirstChild("Main")
		and inv.Main:FindFirstChild("Top")
		and inv.Main.Top.Options:FindFirstChild("Fish")
		and inv.Main.Top.Options.Fish:FindFirstChild("Label")
		and inv.Main.Top.Options.Fish.Label:FindFirstChild("BagSize")

	if not label or not label:IsA("TextLabel") then return 0, 0 end

	local curText, maxText = label.Text:match("(.+)%/(.+)")
	if not curText or not maxText then return 0, 0 end

	return parseNumber(curText), parseNumber(maxText)
end

-- ===== MAIN MODULE =====
local AutoSellSystem = {
	Remote = SellRemote,
	
	-- Sell All Stats
	_totalSells = 0,
	_lastSellTime = 0,
	
	-- Timer Mode
	Timer = {
		Enabled = false,
		Interval = 5,
		Thread = nil,
		_sellCount = 0
	},
	
	-- Count Mode
	Count = {
		Enabled = false,
		Target = 235,
		CheckDelay = 1.5,
		_lastSell = 0,
		_thread = nil
	}
}

-- ===== CORE SELL FUNCTION =====
local function executeSell()
	if not SellRemote then return false end
	
	local success, result = pcall(function()
		return SellRemote:InvokeServer()
	end)
	
	if success then
		AutoSellSystem._totalSells = AutoSellSystem._totalSells + 1
		AutoSellSystem._lastSellTime = tick()
		return true
	end
	
	return false
end

-- ===== SELL ALL (MANUAL) =====
function AutoSellSystem.SellOnce()
	if not SellRemote then return false end
	if tick() - AutoSellSystem._lastSellTime < 0.5 then return false end
	return executeSell()
end

-- ===== TIMER MODE =====
function AutoSellSystem.Timer.Start(interval)
	if AutoSellSystem.Timer.Enabled then return false end
	if not SellRemote then return false end
	
	if interval and tonumber(interval) and tonumber(interval) >= 1 then
		AutoSellSystem.Timer.Interval = tonumber(interval)
	end
	
	AutoSellSystem.Timer.Enabled = true
	AutoSellSystem.Timer._sellCount = 0
	
	AutoSellSystem.Timer.Thread = task.spawn(function()
		while AutoSellSystem.Timer.Enabled do
			task.wait(AutoSellSystem.Timer.Interval)
			
			if not AutoSellSystem.Timer.Enabled then break end
			
			if executeSell() then
				AutoSellSystem.Timer._sellCount = AutoSellSystem.Timer._sellCount + 1
			end
		end
	end)
	
	return true
end

function AutoSellSystem.Timer.Stop()
	if not AutoSellSystem.Timer.Enabled then return false end
	AutoSellSystem.Timer.Enabled = false
	return true
end

function AutoSellSystem.Timer.SetInterval(seconds)
	if tonumber(seconds) and seconds >= 1 then
		AutoSellSystem.Timer.Interval = tonumber(seconds)
		return true
	end
	return false
end

function AutoSellSystem.Timer.GetStatus()
	return {
		enabled = AutoSellSystem.Timer.Enabled,
		interval = AutoSellSystem.Timer.Interval,
		sellCount = AutoSellSystem.Timer._sellCount
	}
end

-- ===== COUNT MODE =====
function AutoSellSystem.Count.Start(target)
	if AutoSellSystem.Count.Enabled then return false end
	if not SellRemote then return false end
	
	if target and tonumber(target) and tonumber(target) > 0 then
		AutoSellSystem.Count.Target = tonumber(target)
	end
	
	AutoSellSystem.Count.Enabled = true
	
	AutoSellSystem.Count._thread = task.spawn(function()
		while AutoSellSystem.Count.Enabled do
			task.wait(AutoSellSystem.Count.CheckDelay)
			
			if not AutoSellSystem.Count.Enabled then break end
			
			local current, max = getBagCount()
			
			if AutoSellSystem.Count.Target > 0 and current >= AutoSellSystem.Count.Target then
				if tick() - AutoSellSystem.Count._lastSell < 3 then
					continue
				end
				
				AutoSellSystem.Count._lastSell = tick()
				executeSell()
				task.wait(2)
			end
		end
	end)
	
	return true
end

function AutoSellSystem.Count.Stop()
	if not AutoSellSystem.Count.Enabled then return false end
	AutoSellSystem.Count.Enabled = false
	return true
end

function AutoSellSystem.Count.SetTarget(count)
	if tonumber(count) and tonumber(count) > 0 then
		AutoSellSystem.Count.Target = tonumber(count)
		return true
	end
	return false
end

function AutoSellSystem.Count.GetStatus()
	local cur, max = getBagCount()
	return {
		enabled = AutoSellSystem.Count.Enabled,
		target = AutoSellSystem.Count.Target,
		current = cur,
		max = max
	}
end

-- ===== UTILITY =====
function AutoSellSystem.GetStats()
	return {
		totalSells = AutoSellSystem._totalSells,
		lastSellTime = AutoSellSystem._lastSellTime,
		remoteFound = SellRemote ~= nil,
		timerStatus = AutoSellSystem.Timer.GetStatus(),
		countStatus = AutoSellSystem.Count.GetStatus()
	}
end

function AutoSellSystem.ResetStats()
	AutoSellSystem._totalSells = 0
	AutoSellSystem._lastSellTime = 0
	AutoSellSystem.Timer._sellCount = 0
end

_G.AutoSellSystem = AutoSellSystem
return AutoSellSystem
end)()
modules["AntiAFK"] = (function()
-- 💤 FungsiKeaby/Misc/AntiAFK.lua
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local AntiAFK = {
    Enabled = false,
    Connection = nil
}

function AntiAFK.Start()
    if AntiAFK.Enabled then return end
    AntiAFK.Enabled = true
    print("🟢 Anti-AFK diaktifkan")

    AntiAFK.Connection = localPlayer.Idled:Connect(function()
        if AntiAFK.Enabled then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            print("💤 [AntiAFK] Mencegah kick karena idle...")
        end
    end)
end

function AntiAFK.Stop()
    if not AntiAFK.Enabled then return end
    AntiAFK.Enabled = false
    print("🔴 Anti-AFK dimatikan")

    if AntiAFK.Connection then
        AntiAFK.Connection:Disconnect()
        AntiAFK.Connection = nil
    end
end

return AntiAFK
end)()
modules["UnlockFPS"] = (function()
-- ⚡ FungsiKeaby/Misc/UnlockFPS.lua
local UnlockFPS = {
    Enabled = false,
    CurrentCap = 60,
}

-- daftar pilihan FPS yang bisa dipilih dari dropdown GUI
UnlockFPS.AvailableCaps = {60, 90, 120, 240}

function UnlockFPS.SetCap(fps)
    if setfpscap then
        setfpscap(fps)
        UnlockFPS.CurrentCap = fps
        print(string.format("🎯 [UnlockFPS] FPS cap diatur ke %d", fps))
    else
        warn("⚠️ setfpscap() tidak tersedia di executor kamu.")
    end
end

function UnlockFPS.Start()
    if UnlockFPS.Enabled then return end
    UnlockFPS.Enabled = true
    UnlockFPS.SetCap(UnlockFPS.CurrentCap)
    print(string.format("⚡ [UnlockFPS] Aktif (cap: %d)", UnlockFPS.CurrentCap))
end

function UnlockFPS.Stop()
    if not UnlockFPS.Enabled then return end
    UnlockFPS.Enabled = false
    if setfpscap then
        setfpscap(60)
        print("🛑 [UnlockFPS] Dinonaktifkan (kembali ke 60fps)")
    end
end

return UnlockFPS
end)()
modules["FPSBooster"] = (function()
-- ==============================================================
--                ⭐ FPS BOOSTER MODULE (OPTIMIZED) ⭐
--                    Ready untuk GUI Integration
-- ==============================================================

local FPSBooster = {}
FPSBooster.Enabled = false

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

-- Storage untuk restore
local originalStates = {
    reflectance = {},
    transparency = {},
    lighting = {},
    effects = {},
    waterProperties = {}
}

-- Connection untuk new objects
local newObjectConnection = nil

-- Fungsi untuk optimize single object
local function optimizeObject(obj)
    if not FPSBooster.Enabled then return end
    
    pcall(function()
        -- Optimize BasePart (Bangunan, model, dll)
        if obj:IsA("BasePart") then
            -- Simpan original states (JANGAN UBAH WARNA & MATERIAL)
            if not originalStates.reflectance[obj] then
                originalStates.reflectance[obj] = obj.Reflectance
            end
            
            -- Hapus reflections & shadows saja
            obj.Reflectance = 0
            obj.CastShadow = false
        end
        
        -- Matikan Decals & Textures
        if obj:IsA("Decal") or obj:IsA("Texture") then
            if not originalStates.transparency[obj] then
                originalStates.transparency[obj] = obj.Transparency
            end
            obj.Transparency = 1 -- Invisible
        end
        
        -- Matikan SurfaceAppearance (texture PBR)
        if obj:IsA("SurfaceAppearance") then
            obj:Destroy()
        end
        
        -- Matikan ParticleEmitter (debu, asap, dll)
        if obj:IsA("ParticleEmitter") then
            obj.Enabled = false
        end
        
        -- Matikan Trail effects
        if obj:IsA("Trail") then
            obj.Enabled = false
        end
        
        -- Matikan Beam effects
        if obj:IsA("Beam") then
            obj.Enabled = false
        end
        
        -- Matikan Fire, Smoke, Sparkles
        if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end)
end

-- Fungsi untuk restore single object
local function restoreObject(obj)
    pcall(function()
        if obj:IsA("BasePart") then
            if originalStates.reflectance[obj] then
                obj.Reflectance = originalStates.reflectance[obj]
                obj.CastShadow = true
            end
        end
        
        if obj:IsA("Decal") or obj:IsA("Texture") then
            if originalStates.transparency[obj] then
                obj.Transparency = originalStates.transparency[obj]
            end
        end
        
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = true
        end
        
        if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = true
        end
    end)
end

-- ============================================
-- MAIN ENABLE FUNCTION
-- ============================================
function FPSBooster.Enable()
    if FPSBooster.Enabled then
        return false, "Already enabled"
    end
    
    FPSBooster.Enabled = true
    
    -----------------------------------------
    -- 1. Optimize semua existing objects
    -----------------------------------------
    for _, obj in ipairs(workspace:GetDescendants()) do
        optimizeObject(obj)
    end
    
    -----------------------------------------
    -- 2. MATIKAN ANIMASI AIR (Terrain Water)
    -----------------------------------------
    if Terrain then
        pcall(function()
            -- Simpan water properties
            originalStates.waterProperties = {
                WaterReflectance = Terrain.WaterReflectance,
                WaterWaveSize = Terrain.WaterWaveSize,
                WaterWaveSpeed = Terrain.WaterWaveSpeed
            }
            
            -- Matikan animasi air (WARNA TETAP DEFAULT)
            Terrain.WaterWaveSize = 0 -- NO WAVES
            Terrain.WaterWaveSpeed = 0 -- NO ANIMATION
            Terrain.WaterReflectance = 0 -- NO REFLECTION
        end)
    end
    
    -----------------------------------------
    -- 3. Optimize Lighting (Hapus Shadows & Fog)
    -----------------------------------------
    originalStates.lighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart
    }
    
    Lighting.GlobalShadows = false -- NO SHADOWS
    Lighting.FogStart = 0
    Lighting.FogEnd = 1000000 -- NO FOG
    
    -----------------------------------------
    -- 4. Matikan Post-Processing Effects
    -----------------------------------------
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            originalStates.effects[effect] = effect.Enabled
            effect.Enabled = false
        end
    end
    
    -----------------------------------------
    -- 5. Set Render Quality ke MINIMUM
    -----------------------------------------
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    
    -----------------------------------------
    -- 6. Hook new objects yang spawn
    -----------------------------------------
    newObjectConnection = workspace.DescendantAdded:Connect(function(obj)
        if FPSBooster.Enabled then
            task.wait(0.1) -- Delay kecil
            optimizeObject(obj)
        end
    end)
    
    return true, "FPS Booster enabled"
end

-- ============================================
-- MAIN DISABLE FUNCTION
-- ============================================
function FPSBooster.Disable()
    if not FPSBooster.Enabled then
        return false, "Already disabled"
    end
    
    FPSBooster.Enabled = false
    
    -----------------------------------------
    -- 1. Restore semua objects
    -----------------------------------------
    for _, obj in ipairs(workspace:GetDescendants()) do
        restoreObject(obj)
    end
    
    -----------------------------------------
    -- 2. Restore Terrain Water
    -----------------------------------------
    if Terrain and originalStates.waterProperties then
        pcall(function()
            Terrain.WaterReflectance = originalStates.waterProperties.WaterReflectance
            Terrain.WaterWaveSize = originalStates.waterProperties.WaterWaveSize
            Terrain.WaterWaveSpeed = originalStates.waterProperties.WaterWaveSpeed
        end)
    end
    
    -----------------------------------------
    -- 3. Restore Lighting
    -----------------------------------------
    if originalStates.lighting.GlobalShadows ~= nil then
        Lighting.GlobalShadows = originalStates.lighting.GlobalShadows
        Lighting.FogEnd = originalStates.lighting.FogEnd
        Lighting.FogStart = originalStates.lighting.FogStart
    end
    
    -----------------------------------------
    -- 4. Restore Post-Processing
    -----------------------------------------
    for effect, state in pairs(originalStates.effects) do
        if effect and effect.Parent then
            effect.Enabled = state
        end
    end
    
    -----------------------------------------
    -- 5. Restore Render Quality
    -----------------------------------------
    settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    
    -----------------------------------------
    -- 6. Disconnect hook
    -----------------------------------------
    if newObjectConnection then
        newObjectConnection:Disconnect()
        newObjectConnection = nil
    end
    
    -- Clear original states
    originalStates = {
        reflectance = {},
        transparency = {},
        lighting = {},
        effects = {},
        waterProperties = {}
    }
    
    return true, "FPS Booster disabled"
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
function FPSBooster.IsEnabled()
    return FPSBooster.Enabled
end

return FPSBooster
end)()
modules["AutoBuyWeather"] = (function() return {Enabled = false, Start = function() end} end)()
modules["Notify"] = (function() return {Enabled = false, Send = function() end} end)()
modules["GoodPerfectionStable"] = (function() return {Enabled = false, Toggle = function() end} end)()
modules["PingFPSMonitor"] = (function() return {Enabled = false, Toggle = function() end} end)()
modules["DisableRendering"] = (function()
-- =====================================================
-- DISABLE 3D RENDERING MODULE (CLEAN VERSION)
-- For integration with Lynx GUI v2.3
-- =====================================================

local DisableRendering = {}

-- =====================================================
-- SERVICES
-- =====================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- =====================================================
-- CONFIGURATION
-- =====================================================
DisableRendering.Settings = {
    AutoPersist = true -- Keep active after respawn
}

-- =====================================================
-- STATE VARIABLES
-- =====================================================
local State = {
    RenderingDisabled = false,
    RenderConnection = nil
}

-- =====================================================
-- PUBLIC API FUNCTIONS
-- =====================================================

-- Start disable rendering
function DisableRendering.Start()
    if State.RenderingDisabled then
        return false, "Already disabled"
    end
    
    local success, err = pcall(function()
        -- Disable 3D rendering
        State.RenderConnection = RunService.RenderStepped:Connect(function()
            pcall(function()
                RunService:Set3dRenderingEnabled(false)
            end)
        end)
        
        State.RenderingDisabled = true
    end)
    
    if not success then
        warn("[DisableRendering] Failed to start:", err)
        return false, "Failed to start"
    end
    
    return true, "Rendering disabled"
end

-- Stop disable rendering
function DisableRendering.Stop()
    if not State.RenderingDisabled then
        return false, "Already enabled"
    end
    
    local success, err = pcall(function()
        -- Disconnect render loop
        if State.RenderConnection then
            State.RenderConnection:Disconnect()
            State.RenderConnection = nil
        end
        
        -- Re-enable rendering
        RunService:Set3dRenderingEnabled(true)
        
        State.RenderingDisabled = false
    end)
    
    if not success then
        warn("[DisableRendering] Failed to stop:", err)
        return false, "Failed to stop"
    end
    
    return true, "Rendering enabled"
end

-- Toggle rendering
function DisableRendering.Toggle()
    if State.RenderingDisabled then
        return DisableRendering.Stop()
    else
        return DisableRendering.Start()
    end
end

-- Get current status
function DisableRendering.IsDisabled()
    return State.RenderingDisabled
end

-- =====================================================
-- AUTO-PERSIST ON RESPAWN
-- =====================================================
if DisableRendering.Settings.AutoPersist then
    LocalPlayer.CharacterAdded:Connect(function()
        if State.RenderingDisabled then
            task.wait(0.5)
            pcall(function()
                RunService:Set3dRenderingEnabled(false)
            end)
        end
    end)
end

-- =====================================================
-- CLEANUP FUNCTION
-- =====================================================
function DisableRendering.Cleanup()
    -- Enable rendering if disabled
    if State.RenderingDisabled then
        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)
    end
    
    -- Disconnect all connections
    if State.RenderConnection then
        State.RenderConnection:Disconnect()
    end
end

return DisableRendering
end)()
modules["MovementModule"] = (function()
local MovementModule = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Settings
MovementModule.Settings = {
    SprintSpeed = 50,
    DefaultSpeed = 16,
    SprintEnabled = false,
    InfiniteJumpEnabled = false
}

-- Internal State
local connections = {}
local jumpConnection = nil
local sprintConnection = nil

local function cleanup()
    for _, conn in pairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    connections = {}
    
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    
    if sprintConnection then
        sprintConnection:Disconnect()
        sprintConnection = nil
    end
end

local function maintainSprintSpeed()
    if sprintConnection then
        sprintConnection:Disconnect()
    end
    
    -- Loop yang terus memantau dan mempertahankan sprint speed
    sprintConnection = RunService.Heartbeat:Connect(function()
        if MovementModule.Settings.SprintEnabled and humanoid and humanoid.WalkSpeed ~= MovementModule.Settings.SprintSpeed then
            humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
        end
    end)
end

function MovementModule.SetSprintSpeed(speed)
    MovementModule.Settings.SprintSpeed = math.clamp(speed, 16, 200)
    
    if MovementModule.Settings.SprintEnabled and humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
    end
end

function MovementModule.EnableSprint()
    if MovementModule.Settings.SprintEnabled then return false end
    
    MovementModule.Settings.SprintEnabled = true
    
    if humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
    end
    
    -- Aktifkan loop pemantau sprint speed
    maintainSprintSpeed()
    
    return true
end

function MovementModule.DisableSprint()
    if not MovementModule.Settings.SprintEnabled then return false end
    
    MovementModule.Settings.SprintEnabled = false
    
    -- Matikan loop pemantau
    if sprintConnection then
        sprintConnection:Disconnect()
        sprintConnection = nil
    end
    
    if humanoid then
        humanoid.WalkSpeed = MovementModule.Settings.DefaultSpeed
    end
    
    return true
end

function MovementModule.IsSprintEnabled()
    return MovementModule.Settings.SprintEnabled
end

function MovementModule.GetSprintSpeed()
    return MovementModule.Settings.SprintSpeed
end

local function enableInfiniteJump()
    if jumpConnection then
        jumpConnection:Disconnect()
    end
    
    jumpConnection = UserInputService.JumpRequest:Connect(function()
        if MovementModule.Settings.InfiniteJumpEnabled and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

function MovementModule.EnableInfiniteJump()
    if MovementModule.Settings.InfiniteJumpEnabled then return false end
    
    MovementModule.Settings.InfiniteJumpEnabled = true
    enableInfiniteJump()
    
    return true
end

function MovementModule.DisableInfiniteJump()
    if not MovementModule.Settings.InfiniteJumpEnabled then return false end
    
    MovementModule.Settings.InfiniteJumpEnabled = false
    
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    
    return true
end

function MovementModule.IsInfiniteJumpEnabled()
    return MovementModule.Settings.InfiniteJumpEnabled
end

table.insert(connections, player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    
    -- Re-apply sprint if enabled
    if MovementModule.Settings.SprintEnabled then
        task.wait(0.1)
        humanoid.WalkSpeed = MovementModule.Settings.SprintSpeed
        maintainSprintSpeed() -- Aktifkan kembali loop pemantau
    end
    
    -- Re-apply infinite jump if enabled
    if MovementModule.Settings.InfiniteJumpEnabled then
        enableInfiniteJump()
    end
end))

function MovementModule.Start()
    MovementModule.Settings.SprintEnabled = false
    MovementModule.Settings.InfiniteJumpEnabled = false
    enableInfiniteJump()
    return true
end

function MovementModule.Stop()
    MovementModule.DisableSprint()
    MovementModule.DisableInfiniteJump()
    cleanup()
    return true
end

-- Initialize
MovementModule.Start()

return MovementModule
end)()
modules["AutoFavorite"] = (function() return {Enabled = false, Toggle = function() end} end)()
modules["Webhook"] = (function()
local WebhookModule = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function getHTTPRequest()
    -- Coba berbagai metode request berdasarkan executor
    local requestFunctions = {
        -- Metode standar
        request,
        http_request,
        -- Syn/Synapse
        (syn and syn.request),
        -- Fluxus
        (fluxus and fluxus.request),
        -- Script-Ware
        (http and http.request),
        -- Solara (khusus)
        (solara and solara.request),
        -- Fallback lainnya
        (game and game.HttpGet and function(opts)
            if opts.Method == "GET" then
                return {Body = game:HttpGet(opts.Url)}
            end
        end)
    }
    
    for _, func in ipairs(requestFunctions) do
        if func and type(func) == "function" then
            return func
        end
    end
    
    return nil
end

local httpRequest = getHTTPRequest()

WebhookModule.Config = {
    WebhookURL = "",
    DiscordUserID = "",
    DebugMode = false,
    EnabledRarities = {},
    UseSimpleMode = false -- Mode sederhana tanpa thumbnail API
}

local Items, Variants

-- Safe module loading
local function loadGameModules()
    local success, err = pcall(function()
        Items = require(ReplicatedStorage:WaitForChild("Items"))
        Variants = require(ReplicatedStorage:WaitForChild("Variants"))
    end)
    
    return success
end

local TIER_NAMES = {
    [1] = "Common",
    [2] = "Uncommon", 
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "SECRET"
}

local TIER_COLORS = {
    [1] = 9807270,
    [2] = 3066993,
    [3] = 3447003,
    [4] = 10181046,
    [5] = 15844367,
    [6] = 16711680,
    [7] = 1752220
}

local isRunning = false
local eventConnection = nil

local function getPlayerDisplayName()
    return LocalPlayer.DisplayName or LocalPlayer.Name
end

local function getDiscordImageUrl(assetId)
    if not assetId then return nil end
    
    local thumbnailUrl = string.format(
        "https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false",
        tostring(assetId)
    )
    
    local rbxcdnUrl = string.format(
        "https://tr.rbxcdn.com/180DAY-%s/420/420/Image/Png",
        tostring(assetId)
    )
    
    -- Coba Thumbnail API dulu (jika httpRequest tersedia)
    if httpRequest then
        local success, result = pcall(function()
            local response = httpRequest({
                Url = thumbnailUrl,
                Method = "GET"
            })
            
            if response and response.Body then
                local data = HttpService:JSONDecode(response.Body)
                if data and data.data and data.data[1] and data.data[1].imageUrl then
                    return data.data[1].imageUrl
                end
            end
        end)
        
        if success and result then
            return result
        end
    end
    
    -- Fallback ke rbxcdn
    return rbxcdnUrl
end

local function getFishImageUrl(fish)
    local assetId = nil
    
    if fish.Data.Icon then
        assetId = tostring(fish.Data.Icon):match("%d+")
    elseif fish.Data.ImageId then
        assetId = tostring(fish.Data.ImageId)
    elseif fish.Data.Image then
        assetId = tostring(fish.Data.Image):match("%d+")
    end
    
    if assetId then
        local discordUrl = getDiscordImageUrl(assetId)
        if discordUrl then
            return discordUrl
        end
    end
    
    return "https://i.imgur.com/8yZqFqM.png"
end

local function getFish(itemId)
    if not Items then return nil end
    
    for _, f in pairs(Items) do
        if f.Data and f.Data.Id == itemId then
            return f
        end
    end
end

local function getVariant(id)
    if not id or not Variants then return nil end
    
    local idStr = tostring(id)
    
    for _, v in pairs(Variants) do
        if v.Data then
            if tostring(v.Data.Id) == idStr or tostring(v.Data.Name) == idStr then
                return v
            end
        end
    end
    
    return nil
end

local function send(fish, meta, extra)
    -- Validasi webhook URL
    if not WebhookModule.Config.WebhookURL or WebhookModule.Config.WebhookURL == "" then
        return
    end
    
    -- Validasi HTTP request function
    if not httpRequest then
        return
    end
    
    local tier = TIER_NAMES[fish.Data.Tier] or "Unknown"
    local color = TIER_COLORS[fish.Data.Tier] or 3447003
    
    -- FILTER RARITY
    if WebhookModule.Config.EnabledRarities and #WebhookModule.Config.EnabledRarities > 0 then
        local isEnabled = false
        
        for _, enabledTier in ipairs(WebhookModule.Config.EnabledRarities) do
            if enabledTier == tier then
                isEnabled = true
                break
            end
        end
        
        if not isEnabled then
            return
        end
    end
    
    local mutationText = "None"
    local finalPrice = fish.SellPrice or 0
    local variantId = nil
    
    if extra then
        variantId = extra.Variant or extra.Mutation or extra.VariantId or extra.MutationId
    end
    
    if not variantId and meta then
        variantId = meta.Variant or meta.Mutation or meta.VariantId or meta.MutationId
    end
    
    local isShiny = (meta and meta.Shiny) or (extra and extra.Shiny)
    if isShiny then
        mutationText = "Shiny"
        finalPrice = finalPrice * 2
    end
    
    if variantId then
        local v = getVariant(variantId)
        if v then
            mutationText = v.Data.Name .. " (" .. v.SellMultiplier .. "x)"
            finalPrice = finalPrice * v.SellMultiplier
        else
            mutationText = variantId
        end
    end
    
    local imageUrl = getFishImageUrl(fish)
    local playerDisplayName = getPlayerDisplayName()
    local mention = WebhookModule.Config.DiscordUserID ~= "" and "<@" .. WebhookModule.Config.DiscordUserID .. "> " or ""
    
    local congratsMsg = string.format(
        "%s **%s** You have obtained a new **%s** fish!",
        mention,
        playerDisplayName,
        tier
    )
    
    local fields = {
        {
            name = "Fish Name :",
            value = "> " .. fish.Data.Name,
            inline = false
        },
        {
            name = "Fish Tier :",
            value = "> " .. tier,
            inline = false
        },
        {
            name = "Weight :",
            value = string.format("> %.2f Kg", meta.Weight or 0),
            inline = false
        },
        {
            name = "Mutation :",
            value = "> " .. mutationText,
            inline = false
        },
        {
            name = "Sell Price :",
            value = "> $" .. math.floor(finalPrice),
            inline = false
        }
    }
    
    local payload = {
        embeds = {{
            author = {
                name = "Lynxx Webhook | Fish Caught"
            },
            description = congratsMsg,
            color = color,
            fields = fields,
            image = {
                url = imageUrl
            },
            footer = {
                text = "Lynxx Webhook • " .. os.date("%m/%d/%Y %H:%M"),
                icon_url = "https://i.imgur.com/shnNZuT.png"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        httpRequest({
            Url = WebhookModule.Config.WebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

function WebhookModule:SetWebhookURL(url)
    self.Config.WebhookURL = url
end

function WebhookModule:SetDiscordUserID(id)
    self.Config.DiscordUserID = id
end

function WebhookModule:SetDebugMode(enabled)
    self.Config.DebugMode = enabled
end

function WebhookModule:SetEnabledRarities(rarities)
    self.Config.EnabledRarities = rarities
end

function WebhookModule:SetSimpleMode(enabled)
    self.Config.UseSimpleMode = enabled
end

function WebhookModule:GetTierNames()
    return TIER_NAMES
end

function WebhookModule:Start()
    if isRunning then
        return false
    end
    
    if not self.Config.WebhookURL or self.Config.WebhookURL == "" then
        return false
    end
    
    if not httpRequest then
        return false
    end
    
    -- Load game modules
    if not loadGameModules() then
        return false
    end
    
    local success, Event = pcall(function()
        return ReplicatedStorage.Packages
            ._Index["sleitnick_net@0.2.0"]
            .net["RE/ObtainedNewFishNotification"]
    end)
    
    if not success or not Event then
        return false
    end
    
    eventConnection = Event.OnClientEvent:Connect(function(itemId, metadata, extraData)
        local fish = getFish(itemId)
        if fish then
            task.spawn(function()
                send(fish, metadata, extraData)
            end)
        end
    end)
    
    isRunning = true
    return true
end

function WebhookModule:Stop()
    if not isRunning then
        return false
    end
    
    if eventConnection then
        eventConnection:Disconnect()
        eventConnection = nil
    end
    
    isRunning = false
    return true
end

function WebhookModule:IsRunning()
    return isRunning
end

function WebhookModule:GetConfig()
    return self.Config
end

-- Check if executor supports webhook
function WebhookModule:IsSupported()
    return httpRequest ~= nil
end

return WebhookModule
end)()

return modules

--// Services 
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local IsStudio = RunService:IsStudio()

--// Place ID Check
local CurrentPlaceId = game.PlaceId
local IsLobby = CurrentPlaceId == 11739766412

--// Anti-AFK
if not IsStudio then
    local speaker = Players.LocalPlayer
    if speaker then
        if getconnections then
            for _, connection in pairs(getconnections(speaker.Idled)) do
                if connection["Disable"] then
                    connection["Disable"](connection)
                elseif connection["Disconnect"] then
                    connection["Disconnect"](connection)
                end
            end
        else
            speaker.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end

--// Global Env Helper
local function getGlobalEnv()
    if getgenv then return getgenv() end
    if getfenv then return getfenv() end
    return _G
end

--// Safe HTTP Load
local function SafeLoadURL(url)
    pcall(function()
        loadstring(game:HttpGet(url))()
    end)
end

--// Credit Collection System
local collectCreditThread

local function collectUpgradeShopCredits()
    if game.PlaceId ~= 11739766412 then return end
    
    local gameFolder = workspace:FindFirstChild("Game")
    if not gameFolder then return end
    local ri = gameFolder:FindFirstChild("RaycastIgnore")
    if not ri then return end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    local event = remotes:FindFirstChild("ClientsideCoinCollectedStartedEvent")
    if not event then return end
    
    for _, child in ipairs(ri:GetChildren()) do
        local num = tonumber(tostring(child.Name):match("^UpgradeShopCredit(%d+)$"))
        if num then
            pcall(function()
                if event:IsA("RemoteEvent") then
                    event:FireServer(num)
                else
                    event:InvokeServer(num)
                end
            end)
        end
    end
end

local function startCollectUpgradeCredit()
    if game.PlaceId ~= 11739766412 then return end
    if collectCreditThread then return end
    
    collectCreditThread = task.spawn(function()
        while getGlobalEnv().TDX_CollectUpgradeCredit do
            collectUpgradeShopCredits()
            task.wait(0.2)
        end
        collectCreditThread = nil
    end)
end

local function stopCollectUpgradeCredit()
    getGlobalEnv().TDX_CollectUpgradeCredit = nil
end

--// Fetch ImGui library
local ImGui
if IsStudio then
    ImGui = require(ReplicatedStorage.ImGui)
else
    ImGui = loadstring(game:HttpGet('https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'))()
end

--// Config System
local ConfigFile = "moon_autoplay_config.json"

local DefaultConfig = {
    SelectedMode = nil,
    MenuKeybind = "Insert",
    CollectCredits = false,
    WebhookEnabled = false,
    WebhookURL = ""
}

local function LoadConfig()
    if isfile and isfile(ConfigFile) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFile))
        end)
        if success and result then
            for key, value in pairs(DefaultConfig) do
                if result[key] == nil then result[key] = value end
            end
            return result
        end
    end
    return DefaultConfig
end

local function SaveConfig(updates)
    local currentConfig = LoadConfig()
    for key, value in pairs(updates) do
        currentConfig[key] = value
    end
    pcall(function()
        writefile(ConfigFile, HttpService:JSONEncode(currentConfig))
    end)
end

--// Webhook System
local function SetupWebhook(enabled, url)
    local env = getGlobalEnv()
    if enabled and url and url ~= "" then
        env.webhookConfig = {
            webhookUrl = url,
            logInventory = true,
            targetGold = nil,
            targetCrystal = nil
        }
    else
        env.webhookConfig = nil
    end
end

--// Base URLs
local BASE_LOADER = "https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/"
local BASE_TDX = "https://raw.githubusercontent.com/mmr1337/tdx/refs/heads/main/"
local BASE_PIP = "https://raw.githubusercontent.com/mmr1337/pip/refs/heads/main/"

--// Script Loading Functions
local function LoadCommonLobbyScripts()
    if not IsLobby then
        SafeLoadURL(BASE_LOADER .. "ass")
    end
end

local function LoadLobbyOnly()
    if IsLobby then
        SafeLoadURL(BASE_LOADER .. "siski")
    end
end

local function LoadEventDependencies()
    LoadCommonLobbyScripts()
    SafeLoadURL(BASE_TDX .. "event")
    SafeLoadURL(BASE_LOADER .. "credits")
    LoadLobbyOnly()
end

local function LoadNightmareEventDependencies()
    LoadCommonLobbyScripts()
    SafeLoadURL(BASE_TDX .. "eventnt")
    SafeLoadURL(BASE_LOADER .. "creditnt")
    LoadLobbyOnly()
end

local function LoadRobotInvasionNightmareDependencies()
    SafeLoadURL(BASE_PIP .. "run/robotinvasionNightmare.lua")
    SafeLoadURL(BASE_PIP .. "run/pipi.lua")
end

--// Script URLs for standard modes
local ScriptURLs = {
    Easy = BASE_TDX .. "easy",
    Intermediate = BASE_TDX .. "intermediate",
    Elite = BASE_TDX .. "Elite",
    Expert = BASE_TDX .. "expert",
    Universal = BASE_TDX .. "coin%26exp"
}

--// Loaders for special modes
local SpecialLoaders = {
    Event = LoadEventDependencies,
    NightmareEvent = LoadNightmareEventDependencies,
    RobotInvasionNightmare = LoadRobotInvasionNightmareDependencies
}

local function LoadScript(mode)
    if SpecialLoaders[mode] then
        SpecialLoaders[mode]()
        return
    end
    if ScriptURLs[mode] then
        SafeLoadURL(ScriptURLs[mode])
    end
end

--// Window 
local Window = ImGui:CreateWindow({
    Title = "Moon",
    Size = UDim2.new(0, 550, 0, 670),
    Position = UDim2.new(0.5, 0, 0, 70)
})
Window:Center()

--// Load Config
local Config = LoadConfig()
local SavedMode = Config.SelectedMode
local CurrentMenuKeybind = Enum.KeyCode[Config.MenuKeybind] or Enum.KeyCode.Insert

--// Setup Webhook from config
SetupWebhook(Config.WebhookEnabled, Config.WebhookURL)

--// Menu Toggle Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == CurrentMenuKeybind then
        Window:SetVisible(not Window.Visible)
    end
end)

--// ═══════════════════════════════════════════
--// Checkbox mutual exclusion system
--// ═══════════════════════════════════════════
local ModeCheckboxes = {}

local function UncheckAllExcept(exceptMode)
    for name, checkbox in pairs(ModeCheckboxes) do
        if name ~= exceptMode and checkbox then
            checkbox:SetTicked(false)
        end
    end
end

local function OnModeSelected(mode)
    return function(self, Value)
        if Value then
            UncheckAllExcept(mode)
            SaveConfig({ SelectedMode = mode })
            LoadScript(mode)
        end
    end
end

--// ═══════════════════════════════════════════
--// Auto Play Tab
--// ═══════════════════════════════════════════
local AutoPlayTab = Window:CreateTab({ Name = "Auto Play" })

AutoPlayTab:Label({
    Text = "Select difficulty mode:",
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

AutoPlayTab:Separator()

--// Mode definitions: { key, label, description }
local ModeDefinitions = {
    { "Easy",                     "Easy",                       "need an operator and a missile trooper" },
    { "Intermediate",             "Intermediate",               "need an Patrol Boat and Barracks" },
    { "Elite",                    "Elite",                      "need an John, Grenadier, Sniper, Shotgunner, Edj, Barracks" },
    { "Expert",                   "Expert",                     "need an XWM Turret and Armored Factory" },
    { "Universal",                "Universal",                  "nothing is needed" },
    { "Event",                    "Event",                      "need an Sniper, EDJ, Medic" },
    { "NightmareEvent",           "NightmareEvent",             "need an Sentry and Warship" },
    { "RobotInvasionNightmare",   "Robot Invasion Nightmare",   "need an Sniper, EDJ, Warship" },
}

for _, def in ipairs(ModeDefinitions) do
    local key, label, description = def[1], def[2], def[3]
    
    ModeCheckboxes[key] = AutoPlayTab:Checkbox({
        Label = label,
        Value = false,
        Callback = OnModeSelected(key),
    })
    
    AutoPlayTab:Label({
        Text = description,
        TextColor3 = Color3.fromRGB(150, 150, 150)
    })
    
    AutoPlayTab:Separator()
end

--// ═══════════════════════════════════════════
--// Webhook Tab
--// ═══════════════════════════════════════════
local WebhookTab = Window:CreateTab({ Name = "Webhook" })

WebhookTab:Label({
    Text = "Discord Webhook Integration",
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

WebhookTab:Separator()

local WebhookEnabledCheckbox
local WebhookURLInput

WebhookURLInput = WebhookTab:InputText({
    Label = "Webhook URL",
    Value = Config.WebhookURL or "",
    PlaceHolder = "https://discord.com/api/webhooks/...",
    Callback = function(self, Value)
        SaveConfig({ WebhookURL = Value })
        if WebhookEnabledCheckbox then
            SetupWebhook(WebhookEnabledCheckbox.Value, Value)
        end
    end,
})

WebhookTab:Label({
    Text = "Paste your Discord webhook URL here",
    TextColor3 = Color3.fromRGB(150, 150, 150)
})

WebhookTab:Separator()

WebhookEnabledCheckbox = WebhookTab:Checkbox({
    Label = "Enable Webhook",
    Value = Config.WebhookEnabled or false,
    Callback = function(self, Value)
        SaveConfig({ WebhookEnabled = Value })
        local url = WebhookURLInput:GetValue()
        SetupWebhook(Value, url)
        
        if Value and url ~= "" then
            task.wait(0.5)
            SafeLoadURL(BASE_LOADER .. "webhook.lua")
        end
    end,
})

WebhookTab:Label({
    Text = "Enable webhook notifications",
    TextColor3 = Color3.fromRGB(150, 150, 150)
})

--// ═══════════════════════════════════════════
--// Settings Tab
--// ═══════════════════════════════════════════
local SettingsTab = Window:CreateTab({ Name = "Settings" })

SettingsTab:Label({
    Text = "Menu Controls:",
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

SettingsTab:Separator()

SettingsTab:Keybind({
    Label = "Toggle Menu",
    Value = CurrentMenuKeybind,
    Callback = function(self, KeyCode)
        CurrentMenuKeybind = KeyCode
        SaveConfig({ MenuKeybind = KeyCode.Name })
    end,
})

if IsLobby then
    SettingsTab:Separator()
    
    SettingsTab:Label({
        Text = "Lobby Features:",
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    
    SettingsTab:Separator()
    
    SettingsTab:Checkbox({
        Label = "Collect Upgrade Credits",
        Value = Config.CollectCredits or false,
        Callback = function(self, Value)
            if Value then
                getGlobalEnv().TDX_CollectUpgradeCredit = true
                startCollectUpgradeCredit()
            else
                stopCollectUpgradeCredit()
            end
            SaveConfig({ CollectCredits = Value })
        end,
    })
    
    SettingsTab:Label({
        Text = "Auto-collect upgrade credit coins in lobby",
        TextColor3 = Color3.fromRGB(150, 150, 150)
    })
end

--// ═══════════════════════════════════════════
--// Read Me Tab
--// ═══════════════════════════════════════════
local CreditsTab = Window:CreateTab({ Name = "Read me" })

local Credits = CreditsTab:Table({
    Border = false,
    Align = "Top"
}):CreateRow()

local Column1 = Credits:CreateColumn()
Column1:Image({
    Image = 85942365582559,
    Ratio = 1 / 1,
    AspectType = Enum.AspectType.FitWithinMaxSize,
    Size = UDim2.fromScale(1, 1)
})
Column1:Label({ Text = "usemoon.xyz" })

Credits:CreateColumn():Label({
    Text = [[This macro was created by dem3x3.
Please report any issues or suggestions to the discord.]],
    TextWrapped = true,
    RichText = true
})

CreditsTab:Separator()

CreditsTab:Label({
    Text = "Discord Server:",
    TextColor3 = Color3.fromRGB(70, 130, 255)
})

CreditsTab:Button({
    Text = "Copy Discord Link",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/AnsNepJ7CW")
        end
    end,
})

--// ═══════════════════════════════════════════
--// Startup: apply saved state
--// ═══════════════════════════════════════════

-- Show Read me tab by default
task.spawn(function()
    task.wait(0.1)
    Window:ShowTab(CreditsTab)
end)

-- Restore saved mode checkbox
if SavedMode and ModeCheckboxes[SavedMode] then
    ModeCheckboxes[SavedMode]:SetTicked(true)
end

-- Auto-start credit collection if was enabled
if IsLobby and Config.CollectCredits then
    getGlobalEnv().TDX_CollectUpgradeCredit = true
    startCollectUpgradeCredit()
end

-- Load webhook if enabled
if Config.WebhookEnabled and Config.WebhookURL and Config.WebhookURL ~= "" then
    task.wait(0.5)
    SafeLoadURL(BASE_LOADER .. "webhook.lua")
end

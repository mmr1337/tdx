--// Services 
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
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

--// Credit Collection System
local function getGlobalEnv()
    if getgenv then return getgenv() end
    if getfenv then return getfenv() end
    return _G
end

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
        local num = tostring(child.Name):match("^UpgradeShopCredit(%d+)$")
        if num then
            local n = tonumber(num)
            if n then
                pcall(function()
                    if event:IsA("RemoteEvent") then
                        event:FireServer(n)
                    elseif event:IsA("RemoteFunction") then
                        event:InvokeServer(n)
                    end
                end)
            end
        end
    end
end

local function startCollectUpgradeCredit()
    if game.PlaceId ~= 11739766412 then return end
    if collectCreditThread then return end
    
    collectCreditThread = task.spawn(function()
        while true do
            if not getGlobalEnv().TDX_CollectUpgradeCredit then
                break
            end
            collectUpgradeShopCredits()
            task.wait(0.2)
        end
        collectCreditThread = nil
    end)
end

local function stopCollectUpgradeCredit()
    getGlobalEnv().TDX_CollectUpgradeCredit = nil
end

--// Fetch library
local ImGui
if IsStudio then
    ImGui = require(ReplicatedStorage.ImGui)
else
    local SourceURL = 'https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'
    ImGui = loadstring(game:HttpGet(SourceURL))()
end

--// Config System
local ConfigFile = "moon_autoplay_config.json"
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

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
                if result[key] == nil then
                    result[key] = value
                end
            end
            return result
        end
    end
    return DefaultConfig
end

local function SaveConfig(mode, keybind, collectCredits, webhookEnabled, webhookURL)
    local currentConfig = LoadConfig()
    
    if mode then
        currentConfig.SelectedMode = mode
    end
    
    if keybind then
        currentConfig.MenuKeybind = keybind
    end
    
    if collectCredits ~= nil then
        currentConfig.CollectCredits = collectCredits
    end
    
    if webhookEnabled ~= nil then
        currentConfig.WebhookEnabled = webhookEnabled
    end
    
    if webhookURL ~= nil then
        currentConfig.WebhookURL = webhookURL
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

--// Load Event Dependencies
local function LoadEventDependencies()
    if not IsLobby then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/ass"))()
        end)
    end
    
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/mmr1337/tdx/refs/heads/main/event"))()
    end)
    
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/credits"))()
    end)
    
    if IsLobby then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/siski"))()
        end)
    end
end

local function LoadNightmareEventDependencies()
    if not IsLobby then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/ass"))()
        end)
    end
    
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/mmr1337/tdx/refs/heads/main/eventnt"))()
    end)
    
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/creditnt"))()
    end)
    
    if IsLobby then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/siski"))()
        end)
    end
end

--// Script URLs
local ScriptURLs = {
    Easy = "https://raw.githubusercontent.com/mmr1337/tdx/refs/heads/main/easy",
    Intermediate = "https://raw.githubusercontent.com/mmr1337/tdx/refs/heads/main/intermediate",
    Elite = "https://raw.githubusercontent.com/mmr1337/tdx/refs/heads/main/Elite",
    Expert = "https://raw.githubusercontent.com/mmr1337/tdx/refs/heads/main/expert",
    Universal = "https://raw.githubusercontent.com/mmr1337/tdx/refs/heads/main/coin%26exp"
}

local CurrentLoadedScript = nil

local function LoadScript(mode)
    if mode == "Event" then
        LoadEventDependencies()
        return
    end
    
    if mode == "NightmareEvent" then
        LoadNightmareEventDependencies()
        return
    end
    
    if not ScriptURLs[mode] then
        return
    end
    
    pcall(function()
        loadstring(game:HttpGet(ScriptURLs[mode]))()
    end)
    
    CurrentLoadedScript = mode
end

--// Window 
local Window = ImGui:CreateWindow({
    Title = "Moon",
    Size = UDim2.new(0, 550, 0, 620),
    Position = UDim2.new(0.5, 0, 0, 70)
})
Window:Center()

--// Load Config
local Config = LoadConfig()
local SavedMode = Config.SelectedMode
local CurrentMenuKeybind = Enum.KeyCode[Config.MenuKeybind] or Enum.KeyCode.Insert

SetupWebhook(Config.WebhookEnabled, Config.WebhookURL)

--// Menu Toggle Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == CurrentMenuKeybind then
        Window:SetVisible(not Window.Visible)
    end
end)

--// Auto Play Tab
local AutoPlayTab = Window:CreateTab({
    Name = "Auto Play"
})

AutoPlayTab:Label({
    Text = "Select difficulty mode:",
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

AutoPlayTab:Separator()

local EasyCheckbox
local IntermediateCheckbox
local EliteCheckbox
local ExpertCheckbox
local UniversalCheckbox
local EventCheckbox
local NightmareEventCheckbox

EasyCheckbox = AutoPlayTab:Checkbox({
    Label = "Easy",
    Value = false,
    Callback = function(self, Value)
        if Value then
            if IntermediateCheckbox then IntermediateCheckbox:SetTicked(false) end
            if EliteCheckbox then EliteCheckbox:SetTicked(false) end
            if ExpertCheckbox then ExpertCheckbox:SetTicked(false) end
            if UniversalCheckbox then UniversalCheckbox:SetTicked(false) end
            if EventCheckbox then EventCheckbox:SetTicked(false) end
            if NightmareEventCheckbox then NightmareEventCheckbox:SetTicked(false) end
            SaveConfig("Easy")
            LoadScript("Easy")
        end
    end,
})

AutoPlayTab:Label({
    Text = "need an operator and a missile trooper",
    TextColor3 = Color3.fromRGB(150, 150, 150)
})

AutoPlayTab:Separator()

IntermediateCheckbox = AutoPlayTab:Checkbox({
    Label = "Intermediate",
    Value = false,
    Callback = function(self, Value)
        if Value then
            if EasyCheckbox then EasyCheckbox:SetTicked(false) end
            if EliteCheckbox then EliteCheckbox:SetTicked(false) end
            if ExpertCheckbox then ExpertCheckbox:SetTicked(false) end
            if UniversalCheckbox then UniversalCheckbox:SetTicked(false) end
            if EventCheckbox then EventCheckbox:SetTicked(false) end
            if NightmareEventCheckbox then NightmareEventCheckbox:SetTicked(false) end
            SaveConfig("Intermediate")
            LoadScript("Intermediate")
        end
    end,
})

AutoPlayTab:Label({
    Text = "need an Patrol Boat and Barracks",
    TextColor3 = Color3.fromRGB(150, 150, 150)
})

AutoPlayTab:Separator()

EliteCheckbox = AutoPlayTab:Checkbox({
    Label = "Elite",
    Value = false,
    Callback = function(self, Value)
        if Value then
            if EasyCheckbox then EasyCheckbox:SetTicked(false) end
            if IntermediateCheckbox then IntermediateCheckbox:SetTicked(false) end
            if ExpertCheckbox then ExpertCheckbox:SetTicked(false) end
            if UniversalCheckbox then UniversalCheckbox:SetTicked(false) end
            if EventCheckbox then EventCheckbox:SetTicked(false) end
            if NightmareEventCheckbox then NightmareEventCheckbox:SetTicked(false) end
            SaveConfig("Elite")
            LoadScript("Elite")
        end
    end,
})

AutoPlayTab:Label({
    Text = "need an John, Grenadier, Sniper, Shotgunner, Edj, Barracks",
    TextColor3 = Color3.fromRGB(150, 150, 150)
})

AutoPlayTab:Separator()

ExpertCheckbox = AutoPlayTab:Checkbox({
    Label = "Expert",
    Value = false,
    Callback = function(self, Value)
        if Value then
            if EasyCheckbox then EasyCheckbox:SetTicked(false) end
            if IntermediateCheckbox then IntermediateCheckbox:SetTicked(false) end
            if EliteCheckbox then EliteCheckbox:SetTicked(false) end
            if UniversalCheckbox then UniversalCheckbox:SetTicked(false) end
            if EventCheckbox then EventCheckbox:SetTicked(false) end
            if NightmareEventCheckbox then NightmareEventCheckbox:SetTicked(false) end
            SaveConfig("Expert")
            LoadScript("Expert")
        end
    end,
})

AutoPlayTab:Label({
    Text = "need an XWM Turret and Armored Factory",
    TextColor3 = Color3.fromRGB(150, 150, 150)
})

AutoPlayTab:Separator()

UniversalCheckbox = AutoPlayTab:Checkbox({
    Label = "Universal",
    Value = false,
    Callback = function(self, Value)
        if Value then
            if EasyCheckbox then EasyCheckbox:SetTicked(false) end
            if IntermediateCheckbox then IntermediateCheckbox:SetTicked(false) end
            if EliteCheckbox then EliteCheckbox:SetTicked(false) end
            if ExpertCheckbox then ExpertCheckbox:SetTicked(false) end
            if EventCheckbox then EventCheckbox:SetTicked(false) end
            if NightmareEventCheckbox then NightmareEventCheckbox:SetTicked(false) end
            SaveConfig("Universal")
            LoadScript("Universal")
        end
    end,
})

AutoPlayTab:Label({
    Text = "nothing is needed",
    TextColor3 = Color3.fromRGB(150, 150, 150)
})

AutoPlayTab:Separator()

EventCheckbox = AutoPlayTab:Checkbox({
    Label = "Event",
    Value = false,
    Callback = function(self, Value)
        if Value then
            if EasyCheckbox then EasyCheckbox:SetTicked(false) end
            if IntermediateCheckbox then IntermediateCheckbox:SetTicked(false) end
            if EliteCheckbox then EliteCheckbox:SetTicked(false) end
            if ExpertCheckbox then ExpertCheckbox:SetTicked(false) end
            if UniversalCheckbox then UniversalCheckbox:SetTicked(false) end
            if NightmareEventCheckbox then NightmareEventCheckbox:SetTicked(false) end
            SaveConfig("Event")
            LoadScript("Event")
        end
    end,
})

AutoPlayTab:Label({
    Text = "need an Sniper, EDJ, Medic",
    TextColor3 = Color3.fromRGB(150, 150, 150)
})

AutoPlayTab:Separator()

NightmareEventCheckbox = AutoPlayTab:Checkbox({
    Label = "NightmareEvent",
    Value = false,
    Callback = function(self, Value)
        if Value then
            if EasyCheckbox then EasyCheckbox:SetTicked(false) end
            if IntermediateCheckbox then IntermediateCheckbox:SetTicked(false) end
            if EliteCheckbox then EliteCheckbox:SetTicked(false) end
            if ExpertCheckbox then ExpertCheckbox:SetTicked(false) end
            if UniversalCheckbox then UniversalCheckbox:SetTicked(false) end
            if EventCheckbox then EventCheckbox:SetTicked(false) end
            SaveConfig("NightmareEvent")
            LoadScript("NightmareEvent")
        end
    end,
})

AutoPlayTab:Label({
    Text = "need an Sentry and Warship",
    TextColor3 = Color3.fromRGB(150, 150, 150)
})

--// Webhook Tab
local WebhookTab = Window:CreateTab({
    Name = "Webhook"
})

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
        SaveConfig(nil, nil, nil, nil, Value)
        
        if WebhookEnabledCheckbox then
            local enabled = WebhookEnabledCheckbox.Value
            SetupWebhook(enabled, Value)
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
        SaveConfig(nil, nil, nil, Value)
        
        local url = WebhookURLInput:GetValue()
        SetupWebhook(Value, url)
        
        if Value and url ~= "" then
            task.wait(0.5)
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/webhook.lua"))()
            end)
        end
    end,
})

WebhookTab:Label({
    Text = "Enable webhook notifications",
    TextColor3 = Color3.fromRGB(150, 150, 150)
})


--// Settings Tab
local SettingsTab = Window:CreateTab({
    Name = "Settings"
})

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
        SaveConfig(nil, KeyCode.Name)
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
            SaveConfig(nil, nil, Value)
        end,
    })
    
    SettingsTab:Label({
        Text = "Auto-collect upgrade credit coins in lobby",
        TextColor3 = Color3.fromRGB(150, 150, 150)
    })
end

--// Read Me Tab
local CreditsTab = Window:CreateTab({
    Name = "Read me",
})

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
Column1:Label({
    Text = "usemoon.xyz"
})

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

task.spawn(function()
    task.wait(0.1)
    Window:ShowTab(CreditsTab)
end)

if SavedMode == "Easy" then
    EasyCheckbox:SetTicked(true)
elseif SavedMode == "Intermediate" then
    IntermediateCheckbox:SetTicked(true)
elseif SavedMode == "Elite" then
    EliteCheckbox:SetTicked(true)
elseif SavedMode == "Expert" then
    ExpertCheckbox:SetTicked(true)
elseif SavedMode == "Universal" then
    UniversalCheckbox:SetTicked(true)
elseif SavedMode == "Event" then
    EventCheckbox:SetTicked(true)
elseif SavedMode == "NightmareEvent" then
    NightmareEventCheckbox:SetTicked(true)
end

if IsLobby and Config.CollectCredits then
    getGlobalEnv().TDX_CollectUpgradeCredit = true
    startCollectUpgradeCredit()
end


if Config.WebhookEnabled and Config.WebhookURL and Config.WebhookURL ~= "" then
    task.wait(0.5)
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/webhook.lua"))()
    end)
end


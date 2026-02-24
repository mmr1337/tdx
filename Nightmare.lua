wait(10)
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local player = Players.LocalPlayer


if not game:IsLoaded() then
    game.Loaded:Wait()
end


local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

repeat
    task.wait(0.1)
until ContentProvider.RequestQueueSize == 0


warn("load")




local keyURL = "https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/key.txt" -- Replace with your actual key list URL
local jsonURL = "https://raw.githubusercontent.com/mmr1337/tdx/refs/heads/main/op.json"
local macroFolder = "tdx/macros"
local macroFile = macroFolder.."/op.json"
local loaderURL = "https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/loader.lua"
local rebildURL = "https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/rebuild.lua"
local skipWaveURL = "https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/auto_skip.lua"
local fpsURL = "https://raw.githubusercontent.com/Baolong12355/loader.lua/refs/heads/main/fps.lua"
local blackURL = "https://raw.githubusercontent.com/Baolong12355/loader.lua/refs/heads/main/black.lua"



local HttpService = game:GetService("HttpService")


if not isfolder("tdx") then makefolder("tdx") end
if not isfolder(macroFolder) then makefolder(macroFolder) end

-- Download JSON macro
local success, result = pcall(function()
    return game:HttpGet(jsonURL)
end)

if success then
    writefile(macroFile, result)
    print("[✔] Downloaded macro file.")
else
    warn("[✘] Failed to download macro:", result)
    return
end

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

getgenv().TDX_Config = {
    ["Key"] = "your_access_key_here", -- Chỉ 1 key duy nhất
    ["mapvoting"] = "CASTELLAN REACH",
    ["Return Lobby"] = true,
    ["x1.5 Speed"] = true,
    ["loadout"] = 0,
    ["Auto Skill"] = true,
    ["Map"] = "CASTELLAN REACH",
    ["Macros"] = "run",
    ["Macro Name"] = "op",
    ["Auto Difficulty"] = "Nightmare"

}

-- Run main loader
loadstring(game:HttpGet(loaderURL))()

_G.WaveConfig = {
    ["WAVE 0"] = "i",
    ["WAVE 1"] = "i",
    ["WAVE 2"] = "i"
}

-- Run auto skip script
loadstring(game:HttpGet(skipWaveURL))()



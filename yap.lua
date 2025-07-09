local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local CutsceneSystem = require(ReplicatedStorage.ClientModules.CutsceneSystem)
local RemoteUtils = require(ReplicatedStorage.SharedModules.RemoteUtils)

local MeteorEggCutscene = ReplicatedStorage.ClientModules.Objects.EggFinale.MeteorEgg

local CutsceneModule = require(MeteorEggCutscene)

local cutsceneState = 1 -- 1 for PT1, 2 for PT2

local mockMeteorEgg = {
    adornee = nil,
    verticalOffset = 0,
    
    hideMeteor = function(self)
        print("Hiding meteor...")
        self.verticalOffset = -100
        if self.adornee and self.adornee:FindFirstChild("Meteor") then
            local meteorPart = self.adornee.Meteor.PrimaryPart
            if meteorPart and meteorPart:FindFirstChild("HealthBar") then
                meteorPart.HealthBar.Enabled = false
            end
        end
    end,
    
    showMeteor = function(self)
        print("Showing meteor...")
        self.verticalOffset = 0
        if self.adornee and self.adornee:FindFirstChild("Meteor") then
            local meteorPart = self.adornee.Meteor.PrimaryPart
            if meteorPart and meteorPart:FindFirstChild("HealthBar") then
                meteorPart.HealthBar.Enabled = true
            end
        end
    end,
    
    updateEggRain = function(self, category)
        print("Updating egg rain for category:", category or "default")
    end,
    
    playEggChangeScene = function(self, category)
        print("Playing egg change scene for category:", category)
        if not CutsceneSystem then
            return
        end
        
        self:hideMeteor()
        self:updateEggRain(category)
        
        local eggRainCutscene = self.adornee and self.adornee:FindFirstChild("EggRainCutscene")
        if eggRainCutscene then
            local cutsceneData = require(eggRainCutscene)
            task.spawn(CutsceneSystem.playCutsceneById, "MeteorCrashPT2", cutsceneData, function()
                self:showMeteor()
            end)
        end
    end
}

local function findOrCreateMeteor()
    local meteor = workspace:FindFirstChild("MeteorEgg")
    if not meteor then
        meteor = Instance.new("Model")
        meteor.Name = "MeteorEgg"
        meteor.Parent = workspace
        
        local meteorModel = Instance.new("Model")
        meteorModel.Name = "Meteor"
        meteorModel.Parent = meteor
        
        local primaryPart = Instance.new("Part")
        primaryPart.Name = "PrimaryPart"
        primaryPart.Size = Vector3.new(4, 4, 4)
        primaryPart.Position = Vector3.new(0, 10, 0)
        primaryPart.BrickColor = BrickColor.new("Bright red")
        primaryPart.Material = Enum.Material.Neon
        primaryPart.Shape = Enum.PartType.Ball
        primaryPart.CanCollide = false
        primaryPart.Anchored = true
        primaryPart.Parent = meteorModel
        
        meteorModel.PrimaryPart = primaryPart
        
        local healthBar = Instance.new("BillboardGui")
        healthBar.Name = "HealthBar"
        healthBar.Size = UDim2.new(0, 200, 0, 20)
        healthBar.StudsOffset = Vector3.new(0, 3, 0)
        healthBar.Parent = primaryPart
        
        local frame = Instance.new("Frame")
        frame.Name = "Frame"
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.new(0, 0, 0)
        frame.Parent = healthBar
        
        local cutsceneModuleScript = Instance.new("ModuleScript")
        cutsceneModuleScript.Name = "Cutscene"
        cutsceneModuleScript.Source = [[
            return {
                scenes = {
                    MeteorCrashPT1 = {
                        duration = 3,
                        actions = {}
                    },
                    MeteorCrashPT2 = {
                        duration = 3,
                        actions = {}
                    }
                }
            }
        ]]
        cutsceneModuleScript.Parent = meteor
        
        print("created meteorat:", meteor:GetFullName())
    end
    
    return meteor
end

local function playMeteorCrashPT1()
    print("=== starting pt1 ===")
    
    local meteor = findOrCreateMeteor()
    mockMeteorEgg.adornee = meteor
    
    mockMeteorEgg:hideMeteor()
    mockMeteorEgg:updateEggRain()
    
    local cutsceneData = meteor:FindFirstChild("Cutscene")
    if cutsceneData then
        cutsceneData = require(cutsceneData)
    else
        cutsceneData = CutsceneModule
    end
    
    task.spawn(CutsceneSystem.playCutsceneById, "MeteorCrashPT1", cutsceneData, function()
        print("pt1 completed")
        while CutsceneSystem.getIsPlayingCutscene() do
            task.wait()
        end
        
        cutsceneState = 2
        print("ready for pt2")
    end)
end

local function playMeteorCrashPT2()
    print("=== starting pt2 ===")
    
    local meteor = findOrCreateMeteor()
    mockMeteorEgg.adornee = meteor
    
    local cutsceneData = meteor:FindFirstChild("Cutscene")
    if cutsceneData then
        cutsceneData = require(cutsceneData)
    else
        cutsceneData = CutsceneModule
    end
    
    task.defer(CutsceneSystem.playCutsceneById, "MeteorCrashPT2", cutsceneData, function()
        print("MeteorCrashPT2 completed!")
        
        RemoteUtils.GetRemoteEvent("MeteorCutscene"):FireServer("MeteorCrash")
        
        mockMeteorEgg:showMeteor()
        
        while CutsceneSystem.getIsPlayingCutscene() do
            task.wait()
        end
        
        cutsceneState = 1
        print("completed, clcik again for pt1")
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if cutsceneState == 1 then
            playMeteorCrashPT1()
        elseif cutsceneState == 2 then
            playMeteorCrashPT2()
        end
    end
end)

print("=== ready ===")
print("Current state: PT" .. cutsceneState)
print("Left click to play MeteorCrashPT1")
print("After PT1 completes, click again to play MeteorCrashPT2")

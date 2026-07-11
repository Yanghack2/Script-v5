-- Sorcerer Tycoon - Ultimate Farm Script
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({
    Name = "⚡ Sorcerer Tycoon - Ultimate Farm",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "SorcererTycoonConfig",
    IntroEnabled = true,
    IntroText = "SORCERER TYCOON",
    IntroIcon = "rbxassetid://4483345998"
})

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")
local rs = game:GetService("RunSystem")
local vu = game:GetService("VirtualUser")
local tween = game:GetService("TweenService")

-- Variables
local skillRemote = game:GetService("ReplicatedStorage").Assets.Remotes.Skills.SKill
local isFarming = false
local isBossFarming = false
local isCollecting = false
local selectedBoss = "Lac"
local bossLocations = {
    Lac = workspace.Map.Boss.Lac,
    Metro = workspace.Map.Boss.Metro,
    Shibuya = workspace.Map.Boss.Shibuya,
    WorldBoss = workspace.Map.Boss.WorldBoss
}

-- Fonctions de téléportation
local function teleportTo(position)
    if root and position then
        root.CFrame = CFrame.new(position)
        wait(0.1)
    end
end

local function getNearestBoss(bossType)
    local bossFolder = bossLocations[bossType]
    if not bossFolder then return nil end
    
    local bosses = bossFolder:FindFirstChild("Bosses")
    if not bosses then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, obj in pairs(bosses:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
            local hum = obj:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (root.Position - obj:GetPivot().Position).Magnitude
                if dist < nearestDist then
                    nearest = obj
                    nearestDist = dist
                end
            end
        end
    end
    
    return nearest
end

local function getDrops(bossType)
    local bossFolder = bossLocations[bossType]
    if not bossFolder then return {} end
    
    local drops = bossFolder:FindFirstChild("Drops")
    if not drops then return {} end
    
    local dropList = {}
    for _, obj in pairs(drops:GetChildren()) do
        if obj:IsA("Part") or obj:IsA("Model") then
            table.insert(dropList, obj)
        end
    end
    
    return dropList
end

-- Fonction Skill Spam
local function useSkill()
    local args = {
        [1] = "Hanami",
        [2] = "Thorn Barrage",
    }
    
    local success, err = pcall(function()
        skillRemote:FireServer(unpack(args))
    end)
    
    return success
end

-- Fonction Farm Boss
local function farmBoss(bossType)
    if isBossFarming then return end
    isBossFarming = true
    
    while isBossFarming do
        local boss = getNearestBoss(bossType)
        
        if boss then
            local bossPos = boss:GetPivot().Position
            teleportTo(bossPos + Vector3.new(0, 0, 5))
            
            -- Spam le skill
            for i = 1, 10 do
                if not isBossFarming then break end
                useSkill()
                wait(0.2)
            end
            
            -- Vérifie si le boss est mort
            local bossHum = boss:FindFirstChild("Humanoid")
            if bossHum and bossHum.Health <= 0 then
                wait(1)
                -- Collecte les drops
                if isCollecting then
                    local drops = getDrops(bossType)
                    for _, drop in pairs(drops) do
                        if drop and drop.Parent then
                            teleportTo(drop.Position)
                            wait(0.3)
                        end
                    end
                end
            end
        else
            -- Si pas de boss, attend
            wait(2)
        end
        
        wait(0.5)
    end
end

-- Fonction Collecte Automatique
local function autoCollect()
    while isCollecting do
        for bossType, _ in pairs(bossLocations) do
            local drops = getDrops(bossType)
            for _, drop in pairs(drops) do
                if drop and drop.Parent then
                    local dropPos = drop:IsA("Model") and drop:GetPivot().Position or drop.Position
                    teleportTo(dropPos)
                    wait(0.3)
                end
            end
        end
        wait(2)
    end
end

-- Fonction Anti AFK
local function antiAFK()
    vu:CaptureController()
    vu:ClickButton1(Vector2.new(0, 0))
end

-- Création des onglets
local MainTab = Window:MakeTab({
    Name = "⚔️ Farm",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local BossTab = Window:MakeTab({
    Name = "👑 Boss",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local CollectTab = Window:MakeTab({
    Name = "💰 Collecte",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local SettingsTab = Window:MakeTab({
    Name = "⚙️ Paramètres",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Onglet Farm
MainTab:AddSection({
    Name = "Skill Spam"
})

MainTab:AddToggle({
    Name = "Auto Skill Spam",
    Default = false,
    Callback = function(Value)
        isFarming = Value
        if Value then
            spawn(function()
                while isFarming do
                    useSkill()
                    wait(0.5)
                end
            end)
        end
    end
})

MainTab:AddButton({
    Name = "🔫 Use Skill Now",
    Callback = function()
        useSkill()
    end
})

MainTab:AddSection({
    Name = "Farm Général"
})

MainTab:AddToggle({
    Name = "Anti AFK",
    Default = true,
    Callback = function(Value)
        if Value then
            spawn(function()
                while Value do
                    antiAFK()
                    wait(60)
                end
            end)
        end
    end
})

-- Onglet Boss
BossTab:AddSection({
    Name = "Sélection du Boss"
})

BossTab:AddDropdown({
    Name = "Choisir le boss",
    Default = "Lac",
    Options = {"Lac", "Metro", "Shibuya", "WorldBoss"},
    Callback = function(Value)
        selectedBoss = Value
    end
})

BossTab:AddToggle({
    Name = "Auto Farm Boss",
    Default = false,
    Callback = function(Value)
        isBossFarming = Value
        if Value then
            spawn(function()
                farmBoss(selectedBoss)
            end)
        end
    end
})

BossTab:AddButton({
    Name = "📍 Téléporter au boss",
    Callback = function()
        local boss = getNearestBoss(selectedBoss)
        if boss then
            teleportTo(boss:GetPivot().Position + Vector3.new(0, 0, 5))
        else
            OrionLib:MakeNotification({
                Name = "Erreur",
                Content = "Aucun boss trouvé !",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end
})

BossTab:AddButton({
    Name = "💀 One Shot Boss",
    Callback = function()
        local boss = getNearestBoss(selectedBoss)
        if boss then
            local bossPos = boss:GetPivot().Position
            teleportTo(bossPos + Vector3.new(0, 0, 3))
            
            for i = 1, 20 do
                useSkill()
                wait(0.1)
            end
            
            OrionLib:MakeNotification({
                Name = "Succès",
                Content = "Boss attaqué !",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

-- Onglet Collecte
CollectTab:AddSection({
    Name = "Collecte Automatique"
})

CollectTab:AddToggle({
    Name = "Auto Collecte Drops",
    Default = false,
    Callback = function(Value)
        isCollecting = Value
        if Value then
            spawn(autoCollect)
        end
    end
})

CollectTab:AddButton({
    Name = "📍 Collecter tous les drops",
    Callback = function()
        for bossType, _ in pairs(bossLocations) do
            local drops = getDrops(bossType)
            for _, drop in pairs(drops) do
                if drop and drop.Parent then
                    local dropPos = drop:IsA("Model") and drop:GetPivot().Position or drop.Position
                    teleportTo(dropPos)
                    wait(0.3)
                end
            end
        end
        
        OrionLib:MakeNotification({
            Name = "Succès",
            Content = "Tous les drops collectés !",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

CollectTab:AddSection({
    Name = "Drops Disponibles"
})

CollectTab:AddButton({
    Name = "🔄 Scanner les drops",
    Callback = function()
        local totalDrops = 0
        for bossType, _ in pairs(bossLocations) do
            local drops = getDrops(bossType)
            totalDrops = totalDrops + #drops
        end
        
        OrionLib:MakeNotification({
            Name = "Scan Terminé",
            Content = totalDrops .. " drops trouvés !",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

-- Onglet Paramètres
SettingsTab:AddSection({
    Name = "Paramètres Généraux"
})

SettingsTab:AddSlider({
    Name = "Vitesse de marche",
    Min = 16,
    Max = 120,
    Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    Callback = function(Value)
        hum.WalkSpeed = Value
    end
})

SettingsTab:AddSlider({
    Name = "Force de saut",
    Min = 50,
    Max = 200,
    Default = 100,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    Callback = function(Value)
        hum.JumpPower = Value
    end
})

SettingsTab:AddToggle({
    Name = "No Clip (Traverser les murs)",
    Default = false,
    Callback = function(Value)
        if Value then
            spawn(function()
                while Value do
                    for _, part in pairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                    wait(1)
                end
            end)
        end
    end
})

SettingsTab:AddSection({
    Name = "Informations"
})

SettingsTab:AddLabel("Développé par : VotreNom")
SettingsTab:AddLabel("Version : 1.0")
SettingsTab:AddLabel("Jeu : Sorcerer Tycoon")

-- Gestion du personnage
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hum = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
end)

-- Notifications de démarrage
OrionLib:MakeNotification({
    Name = "Script Chargé",
    Content = "Sorcerer Tycoon Farm est prêt !",
    Image = "rbxassetid://4483345998",
    Time = 5
})

-- Initialisation
print("✅ Sorcerer Tycoon Ultimate Farm chargé !")
print("📌 Utilise l'interface pour configurer le farm")

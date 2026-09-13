-- EWH 0.2 | Eastern War 2.5 Script

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local IsRunning = true 

-- [ REAL-WORLD BALLISTICS DATA ]
local WeaponProfiles = {
    ["m4-urgi"] = { MuzzleVelocity = 880, Gravity = 35.02, Compatible = true },
    ["svdm"] = { MuzzleVelocity = 830, Gravity = 35.02, Compatible = true },
    ["default"] = { MuzzleVelocity = 800, Gravity = 35.02, Compatible = false }
}

-- [ GLOBAL CONFIGURATION ]
local Config = {
    Aimbot = {
        Enabled = false, 
        Prediction = true, 
        TeamCheck = true,
        ShowFOV = false,
        FOVRadius = 100,
        Smoothness = 1,
        Priority = "Head", 
        Compatibility = {
            ["m4-urgi"] = true,
            ["svdm"] = true
        }
    },
    ESP = {
        Enabled = false,
        Highlight = true,
        TeamCheck = true,
        HUD = true,
        ShowHP = true,
        ShowDistance = true,
        ShowSpeed = true,
        ShowDirection = true
    },
    Settings = {
        DistanceUnit = "Studs", 
        SpeedUnit = "Studs/s",
        MaxHighlights = 7
    },
    Visuals = {
        AccentColor = Color3.fromRGB(180, 0, 255),
        MenuVisible = true
    }
}

---------------------------------------------------------
-- [ CORE UTILITIES ]
---------------------------------------------------------
local function tweenObj(obj, properties, duration)
    if not obj then return end
    local info = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, info, properties)
    tween:Play()
    return tween
end

local function isVisible(targetPart)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

local function formatDistance(studs)
    if Config.Settings.DistanceUnit == "Meters" then
        return string.format("%.1f m", studs / 3.57)
    else
        return math.floor(studs) .. " studs"
    end
end

local function formatSpeed(studsPerSec)
    if Config.Settings.SpeedUnit == "KMH" then
        local kmh = (studsPerSec * 3.6) / 3.57
        return string.format("%.1f km/h", kmh)
    else
        return string.format("%.1f s/s", studsPerSec)
    end
end

local function getDirectionArrow(targetHRP)
    if not targetHRP then return "❓" end
    local relativeVel = Camera.CFrame:VectorToObjectSpace(targetHRP.Velocity)
    local x, z = relativeVel.X, relativeVel.Z
    local horizontal, vertical = "", ""
    if z > 2 then vertical = "⬇️" elseif z < -2 then vertical = "⬆️" end
    if x > 2 then horizontal = "➡️" elseif x < -2 then horizontal = "⬅️" end
    if horizontal == "" and vertical == "" then return "🛑" end
    return vertical .. horizontal
end

---------------------------------------------------------
-- [ BALLISTICS ENGINE ]
---------------------------------------------------------
local function GetBallisticOffset(weaponName, distance)
    local profile = WeaponProfiles[weaponName:lower()] or WeaponProfiles["default"]
    local velocityStuds = profile.MuzzleVelocity * 3.57
    local timeOfFlight = distance / velocityStuds
    local drop = 0.5 * profile.Gravity * (timeOfFlight ^ 2)
    return drop
end

---------------------------------------------------------
-- [ UI CONSTRUCTION ]
---------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EWH_Hub_V02_Fixed"
screenGui.ResetOnSpawn = false
local success_gui = pcall(function() screenGui.Parent = CoreGui end)
if not success_gui then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 520, 0, 400)
mainFrame.Position = UDim2.new(0.5, -260, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)

local glassLayer = Instance.new("Frame")
glassLayer.Size = UDim2.new(1, -130, 1, -40)
glassLayer.Position = UDim2.new(0, 130, 0, 40)
glassLayer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
glassLayer.BackgroundTransparency = 0.4 
glassLayer.BorderSizePixel = 0
glassLayer.Parent = mainFrame
Instance.new("UICorner", glassLayer).CornerRadius = UDim.new(0, 12)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 15)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -100, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "EWH 0.2 Beta"
titleText.TextColor3 = Config.Visuals.AccentColor
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 18
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local expandBtn = Instance.new("TextButton")
expandBtn.Size = UDim2.new(0, 35, 0, 35)
expandBtn.Position = UDim2.new(1, -40, 0, 2)
expandBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
expandBtn.Text = "—"
expandBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
expandBtn.Font = Enum.Font.GothamBold
expandBtn.TextSize = 20
expandBtn.Parent = titleBar
Instance.new("UICorner", expandBtn).CornerRadius = UDim.new(0, 8)

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(0, 130, 1, -40)
tabContainer.Position = UDim2.new(0, 0, 0, 40)
tabContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame
local tabListLayout = Instance.new("UIListLayout")
tabListLayout.Padding = UDim.new(0, 5)
tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabListLayout.Parent = tabContainer

local pagesContainer = Instance.new("Frame")
pagesContainer.Size = UDim2.new(1, -130, 1, -40)
pagesContainer.Position = UDim2.new(0, 130, 0, 40)
pagesContainer.BackgroundTransparency = 1
pagesContainer.Parent = mainFrame

local pages = {}
local buttons = {}

local function createTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(150, 150, 160)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.LayoutOrder = order
    btn.Parent = tabContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.Visible = false
    page.Parent = pagesContainer
    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = page
    
    pages[name] = page
    buttons[name] = btn
    btn.MouseButton1Click:Connect(function()
        for pageName, p in pairs(pages) do
            p.Visible = (pageName == name)
            local targetColor = (pageName == name) and Config.Visuals.AccentColor or Color3.fromRGB(30, 30, 35)
            local targetTextColor = (pageName == name) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
            tweenObj(buttons[pageName], {BackgroundColor3 = targetColor, TextColor3 = targetTextColor}, 0.2)
        end
    end)
    return page
end

local aimbotPage = createTab("Aimbot", 1)
local espPage = createTab("ESP", 2)
local configPage = createTab("Config", 3)
local logPage = createTab("Update Log", 4)
local profilePage = createTab("Perfil", 5)

pages["Aimbot"].Visible = true
buttons["Aimbot"].BackgroundColor3 = Config.Visuals.AccentColor
buttons["Aimbot"].TextColor3 = Color3.fromRGB(255, 255, 255)

-- [ AIMBOT CONTENT ]
local prioFrame = Instance.new("Frame")
prioFrame.Size = UDim2.new(1, -20, 0, 50)
prioFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
prioFrame.Parent = aimbotPage
Instance.new("UICorner", prioFrame).CornerRadius = UDim.new(0, 8)

local prioLabel = Instance.new("TextLabel")
prioLabel.Size = UDim2.new(0, 120, 1, 0)
prioLabel.Position = UDim2.new(0, 12, 0, 0)
prioLabel.BackgroundTransparency = 1
prioLabel.Text = "Target Priority"
prioLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
prioLabel.Font = Enum.Font.GothamSemibold
prioLabel.TextSize = 14
prioLabel.TextXAlignment = Enum.TextXAlignment.Left
prioLabel.Parent = prioFrame

local selectorBg = Instance.new("Frame")
selectorBg.Size = UDim2.new(0, 180, 0, 24)
selectorBg.Position = UDim2.new(1, -192, 0.5, -12)
selectorBg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
selectorBg.Parent = prioFrame
Instance.new("UICorner", selectorBg).CornerRadius = UDim.new(0, 12)

local selectorBall = Instance.new("Frame")
selectorBall.Size = UDim2.new(0, 22, 0, 22)
selectorBall.Position = UDim2.new(0, 1, 0, 1)
selectorBall.BackgroundColor3 = Config.Visuals.AccentColor
selectorBall.Parent = selectorBg
Instance.new("UICorner", selectorBall).CornerRadius = UDim.new(1, 0)

local headBtn = Instance.new("TextButton")
headBtn.Size = UDim2.new(0.5, 0, 1, 0)
headBtn.BackgroundTransparency = 1
headBtn.Text = "Head"
headBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
headBtn.Font = Enum.Font.Gotham
headBtn.TextSize = 12
headBtn.Parent = selectorBg

local torsoBtn = Instance.new("TextButton")
torsoBtn.Size = UDim2.new(0.5, 0, 1, 0)
torsoBtn.Position = UDim2.new(0.5, 0, 0, 0)
torsoBtn.BackgroundTransparency = 1
torsoBtn.Text = "Torso"
torsoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
torsoBtn.Font = Enum.Font.Gotham
torsoBtn.TextSize = 12
torsoBtn.Parent = selectorBg

headBtn.MouseButton1Click:Connect(function()
    Config.Aimbot.Priority = "Head"
    tweenObj(selectorBall, {Position = UDim2.new(0, 1, 0, 1)}, 0.2)
end)
torsoBtn.MouseButton1Click:Connect(function()
    Config.Aimbot.Priority = "Torso"
    tweenObj(selectorBall, {Position = UDim2.new(0.5, 1, 0, 1)}, 0.2)
end)

local weaponInfo = Instance.new("TextLabel")
weaponInfo.Size = UDim2.new(1, -20, 0, 30)
weaponInfo.Position = UDim2.new(0, 10, 0, 60)
weaponInfo.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
weaponInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
weaponInfo.Font = Enum.Font.GothamSemibold
weaponInfo.TextSize = 13
weaponInfo.Text = "Detecting Weapon..."
weaponInfo.Parent = aimbotPage
Instance.new("UICorner", weaponInfo).CornerRadius = UDim.new(0, 6)

local function createToggle(parentPage, text, configCategory, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    frame.BorderSizePixel = 0
    frame.Parent = parentPage
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = text
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 45, 0, 22)
    toggleBtn.Position = UDim2.new(1, -57, 0.5, -11)
    local isOn = Config[configCategory][configKey]
    toggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(180, 60, 60)
    toggleBtn.Text = isOn and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 11
    toggleBtn.Parent = frame
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        Config[configCategory][configKey] = isOn
        local targetColor = isOn and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(180, 60, 60)
        tweenObj(toggleBtn, {BackgroundColor3 = targetColor}, 0.2)
        toggleBtn.Text = isOn and "ON" or "OFF"
    end)
end

local function createSlider(parentPage, text, configCategory, configKey, min, max)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    frame.BorderSizePixel = 0
    frame.Parent = parentPage
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, 0, 0, 25)
    title.Position = UDim2.new(0, 12, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = text .. ": " .. tostring(Config[configCategory][configKey])
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0.9, 0, 0, 6)
    sliderBg.Position = UDim2.new(0.05, 0, 0, 40)
    sliderBg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    local sliderFill = Instance.new("Frame")
    local fillPct = (Config[configCategory][configKey] - min) / (max - min)
    sliderFill.Size = UDim2.new(fillPct, 0, 1, 0)
    sliderFill.BackgroundColor3 = Config.Visuals.AccentColor
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(1, 0, 1, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.Parent = sliderBg
    local dragging = false
    sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation().X
            local sliderPos = sliderBg.AbsolutePosition.X
            local sliderSize = sliderBg.AbsoluteSize.X
            local pct = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
            local val = math.floor(min + ((max - min) * pct))
            Config[configCategory][configKey] = val
            title.Text = text .. ": " .. tostring(val)
            tweenObj(sliderFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.05)
        end
    end)
end

createToggle(aimbotPage, "Enable Aimbot", "Aimbot", "Enabled")
createToggle(aimbotPage, "Prediction", "Aimbot", "Prediction")
createSlider(aimbotPage, "FOV Radius", "Aimbot", "FOVRadius", 10, 500)

-- [ ESP PAGE - NEW LAYOUT ]
createToggle(espPage, "ESP", "ESP", "Enabled")
createToggle(espPage, "Team Check", "ESP", "TeamCheck")

-- Highlight Section
local highlightTitle = Instance.new("TextLabel")
highlightTitle.Size = UDim2.new(1, -20, 0, 25)
highlightTitle.BackgroundTransparency = 1
highlightTitle.Text = "Highlight System"
highlightTitle.TextColor3 = Config.Visuals.AccentColor
highlightTitle.Font = Enum.Font.GothamBold
highlightTitle.TextSize = 13
highlightTitle.TextXAlignment = Enum.TextXAlignment.Left
highlightTitle.Parent = espPage

createToggle(espPage, "Highlight", "ESP", "Highlight")

-- HUD Section
local hudTitle = Instance.new("TextLabel")
hudTitle.Size = UDim2.new(1, -20, 0, 25)
hudTitle.BackgroundTransparency = 1
hudTitle.Text = "Target HUD"
hudTitle.TextColor3 = Config.Visuals.AccentColor
hudTitle.Font = Enum.Font.GothamBold
hudTitle.TextSize = 13
hudTitle.TextXAlignment = Enum.TextXAlignment.Left
hudTitle.Parent = espPage

createToggle(espPage, "Show HUD", "ESP", "HUD")
createToggle(espPage, "Show HP", "ESP", "ShowHP")
createToggle(espPage, "Show Distance", "ESP", "ShowDistance")
createToggle(espPage, "Show Speed", "ESP", "ShowSpeed")
createToggle(espPage, "Show Direction", "ESP", "ShowDirection")

-- [ CONFIG PAGE ]
local configTitle = Instance.new("TextLabel")
configTitle.Size = UDim2.new(1, -20, 0, 30)
configTitle.Position = UDim2.new(0, 10, 0, 10)
configTitle.BackgroundTransparency = 1
configTitle.Text = "General Settings"
configTitle.TextColor3 = Config.Visuals.AccentColor
configTitle.Font = Enum.Font.GothamBold
configTitle.TextSize = 16
configTitle.TextXAlignment = Enum.TextXAlignment.Left
configTitle.Parent = configPage

local function createUnitSelector(parent, text, configKey, option1, option2)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 24)
    btn.Position = UDim2.new(1, -92, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    btn.Text = Config.Settings[configKey]
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(function()
        Config.Settings[configKey] = (Config.Settings[configKey] == option1) and option2 or option1
        btn.Text = Config.Settings[configKey]
    end)
end

createUnitSelector(configPage, "Distance Unit", "DistanceUnit", "Studs", "Meters")
createUnitSelector(configPage, "Speed Unit", "SpeedUnit", "Studs/s", "KMH")

local logText = Instance.new("TextLabel")
logText.Size = UDim2.new(1, -20, 1, -20)
logText.Position = UDim2.new(0, 10, 0, 10)
logText.BackgroundTransparency = 1
logText.TextColor3 = Color3.fromRGB(180, 180, 190)
logText.Font = Enum.Font.Gotham
logText.TextSize = 14
logText.TextWrapped = true
logText.TextXAlignment = Enum.TextXAlignment.Left
logText.TextYAlignment = Enum.TextYAlignment.Top
logText.Text = "v0.2 Beta - ESP Overhaul:\n\n- ADDED: Highlight system (7 closest targets).\n- ADDED: Dynamic Target HUD with customizable info.\n- ADDED: Configurable HUD display options.\n- IMPROVED: FOV visualization (white → red → purple).\n- REMOVED: Skeleton, Box, and Tracer ESP."
logText.Parent = logPage

expandBtn.MouseButton1Click:Connect(function()
    if mainFrame.Size.Y.Offset == 400 then
        tweenObj(mainFrame, {Size = UDim2.new(0, 520, 0, 40)}, 0.3)
        pagesContainer.Visible = false; tabContainer.Visible = false
    else
        tweenObj(mainFrame, {Size = UDim2.new(0, 520, 0, 400)}, 0.3)
        pagesContainer.Visible = true; tabContainer.Visible = true
    end
end)

UserInputService.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.Insert then 
        Config.Visuals.MenuVisible = not Config.Visuals.MenuVisible
        mainFrame.Visible = Config.Visuals.MenuVisible
    end
end)

---------------------------------------------------------
-- [ TACTICAL HUD SYSTEM ]
---------------------------------------------------------
local TargetHUD = Instance.new("Frame")
TargetHUD.Size = UDim2.new(0, 180, 0, 120)
TargetHUD.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TargetHUD.BackgroundTransparency = 0.3
TargetHUD.BorderSizePixel = 0
TargetHUD.Visible = false
TargetHUD.Parent = screenGui
Instance.new("UICorner", TargetHUD).CornerRadius = UDim.new(0, 10)

local HUDStroke = Instance.new("UIStroke")
HUDStroke.Thickness = 1.5
HUDStroke.Color = Config.Visuals.AccentColor
HUDStroke.Parent = TargetHUD

local HUDLayout = Instance.new("UIListLayout")
HUDLayout.Padding = UDim.new(0, 4)
HUDLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
HUDLayout.Parent = TargetHUD

local function createHUDLabel(text, size, bold)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.TextSize = size
    label.Parent = TargetHUD
    return label
end

local HUD_Name = createHUDLabel("Target: ---", 14, true)
local HUD_HP = createHUDLabel("HP: ---", 13, false)
local HUD_HPBar = Instance.new("Frame")
HUD_HPBar.Size = UDim2.new(0.8, 0, 0, 8)
HUD_HPBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
HUD_HPBar.Parent = TargetHUD
Instance.new("UICorner", HUD_HPBar).CornerRadius = UDim.new(0, 3)

local HUD_HPFill = Instance.new("Frame")
HUD_HPFill.Size = UDim2.new(1, 0, 1, 0)
HUD_HPFill.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
HUD_HPFill.BorderSizePixel = 0
HUD_HPFill.Parent = HUD_HPBar
Instance.new("UICorner", HUD_HPFill).CornerRadius = UDim.new(0, 3)

local HUD_Dist = createHUDLabel("Dist: ---", 12, false)
local HUD_Speed = createHUDLabel("Speed: ---", 12, false)
local HUD_Dir = createHUDLabel("Dir: ---", 14, true)

---------------------------------------------------------
-- [ HIGHLIGHT SYSTEM ]
---------------------------------------------------------
local HighlightedPlayers = {}

local function removeHighlight(player)
    if HighlightedPlayers[player] then
        local highlight = HighlightedPlayers[player]
        highlight:Destroy()
        HighlightedPlayers[player] = nil
    end
end

local function addHighlight(player)
    if not player.Character then return end
    removeHighlight(player)
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = player.Character
    highlight.FillColor = Config.Visuals.AccentColor
    highlight.FillTransparency = 0.45
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.Always
    
    HighlightedPlayers[player] = highlight
end

local function updateHighlights()
    if not Config.ESP.Enabled or not Config.ESP.Highlight then
        for player, _ in pairs(HighlightedPlayers) do
            removeHighlight(player)
        end
        return
    end
    
    local playerDistances = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if Config.ESP.TeamCheck and player.Team == LocalPlayer.Team then continue end
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                table.insert(playerDistances, {player = player, distance = dist})
            end
        end
    end
    
    table.sort(playerDistances, function(a, b) return a.distance < b.distance end)
    
    local highlightCount = 0
    for _, data in ipairs(playerDistances) do
        if highlightCount >= Config.Settings.MaxHighlights then break end
        if not HighlightedPlayers[data.player] then
            addHighlight(data.player)
        end
        highlightCount = highlightCount + 1
    end
    
    for player, _ in pairs(HighlightedPlayers) do
        local found = false
        for _, data in ipairs(playerDistances) do
            if data.player == player then
                found = true
                break
            end
        end
        if not found then
            removeHighlight(player)
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

---------------------------------------------------------
-- [ DRAWING SYSTEMS ]
---------------------------------------------------------
local FovCircle = (Drawing and Drawing.new("Circle")) or nil
if FovCircle then 
    FovCircle.Thickness = 2
    FovCircle.Filled = false
end

local TargetMarker = (Drawing and Drawing.new("Circle")) or nil
if TargetMarker then 
    TargetMarker.Radius = 4
    TargetMarker.Thickness = 2
    TargetMarker.Filled = true
    TargetMarker.Visible = false
end

local function getEntityColor(player)
    if Config.ESP.TeamCheck and player.Team then
        return (LocalPlayer.Team == player.Team) and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    end
    return Color3.fromRGB(255, 255, 255)
end

local function getBestPart(character)
    if not character then return nil end
    local priority = Config.Aimbot.Priority
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local head = character:FindFirstChild("Head")
    if priority == "Torso" then
        if torso and isVisible(torso) then return torso end
        if head and isVisible(head) then return head end
    else
        if head and isVisible(head) then return head end
        if torso and isVisible(torso) then return torso end
    end
    return head or torso
end

local function getClosestPlayer()
    local target = nil
    local shortestDistance = Config.Aimbot.FOVRadius
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            if Config.Aimbot.TeamCheck and v.Team == LocalPlayer.Team then continue end
            local targetPart = getBestPart(v.Character)
            if targetPart then
                local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if dist < shortestDistance then target = v; shortestDistance = dist end
                end
            end
        end
    end
    return target
end

---------------------------------------------------------
-- [ MAIN LOOP ]
---------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not IsRunning then return end
    
    local equippedTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if equippedTool then
        local weaponName = equippedTool.Name:lower()
        local profile = WeaponProfiles[weaponName] or WeaponProfiles["default"]
        local isCompatible = profile.Compatible
        weaponInfo.Text = "Weapon: " .. equippedTool.Name .. " | Intelligent: " .. (isCompatible and "YES" or "NO")
    else
        weaponInfo.Text = "No Weapon Equipped"
    end

    updateHighlights()

    local target = getClosestPlayer()
    
    if target and target.Character and Config.ESP.HUD then
        local part = getBestPart(target.Character)
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if part and hrp then
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                TargetHUD.Visible = true
                
                -- Dynamic positioning
                local hudOffsetX = math.random(-50, 50)
                local hudOffsetY = math.random(-30, 30)
                TargetHUD.Position = UDim2.new(0, pos.X + 20 + hudOffsetX, 0, pos.Y - 45 + hudOffsetY)
                
                local distVal = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude or 0
                
                HUD_Name.Text = "Target: " .. target.Name
                
                if Config.ESP.ShowHP then
                    local healthPct = target.Character.Humanoid.Health / target.Character.Humanoid.MaxHealth
                    HUD_HP.Text = string.format("HP: %.0f/%.0f", target.Character.Humanoid.Health, target.Character.Humanoid.MaxHealth)
                    local barColor = Color3.fromHSV(healthPct * 0.3, 1, 1)
                    tweenObj(HUD_HPFill, {Size = UDim2.new(math.clamp(healthPct, 0, 1), 0, 1, 0), BackgroundColor3 = barColor}, 0.1)
                    HUD_HPBar.Visible = true
                    HUD_HP.Visible = true
                else
                    HUD_HPBar.Visible = false
                    HUD_HP.Visible = false
                end
                
                if Config.ESP.ShowDistance then
                    HUD_Dist.Text = "Dist: " .. formatDistance(distVal)
                    HUD_Dist.Visible = true
                else
                    HUD_Dist.Visible = false
                end
                
                if Config.ESP.ShowSpeed then
                    HUD_Speed.Text = "Speed: " .. formatSpeed(hrp.Velocity.Magnitude)
                    HUD_Speed.Visible = true
                else
                    HUD_Speed.Visible = false
                end
                
                if Config.ESP.ShowDirection then
                    HUD_Dir.Text = "Dir: " .. getDirectionArrow(hrp)
                    HUD_Dir.Visible = true
                else
                    HUD_Dir.Visible = false
                end
            else
                TargetHUD.Visible = false
            end
        else
            TargetHUD.Visible = false
        end
    else
        TargetHUD.Visible = false
    end

    if FovCircle then
        FovCircle.Position = UserInputService:GetMouseLocation()
        FovCircle.Radius = Config.Aimbot.FOVRadius
        FovCircle.Visible = Config.Aimbot.ShowFOV
        
        if not target then
            FovCircle.Color = Color3.fromRGB(255, 255, 255)
        elseif getBestPart(target.Character) and isVisible(getBestPart(target.Character)) then
            FovCircle.Color = Config.Visuals.AccentColor
        else
            FovCircle.Color = Color3.fromRGB(255, 50, 50)
        end
    end

    if Config.Aimbot.Enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if target and target.Character then
            local targetPart = getBestPart(target.Character)
            if targetPart then
                local aimPos = targetPart.Position
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                local toolName = tool and tool.Name:lower() or "default"
                local profile = WeaponProfiles[toolName] or WeaponProfiles["default"]
                if Config.Aimbot.Prediction then
                    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = (aimPos - Camera.CFrame.Position).Magnitude
                        local velStuds = profile.MuzzleVelocity * 3.57
                        local timeToTarget = dist / velStuds
                        aimPos = aimPos + (hrp.Velocity * timeToTarget)
                    end
                end
                if profile.Compatible then
                    local finalDist = (aimPos - Camera.CFrame.Position).Magnitude
                    local drop = GetBallisticOffset(toolName, finalDist)
                    aimPos = aimPos + Vector3.new(0, drop, 0)
                end
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPos), math.clamp(1 / Config.Aimbot.Smoothness, 0.05, 1))
            end
        end
    end
end)

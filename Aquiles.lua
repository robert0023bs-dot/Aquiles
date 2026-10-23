--[========================================================================]--
--  Script: Aquiles v2.0 (Corrigido e Otimizado)
--[========================================================================]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if not Drawing then
    warn("[Aquiles] AVISO: A Drawing API não está disponível. O ESP não funcionará.")
end

--------------------------------------------------------------------------------
-- [ MÓDULO 1: UTILS & NOTIFICAÇÕES ]
--------------------------------------------------------------------------------
local Utils = {}
function Utils.CreateNotification(title, text, duration)
    duration = duration or 3
    task.spawn(function()
        local notifGui = CoreGui:FindFirstChild("AquilesNotifs")
        if not notifGui then
            notifGui = Instance.new("ScreenGui")
            notifGui.Name = "AquilesNotifs"
            notifGui.ResetOnSpawn = false
            notifGui.Parent = CoreGui
        end
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 240, 0, 60)
        frame.Position = UDim2.new(1, -260, 1, -80)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        frame.BorderSizePixel = 0
        frame.Parent = notifGui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(138, 43, 226)
        stroke.Thickness = 1.5
        stroke.Parent = frame

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -20, 0, 22)
        titleLabel.Position = UDim2.new(0, 10, 0, 5)
        titleLabel.BackgroundTransparency = 1
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 14
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Text = title
        titleLabel.Parent = frame

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -20, 0, 25)
        textLabel.Position = UDim2.new(0, 10, 0, 27)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
        textLabel.TextSize = 12
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Text = text
        textLabel.Parent = frame
        task.wait(duration)
        frame:Destroy()
    end)
end

--------------------------------------------------------------------------------
-- [ MÓDULO 2: CONFIGURAÇÕES ]
--------------------------------------------------------------------------------
local Config = {
    UIKeybind = Enum.KeyCode.RightShift,
    ESP = { Enabled = true, MaxDistance = 1000, Box = true, Names = true, Distance = true, Tracers = true, HealthBar = true },
    Aim = { Enabled = false, Key = Enum.UserInputType.MouseButton2, FOV = 120, Smoothness = 5, Prediction = true, WallCheck = true, TargetPart = "Head", Priority = "Assassino" },
    ItemsESP = { Enabled = true },
    Misc = { Fullbright = false }
}

--------------------------------------------------------------------------------
-- [ MÓDULO 3: FUNÇÕES AUXILIARES ]
--------------------------------------------------------------------------------
function GetPlayerRole(player)
    if not player.Character then return "Inocente", Color3.fromRGB(50, 255, 50) end
    local backpack = player:FindFirstChildOfClass("Backpack")
    local char = player.Character
    
    local hasGun = (char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")))
    local hasKnife = (char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife")))
    local hasHero = (char:FindFirstChild("Hero") or (backpack and backpack:FindFirstChild("Hero")))
    
    if hasHero then return "Herói", Color3.fromRGB(255, 255, 0)
    elseif hasKnife then return "Assassino", Color3.fromRGB(255, 50, 50)
    elseif hasGun then return "Policial", Color3.fromRGB(50, 120, 255)
    else return "Inocente", Color3.fromRGB(50, 255, 50) end
end

--------------------------------------------------------------------------------
-- [ MÓDULO 4: ESP DE JOGADORES ]
--------------------------------------------------------------------------------
local ESPModule = {}
local espCache = {}

Players.PlayerRemoving:Connect(function(player)
    if espCache[player] then
        for _, obj in pairs(espCache[player]) do
            pcall(function() obj:Remove() end)
        end
        espCache[player] = nil
    end
end)

function ESPModule.Update()
    if not Drawing then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local char = player.Character
            local hrp = char.HumanoidRootPart
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude

            if not espCache[player] then
                espCache[player] = {
                    Box = Drawing.new("Square"), Name = Drawing.new("Text"),
                    Tracer = Drawing.new("Line"), HealthBarBg = Drawing.new("Square"),
                    HealthBar = Drawing.new("Square")
                }
                local d = espCache[player]
                d.Box.Filled = false; d.Box.Thickness = 1
                d.Name.Size = 13; d.Name.Center = true; d.Name.Outline = true; d.Name.Color = Color3.new(1,1,1)
                d.Tracer.Thickness = 1
                d.HealthBarBg.Filled = true; d.HealthBarBg.Color = Color3.new(0,0,0)
                d.HealthBar.Filled = true
            end

            local drawings = espCache[player]
            local role, roleColor = GetPlayerRole(player)

            if Config.ESP.Enabled and onScreen and dist <= Config.ESP.MaxDistance then
                local head = char:FindFirstChild("Head")
                local topPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or pos
                local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local height = math.abs(topPos.Y - bottomPos.Y)
                local width = height / 2

                drawings.Box.Visible = Config.ESP.Box
                if Config.ESP.Box then
                    drawings.Box.Size = Vector2.new(width, height)
                    drawings.Box.Position = Vector2.new(pos.X - width / 2, topPos.Y)
                    drawings.Box.Color = roleColor
                end

                drawings.Name.Visible = Config.ESP.Names
                if Config.ESP.Names then
                    drawings.Name.Position = Vector2.new(pos.X, topPos.Y - 16)
                    local textStr = player.Name .. " [" .. role .. "]"
                    if Config.ESP.Distance then textStr = textStr .. " (" .. math.floor(dist) .. "m)" end
                    drawings.Name.Text = textStr
                end

                drawings.Tracer.Visible = Config.ESP.Tracers
                if Config.ESP.Tracers then
                    drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    drawings.Tracer.To = Vector2.new(pos.X, bottomPos.Y)
                    drawings.Tracer.Color = roleColor
                end

                drawings.HealthBarBg.Visible = Config.ESP.HealthBar
                drawings.HealthBar.Visible = Config.ESP.HealthBar
                if Config.ESP.HealthBar and humanoid then
                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local barHeight = height * healthPercent
                    drawings.HealthBarBg.Size = Vector2.new(3, height + 2)
                    drawings.HealthBarBg.Position = Vector2.new(pos.X - width / 2 - 6, topPos.Y - 1)
                    drawings.HealthBar.Size = Vector2.new(1, barHeight)
                    drawings.HealthBar.Position = Vector2.new(pos.X - width / 2 - 5, topPos.Y + (height - barHeight))
                    drawings.HealthBar.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), 1 - healthPercent)
                end
            else
                for _, obj in pairs(drawings) do obj.Visible = false end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- [ MÓDULO 5: ESP DE ITENS ]
--------------------------------------------------------------------------------
local itemCache = {}
function UpdateItemESP()
    if not Drawing or not Config.ItemsESP.Enabled then
        for obj, drawing in pairs(itemCache) do drawing.Visible = false end
        return
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "Gun" or obj.Name == "Knife") and not obj:IsDescendantOf(LocalPlayer.Character) then
            if not itemCache[obj] then
                itemCache[obj] = Drawing.new("Text")
                itemCache[obj].Size = 13
                itemCache[obj].Center = true
                itemCache[obj].Outline = true
            end
            
            local pos, onScreen = Camera:WorldToViewportPoint(obj.Position)
            local dist = (Camera.CFrame.Position - obj.Position).Magnitude
            
            if onScreen and dist <= Config.ESP.MaxDistance then
                local d = itemCache[obj]
                d.Visible = true
                d.Position = Vector2.new(pos.X, pos.Y)
                d.Text = "[" .. obj.Name .. "] " .. math.floor(dist) .. "m"
                d.Color = (obj.Name == "Gun") and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 150, 0)
            else
                if itemCache[obj] then itemCache[obj].Visible = false end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- [ MÓDULO 6: AIMBOT ]
--------------------------------------------------------------------------------
local AimModule = {}
local fovCircle = Drawing.new("Circle")
fovCircle.Filled = false; fovCircle.Thickness = 1.5; fovCircle.Color = Color3.fromRGB(138, 43, 226)

function AimModule.GetTarget()
    local bestTarget = nil
    local shortestDistance = Config.Aim.FOV
    local priorityOrder = { Assassino = 1, Policial = 2, Herói = 3, Inocente = 4 }

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            
            if humanoid and humanoid.Health > 0 and hrp then
                local role, _ = GetPlayerRole(player)
                local targetPart = char:FindFirstChild(Config.Aim.TargetPart) or hrp
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    
                    local canSee = true
                    if Config.Aim.WallCheck then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        local ray = Workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), rayParams)
                        if ray then canSee = false end
                    end

                    if canSee then
                        local priorityBonus = (role == Config.Aim.Priority) and -50 or 0
                        local score = distToMouse + priorityBonus

                        if score < shortestDistance then
                            shortestDistance = score
                            bestTarget = targetPart
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

function AimModule.Update()
    if not Drawing then return end
    fovCircle.Visible = Config.Aim.Enabled
    fovCircle.Radius = Config.Aim.FOV
    fovCircle.Position = UserInputService:GetMouseLocation()

    if Config.Aim.Enabled and UserInputService:IsMouseButtonPressed(Config.Aim.Key) then
        local target = AimModule.GetTarget()
        if target then
            local targetPos = target.Position
            if Config.Aim.Prediction and target.Parent:FindFirstChild("HumanoidRootPart") then
                targetPos = targetPos + (target.Parent.HumanoidRootPart.Velocity * 0.065)
            end
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), 1 / Config.Aim.Smoothness)
        end
    end
end

--------------------------------------------------------------------------------
-- [ MÓDULO 7: INTERFACE GRÁFICA (UI) ]
--------------------------------------------------------------------------------
local UIModule = {}

function UIModule.Init()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AquilesHub"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 520, 0, 360)
    mainFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
    
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Color3.fromRGB(138, 43, 226)
    mainStroke.Thickness = 1.5

    local topBar = Instance.new("Frame", mainFrame)
    topBar.Size = UDim2.new(1, 0, 0, 35)
    topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    topBar.BorderSizePixel = 0
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

    local titleLabel = Instance.new("TextLabel", topBar)
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "⚡ AQUILES | Murder Mystery 2"

    local closeBtn = Instance.new("TextButton", topBar)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 2)
    closeBtn.BackgroundTransparency = 1
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeBtn.TextSize = 16; closeBtn.Font = Enum.Font.GothamBold; closeBtn.Text = "X"

    local reopenBtn = Instance.new("TextButton", screenGui)
    reopenBtn.Size = UDim2.new(0, 110, 0, 35)
    reopenBtn.Position = UDim2.new(0, 20, 0.5, -15)
    reopenBtn.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    reopenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    reopenBtn.Font = Enum.Font.GothamBold; reopenBtn.TextSize = 13
    reopenBtn.Text = "⚡ Abrir Aquiles"
    reopenBtn.Visible = false
    Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 6)

    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        reopenBtn.Visible = true
    end)
    reopenBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        reopenBtn.Visible = false
    end)

    local sidebar = Instance.new("Frame", mainFrame)
    sidebar.Size = UDim2.new(0, 130, 1, -35)
    sidebar.Position = UDim2.new(0, 0, 0, 35)
    sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
    sidebar.BorderSizePixel = 0

    local container = Instance.new("Frame", mainFrame)
    container.Size = UDim2.new(1, -140, 1, -45)
    container.Position = UDim2.new(0, 135, 0, 40)
    container.BackgroundTransparency = 1

    local tabs = {"Visual", "Aim", "Misc"}
    local tabButtons, tabPages = {}, {}

    for i, tabName in ipairs(tabs) do
        local btn = Instance.new("TextButton", sidebar)
        btn.Size = UDim2.new(1, -20, 0, 35)
        btn.Position = UDim2.new(0, 10, 0, 15 + (i - 1) * 45)
        btn.BackgroundColor3 = i == 1 and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(25, 25, 35)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13; btn.Font = Enum.Font.GothamBold; btn.Text = tabName
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        tabButtons[tabName] = btn

        local page = Instance.new("ScrollingFrame", container)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = (i == 1)
        page.CanvasSize = UDim2.new(0, 0, 0, 500)
        page.ScrollBarThickness = 4
        tabPages[tabName] = page

        btn.MouseButton1Click:Connect(function()
            for name, p in pairs(tabPages) do
                p.Visible = (name == tabName)
                tabButtons[name].BackgroundColor3 = (name == tabName) and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(25, 25, 35)
            end
        end)
    end

    local function CreateToggle(parent, title, default, callback)
        local count = 0
        for _ in pairs(parent:GetChildren()) do count = count + 1 end
        local yPos = count * 42

        local toggleFrame = Instance.new("Frame", parent)
        toggleFrame.Size = UDim2.new(1, -10, 0, 35)
        toggleFrame.Position = UDim2.new(0, 5, 0, yPos)
        toggleFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        toggleFrame.BorderSizePixel = 0
        Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 6)

        local label = Instance.new("TextLabel", toggleFrame)
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextSize = 13; label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = title

        local state = default
        local tBtn = Instance.new("TextButton", toggleFrame)
        tBtn.Size = UDim2.new(0, 40, 0, 20)
        tBtn.Position = UDim2.new(1, -45, 0.5, -10)
        tBtn.BackgroundColor3 = state and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(45, 45, 55)
        tBtn.Text = ""
        Instance.new("UICorner", tBtn).CornerRadius = UDim.new(1, 0)

        tBtn.MouseButton1Click:Connect(function()
            state = not state
            tBtn.BackgroundColor3 = state and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(45, 45, 55)
            callback(state)
        end)
    end

    local visualPage = tabPages["Visual"]
    CreateToggle(visualPage, "Ativar ESP Geral", Config.ESP.Enabled, function(v) Config.ESP.Enabled = v end)
    CreateToggle(visualPage, "Box 2D", Config.ESP.Box, function(v) Config.ESP.Box = v end)
    CreateToggle(visualPage, "Nome e Distância", Config.ESP.Names, function(v) Config.ESP.Names = v end)
    CreateToggle(visualPage, "Tracers (Linhas)", Config.ESP.Tracers, function(v) Config.ESP.Tracers = v end)
    CreateToggle(visualPage, "Barra de Vida", Config.ESP.HealthBar, function(v) Config.ESP.HealthBar = v end)
    CreateToggle(visualPage, "ESP de Itens (Armas no chão)", Config.ItemsESP.Enabled, function(v) Config.ItemsESP.Enabled = v end)

    local aimPage = tabPages["Aim"]
    CreateToggle(aimPage, "Ativar Aimbot", Config.Aim.Enabled, function(v) Config.Aim.Enabled = v end)
    CreateToggle(aimPage, "Previsão (Prediction)", Config.Aim.Prediction, function(v) Config.Aim.Prediction = v end)
    CreateToggle(aimPage, "WallCheck (Não passa parede)", Config.Aim.WallCheck, function(v) Config.Aim.WallCheck = v end)

    local miscPage = tabPages["Misc"]
    CreateToggle(miscPage, "Fullbright (Iluminação Max)", Config.Misc.Fullbright, function(v)
        Config.Misc.Fullbright = v
        Lighting.Brightness = v and 2 or 1
        Lighting.ClockTime = v and 14 or 12
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Config.UIKeybind then
            if mainFrame.Visible then
                mainFrame.Visible = false
                reopenBtn.Visible = true
            else
                mainFrame.Visible = true
                reopenBtn.Visible = false
            end
        end
    end)

    Utils.CreateNotification("Aquiles v2.0", "Script carregado e corrigido!", 4)
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        ESPModule.Update()
        UpdateItemESP()
        AimModule.Update()
    end)
end)

UIModule.Init()

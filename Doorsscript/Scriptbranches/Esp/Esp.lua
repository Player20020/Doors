local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Hub = getgenv().DoorsHub
if not Hub or not Hub.Tabs or not Hub.Tabs.Visuals then
    warn("[ESP] Ошибка: Не найдена вкладка Visuals в DoorsHub")
    return
end

local VisualsTab = Hub.Tabs.Visuals
local Camera = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

-- Настройки ESP
local espEnabled = true
local showMonsters = true
local showTraps = true

-- База данных сущностей и настроек отображения цветов
local MonsterConfig = {
    ["RushMoving"]   = { Name = "Rush", Color = Color3.fromRGB(255, 50, 50), Type = "Monster" },
    ["AmbushMoving"] = { Name = "Ambush", Color = Color3.fromRGB(0, 255, 120), Type = "Monster" },
    ["Eyes"]         = { Name = "Eyes", Color = Color3.fromRGB(160, 32, 240), Type = "Monster" },
    ["Screech"]      = { Name = "Screech", Color = Color3.fromRGB(50, 50, 50), Type = "Monster" },
    ["FigureRig"]    = { Name = "Figure", Color = Color3.fromRGB(180, 0, 0), Type = "Monster" },
    ["SeekMoving"]   = { Name = "Seek", Color = Color3.fromRGB(0, 0, 0), Type = "Monster" },
    ["Halt"]         = { Name = "Halt", Color = Color3.fromRGB(0, 200, 255), Type = "Monster" },
    ["Window"]       = { Name = "Sally", Color = Color3.fromRGB(255, 255, 255), Type = "Monster" },
    ["Snare"]        = { Name = "Snare (Шипы)", Color = Color3.fromRGB(200, 100, 0), Type = "Trap" },
    ["DoorFake"]     = { Name = "Dupe (Фейк)", Color = Color3.fromRGB(255, 0, 100), Type = "Trap" }
}

-- Хранилище активных объектов ESP
local trackedEntities = {}

-- Создание подсветки и 3D-текста над головой
local function applyESP(model, config)
    if not model or trackedEntities[model] then return end

    -- 1. Подсветка силуэта через стены
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = model
    highlight.FillColor = config.Color
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0.1
    highlight.Parent = model

    -- 2. Текстовая метка с дистанцией
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(0, 120, 0, 40)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Adornee = model:IsA("BasePart") and model or model:FindFirstChildWhichIsA("BasePart")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = config.Color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Text = config.Name
    label.Parent = billboard

    billboard.Parent = model

    trackedEntities[model] = {
        Highlight = highlight,
        Billboard = billboard,
        Label = label,
        Config = config
    }

    -- Удаление из таблицы при уничтожении объекта
    model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            trackedEntities[model] = nil
        end
    end)
end

-- Проверка и добавление сущности
local function checkCandidate(child)
    local config = MonsterConfig[child.Name]
    if config then
        applyESP(child, config)
    end
end

-- Обновление дистанции до монстра в реальном времени
RunService.RenderStepped:Connect(function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    for model, data in pairs(trackedEntities) do
        local isEnabled = espEnabled and (
            (data.Config.Type == "Monster" and showMonsters) or
            (data.Config.Type == "Trap" and showTraps)
        )

        data.Highlight.Enabled = isEnabled
        data.Billboard.Enabled = isEnabled

        if isEnabled and root then
            local mainPart = model:IsA("BasePart") and model or model:FindFirstChildWhichIsA("BasePart")
            if mainPart then
                local dist = math.floor((root.Position - mainPart.Position).Magnitude)
                data.Label.Text = string.format("%s\n[%d m]", data.Config.Name, dist)
            end
        end
    end
end)

-- Сканирование комнат (Dupe, Snare, Figure спавнятся внутри комнат)
local currentRooms = Workspace:WaitForChild("CurrentRooms")

local function scanRoomForEntities(room)
    for _, desc in ipairs(room:GetDescendants()) do
        checkCandidate(desc)
    end

    room.DescendantAdded:Connect(function(desc)
        checkCandidate(desc)
    end)
end

for _, room in ipairs(currentRooms:GetChildren()) do
    scanRoomForEntities(room)
end
currentRooms.ChildAdded:Connect(scanRoomForEntities)

-- Мониторинг появления динамических монстров (Rush, Ambush, Halt, Eyes)
Workspace.ChildAdded:Connect(checkCandidate)
Camera.ChildAdded:Connect(checkCandidate) -- Screech спавнится внутри камеры

-- UI-элементы в Rayfield (Вкладка Visuals)
VisualsTab:CreateSection("ESP на Сущностей")

VisualsTab:CreateToggle({
    Name = "Включить ESP",
    CurrentValue = true,
    Flag = "ESP_MasterToggle",
    Callback = function(val)
        espEnabled = val
    end
})

VisualsTab:CreateToggle({
    Name = "Подсветка Монстров (Rush, Seek, Figure...)",
    CurrentValue = true,
    Flag = "ESP_MonstersToggle",
    Callback = function(val)
        showMonsters = val
    end
})

VisualsTab:CreateToggle({
    Name = "Подсветка Ловушек (Dupe, Snare)",
    CurrentValue = true,
    Flag = "ESP_TrapsToggle",
    Callback = function(val)
        showTraps = val
    end
})

print("[Doors Hub] Модуль ESP успешно инициализирован.")

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Hub = getgenv().DoorsHub
if not Hub or not Hub.Tabs or not Hub.Tabs.Movement then
    warn("[SeekAssist] Ошибка: Вкладка Movement не найдена")
    return
end

local MovementTab = Hub.Tabs.Movement
local localPlayer = Players.LocalPlayer
local currentRooms = Workspace:WaitForChild("CurrentRooms")

local antiObstacles = true
local autoSeekRun = true
local isRunningSeek = false

-- 1. Отключение урона от падающих люстр и рук Сика (Anti Seek Obstacles)
local function disableSeekHazards(room)
    if not antiObstacles then return end
    for _, desc in ipairs(room:GetDescendants()) do
        if desc.Name == "Seek_Arm" or desc.Name == "ChandelierObstruction" then
            for _, part in ipairs(desc:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanTouch = false
                end
            end
        end
    end
end

-- 2. Авто-движение по точкам Guiding Light
local function followGuidingLight(room)
    if not autoSeekRun or isRunningSeek then return end
    
    local char = localPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end

    -- Проверяем, комната ли это с Сиком (наличие света Guiding Light)
    local guideLights = {}
    for _, desc in ipairs(room:GetDescendants()) do
        if desc.Name == "SeekGuidingLight" and desc:IsA("BasePart") then
            table.insert(guideLights, desc)
        end
    end

    if #guideLights == 0 then return end
    isRunningSeek = true

    -- Сортируем светлячки по удаленности от персонажа
    table.sort(guideLights, function(a, b)
        return (root.Position - a.Position).Magnitude < (root.Position - b.Position).Magnitude
    end)

    for _, light in ipairs(guideLights) do
        if not autoSeekRun or not isRunningSeek then break end
        humanoid:MoveTo(light.Position)
        
        local timer = tick()
        while (root.Position - light.Position).Magnitude > 4 and tick() - timer < 3 do
            task.wait(0.05)
        end
    end

    isRunningSeek = false
end

-- Мониторинг комнат
for _, room in ipairs(currentRooms:GetChildren()) do
    disableSeekHazards(room)
end

currentRooms.ChildAdded:Connect(function(room)
    task.wait(0.2)
    disableSeekHazards(room)
    task.spawn(function()
        followGuidingLight(room)
    end)
end)

-- UI-элементы в Rayfield
MovementTab:CreateSection("Погоня Сика (Seek Chase)")

MovementTab:CreateToggle({
    Name = "Анти-препятствия (Руки и Люстры)",
    CurrentValue = true,
    Callback = function(val)
        antiObstacles = val
    end
})

MovementTab:CreateToggle({
    Name = "Авто-маршрут (По Guiding Light)",
    CurrentValue = true,
    Callback = function(val)
        autoSeekRun = val
    end
})

print("[Doors Hub] Модуль SeekAssist успешно инициализирован.")

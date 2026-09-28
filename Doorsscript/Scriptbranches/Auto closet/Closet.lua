local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local Hub = getgenv().DoorsHub
if not Hub or not Hub.Tabs or not Hub.Tabs.Movement then
    warn("[AutoCloset] Ошибка: Не найдена вкладка Movement в DoorsHub")
    return
end

local MovementTab = Hub.Tabs.Movement
local localPlayer = Players.LocalPlayer
local currentRooms = Workspace:WaitForChild("CurrentRooms")

-- Флаги состояния
local autoClosetEnabled = true
local isHiding = false

-- Опасные монстры, от которых нужно бежать в шкаф
local DangerousMonsters = {
    ["RushMoving"] = true,
    ["AmbushMoving"] = true
}

-- Поиск ближайшего доступного шкафа или кровати
local function getClosestHidingSpot()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil, nil end

    local closestSpot = nil
    local closestPrompt = nil
    local minDistance = math.huge

    for _, room in ipairs(currentRooms:GetChildren()) do
        local assets = room:FindFirstChild("Assets")
        local container = assets or room

        for _, obj in ipairs(container:GetDescendants()) do
            -- Шкафы и кровати имеют ProximityPrompt для взаимодействия
            if (obj.Name == "Wardrobe" or obj.Name == "Bed") and obj:IsA("Model") then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                local mainPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")

                -- Проверяем, что шкаф не занят (у занятых шкафов отключается или скрывается Prompt)
                if prompt and prompt.Enabled and mainPart then
                    local dist = (root.Position - mainPart.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        closestSpot = mainPart
                        closestPrompt = prompt
                    end
                end
            end
        end
    end

    return closestSpot, closestPrompt
end

-- Логика безопасного прятания
local function hideFromMonster(monsterInstance)
    if not autoClosetEnabled or isHiding then return end
    isHiding = true

    local char = localPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then 
        isHiding = false 
        return 
    end

    -- Находим шкаф
    local targetPart, prompt = getClosestHidingSpot()
    if not targetPart or not prompt then
        warn("[AutoCloset] Поблизости не найдено свободных шкафов!")
        isHiding = false
        return
    end

    -- Бежим прямо к шкафу
    humanoid:MoveTo(targetPart.Position)

    -- Ждём сближения со шкафом
    local startTime = tick()
    while (root.Position - targetPart.Position).Magnitude > 6 and tick() - startTime < 3.5 do
        task.wait(0.05)
    end

    -- Активируем взаимодействие с укрытием
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + 0.05)
        prompt:InputHoldEnd()
    end

    -- Ждём, пока монстр полностью пролетит и удалится из Workspace
    monsterInstance.AncestryChanged:Wait()
    task.wait(1) -- Небольшая пауза для безопасности

    -- Вылезаем из шкафа (повторное нажатие или движение)
    if char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(root.Position + Vector3.new(0, 0, 3))
    end

    isHiding = false
end

-- Мониторинг появления опасных сущностей
Workspace.ChildAdded:Connect(function(child)
    if DangerousMonsters[child.Name] then
        task.spawn(function()
            hideFromMonster(child)
        end)
    end
end)

-- UI в Rayfield
MovementTab:CreateSection("Авто-Укрытие")

MovementTab:CreateToggle({
    Name = "Авто-шкаф при Rush / Ambush",
    CurrentValue = true,
    Flag = "AutoClosetToggle",
    Callback = function(val)
        autoClosetEnabled = val
    end
})

print("[Doors Hub] Модуль AutoCloset успешно инициализирован.")

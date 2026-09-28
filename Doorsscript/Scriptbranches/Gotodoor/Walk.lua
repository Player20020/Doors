local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Hub = getgenv().DoorsHub
if not Hub or not Hub.Tabs or not Hub.Tabs.Movement then
    warn("[AutoWalk] Ошибка: Не найдена вкладка Movement в DoorsHub")
    return
end

local MovementTab = Hub.Tabs.Movement
local player = Players.LocalPlayer
local currentRooms = Workspace:WaitForChild("CurrentRooms")

-- Переменные состояния
local autoWalkEnabled = false
local walkThread = nil

-- Параметры поиска пути
local pathArgs = {
    AgentRadius = 2.5,
    AgentHeight = 5,
    AgentCanJump = false,
    WaypointSpacing = 3
}

-- Поиск последней сгенерированной комнаты
local function getLatestRoom()
    local highestNum = -1
    local latestRoom = nil
    for _, room in ipairs(currentRooms:GetChildren()) do
        local roomNum = tonumber(room.Name)
        if roomNum and roomNum > highestNum then
            highestNum = roomNum
            latestRoom = room
        end
    end
    return latestRoom
end

-- Перемещение персонажа через PathfindingService
local function walkToTarget(targetPosition)
    local char = player.Character
    if not char then return false end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart or humanoid.Health <= 0 then return false end

    local path = PathfindingService:CreatePath(pathArgs)
    local success, _ = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPosition)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        -- Если путь не построился из-за препятствия, делаем прямое движение
        humanoid:MoveTo(targetPosition)
        return false
    end

    local waypoints = path:GetWaypoints()
    for i = 2, #waypoints do
        if not autoWalkEnabled then
            humanoid:MoveTo(rootPart.Position)
            return false
        end

        local wp = waypoints[i]
        humanoid:MoveTo(wp.Position)

        -- Ожидание достижения точки
        local reached = humanoid.MoveToFinished:Wait()
        if not reached then
            break
        end
    end

    return true
end

-- Остановка перемещения
local function stopWalking()
    autoWalkEnabled = false
    if walkThread then
        task.cancel(walkThread)
        walkThread = nil
    end

    local char = player.Character
    if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

-- Запуск цикла автоходьбы
local function startWalking()
    if walkThread then return end
    autoWalkEnabled = true

    walkThread = task.spawn(function()
        while autoWalkEnabled do
            local room = getLatestRoom()
            if room then
                local doorModel = room:FindFirstChild("Door")
                local targetPart = doorModel and (doorModel:FindFirstChild("Door") or doorModel:FindFirstChildWhichIsA("BasePart"))

                if targetPart then
                    walkToTarget(targetPart.Position)
                end
            end
            task.wait(0.4)
        end
    end)
end

-- UI-элементы в Rayfield
MovementTab:CreateSection("Автоматическое передвижение")

local WalkToggle = MovementTab:CreateToggle({
    Name = "Автоходьба к следующей двери",
    CurrentValue = false,
    Flag = "AutoWalkToggle",
    Callback = function(Value)
        if Value then
            startWalking()
        else
            stopWalking()
        end
    end,
})

MovementTab:CreateKeybind({
    Name = "Бинд переключения автоходьбы",
    CurrentKeybind = "X",
    HoldToInteract = false,
    Flag = "AutoWalkKeybind",
    Callback = function()
        -- Инвертируем состояние переключателя в интерфейсе
        WalkToggle:Set(not autoWalkEnabled)
    end,
})

print("[Doors Hub] Модуль AutoWalk успешно инициализирован.")

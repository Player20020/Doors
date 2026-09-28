local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Hub = getgenv().DoorsHub
if not Hub or not Hub.Tabs or not Hub.Tabs.Movement then
    warn("[KeyHelper] Ошибка: Не найдена вкладка Movement в DoorsHub")
    return
end

local MovementTab = Hub.Tabs.Movement
local player = Players.LocalPlayer
local currentRooms = Workspace:WaitForChild("CurrentRooms")

local autoKeyEnabled = true
local isInteracting = false

-- Вспомогательная функция безопасного вызова ProximityPrompt
local function interactWithPrompt(prompt)
    if not prompt or not prompt.Enabled then return false end

    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + 0.05)
        prompt:InputHoldEnd()
    end
    return true
end

-- Поиск последней сгенерированной комнаты
local function getLatestRoom()
    local highestNum = -1
    local latestRoom = nil
    for _, room in ipairs(currentRooms:GetChildren()) do
        local num = tonumber(room.Name)
        if num and num > highestNum then
            highestNum = num
            latestRoom = room
        end
    end
    return latestRoom
end

-- Проверка наличия ключа в инвентаре или в руках
local function getCarriedKey()
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")

    -- Проверяем, держит ли персонаж ключ прямо сейчас
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and string.find(item.Name:lower(), "key") then
                return item
            end
        end
    end

    -- Проверяем инвентарь (рюкзак)
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and string.find(item.Name:lower(), "key") then
                return item
            end
        end
    end

    return nil
end

-- Поиск модели ключа в комнате
local function findKeyInRoom(room)
    for _, desc in ipairs(room:GetDescendants()) do
        if desc.Name == "KeyObtain" and desc:IsA("Model") then
            local prompt = desc:FindFirstChildWhichIsA("ProximityPrompt", true)
            local part = desc:FindFirstChildWhichIsA("BasePart")
            if prompt and part then
                return part, prompt
            end
        end
    end
    return nil, nil
end

-- Основная функция проверки замка и решения проблемы с ключом
local function handleLockedDoor()
    if not autoKeyEnabled or isInteracting then return end

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then return end

    local room = getLatestRoom()
    if not room then return end

    local door = room:FindFirstChild("Door")
    if not door then return end

    -- Замок в моделях дверей Doors лежит внутри модели Lock
    local lock = door:FindFirstChild("Lock")
    if not lock then return end -- Дверь не заперта

    local lockPrompt = lock:FindFirstChildWhichIsA("ProximityPrompt", true)
    local lockPart = lock:FindFirstChildWhichIsA("BasePart")
    if not lockPrompt or not lockPart then return end

    isInteracting = true

    -- Шаг 1: Проверяем, взят ли уже ключ
    local heldKey = getCarriedKey()

    -- Шаг 2: Если ключа в кармане нет, идем искать его по комнате
    if not heldKey then
        local keyPart, keyPrompt = findKeyInRoom(room)
        if keyPart and keyPrompt then
            -- Бежим к ключу
            humanoid:MoveTo(keyPart.Position)
            local startTime = tick()

            while (root.Position - keyPart.Position).Magnitude > 6 and tick() - startTime < 8 do
                task.wait(0.1)
            end

            -- Подбираем ключ
            task.wait(0.2)
            interactWithPrompt(keyPrompt)
            task.wait(0.5)
        else
            -- Ключ еще не найден (возможно, спрятан в ящике стола)
            isInteracting = false
            return
        end
    end

    -- Шаг 3: Экипируем ключ из рюкзака в руку, если он не в руках
    local keyInBackpack = player.Backpack:FindFirstChildWhichIsA("Tool")
    if keyInBackpack and string.find(keyInBackpack.Name:lower(), "key") then
        humanoid:EquipTool(keyInBackpack)
        task.wait(0.3)
    end

    -- Шаг 4: Подходим к замку двери
    humanoid:MoveTo(lockPart.Position)
    local walkTime = tick()

    while (root.Position - lockPart.Position).Magnitude > 6 and tick() - walkTime < 6 do
        task.wait(0.1)
    end

    -- Шаг 5: Отпираем замок
    task.wait(0.2)
    interactWithPrompt(lockPrompt)
    task.wait(0.5)

    isInteracting = false
end

-- Фоновый цикл проверки закрытых дверей
task.spawn(function()
    while true do
        task.wait(0.5)
        if autoKeyEnabled then
            pcall(handleLockedDoor)
        end
    end
end)

-- UI-элементы в Rayfield
MovementTab:CreateSection("Авто-взаимодействие с замками")

MovementTab:CreateToggle({
    Name = "Авто-подбор ключа и открытие замка",
    CurrentValue = true,
    Flag = "AutoKeyToggle",
    Callback = function(val)
        autoKeyEnabled = val
    end
})

print("[Doors Hub] Модуль KeyHelper успешно инициализирован.")

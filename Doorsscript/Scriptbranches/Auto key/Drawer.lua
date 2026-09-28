local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Hub = getgenv().DoorsHub
if not Hub or not Hub.Tabs or not Hub.Tabs.Movement then
    warn("[Drawers] Вкладка Movement не найдена")
    return
end

local MovementTab = Hub.Tabs.Movement
local localPlayer = Players.LocalPlayer
local currentRooms = Workspace:WaitForChild("CurrentRooms")

local autoLootDrawers = true
local isSearching = false

-- Проверка вызова ProximityPrompt
local function firePrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration or 0)
        prompt:InputHoldEnd()
    end
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

-- Поиск и открытие всех закрытых ящиков в текущей комнате
local function searchRoomDrawers()
    if not autoLootDrawers or isSearching then return end

    local room = getLatestRoom()
    if not room then return end

    local door = room:FindFirstChild("Door")
    local lock = door and door:FindFirstChild("Lock")
    
    -- Обыскиваем ящики только если дверь закрыта на замок и ключ еще не на полу
    local keyInRoom = room:FindFirstChild("KeyObtain", true)
    if not lock or keyInRoom then return end

    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    -- Находим все нераскрытые ящики
    local drawers = {}
    for _, desc in ipairs(room:GetDescendants()) do
        if desc.Name == "DrawerContainer" or desc.Name == "TableWithDrawers" or desc.Name == "Desk" then
            local prompt = desc:FindFirstChildWhichIsA("ProximityPrompt", true)
            local part = desc:FindFirstChildWhichIsA("BasePart")
            if prompt and prompt.Enabled and part then
                table.insert(drawers, { part = part, prompt = prompt })
            end
        end
    end

    if #drawers == 0 then return end
    isSearching = true

    for _, drawer in ipairs(drawers) do
        -- Если во время обыска ключ уже выпал или дверь открыли — останавливаемся
        if not autoLootDrawers or room:FindFirstChild("KeyObtain", true) or not door:FindFirstChild("Lock") then
            break
        end

        hum:MoveTo(drawer.part.Position)
        local timer = tick()

        while (root.Position - drawer.part.Position).Magnitude > 6 and tick() - timer < 3 do
            task.wait(0.05)
        end

        firePrompt(drawer.prompt)
        task.wait(0.2)
    end

    isSearching = false
end

-- Фоновый опрос ящиков
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(searchRoomDrawers)
    end
end)

-- UI в Rayfield
MovementTab:CreateSection("Поиск ключей в мебели")

MovementTab:CreateToggle({
    Name = "Авто-открытие ящиков при закрытой двери",
    CurrentValue = true,
    Callback = function(val)
        autoLootDrawers = val
    end
})

print("[Doors Hub] Модуль Drawers успешно инициализирован.")

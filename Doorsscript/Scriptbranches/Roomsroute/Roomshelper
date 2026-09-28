local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Hub = getgenv().DoorsHub
local MainTab = Hub.Tabs.Main
local localPlayer = Players.LocalPlayer
local currentRooms = Workspace:WaitForChild("CurrentRooms")

-- Настройки
local autoCollectGold = true
local autoBuyJeff = true
local routeToRooms = true

local selectedJeffItems = {
    ["SkeletonKey"] = true,
    ["Lockpicks"] = true,
    ["Crucifix"] = false,
    ["Flashlight"] = false
}

local function interact(prompt)
    if not prompt or not prompt.Enabled then return end
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + 0.05)
        prompt:InputHoldEnd()
    end
end

-- Подсчет предметов инвентаря
local function countItem(namePattern)
    local count = 0
    local checkPool = { localPlayer.Character, localPlayer:FindFirstChild("Backpack") }
    for _, container in ipairs(checkPool) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and string.find(item.Name:lower(), namePattern:lower()) then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- 1. Сбор золота по комнатам
local function farmGold(room)
    if not autoCollectGold then return end
    for _, desc in ipairs(room:GetDescendants()) do
        if (desc.Name == "GoldPile" or desc.Name == "Coin") and desc:IsA("Model") then
            local prompt = desc:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                interact(prompt)
            end
        end
    end
end

-- 2. Логика магазина Джеффа (Комната 52)
local function handleJeffShop(room)
    if not autoBuyJeff or room.Name ~= "52" then return end
    
    local shopFolder = room:WaitForChild("Shop", 5) or room
    for _, item in ipairs(shopFolder:GetDescendants()) do
        for itemName, shouldBuy in pairs(selectedJeffItems) do
            if shouldBuy and string.find(item.Name, itemName) then
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    -- Покупаем до лимита (например, 2 отмычки)
                    if itemName == "Lockpicks" and countItem("lockpick") >= 2 then
                        continue
                    end
                    interact(prompt)
                    task.wait(0.3)
                end
            end
        end
    end
end

-- 3. Проверка и вход в Архивы (Rooms A-000)
local function checkRoomsRequirements()
    local hasSkeletonKey = countItem("skeleton") >= 1
    local lockpicksCount = countItem("lockpick")
    return hasSkeletonKey and lockpicksCount >= 2
end

local function routeToUnderground(room)
    if not routeToRooms then return end
    local roomNum = tonumber(room.Name)
    if roomNum and roomNum >= 60 and roomNum <= 62 then
        if checkRoomsRequirements() then
            Hub.Rayfield:Notify({
                Title = "The Rooms (Архивы)",
                Content = "Условия выполнены (Ключ + 2 Отмычки)! Идем к подэтажу A-000.",
                Duration = 6
            })
            -- Ищем скрытую дверь/проход за шкафом в комнате 60
            local roomsGate = room:FindFirstChild("RoomsDoor") or room:FindFirstChild("SpecialDoor")
            if roomsGate then
                local char = localPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid:MoveTo(roomsGate:GetPivot().Position)
                end
            end
        else
            Hub.Rayfield:Notify({
                Title = "Вход отменен",
                Content = "Не хватает предметов: нужен 1 Skeleton Key и 2 Lockpicks!",
                Duration = 5
            })
        end
    end
end

-- Слушатель генерации комнат
currentRooms.ChildAdded:Connect(function(room)
    task.wait(0.5)
    farmGold(room)
    handleJeffShop(room)
    routeToUnderground(room)
end)

-- UI в Rayfield
MainTab:CreateSection("Экономика и The Rooms")

MainTab:CreateToggle({
    Name = "Авто-сбор золота (Фарм на Джеффа)",
    CurrentValue = true,
    Callback = function(val) autoCollectGold = val end
})

MainTab:CreateToggle({
    Name = "Авто-закуп у Джеффа (Дверь 52)",
    CurrentValue = true,
    Callback = function(val) autoBuyJeff = val end
})

MainTab:CreateDropdown({
    Name = "Товары Джеффа для авто-покупки",
    Options = {"SkeletonKey + 2 Lockpicks (Для Rooms)", "Все товары", "Только Crucifix"},
    CurrentOption = {"SkeletonKey + 2 Lockpicks (Для Rooms)"},
    MultipleOptions = false,
    Callback = function(option)
        local opt = option[1] or option
        if opt == "SkeletonKey + 2 Lockpicks (Для Rooms)" then
            selectedJeffItems = { SkeletonKey = true, Lockpicks = true, Crucifix = false, Flashlight = false }
        elseif opt == "Все товары" then
            selectedJeffItems = { SkeletonKey = true, Lockpicks = true, Crucifix = true, Flashlight = true }
        elseif opt == "Только Crucifix" then
            selectedJeffItems = { SkeletonKey = false, Lockpicks = false, Crucifix = true, Flashlight = false }
        end
    end
})

MainTab:CreateToggle({
    Name = "Идти в Архивы (A-000 на 60 двери)",
    CurrentValue = true,
    Callback = function(val) routeToRooms = val end
})

print("[Doors Hub] Модуль RoomsRoute успешно инициализирован.")

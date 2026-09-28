local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Hub = getgenv().DoorsHub
if not Hub or not Hub.Tabs or not Hub.Tabs.Main then
    warn("[Room100] Rayfield Tabs не найдены")
    return
end

local MainTab = Hub.Tabs.Main
local localPlayer = Players.LocalPlayer
local currentRooms = Workspace:WaitForChild("CurrentRooms")

local autoCollectFuses = true
local isCollecting = false

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

-- Основной цикл для 100 комнаты
local function handleRoom100()
    if not autoCollectFuses or isCollecting then return end

    local room100 = currentRooms:FindFirstChild("100")
    if not room100 then return end

    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    -- Поиск доступных предохранителей
    local fuses = {}
    for _, desc in ipairs(room100:GetDescendants()) do
        if desc.Name == "FuseObtain" or desc.Name == "LiveBreakerPolePickup" then
            local prompt = desc:FindFirstChildWhichIsA("ProximityPrompt", true)
            local part = desc:IsA("BasePart") and desc or desc:FindFirstChildWhichIsA("BasePart")
            if prompt and prompt.Enabled and part then
                table.insert(fuses, { part = part, prompt = prompt })
            end
        end
    end

    -- Если еще есть несобранные предохранители
    if #fuses > 0 then
        isCollecting = true
        
        -- Сортируем по удаленности от персонажа
        table.sort(fuses, function(a, b)
            return (root.Position - a.part.Position).Magnitude < (root.Position - b.part.Position).Magnitude
        end)

        local target = fuses[1]
        hum:MoveTo(target.part.Position)
        
        local timer = tick()
        while (root.Position - target.part.Position).Magnitude > 5 and tick() - timer < 4 do
            task.wait(0.05)
        end

        firePrompt(target.prompt)
        task.wait(0.2)
        isCollecting = false
        return
    end

    -- Когда все 10 предохранителей собраны — вставляем их в щиток
    local breaker = room100:FindFirstChild("ElevatorBreaker", true)
    if breaker then
        local fusesPrompt = breaker:FindFirstChild("FusesPrompt", true) 
            or breaker:FindFirstChildWhichIsA("ProximityPrompt", true)

        if fusesPrompt and fusesPrompt.Enabled and fusesPrompt.Name == "FusesPrompt" then
            isCollecting = true
            local mainPart = breaker:FindFirstChildWhichIsA("BasePart")
            if mainPart then
                hum:MoveTo(mainPart.Position)
                local timer = tick()
                while (root.Position - mainPart.Position).Magnitude > 6 and tick() - timer < 5 do
                    task.wait(0.05)
                end
                firePrompt(fusesPrompt)
                task.wait(0.5)
            end
            isCollecting = false
        end
    end
end

-- Мониторинг появления комнаты 100
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(handleRoom100)
    end
end)

-- UI в Rayfield
MainTab:CreateSection("Комната 100 (Предохранители)")

MainTab:CreateToggle({
    Name = "Авто-сбор 10 предохранителей",
    CurrentValue = true,
    Callback = function(val)
        autoCollectFuses = val
    end
})

print("[Doors Hub] Модуль Room100 Fuses успешно инициализирован.")

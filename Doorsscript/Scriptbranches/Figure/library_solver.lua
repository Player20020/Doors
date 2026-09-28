local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Hub = getgenv().DoorsHub
if not Hub or not Hub.Tabs or not Hub.Tabs.Main then
    warn("[LibrarySolver] Ошибка: Rayfield Tabs не найдены")
    return
end

local MainTab = Hub.Tabs.Main
local localPlayer = Players.LocalPlayer

-- Поиск папки ремоутов
local RemotesFolder = ReplicatedStorage:FindFirstChild("EntityInfo") 
    or ReplicatedStorage:FindFirstChild("Bricks") 
    or ReplicatedStorage:FindFirstChild("RemotesFolder")

local PL = RemotesFolder and RemotesFolder:FindFirstChild("PL")

-- Флаги
local silentSteps = true
local shrinkHitbox = true
local autoCodeSubmit = true

-- 1. Скрытие звука шагов (постоянный статус "на корточках" для сервера)
RunService.Heartbeat:Connect(function()
    if silentSteps and RemotesFolder and RemotesFolder:FindFirstChild("Crouch") then
        RemotesFolder.Crouch:FireServer(true, true)
    end
end)

-- 2. Ломаем хитбокс Фигуры
local function nerfFigure(fig)
    if not shrinkHitbox or not fig then return end
    local root = fig:WaitForChild("Root", 5)
    if root and root:IsA("BasePart") then
        root.Size = Vector3.new(0.001, 0.001, 0.001)
        root.CanTouch = false
    end
end

for _, v in ipairs(Workspace:GetDescendants()) do
    if v.Name == "FigureRig" or v.Name == "FigureRagdoll" then
        nerfFigure(v)
    end
end

Workspace.DescendantAdded:Connect(function(v)
    if v.Name == "FigureRig" or v.Name == "FigureRagdoll" then
        nerfFigure(v)
    end
end)

-- 3. Вычисление кода из подсказок UI
local function getLibraryCode()
    local codeLength = 5
    local slot = table.create(codeLength, "_")

    local paper = nil
    local char = localPlayer.Character
    local backpack = localPlayer:FindFirstChild("Backpack")

    -- Проверяем наличие листа в инвентаре или руках
    local searchPool = { char, backpack }
    for _, container in ipairs(searchPool) do
        if container then
            paper = container:FindFirstChild("LibraryHintPaper") or container:FindFirstChild("LibraryHintPaperHard")
            if paper then break end
        end
    end

    if not paper or not paper:FindFirstChild("UI") then return nil end

    local permUI = localPlayer.PlayerGui:FindFirstChild("PermUI")
    local hints = permUI and permUI:FindFirstChild("Hints") and permUI.Hints:GetChildren()
    if not hints then return nil end

    for _, i in ipairs(paper.UI:GetChildren()) do
        if i:IsA("ImageLabel") and i.Name ~= "Image" then
            local pos = tonumber(i.Name)
            if pos and slot[pos] then
                for _, v in ipairs(hints) do
                    if v.Name == "Icon" and v.ImageRectOffset.X == i.ImageRectOffset.X then
                        local label = v:FindFirstChild("TextLabel")
                        if label then
                            slot[pos] = label.Text
                        end
                        break
                    end
                end
            end
        end
    end

    local finalCode = table.concat(slot)
    if string.find(finalCode, "_") then
        return nil -- Не все книги найдены
    end
    return finalCode
end

-- Автоматическая отправка кода в кодовый замок двери 50
task.spawn(function()
    while true do
        task.wait(1)
        if autoCodeSubmit and PL then
            local code = getLibraryCode()
            if code then
                PL:FireServer(code)
                Hub.Rayfield:Notify({
                    Title = "Библиотека решена!",
                    Content = "Код введен: " .. tostring(code),
                    Duration = 4
                })
                task.wait(5)
            end
        end
    end
end)

-- UI в Rayfield
MainTab:CreateSection("Комната 50 (Фигура)")

MainTab:CreateToggle({
    Name = "Немой бег (Анти-слух Фигуры)",
    CurrentValue = true,
    Callback = function(val)
        silentSteps = val
        if not val and RemotesFolder and RemotesFolder:FindFirstChild("Crouch") then
            RemotesFolder.Crouch:FireServer(false)
        end
    end
})

MainTab:CreateToggle({
    Name = "Уменьшить хитбокс Фигуры",
    CurrentValue = true,
    Callback = function(val)
        shrinkHitbox = val
    end
})

MainTab:CreateToggle({
    Name = "Авто-ввод кода библиотеки",
    CurrentValue = true,
    Callback = function(val)
        autoCodeSubmit = val
    end
})

print("[Doors Hub] Модуль LibrarySolver успешно инициализирован.")

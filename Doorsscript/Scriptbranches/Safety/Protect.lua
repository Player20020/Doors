local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Hub = getgenv().DoorsHub
local Camera = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local antiEyes = true
local antiScreech = true
local antiSnare = true

-- 1. Защита от Eyes: принудительный взгляд в пол
RunService.RenderStepped:Connect(function()
    if antiEyes and Workspace:FindFirstChild("Eyes") then
        local camCFrame = Camera.CFrame
        Camera.CFrame = CFrame.new(camCFrame.Position) * CFrame.Angles(math.rad(-89), 0, 0)
    end
end)

-- 2. Защита от Screech: моментальный фокус камеры
Camera.ChildAdded:Connect(function(child)
    if antiScreech and child.Name == "Screech" then
        local rootPart = child:FindFirstChildWhichIsA("BasePart")
        if rootPart then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, rootPart.Position)
        end
    end
end)

-- 3. Защита от Snare: нейтрализация капканов
local currentRooms = Workspace:WaitForChild("CurrentRooms")

local function disableSnares(room)
    for _, desc in ipairs(room:GetDescendants()) do
        if desc.Name == "Snare" and desc:IsA("BasePart") then
            desc.CanTouch = false
        end
    end
end

for _, room in ipairs(currentRooms:GetChildren()) do disableSnares(room) end
currentRooms.ChildAdded:Connect(function(room)
    task.wait(0.5)
    disableSnares(room)
end)

-- UI в Rayfield (Главная вкладка)
local MainTab = Hub.Tabs.Main
MainTab:CreateSection("Пассивная защита")

MainTab:CreateToggle({
    Name = "Анти-Eyes (Смотреть в пол)",
    CurrentValue = true,
    Callback = function(val) antiEyes = val end
})

MainTab:CreateToggle({
    Name = "Авто-отпугивание Screech",
    CurrentValue = true,
    Callback = function(val) antiScreech = val end
})

MainTab:CreateToggle({
    Name = "Отключение ловушек Snare",
    CurrentValue = true,
    Callback = function(val) antiSnare = val end
})

print("[Doors Hub] Модуль Safety успешно инициализирован.")

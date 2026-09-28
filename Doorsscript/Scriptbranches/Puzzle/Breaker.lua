local Workspace = game:GetService("Workspace")

local Hub = getgenv().DoorsHub
if not Hub or not Hub.Tabs or not Hub.Tabs.Main then
    warn("[AutoBreaker] Ошибка: Rayfield Tabs не найдены")
    return
end

local MainTab = Hub.Tabs.Main
local autoBreakerEnabled = true
local breakerConnection = nil

-- Алгоритм решения электрощитка
local function solveBreaker(breakerModel)
    local surfaceGui = breakerModel:WaitForChild("SurfaceGui", 5)
    if not surfaceGui then return end

    local frame = surfaceGui:WaitForChild("Frame", 5)
    local codeLabel = frame and frame:WaitForChild("Code", 5)
    if not codeLabel then return end

    local function runStep()
        task.wait(0.05)
        if not autoBreakerEnabled then return end

        local targetNumber = tonumber(codeLabel.Text)
        if not targetNumber then return end

        for _, switch in ipairs(breakerModel:GetChildren()) do
            if switch.Name == "BreakerSwitch" and switch:GetAttribute("ID") == targetNumber then
                local indicatorFrame = codeLabel:FindFirstChild("Frame")
                if not indicatorFrame then break end

                local trans = indicatorFrame.BackgroundTransparency
                local constraint = switch:FindFirstChild("PrismaticConstraint")
                local light = switch:FindFirstChild("Light")
                local sound = switch:FindFirstChild("Sound")

                -- trans == 0: переключатель должен быть включен
                if trans == 0 then
                    if switch:GetAttribute("Enabled") then return end
                    switch:SetAttribute("Enabled", true)

                    if constraint then 
                        constraint.TargetPosition = -0.2 
                    end
                    if light then
                        light.Material = Enum.Material.Neon
                        local spark = light:FindFirstChild("Spark", true)
                        if spark then spark:Emit(1) end
                    end
                    if sound then sound:Play() end

                -- trans == 1: переключатель должен быть выключен
                elseif trans == 1 then
                    if not switch:GetAttribute("Enabled") then return end
                    switch:SetAttribute("Enabled", false)

                    if constraint then 
                        constraint.TargetPosition = 0.2 
                    end
                    if light then 
                        light.Material = Enum.Material.Glass 
                    end
                    if sound then sound:Play() end
                end
                break
            end
        end
    end

    if breakerConnection then
        breakerConnection:Disconnect()
        breakerConnection = nil
    end

    breakerConnection = codeLabel:GetPropertyChangedSignal("Text"):Connect(runStep)
    runStep()
end

-- Поиск щитка в комнатах
local function scanForBreaker()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "ElevatorBreaker" then
            solveBreaker(obj)
            break
        end
    end
end

-- Мониторинг появления щитка
Workspace.DescendantAdded:Connect(function(desc)
    if desc.Name == "ElevatorBreaker" then
        task.wait(0.5)
        solveBreaker(desc)
    end
end)

-- Проверяем, если игрок уже в 100-й комнате
scanForBreaker()

-- UI-элементы в Rayfield
MainTab:CreateSection("Комната 100 (Щиток)")

MainTab:CreateToggle({
    Name = "Авто-решение электрощитка",
    CurrentValue = true,
    Flag = "AutoBreakerToggle",
    Callback = function(val)
        autoBreakerEnabled = val
        if val then
            scanForBreaker()
        end
    end
})

print("[Doors Hub] Модуль AutoBreaker успешно инициализирован.")

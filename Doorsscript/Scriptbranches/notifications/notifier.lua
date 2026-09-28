local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Hub = getgenv().DoorsHub

if not Hub or not Hub.Rayfield then
    warn("[Notifier] Rayfield не найден в getgenv().DoorsHub")
    return
end

local Rayfield = Hub.Rayfield
local MainTab = Hub.Tabs.Main

local notifyEnabled = true

-- База данных сущностей и подсказок к ним
local EntityAlerts = {
    ["RushMoving"]   = { title = "Rush!",       text = "Быстро прячься в шкаф или кровать!", duration = 5 },
    ["AmbushMoving"] = { title = "Ambush!",     text = "Прячься! Он пробежит несколько раз!", duration = 6 },
    ["Eyes"]         = { title = "Eyes!",       text = "Опусти камеру в пол, не смотри!", duration = 4 },
    ["Screech"]      = { title = "Screech!",    text = "Оглянись и посмотри на него прямо сейчас!", duration = 3 },
    ["Halt"]         = { title = "Halt!",       text = "Приготовься разворачиваться!", duration = 5 },
    ["Sally"]        = { title = "Sally!",      text = "Осторожно, Салли в комнате!", duration = 4 },
    ["Snare"]        = { title = "Ловушка Snare", text = "Смотри под ноги, шипы на полу!", duration = 3 },
    ["Glitch"]       = { title = "Glitch",      text = "Телепортация назад к группе...", duration = 3 },
    ["Dupe"]         = { title = "Dupe",        text = "Проверяй номера дверей!", duration = 4 }
}

local function sendAlert(data)
    if not notifyEnabled then return end
    Rayfield:Notify({
        Title = "⚠️ " .. data.title,
        Content = data.text,
        Duration = data.duration or 4,
        Image = 4483362458
    })
end

-- Проверка появления сущности
local function checkEntity(child)
    if EntityAlerts[child.Name] then
        sendAlert(EntityAlerts[child.Name])
    end
end

-- 1. Слушатель для Workspace (Rush, Ambush, Eyes, Halt и т.д.)
Workspace.ChildAdded:Connect(checkEntity)

-- 2. Слушатель для Camera (Скрич обычно появляется прямо перед камерой)
Camera.ChildAdded:Connect(function(child)
    if child.Name == "Screech" then
        sendAlert(EntityAlerts["Screech"])
    end
end)

-- UI-элементы в Rayfield
MainTab:CreateSection("Оповещения об опасностях")

MainTab:CreateToggle({
    Name = "Уведомления о монстрах",
    CurrentValue = true,
    Flag = "EntityNotifyToggle",
    Callback = function(Value)
        notifyEnabled = Value
    end,
})

print("[Doors Hub] Модуль Notifier успешно инициализирован.")

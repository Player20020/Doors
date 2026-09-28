-- Инициализация Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Doors Modular Hub",
    LoadingTitle = "Doors Script Hub",
    LoadingSubtitle = "by Player20020",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

-- Создаем вкладки интерфейса
local Tabs = {
    Main = Window:CreateTab("Главная", 4483362458),
    Visuals = Window:CreateTab("Визуалы", 4483362458),
    Movement = Window:CreateTab("Движение", 4483362458)
}

-- Делимся глобальным контекстом с подключаемыми модулями
getgenv().DoorsHub = {
    Rayfield = Rayfield,
    Window = Window,
    Tabs = Tabs
}

-- Базовый URL репозитория на GitHub
local BASE_URL = "https://raw.githubusercontent.com/Player20020/Doors/main/doors/doorsscript/scriptbranches/"

-- Список всех созданных модулей для последовательной загрузки
local modules = {
    { name = "Entity Notifier", path = "notifications/notifier.lua" },
    { name = "Safety Guard",    path = "safety/protect.lua" },
    { name = "Figure Solver",   path = "figure/library_solver.lua" },
    { name = "Auto Breaker",    path = "puzzle/breaker.lua" },
    { name = "Seek Assist",     path = "seek/seekassist.lua" },
    { name = "Auto Walk",       path = "gotodoor/walk.lua" },
    { name = "Auto Closet",     path = "autocloset/closet.lua" },
    { name = "Key & Locks",     path = "autokey/keyhelper.lua" },
    { name = "Rooms & Economy", path = "roomsroute/roomshelper.lua" },
    { name = "ESP",             path = "esp/esp.lua" }
}


-- Поочередная загрузка скриптов (раз в 1 секунду)
task.spawn(function()
    for _, mod in ipairs(modules) do
        local success, err = pcall(function()
            local scriptContent = game:HttpGet(BASE_URL .. mod.path)
            local loadedFunc = loadstring(scriptContent)
            if loadedFunc then
                loadedFunc()
            else
                error("Модуль пуст или возвращает nil")
            end
        end)

        if success then
            Rayfield:Notify({
                Title = "Модуль загружен",
                Content = mod.name .. " успешно подключен!",
                Duration = 2,
                Image = 4483362458
            })
        else
            warn("[Doors Hub] Ошибка загрузки: " .. mod.name .. " -> " .. tostring(err))
        end

        task.wait(1)
    end

    Rayfield:Notify({
        Title = "Готово!",
        Content = "Все модули успешно инициализированы.",
        Duration = 3,
        Image = 4483362458
    })
end)

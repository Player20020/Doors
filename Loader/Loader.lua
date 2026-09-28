-- Загрузка Rayfield Interface Suite
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Doors Modular Hub",
    LoadingTitle = "Doors Script",
    LoadingSubtitle = "by YourName",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

-- Создаем вкладки
local Tabs = {
    Main = Window:CreateTab("Главная", 4483362458),
    Visuals = Window:CreateTab("Визуалы", 4483362458),
    Movement = Window:CreateTab("Движение", 4483362458)
}

-- Глобальный контекст, передаваемый в модули
getgenv().DoorsHub = {
    Rayfield = Rayfield,
    Window = Window,
    Tabs = Tabs
}

-- Список модулей для загрузки
local BASE_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/doors/doorsscript/scriptbranches/"

local modules = {
    { name = "Entity Notifier", path = "notifications/notifier.lua" },
    { name = "Auto Walk",       path = "gotodoor/walk.lua" },
    { name = "ESP",             path = "esp/esp.lua" }
}

-- Поочередная загрузка с интервалом в 1 секунду
task.spawn(function()
    for _, mod in ipairs(modules) do
        local success, err = pcall(function()
            local scriptContent = game:HttpGet(BASE_URL .. mod.path)
            local loadedFunc = loadstring(scriptContent)
            if loadedFunc then
                loadedFunc()
            else
                error("Скрипт пуст или вернул nil")
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
            warn("[Doors Hub] Ошибка при загрузке: " .. mod.name .. " -> " .. tostring(err))
        end

        task.wait(1) -- Задержка 1 секунда, чтобы исключить краши и подвисания
    end
end)

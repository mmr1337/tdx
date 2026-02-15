-- Локальный скрипт для начального экрана загрузки
-- Разместите этот скрипт в StarterPlayer -> StarterPlayerScripts (как LocalScript)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Конфигурация
local LOADING_DURATION = 10 -- Длительность загрузки в секундах
local LOGO_IMAGE = "rbxassetid://9027816855" -- ID вашего логотипа (можно изменить)

-- Ждем загрузки персонажа
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Сохраняем начальную позицию для фиксации
local startPosition = humanoidRootPart.CFrame
local isFixed = true
local bodyVelocity = nil

-- Функция для создания BodyVelocity
local function createBodyVelocity()
    if bodyVelocity and bodyVelocity.Parent then
        bodyVelocity:Destroy()
    end
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = humanoidRootPart
end

-- Создаем BodyVelocity для начального персонажа
createBodyVelocity()

-- Обработка перезаспавна персонажа
player.CharacterAdded:Connect(function(newCharacter)
    if isFixed then
        character = newCharacter
        humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
        humanoid = newCharacter:WaitForChild("Humanoid")
        startPosition = humanoidRootPart.CFrame
        
        -- Пересоздаем BodyVelocity для нового персонажа
        createBodyVelocity()
    end
end)

-- Создаем ScreenGui с максимальным приоритетом
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreen"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 2147483647 -- Максимальное значение DisplayOrder
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Скрываем курсор
UserInputService.MouseIconEnabled = false

-- Создаем основной Frame (фон) с градиентом
local backgroundFrame = Instance.new("Frame")
backgroundFrame.Name = "Background"
backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
backgroundFrame.Position = UDim2.new(0, 0, 0, 0)
backgroundFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
backgroundFrame.BorderSizePixel = 0
backgroundFrame.ZIndex = 1
backgroundFrame.Parent = screenGui

-- Добавляем градиент для фона
local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 15)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 10))
})
bgGradient.Rotation = 45
bgGradient.Parent = backgroundFrame

-- Создаем контейнер для снежинок
local snowContainer = Instance.new("Frame")
snowContainer.Name = "SnowContainer"
snowContainer.Size = UDim2.new(1, 0, 1, 0)
snowContainer.Position = UDim2.new(0, 0, 0, 0)
snowContainer.BackgroundTransparency = 1
snowContainer.ZIndex = 2
snowContainer.Parent = screenGui

-- Функция для получения размера экрана
local function getScreenSize()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1920, 1080) -- Дефолтный размер
end

-- Функция для создания снежинки
local function createSnowflake()
    local screenSize = getScreenSize()
    local snowflake = Instance.new("Frame")
    snowflake.Name = "Snowflake"
    local size = math.random(2, 5) -- Уменьшен размер: от 2 до 5 пикселей
    snowflake.Size = UDim2.new(0, size, 0, size)
    snowflake.Position = UDim2.new(0, math.random(0, screenSize.X), 0, -10)
    snowflake.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    snowflake.BorderSizePixel = 0
    snowflake.BackgroundTransparency = math.random(40, 80) / 100 -- Прозрачность от 0.4 до 0.8
    snowflake.ZIndex = 3
    snowflake.Parent = snowContainer
    
    -- Добавляем скругление для более мягкого вида
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = snowflake
    
    return snowflake
end

-- Глобальная переменная для текущего процента загрузки
local currentProgress = 0

-- Функция для анимации падения снежинки (плавное и быстрое)
local function animateSnowflake(snowflake, baseSpeed)
    local screenSize = getScreenSize()
    local startX = snowflake.Position.X.Offset
    local startY = snowflake.Position.Y.Offset
    
    -- Скорость зависит от процента загрузки (быстрее при большем проценте)
    local speedMultiplier = 1 + (currentProgress * 2) -- От 1x до 3x скорости
    local fallSpeed = (baseSpeed or math.random(100, 200)) * speedMultiplier
    local swayAmount = math.random(20, 50) -- Амплитуда покачивания
    local swaySpeed = math.random(3, 7) / 10 -- Скорость покачивания
    
    local startTime = tick()
    local lastTime = tick()
    local currentY = startY

    -- Плавная анимация через Heartbeat
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not snowflake or not snowflake.Parent or not screenGui or not screenGui.Parent then
            connection:Disconnect()
            if snowflake then
                snowflake:Destroy()
            end
            return
        end

        local currentTime = tick()
        local deltaTime = math.min(currentTime - lastTime, 0.1) -- Ограничиваем для стабильности
        lastTime = currentTime

        -- Плавное падение вниз
        currentY = currentY + (fallSpeed * deltaTime)

        -- Плавное покачивание влево-вправо
        local elapsed = currentTime - startTime
        local swayX = startX + math.sin(elapsed * swaySpeed) * swayAmount

        -- Обновляем позицию плавно
        snowflake.Position = UDim2.new(0, swayX, 0, currentY)

        -- Если снежинка ушла за экран, удаляем её
        local currentScreenSize = getScreenSize()
        if currentY > currentScreenSize.Y + 50 then
            connection:Disconnect()
            if snowflake then
                snowflake:Destroy()
            end
        end
    end)
end

-- Система создания снежинок в зависимости от процента загрузки
local snowflakes = {}
local snowflakeConnection

local function startSnowSystem()
    snowflakeConnection = RunService.Heartbeat:Connect(function()
        if not screenGui or not screenGui.Parent then
            if snowflakeConnection then
                snowflakeConnection:Disconnect()
            end
            return
        end

        -- Количество снежинок зависит от процента загрузки
        -- В начале: 1 снежинка каждые 0.8-1.2 секунды
        -- В конце (100%): 1 снежинка каждые 0.1-0.3 секунды (метель)
        local spawnRate = 0.8 - (currentProgress * 0.7) -- От 0.8 до 0.1 секунды
        spawnRate = math.max(0.05, spawnRate) -- Минимум 0.05 секунды

        -- Вероятность создания снежинки (чем больше прогресс, тем чаще)
        local spawnChance = 0.1 + (currentProgress * 0.9) -- От 10% до 100%

        if math.random() < spawnChance then
            -- Создаем снежинку
            local snowflake = createSnowflake()
            table.insert(snowflakes, snowflake)

            -- Скорость зависит от процента (быстрее при большем проценте)
            local baseSpeed = math.random(100, 200) -- Базовая скорость
            animateSnowflake(snowflake, baseSpeed)
        end

        -- Очищаем массив от удаленных снежинок
        for i = #snowflakes, 1, -1 do
            if not snowflakes[i] or not snowflakes[i].Parent then
                table.remove(snowflakes, i)
            end
        end
    end)
end

-- Запускаем систему снежинок
startSnowSystem()

-- Создаем Frame для логотипа
local logoFrame = Instance.new("Frame")
logoFrame.Name = "LogoFrame"
logoFrame.Size = UDim2.new(0, 300, 0, 300)
logoFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
logoFrame.BackgroundTransparency = 1
logoFrame.ZIndex = 4
logoFrame.Parent = screenGui

-- Создаем ImageLabel для логотипа
local logoImage = Instance.new("ImageLabel")
logoImage.Name = "Logo"
logoImage.Size = UDim2.new(1, 0, 1, 0)
logoImage.Position = UDim2.new(0, 0, 0, 0)
logoImage.BackgroundTransparency = 1
logoImage.Image = LOGO_IMAGE
logoImage.ImageTransparency = 0
logoImage.ZIndex = 5
logoImage.Parent = logoFrame

-- Добавляем UICorner для логотипа
local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(0, 20)
logoCorner.Parent = logoImage

-- Создаем Frame для контейнера букв
local titleContainer = Instance.new("Frame")
titleContainer.Name = "TitleContainer"
titleContainer.Size = UDim2.new(0, 900, 0, 120)
titleContainer.Position = UDim2.new(0.5, -450, 0.5, 50)
titleContainer.BackgroundTransparency = 1
titleContainer.ZIndex = 6
titleContainer.Parent = screenGui

-- Текст для анимации букв
local titleText = "MOON"
local letterLabels = {}
local letterWidth = 60
local letterHeight = 100
local letterSpacing = 10
local totalWidth = (#titleText * letterWidth) + ((#titleText - 1) * letterSpacing)
local startX = (900 - totalWidth) / 2

-- Создаем отдельный TextLabel для каждой буквы
for i = 1, #titleText do
    local char = titleText:sub(i, i)
    local letterLabel = Instance.new("TextLabel")
    letterLabel.Name = "Letter" .. i
    letterLabel.Size = UDim2.new(0, letterWidth, 0, letterHeight)
    letterLabel.Position = UDim2.new(0, startX + (i - 1) * (letterWidth + letterSpacing), 0, 10)
    letterLabel.BackgroundTransparency = 1
    letterLabel.Text = char == " " and "" or char
    letterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    letterLabel.TextSize = 80
    letterLabel.Font = Enum.Font.SourceSansBold
    letterLabel.TextStrokeTransparency = 0.3
    letterLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    letterLabel.TextXAlignment = Enum.TextXAlignment.Center
    letterLabel.TextYAlignment = Enum.TextYAlignment.Center
    letterLabel.ZIndex = 7
    letterLabel.Parent = titleContainer
    
    -- Добавляем градиент для каждой буквы
    local letterGradient = Instance.new("UIGradient")
    letterGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 220, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    letterGradient.Parent = letterLabel
    
    table.insert(letterLabels, letterLabel)
end

-- Создаем Frame для прогресс-бара (более стильный)
local progressBarFrame = Instance.new("Frame")
progressBarFrame.Name = "ProgressBarFrame"
progressBarFrame.Size = UDim2.new(0, 600, 0, 4)
progressBarFrame.Position = UDim2.new(0.5, -300, 1, -80)
progressBarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
progressBarFrame.BorderSizePixel = 0
progressBarFrame.ZIndex = 8
progressBarFrame.Parent = screenGui

-- Добавляем UICorner для прогресс-бара
local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 2)
progressCorner.Parent = progressBarFrame

-- Создаем Frame для заполнения прогресс-бара
local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.Position = UDim2.new(0, 0, 0, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
progressFill.BorderSizePixel = 0
progressFill.ZIndex = 9
progressFill.Parent = progressBarFrame

-- Добавляем UICorner для заполнения
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 2)
fillCorner.Parent = progressFill

-- Добавляем градиент для прогресс-бара (бледно-голубой -> белый)
local fillGradient = Instance.new("UIGradient")
fillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 220, 255)), -- Бледно-голубой в начале
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))  -- Белый на конце
})
fillGradient.Rotation = 0
fillGradient.Parent = progressFill

-- Создаем TextLabel для процентов (над прогресс-баром)
local percentLabel = Instance.new("TextLabel")
percentLabel.Name = "PercentLabel"
percentLabel.Size = UDim2.new(0, 200, 0, 40)
percentLabel.Position = UDim2.new(0.5, -100, 1, -120)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "0%"
percentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
percentLabel.TextSize = 32
percentLabel.Font = Enum.Font.SourceSansBold
percentLabel.TextStrokeTransparency = 0.5
percentLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
percentLabel.TextXAlignment = Enum.TextXAlignment.Center
percentLabel.ZIndex = 10
percentLabel.Parent = screenGui

-- Функция для фиксации персонажа
local function fixCharacter()
    if humanoidRootPart and isFixed then
        -- Устанавливаем позицию через BodyVelocity
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        -- Также устанавливаем CFrame для дополнительной фиксации
        humanoidRootPart.CFrame = startPosition
        -- Отключаем движение через Humanoid
        if humanoid then
            humanoid.PlatformStand = true
        end
    end
end

-- Подключаем фиксацию персонажа каждый кадр
local fixConnection
fixConnection = RunService.Heartbeat:Connect(function()
    if isFixed then
        fixCharacter()
    end
end)

-- Функция для анимации текста (плавное подпрыгивание букв)
local function animateTitle()
    -- Плавное появление каждой буквы с задержкой
    for i, letterLabel in ipairs(letterLabels) do
        if letterLabel.Text ~= "" then
            -- Начальное состояние - прозрачная и немного выше
            letterLabel.TextTransparency = 1
            local originalPosition = letterLabel.Position
            letterLabel.Position = originalPosition + UDim2.new(0, 0, 0, -30)
            
            -- Плавное появление с задержкой
            spawn(function()
                wait(i * 0.05) -- Задержка для волнового эффекта
                
                local fadeIn = TweenService:Create(
                    letterLabel,
                    TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        TextTransparency = 0,
                        Position = originalPosition
                    }
                )
                fadeIn:Play()
            end)
        end
    end
    
    -- Плавное подпрыгивание букв (циклическая анимация)
    wait(1.2) -- Ждем появления всех букв
    
    -- Создаем функцию для подпрыгивания каждой буквы
    local function createBounceAnimation(letterLabel, index)
        local originalPosition = letterLabel.Position
        local baseDelay = (index - 1) * 0.08 -- Задержка для волнового эффекта
        
        spawn(function()
            wait(baseDelay)
            
            -- Создаем циклическую анимацию подпрыгивания (более плавную)
            local bounceTween = TweenService:Create(
                letterLabel,
                TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {
                    Position = originalPosition + UDim2.new(0, 0, 0, -20)
                }
            )
            bounceTween:Play()
        end)
    end
    
    -- Применяем анимацию ко всем буквам
    for i, letterLabel in ipairs(letterLabels) do
        if letterLabel.Text ~= "" then
            createBounceAnimation(letterLabel, i)
        end
    end
    
    -- Анимация градиента для всех букв (движение)
    local gradientConnection
    local startTime = tick()
    gradientConnection = RunService.Heartbeat:Connect(function()
        local time = (tick() - startTime) * 0.3
        local offset = (math.sin(time) + 1) / 2 -- От 0 до 1
        
        for _, letterLabel in ipairs(letterLabels) do
            local gradient = letterLabel:FindFirstChild("UIGradient")
            if gradient then
                gradient.Offset = Vector2.new(offset - 0.5, 0)
            end
        end
    end)
end

-- Функция для анимации логотипа (простая и эффектная)
local function animateLogo()
    -- Плавное появление логотипа
    logoImage.ImageTransparency = 1
    local fadeIn = TweenService:Create(
        logoImage,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            ImageTransparency = 0
        }
    )
    fadeIn:Play()
    
    -- Легкая пульсация размера
    local originalSize = logoImage.Size
    local pulseTween = TweenService:Create(
        logoImage,
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {
            Size = originalSize + UDim2.new(0, 15, 0, 15)
        }
    )
    pulseTween:Play()
end

-- Функция для анимации прогресс-бара (пульсация цвета)
local function animateProgressBar()
    -- Показываем прогресс-бар сразу без анимации появления
    percentLabel.TextTransparency = 0
    
    -- Анимация пульсации синего цвета в градиенте
    local gradientConnection
    local startTime = tick()
    gradientConnection = RunService.Heartbeat:Connect(function()
        if fillGradient and fillGradient.Parent then
            local time = (tick() - startTime) * 1.5
            -- Пульсация от бледно-голубого к более синему
            local pulse = (math.sin(time) + 1) / 2 -- От 0 до 1
            
            -- Интерполируем между бледно-голубым и более синим
            local paleBlue = Color3.fromRGB(200, 220, 255) -- Бледно-голубой
            local brightBlue = Color3.fromRGB(100, 150, 255) -- Более синий
            
            -- Смешиваем цвета в зависимости от пульсации
            local blueColor = paleBlue:lerp(brightBlue, pulse)
            
            -- Устанавливаем градиент: пульсирующий синий -> белый
            fillGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, blueColor), -- Пульсирующий синий в начале
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) -- Всегда белый на конце
            })
        else
            gradientConnection:Disconnect()
        end
    end)
end

-- Запускаем анимации с задержкой
spawn(function()
    wait(0.3)
    animateLogo()
    wait(0.5)
    animateTitle()
    wait(0.3)
    animateProgressBar()
end)

-- Функция для обновления прогресс-бара
local startTime = tick()
local function updateProgress()
    local elapsed = tick() - startTime
    local progress = math.min(elapsed / LOADING_DURATION, 1)
    
    -- Обновляем глобальную переменную прогресса для системы снежинок
    currentProgress = progress
    
    -- Обновляем размер заполнения
    progressFill.Size = UDim2.new(progress, 0, 1, 0)
    
    -- Обновляем текст процентов
    local percent = math.floor(progress * 100)
    percentLabel.Text = percent .. "%"
    
    return progress >= 1
end

-- Основной цикл загрузки
spawn(function()
    local progressConnection
    progressConnection = RunService.Heartbeat:Connect(function()
        local isComplete = updateProgress()
        
        if isComplete then
            progressConnection:Disconnect()
            
            -- Останавливаем систему снежинок
            if snowflakeConnection then
                snowflakeConnection:Disconnect()
            end
            
            -- Останавливаем фиксацию
            isFixed = false
            if fixConnection then
                fixConnection:Disconnect()
            end
            
            -- Удаляем BodyVelocity
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity:Destroy()
            end
            
            -- Восстанавливаем нормальное состояние Humanoid
            if humanoid then
                humanoid.PlatformStand = false
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            
            -- Анимация для всех элементов
            local fadeElements = {}
            for _, element in pairs(screenGui:GetDescendants()) do
                if element:IsA("Frame") or element:IsA("ImageLabel") or element:IsA("TextLabel") then
                    table.insert(fadeElements, element)
                end
            end
            
            -- Плавно скрываем все элементы (проверяем тип элемента)
            for _, element in pairs(fadeElements) do
                local properties = {}
                
                -- Для Frame - только BackgroundTransparency
                if element:IsA("Frame") then
                    properties.BackgroundTransparency = 1
                end
                
                -- Для ImageLabel - ImageTransparency
                if element:IsA("ImageLabel") then
                    properties.ImageTransparency = 1
                end
                
                -- Для TextLabel - TextTransparency и TextStrokeTransparency
                if element:IsA("TextLabel") then
                    properties.TextTransparency = 1
                    properties.TextStrokeTransparency = 1
                end
                
                if next(properties) then
                    local tween = TweenService:Create(
                        element,
                        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                        properties
                    )
                    tween:Play()
                end
            end
            
            -- Показываем курсор после завершения анимации
            wait(1.6)
            UserInputService.MouseIconEnabled = true
            
            -- Удаляем GUI после анимации
            screenGui:Destroy()
        end
    end)
end)

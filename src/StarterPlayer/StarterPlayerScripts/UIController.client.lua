--!strict
--[[
    UIController.client.lua
    Arquitectura de Cliente: Controlador de Interfaz de Usuario Dinámica y Moderna.
    
    Genera programáticamente la UI del estado del juego en el PlayerGui local.
    Al construirse 100% por código Luau:
    - Evita problemas de serialización binaria en sistemas de sincronización con Argon/Rojo.
    - Configura ResetOnSpawn = false para evitar parpadeos visuales al morir o reaparecer.
    - Se sincroniza reactivamente mediante eventos .Changed con ReplicatedStorage.GameState.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

-- ============================================================================
-- CONSTRUCCIÓN PROGRAMÁTICA DE LA INTERFAZ VISUAL
-- ============================================================================
local function createGameStatusUI(): (ScreenGui, TextLabel)
    -- 1. ScreenGui Principal (No se reinicia al morir)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameStatusGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = false
    screenGui.DisplayOrder = 10

    -- 2. Contenedor Superior Centralizado
    local topContainer = Instance.new("Frame")
    topContainer.Name = "TopContainer"
    topContainer.AnchorPoint = Vector2.new(0.5, 0)
    topContainer.Position = UDim2.new(0.5, 0, 0, 18)
    topContainer.Size = UDim2.new(0, 720, 0, 58)
    topContainer.BackgroundTransparency = 1
    topContainer.BorderSizePixel = 0
    topContainer.Parent = screenGui

    -- Restricción de escala para pantallas móviles o compactas
    local uiScale = Instance.new("UIScale")
    uiScale.Name = "ResponsiveScale"
    uiScale.Scale = 1
    uiScale.Parent = topContainer

    -- 3. TextLabel Principal de Estado y Temporizador
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    statusLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    statusLabel.Size = UDim2.new(1, 0, 1, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.BorderSizePixel = 0
    statusLabel.Font = Enum.Font.GothamSSm
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 28
    statusLabel.TextWrapped = true
    statusLabel.RichText = true
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.TextYAlignment = Enum.TextYAlignment.Center
    statusLabel.Text = "Conectando al servidor..."

    -- Contorno sutil de alta legibilidad contra cielos brillantes o explosiones
    local textStroke = Instance.new("UIStroke")
    textStroke.Name = "LegibilityStroke"
    textStroke.Thickness = 2.5
    textStroke.Color = Color3.fromRGB(12, 14, 18)
    textStroke.Transparency = 0.2
    textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    textStroke.Parent = statusLabel

    statusLabel.Parent = topContainer
    screenGui.Parent = playerGui

    return screenGui, statusLabel
end

local screenGui, statusLabel = createGameStatusUI()

-- ============================================================================
-- VINCULACIÓN Y SINCRONIZACIÓN REACTIVA CON EL SERVIDOR
-- ============================================================================
local gameStateFolder = ReplicatedStorage:WaitForChild("GameState") :: Folder
local statusValue = gameStateFolder:WaitForChild("Status") :: StringValue
local timeLeftValue = gameStateFolder:WaitForChild("TimeLeft") :: IntValue

-- Animación sutil de pulso al actualizar el temporizador o mensaje
local tweenInfoPulse = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenPulseUp = TweenService:Create(statusLabel, tweenInfoPulse, { TextSize = 30 })
local tweenPulseBack = TweenService:Create(statusLabel, tweenInfoPulse, { TextSize = 28 })

local function triggerTextPulse()
    pcall(function()
        tweenPulseUp:Play()
        task.delay(0.15, function()
            tweenPulseBack:Play()
        end)
    end)
end

--[[
    Actualiza la presentación en pantalla combinando el estado textual y el temporizador.
]]
local function updateVisualState()
    local currentStatus = statusValue.Value
    local currentTime = timeLeftValue.Value

    if currentTime > 0 then
        -- Formato activo con segundos restantes
        statusLabel.Text = string.format("%s: <font color=\"#FFD15C\"><b>%ds</b></font>", currentStatus, currentTime)
    else
        -- Formato de mensaje directo
        statusLabel.Text = string.format("<b>%s</b>", currentStatus)
    end

    triggerTextPulse()
end

-- Escuchar eventos de cambio de valor
statusValue.Changed:Connect(updateVisualState)
timeLeftValue.Changed:Connect(updateVisualState)

-- Inicializar la vista inmediatamente con los datos actuales
updateVisualState()

print("[UIController] Controlador de interfaz sincronizado correctamente con GameState.")

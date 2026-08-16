--!strict
--[[
    StateSetup.server.lua
    Arquitectura de Servidor: Inicialización y Gestión del Estado Global del Juego (State Management).
    
    Crea y configura el contenedor ReplicatedStorage.GameState con los ValueObjects necesarios:
    - Status (StringValue): Mensajes del estado de la partida ("Intermedio", "¡Sobrevive!", etc.)
    - TimeLeft (IntValue): Temporizador en segundos restantes de la fase activa.
    
    Ventaja Arquitectónica:
    El uso de ValueBases en ReplicatedStorage permite replicación automática nativa y que
    los clientes se suscriban mediante .Changed sin saturar el canal de red con RemoteEvents.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function initializeGameState(): Folder
    print("[StateSetup] Inicializando Estado Global del Juego (GameState)...")

    -- 1. Obtener o instanciar la carpeta principal de GameState
    local gameStateFolder = ReplicatedStorage:FindFirstChild("GameState") :: Folder
    if not gameStateFolder then
        gameStateFolder = Instance.new("Folder")
        gameStateFolder.Name = "GameState"
        gameStateFolder.Parent = ReplicatedStorage
        print("[StateSetup] Contenedor 'GameState' creado en ReplicatedStorage.")
    else
        print("[StateSetup] Contenedor 'GameState' existente reutilizado.")
    end

    -- 2. Instanciar o configurar el StringValue 'Status'
    local statusValue = gameStateFolder:FindFirstChild("Status") :: StringValue
    if not statusValue then
        statusValue = Instance.new("StringValue")
        statusValue.Name = "Status"
        statusValue.Value = "Iniciando servidor..."
        statusValue.Parent = gameStateFolder
        print("[StateSetup] StringValue 'Status' inicializado.")
    end

    -- 3. Instanciar o configurar el IntValue 'TimeLeft'
    local timeLeftValue = gameStateFolder:FindFirstChild("TimeLeft") :: IntValue
    if not timeLeftValue then
        timeLeftValue = Instance.new("IntValue")
        timeLeftValue.Name = "TimeLeft"
        timeLeftValue.Value = 0
        timeLeftValue.Parent = gameStateFolder
        print("[StateSetup] IntValue 'TimeLeft' inicializado.")
    end

    print("[StateSetup] Estado Global listo y replicando a los clientes.")
    return gameStateFolder
end

-- Ejecutar la inicialización en el arranque del servidor
initializeGameState()

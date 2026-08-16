--!strict
--[[
    GameManager.server.lua
    Arquitectura de Servidor: Controlador del Bucle Central de Juego (Core Game Loop).
    
    Gestiona el ciclo de vida de las partidas mediante una máquina de estados estricta:
    - Fase 0: Espera de jugadores mínimos para iniciar.
    - Fase 1: Intermedio / Lobby (cuenta regresiva previa al evento).
    - Fase 2: Teletransporte seguro de participantes a la Isla con dispersión aleatoria.
    - Fase 3: Ronda activa de supervivencia (desastre en curso).
    - Fase 4: Cierre de ronda, extracción de supervivientes al Lobby y curación.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- IMPORTACIÓN DE CONFIGURACIÓN Y SERVICIOS
-- ============================================================================
local EnvironmentConfig = nil
pcall(function()
    local sharedConfigs = ReplicatedStorage:WaitForChild("SharedConfigs", 3)
    if sharedConfigs then
        local envModule = sharedConfigs:FindFirstChild("EnvironmentConfig")
        if envModule then
            EnvironmentConfig = require(envModule :: ModuleScript)
        end
    end
end)

-- ============================================================================
-- CONSTANTES DE CONFIGURACIÓN DE PARTIDA
-- ============================================================================
local MIN_PLAYERS: number = 1
local INTERMISSION_DURATION: number = 15 -- Segundos en el Lobby
local ROUND_DURATION: number = 60        -- Segundos de supervivencia en la Isla
local POST_ROUND_DELAY: number = 3       -- Tiempo de espera para mostrar resultados

-- Posiciones por defecto en caso de no cargar el módulo de configuración
local LOBBY_POSITION: Vector3 = if EnvironmentConfig and EnvironmentConfig.Lobby 
    then EnvironmentConfig.Lobby.Position + Vector3.new(0, 6, 0)
    else Vector3.new(0, 215, -460)

local ISLAND_POSITION: Vector3 = if EnvironmentConfig and EnvironmentConfig.Island
    then EnvironmentConfig.Island.Position + Vector3.new(0, 50, 0)
    else Vector3.new(0, 50, 0)

-- ============================================================================
-- VINCULACIÓN AL ESTADO GLOBAL (GAME STATE)
-- ============================================================================
local gameStateFolder = ReplicatedStorage:WaitForChild("GameState", 10) :: Folder
assert(gameStateFolder, "[GameManager] ERROR CRÍTICO: La carpeta GameState no fue encontrada en ReplicatedStorage.")

local statusValue = gameStateFolder:WaitForChild("Status", 5) :: StringValue
local timeLeftValue = gameStateFolder:WaitForChild("TimeLeft", 5) :: IntValue
assert(statusValue and timeLeftValue, "[GameManager] ERROR CRÍTICO: Variables de estado 'Status' o 'TimeLeft' faltantes.")

-- ============================================================================
-- MÉTODOS AUXILIARES DE JUGABILIDAD Y TELETRANSPORTE
-- ============================================================================

--[[
    Teletransporta de forma segura a un jugador a una coordenada específica.
    Protege contra personajes nulos, miembros faltantes o desconexiones instantáneas.
]]
local function safeTeleportPlayer(player: Player, targetCFrame: CFrame, healPlayer: boolean?): boolean
    local success, result = pcall(function()
        local character = player.Character
        if not character or not character.Parent then
            return false
        end

        local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if not rootPart or not humanoid or humanoid.Health <= 0 then
            return false
        end

        -- Anular velocidades residuales para evitar bugs de inercia o 'flinging'
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero

        -- Asignar nueva coordenada física
        rootPart.CFrame = targetCFrame

        -- Curación opcional al estado óptimo
        if healPlayer and humanoid.Health > 0 then
            humanoid.Health = humanoid.MaxHealth
        end

        return true
    end)

    if not success then
        warn(string.format("[GameManager] Error al teletransportar al jugador %s: %s", player.Name, tostring(result)))
        return false
    end

    return result == true
end

--[[
    Retorna la lista de jugadores que poseen un personaje vivo en el mundo.
]]
local function getAlivePlayers(): { Player }
    local alive: { Player } = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and rootPart then
                table.insert(alive, player)
            end
        end
    end
    return alive
end

-- ============================================================================
-- BUCLE PRINCIPAL DEL JUEGO (CORE GAME LOOP)
-- ============================================================================
local function startCoreGameLoop()
    print("[GameManager] Iniciando bucle central de supervivencia...")

    while true do
        ------------------------------------------------------------------------
        -- FASE 0: ESPERA DE JUGADORES
        ------------------------------------------------------------------------
        if #Players:GetPlayers() < MIN_PLAYERS then
            print("[GameManager] Fase 0: Esperando jugadores suficientes...")
            statusValue.Value = "Esperando más jugadores..."
            timeLeftValue.Value = 0

            while #Players:GetPlayers() < MIN_PLAYERS do
                task.wait(1)
            end
            print("[GameManager] Jugador(es) detectado(s). Comenzando ciclo de juego.")
        end

        ------------------------------------------------------------------------
        -- FASE 1: INTERMEDIO (LOBBY)
        ------------------------------------------------------------------------
        print("[GameManager] Fase 1: Intermedio en el Lobby iniciado.")
        statusValue.Value = "El próximo desastre comienza en..."
        timeLeftValue.Value = INTERMISSION_DURATION

        local cancelIntermission = false
        for remainingSeconds = INTERMISSION_DURATION, 1, -1 do
            if #Players:GetPlayers() < MIN_PLAYERS then
                cancelIntermission = true
                break
            end

            timeLeftValue.Value = remainingSeconds
            task.wait(1)
        end

        if cancelIntermission then
            print("[GameManager] Intermedio cancelado: cantidad de jugadores insuficiente.")
            continue
        end

        timeLeftValue.Value = 0

        ------------------------------------------------------------------------
        -- FASE 2: TELETRANSPORTE A LA ISLA
        ------------------------------------------------------------------------
        print("[GameManager] Fase 2: Desplegando jugadores a la Isla...")
        statusValue.Value = "Cargando mapa y desplegando jugadores..."
        timeLeftValue.Value = 0

        local currentPlayers = Players:GetPlayers()
        local teleportSuccessCount = 0

        for _, player in ipairs(currentPlayers) do
            -- Generar desplazamiento aleatorio en X y Z para evitar solapamiento de personajes
            local randomOffsetX = math.random(-45, 45)
            local randomOffsetZ = math.random(-45, 45)
            local randomYaw = math.rad(math.random(0, 360))

            local spawnPosition = ISLAND_POSITION + Vector3.new(randomOffsetX, 2, randomOffsetZ)
            local spawnCFrame = CFrame.new(spawnPosition) * CFrame.Angles(0, randomYaw, 0)

            local ok = safeTeleportPlayer(player, spawnCFrame, true)
            if ok then
                teleportSuccessCount += 1
            end
        end

        print(string.format("[GameManager] %d/%d jugadores teletransportados exitosamente a la Isla.", teleportSuccessCount, #currentPlayers))
        task.wait(1.5) -- Breve pausa para estabilización de físicas y carga cliente

        ------------------------------------------------------------------------
        -- FASE 3: SUPERVIVENCIA (RONDA ACTIVA)
        ------------------------------------------------------------------------
        print("[GameManager] Fase 3: ¡Ronda de supervivencia activa iniciada!")
        statusValue.Value = "¡Sobrevive al desastre!"
        timeLeftValue.Value = ROUND_DURATION

        -- ====================================================================
        -- [AQUÍ SE INYECTARÁ LA LÓGICA DEL DESASTRE MÁS ADELANTE]
        -- Ejemplos futuros: Invocar desastres aleatorios (Tornado, Tsunami, Lluvia de Meteoros, Terremoto)
        -- ====================================================================

        for remainingSeconds = ROUND_DURATION, 1, -1 do
            -- Verificar si aún quedan supervivientes en la isla
            local alivePlayers = getAlivePlayers()
            if #alivePlayers == 0 then
                print("[GameManager] No quedan supervivientes en la isla. Concluyendo ronda anticipadamente.")
                break
            end

            timeLeftValue.Value = remainingSeconds
            task.wait(1)
        end

        timeLeftValue.Value = 0

        ------------------------------------------------------------------------
        -- FASE 4: FIN DE LA RONDA Y RETORNO
        ------------------------------------------------------------------------
        print("[GameManager] Fase 4: Fin de la ronda. Rescatando supervivientes...")
        statusValue.Value = "¡Ronda terminada! Rescatando supervivientes..."
        timeLeftValue.Value = 0

        task.wait(POST_ROUND_DELAY)

        -- Teletransportar supervivientes vivos de vuelta a la zona segura del Lobby
        local survivors = getAlivePlayers()
        print(string.format("[GameManager] %d superviviente(s) registrado(s). Retornando al Lobby...", #survivors))

        for _, survivor in ipairs(survivors) do
            local lobbyOffsetX = math.random(-15, 15)
            local lobbyOffsetZ = math.random(-10, 10)
            local targetLobbyCFrame = CFrame.new(LOBBY_POSITION + Vector3.new(lobbyOffsetX, 2, lobbyOffsetZ))

            -- Teletransportar y restaurar salud al 100%
            safeTeleportPlayer(survivor, targetLobbyCFrame, true)
        end

        -- Pausa de transición antes de reiniciar el ciclo del intermedio
        task.wait(2)
        print("[GameManager] Ciclo completado. Preparando siguiente partida...")
    end
end

-- Ejecutar el bucle principal en un hilo gestionado
task.spawn(startCoreGameLoop)

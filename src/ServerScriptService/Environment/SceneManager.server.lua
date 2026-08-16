--!strict
--[[
    SceneManager.server.lua
    Script de Servidor principal para la inicialización gráfica y ambiental de alta fidelidad (PBR).
    Configura Future Lighting y Atmósfera, y construye el Lobby de Estación de Mando y la Isla Gigante
    en sus coordenadas separadas geográficamente.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Referencias a los módulos del entorno
local EnvironmentConfig = require(ReplicatedStorage.SharedConfigs.EnvironmentConfig)
local LightingManager = require(ServerScriptService.Environment.VisualEffects.LightingManager)
local PartTextures = require(ServerScriptService.Environment.VisualEffects.PartTextures)
local LobbyGeneration = require(ServerScriptService.Environment.Generation.LobbyGeneration)
local IslandGeneration = require(ServerScriptService.Environment.Generation.IslandGeneration)

local function initializeScene()
    print("================================================================================")
    print("      NATURAL DISASTER - ENTORNO GRÁFICO AVANZADO PBR / FUTURE LIGHTING         ")
    print("================================================================================")

    -- 1. Inicializar Iluminación 'Future', Atmósfera y Post-Procesado
    print("[SceneManager] Configurando sistema de iluminación y atmósfera PBR...")
    LightingManager.SetupLighting()

    -- 2. Construir el Lobby de Estación de Mando (Ubicación Lateral Lejana)
    print("[SceneManager] Construyendo Lobby de Estación de Mando...")
    local lobby = LobbyGeneration.BuildLobby()

    -- 3. Construir la Isla Gigante (Centro del Mundo con 5 Refugios y Naturaleza)
    print("[SceneManager] Construyendo Isla Masiva y Ecosistema...")
    local island = IslandGeneration.BuildIsland()

    print("[SceneManager] Entorno inicializado exitosamente.")
    print(string.format(" -> Lobby: Coordenadas %s | Jaula de Seguridad Activa", tostring(EnvironmentConfig.Lobby.Position)))
    print(string.format(" -> Isla:  Coordenadas %s | Escala %dx%d studs | Distrito Urbano y Periferia", 
        tostring(EnvironmentConfig.Island.Position), 
        EnvironmentConfig.Island.Dimensions.X, 
        EnvironmentConfig.Island.Dimensions.Y))
    print("================================================================================")
end

-- Ejecutar inicialización del entorno
initializeScene()

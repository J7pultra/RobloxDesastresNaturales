--!strict
--[[
    LobbyGeneration.lua
    Módulo para la generación del Lobby como una Moderna Plataforma de Observación Minimalista.
    Ubicada en Vector3.new(0, 65, -190) con vista panorámica directa a la Isla en (0, 0, 0).
    Paleta sobria y elegante: metales oscuros, acabados en gris grafito, acentos en blanco suave,
    bancos de madera noble, cristal templado y muros de contención invisibles.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentConfig = require(ReplicatedStorage.SharedConfigs.EnvironmentConfig)
local PartTextures = require(script.Parent.Parent.VisualEffects.PartTextures)

local LobbyGeneration = {}

function LobbyGeneration.BuildLobby(): Folder
    -- Limpieza si ya existe
    local existingLobby = Workspace:FindFirstChild("MainLobby")
    if existingLobby then
        existingLobby:Destroy()
    end

    local lobbyFolder = Instance.new("Folder")
    lobbyFolder.Name = "MainLobby"

    local cfg = EnvironmentConfig.Lobby
    local center = cfg.Position
    local size = cfg.Size
    local barrierHeight = cfg.BarrierHeight
    local theme = cfg.Theme

    -- 1. Plataforma Base y Suelo Grafito Minimalista
    local mainFloor = PartTextures.CreatePart({
        Name = "ObservationDeck_Floor",
        Size = Vector3.new(size.X, 4, size.Z),
        CFrame = CFrame.new(center),
        Material = theme.MainFloor.Material,
        Color = theme.MainFloor.Color,
        Reflectance = theme.MainFloor.Reflectance,
        Parent = lobbyFolder,
    })

    -- Moldura perimetral en blanco suave / plateado
    local trimThickness = 1.5
    local outerTrim = PartTextures.CreatePart({
        Name = "Deck_PerimeterTrim",
        Size = Vector3.new(size.X + trimThickness * 2, 3.8, size.Z + trimThickness * 2),
        CFrame = CFrame.new(center - Vector3.new(0, 0.2, 0)),
        Material = theme.AccentTrim.Material,
        Color = theme.AccentTrim.Color,
        Reflectance = theme.AccentTrim.Reflectance,
        Parent = lobbyFolder,
    })

    -- Franjas de división de suelo arquitectónicas sutiles (gris oscuro y blanco mate)
    local floorY = center.Y + 2.05
    local centerStripe = PartTextures.CreatePart({
        Name = "FloorAccentStripe",
        Size = Vector3.new(size.X - 10, 0.05, 1.2),
        CFrame = CFrame.new(center.X, floorY, center.Z - 6),
        Material = theme.AccentTrim.Material,
        Color = theme.AccentTrim.Color,
        CanCollide = false,
        CastShadow = false,
        Parent = lobbyFolder,
    })

    -- 2. Mirador Panorámico Frontal hacia la Isla (+Z)
    local frontZ = center.Z + (size.Z / 2)
    local backZ = center.Z - (size.Z / 2)
    local leftX = center.X - (size.X / 2)
    local rightX = center.X + (size.X / 2)

    -- Barandilla de cristal templado frontal con vista directa a la isla
    local glassPanelCount = 12
    local panelWidth = size.X / glassPanelCount

    for i = 1, glassPanelCount do
        local px = leftX + (panelWidth / 2) + ((i - 1) * panelWidth)

        -- Panel de cristal
        PartTextures.CreatePart({
            Name = "FrontGlassPanel_" .. i,
            Size = Vector3.new(panelWidth - 0.4, 5.5, 0.6),
            CFrame = CFrame.new(px, floorY + 2.75, frontZ - 0.5),
            Material = theme.ObservationGlass.Material,
            Color = theme.ObservationGlass.Color,
            Transparency = theme.ObservationGlass.Transparency,
            Reflectance = theme.ObservationGlass.Reflectance,
            Parent = lobbyFolder,
        })

        -- Pasamanos metálico superior
        PartTextures.CreatePart({
            Name = "FrontHandrail_" .. i,
            Size = Vector3.new(panelWidth, 0.5, 0.9),
            CFrame = CFrame.new(px, floorY + 5.7, frontZ - 0.5),
            Material = theme.RailingMetal.Material,
            Color = theme.RailingMetal.Color,
            Reflectance = theme.RailingMetal.Reflectance,
            Parent = lobbyFolder,
        })
    end

    -- Barandillas laterales y traseras
    local lateralRailingHeight = 6
    local railings = {
        -- Lateral Izquierdo
        { Size = Vector3.new(0.8, lateralRailingHeight, size.Z), Pos = Vector3.new(leftX + 0.4, floorY + lateralRailingHeight / 2, center.Z) },
        -- Lateral Derecho
        { Size = Vector3.new(0.8, lateralRailingHeight, size.Z), Pos = Vector3.new(rightX - 0.4, floorY + lateralRailingHeight / 2, center.Z) },
        -- Muro Posterior Arquitectónico
        { Size = Vector3.new(size.X, 14, 2), Pos = Vector3.new(center.X, floorY + 7, backZ + 1) },
    }

    for i, r in ipairs(railings) do
        PartTextures.CreatePart({
            Name = "EnclosureWall_" .. i,
            Size = r.Size,
            CFrame = CFrame.new(r.Pos),
            Material = theme.StructuralPillars.Material,
            Color = theme.StructuralPillars.Color,
            Reflectance = theme.StructuralPillars.Reflectance,
            Parent = lobbyFolder,
        })
    end

    -- 3. Columnas y Techo Voladizo Moderno (Arquitectura Minimalista)
    local pillarHeight = 22
    local pillarPositions = {
        Vector3.new(leftX + 6, floorY + pillarHeight / 2, backZ + 6),
        Vector3.new(rightX - 6, floorY + pillarHeight / 2, backZ + 6),
        Vector3.new(leftX + 6, floorY + pillarHeight / 2, center.Z),
        Vector3.new(rightX - 6, floorY + pillarHeight / 2, center.Z),
    }

    for i, pPos in ipairs(pillarPositions) do
        PartTextures.CreatePart({
            Name = "ModernPillar_" .. i,
            Size = Vector3.new(3, pillarHeight, 3),
            CFrame = CFrame.new(pPos),
            Material = theme.StructuralPillars.Material,
            Color = theme.StructuralPillars.Color,
            Reflectance = theme.StructuralPillars.Reflectance,
            Parent = lobbyFolder,
        })
    end

    -- Techo voladizo moderno que cubre la mitad trasera y deja el mirador abierto hacia el cielo e isla
    local roofDepth = size.Z * 0.65
    local canopy = PartTextures.CreatePart({
        Name = "ModernCanopy",
        Size = Vector3.new(size.X + 4, 1.8, roofDepth),
        CFrame = CFrame.new(center.X, floorY + pillarHeight + 0.9, backZ + (roofDepth / 2)),
        Material = theme.StructuralPillars.Material,
        Color = theme.StructuralPillars.Color,
        Reflectance = 0.1,
        Parent = lobbyFolder,
    })

    -- Moldura blanca inferior del techo
    PartTextures.CreatePart({
        Name = "CanopyFascia",
        Size = Vector3.new(size.X + 4, 0.4, roofDepth),
        CFrame = CFrame.new(center.X, floorY + pillarHeight - 0.1, backZ + (roofDepth / 2)),
        Material = theme.AccentTrim.Material,
        Color = theme.AccentTrim.Color,
        Parent = canopy,
    })

    -- Downlights sutiles y cálidos en el techo
    local lightPositions = {
        Vector3.new(center.X - 25, floorY + pillarHeight - 0.5, backZ + 18),
        Vector3.new(center.X, floorY + pillarHeight - 0.5, backZ + 18),
        Vector3.new(center.X + 25, floorY + pillarHeight - 0.5, backZ + 18),
    }
    for i, lPos in ipairs(lightPositions) do
        local fixture = PartTextures.CreateCylinder({
            Name = "CeilingFixture_" .. i,
            Size = Vector3.new(0.4, 3, 3),
            CFrame = CFrame.new(lPos) * CFrame.Angles(0, 0, math.rad(90)),
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(240, 240, 245),
            Parent = canopy,
        })
        local spotLight = Instance.new("SpotLight")
        spotLight.Color = Color3.fromRGB(255, 250, 235) -- Blanco cálido sutil
        spotLight.Brightness = 1.4
        spotLight.Range = 28
        spotLight.Angle = 75
        spotLight.Face = Enum.NormalId.Bottom
        spotLight.Parent = fixture
    end

    -- 4. Bancos de Madera Minimalistas para Espera
    local benchConfigs = {
        Vector3.new(center.X - 22, floorY + 1.2, center.Z - 14),
        Vector3.new(center.X + 22, floorY + 1.2, center.Z - 14),
        Vector3.new(center.X - 22, floorY + 1.2, center.Z + 4),
        Vector3.new(center.X + 22, floorY + 1.2, center.Z + 4),
    }
    for i, bPos in ipairs(benchConfigs) do
        -- Asiento de madera
        PartTextures.CreatePart({
            Name = "ObservationBench_" .. i,
            Size = Vector3.new(12, 0.8, 3.2),
            CFrame = CFrame.new(bPos),
            Material = theme.BenchWood.Material,
            Color = theme.BenchWood.Color,
            Reflectance = theme.BenchWood.Reflectance,
            Parent = lobbyFolder,
        })
        -- Patas de metal
        PartTextures.CreatePart({
            Name = "BenchLeg_L",
            Size = Vector3.new(0.6, 1.6, 3.2),
            CFrame = CFrame.new(bPos + Vector3.new(-5.2, -0.4, 0)),
            Material = theme.RailingMetal.Material,
            Color = theme.RailingMetal.Color,
            Parent = lobbyFolder,
        })
        PartTextures.CreatePart({
            Name = "BenchLeg_R",
            Size = Vector3.new(0.6, 1.6, 3.2),
            CFrame = CFrame.new(bPos + Vector3.new(5.2, -0.4, 0)),
            Material = theme.RailingMetal.Material,
            Color = theme.RailingMetal.Color,
            Parent = lobbyFolder,
        })
    end

    -- 5. Terminal Central de Información y Estado de la Ronda
    local kioskBase = PartTextures.CreatePart({
        Name = "InfoKiosk_Stand",
        Size = Vector3.new(10, 4, 3),
        CFrame = CFrame.new(center.X, floorY + 2, backZ + 8),
        Material = theme.SecondaryFloor.Material,
        Color = theme.SecondaryFloor.Color,
        Parent = lobbyFolder,
    })
    local kioskScreen = PartTextures.CreatePart({
        Name = "InfoKiosk_Display",
        Size = Vector3.new(8.5, 3.2, 0.4),
        CFrame = CFrame.new(center.X, floorY + 5.2, backZ + 8.8) * CFrame.Angles(math.rad(-15), 0, 0),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(25, 28, 32),
        Parent = kioskBase,
    })

    -- 6. Puntos de Spawn Elegantes y Sobrios
    local spawnsFolder = Instance.new("Folder")
    spawnsFolder.Name = "SpawnPads"
    spawnsFolder.Parent = lobbyFolder

    local spawnCount = cfg.SpawnCount
    local cols = 5
    local rows = math.ceil(spawnCount / cols)

    for i = 1, spawnCount do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local sx = center.X - 30 + (col * 15)
        local sz = backZ + 16 + (row * 14)
        local sy = floorY + 0.1

        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "ObservationSpawn_" .. i
        spawn.Size = Vector3.new(6, 0.25, 6)
        spawn.CFrame = CFrame.new(sx, sy, sz)
        spawn.Anchored = true
        spawn.CanCollide = true
        spawn.Neutral = true
        spawn.Material = theme.SpawnPad.Material
        spawn.Color = theme.SpawnPad.Color
        spawn.Reflectance = theme.SpawnPad.Reflectance
        spawn.TopSurface = Enum.SurfaceType.Smooth
        spawn.BottomSurface = Enum.SurfaceType.Smooth
        spawn.CastShadow = false
        spawn.Parent = spawnsFolder

        -- Borde blanco sutil
        PartTextures.CreatePart({
            Name = "SpawnBorder",
            Size = Vector3.new(6.6, 0.15, 6.6),
            CFrame = CFrame.new(sx, sy - 0.08, sz),
            Material = theme.AccentTrim.Material,
            Color = theme.AccentTrim.Color,
            CastShadow = false,
            Parent = spawn,
        })
    end

    -- 7. Muros de Contención Invisibles (Jaula de Seguridad Absoluta)
    -- Los jugadores NO pueden saltar hacia la isla; deben usar el teletransporte.
    local cageFolder = Instance.new("Folder")
    cageFolder.Name = "SafetyCage"
    cageFolder.Parent = lobbyFolder

    local cageWalls = {
        -- Frontal (sobre el mirador de cristal)
        { Size = Vector3.new(size.X + 10, barrierHeight, 3), Pos = Vector3.new(center.X, floorY + barrierHeight / 2, frontZ + 1.5) },
        -- Posterior
        { Size = Vector3.new(size.X + 10, barrierHeight, 3), Pos = Vector3.new(center.X, floorY + barrierHeight / 2, backZ - 1.5) },
        -- Izquierdo
        { Size = Vector3.new(3, barrierHeight, size.Z + 10), Pos = Vector3.new(leftX - 1.5, floorY + barrierHeight / 2, center.Z) },
        -- Derecho
        { Size = Vector3.new(3, barrierHeight, size.Z + 10), Pos = Vector3.new(rightX + 1.5, floorY + barrierHeight / 2, center.Z) },
        -- Techo invisible
        { Size = Vector3.new(size.X + 14, 3, size.Z + 14), Pos = Vector3.new(center.X, floorY + barrierHeight + 1.5, center.Z) },
    }

    for i, cWall in ipairs(cageWalls) do
        PartTextures.CreatePart({
            Name = "InvisibleBarrier_" .. i,
            Size = cWall.Size,
            CFrame = CFrame.new(cWall.Pos),
            Transparency = 1,
            CanCollide = true,
            CastShadow = false,
            Parent = cageFolder,
        })
    end

    lobbyFolder.Parent = Workspace
    print(string.format("[LobbyGeneration] Plataforma de observación generada en %s con vista directa a la isla.", tostring(center)))

    return lobbyFolder
end

return LobbyGeneration

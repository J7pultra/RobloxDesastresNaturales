--!strict
--[[
    EnvironmentConfig.lua
    Configuración centralizada para el entorno de escala masiva (840x840 studs).
    Lobby elevado con vista aérea panorámica y temas para el mapa orgánico con ruido Perlin.
]]

local EnvironmentConfig = {}

-- ============================================================================
-- COORDENADAS Y POSICIONAMIENTO DEL LOBBY
-- ============================================================================
EnvironmentConfig.Lobby = {
    -- Vista aérea panorámica dominante sobre la isla masiva de 840 studs
    Position = Vector3.new(0, 210, -460),
    Size = Vector3.new(110, 16, 70),
    BarrierHeight = 40,
    SpawnCount = 12,
    Theme = {
        MainFloor = {
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(42, 44, 48), -- Gris grafito sobrio
            Reflectance = 0.05,
        },
        SecondaryFloor = {
            Material = Enum.Material.Metal,
            Color = Color3.fromRGB(35, 37, 40),
            Reflectance = 0.12,
        },
        AccentTrim = {
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(225, 228, 232), -- Blanco suave minimalista
            Reflectance = 0.08,
        },
        StructuralPillars = {
            Material = Enum.Material.Metal,
            Color = Color3.fromRGB(28, 30, 34),
            Reflectance = 0.15,
        },
        ObservationGlass = {
            Material = Enum.Material.Glass,
            Color = Color3.fromRGB(200, 220, 240),
            Transparency = 0.75,
            Reflectance = 0.35,
        },
        RailingMetal = {
            Material = Enum.Material.Metal,
            Color = Color3.fromRGB(80, 84, 90),
            Reflectance = 0.2,
        },
        BenchWood = {
            Material = Enum.Material.WoodPlanks,
            Color = Color3.fromRGB(75, 55, 40),
            Reflectance = 0.02,
        },
        SpawnPad = {
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(60, 64, 70),
            Reflectance = 0.06,
        },
    }
}

-- ============================================================================
-- CONFIGURACIÓN DE LA ISLA MASIVA (MAPA GIGANTE 840x840 STUDS)
-- ============================================================================
EnvironmentConfig.Island = {
    Position = Vector3.new(0, 0, 0),
    Dimensions = Vector2.new(840, 840), -- Escala masiva (840x840 studs)
    GridResolution = 20, -- Tamaño de cada celda del terreno orgánico
    BaseSeaElevation = 5,
    PeakElevation = 45, -- Altura máxima de crestas y colinas
    OceanDimensions = Vector2.new(1900, 1900), -- Perímetro oceánico infinito
    WaterLevel = 0,
    Theme = {
        CoastSand = {
            Material = Enum.Material.Sand,
            Color = Color3.fromRGB(215, 198, 155), -- Arena cálida suave
            Reflectance = 0.02,
        },
        LowlandGrass = {
            Material = Enum.Material.Grass,
            Color = Color3.fromRGB(82, 128, 55), -- Césped natural limpio
            Reflectance = 0.02,
        },
        HighlandGrass = {
            Material = Enum.Material.LeafyGrass,
            Color = Color3.fromRGB(68, 110, 45), -- Césped montañoso denso
            Reflectance = 0.03,
        },
        RidgeRock = {
            Material = Enum.Material.Slate,
            Color = Color3.fromRGB(80, 84, 88), -- Pizarra rocosa
            Reflectance = 0.04,
        },
        RoadConcrete = {
            Material = Enum.Material.Concrete,
            Color = Color3.fromRGB(65, 68, 72), -- Asfalto / Calzada urbana
            Reflectance = 0.05,
        },
        RoadPavement = {
            Material = Enum.Material.SmoothPlastic,
            Color = Color3.fromRGB(180, 182, 186), -- Aceras peatonales
            Reflectance = 0.02,
        },
        Ocean = {
            Material = Enum.Material.Glass,
            Color = Color3.fromRGB(25, 95, 160),
            Transparency = 0.45,
            Reflectance = 0.4,
        },
        OceanDeep = {
            Material = Enum.Material.Slate,
            Color = Color3.fromRGB(20, 25, 32),
        },
        -- Naturaleza
        TreeTrunk = {
            Material = Enum.Material.Wood,
            Color = Color3.fromRGB(85, 58, 38),
            Reflectance = 0.02,
        },
        TreeLeaves = {
            Material = Enum.Material.LeafyGrass,
            Color = Color3.fromRGB(42, 92, 40),
            Reflectance = 0.02,
        },
        RockFormation = {
            Material = Enum.Material.Slate,
            Color = Color3.fromRGB(75, 78, 82),
            Reflectance = 0.05,
        },
        -- Arquitectura Avanzada (Tratamiento de caras y fachadas cortina)
        CorporateConcrete = {
            Material = Enum.Material.Concrete,
            Color = Color3.fromRGB(220, 222, 226), -- Blanco hormigón arquitectónico
            Reflectance = 0.05,
        },
        DarkMullion = {
            Material = Enum.Material.Metal,
            Color = Color3.fromRGB(36, 38, 44), -- Acero grafito para montantes verticales
            Reflectance = 0.18,
        },
        CurtainGlass = {
            Material = Enum.Material.Glass,
            Color = Color3.fromRGB(165, 205, 235), -- Muro cortina de cristal reflectante
            Transparency = 0.6,
            Reflectance = 0.5,
        },
        BunkerConcrete = {
            Material = Enum.Material.Concrete,
            Color = Color3.fromRGB(115, 118, 122), -- Hormigón blindado pesado
            Reflectance = 0.02,
        },
        IndustrialMetal = {
            Material = Enum.Material.Metal,
            Color = Color3.fromRGB(55, 58, 65),
            Reflectance = 0.15,
        },
        RoofAccent = {
            Material = Enum.Material.Metal,
            Color = Color3.fromRGB(32, 34, 38),
            Reflectance = 0.12,
        }
    }
}

-- ============================================================================
-- ILUMINACIÓN CINEMATOGRÁFICA NATURAL
-- ============================================================================
EnvironmentConfig.Lighting = {
    Technology = Enum.Technology.Future,
    ClockTime = 14.2,
    GeographicLatitude = 25,
    Brightness = 2.2,
    OutdoorAmbient = Color3.fromRGB(75, 80, 90),
    Ambient = Color3.fromRGB(45, 48, 55),
    ColorShift_Top = Color3.fromRGB(255, 250, 240),
    ColorShift_Bottom = Color3.fromRGB(150, 160, 175),
    EnvironmentDiffuseScale = 1.0,
    EnvironmentSpecularScale = 1.0,
    ShadowSoftness = 0.25,
    Atmosphere = {
        Density = 0.28,
        Offset = 0.1,
        Color = Color3.fromRGB(200, 218, 238),
        Decay = Color3.fromRGB(115, 130, 150),
        Glare = 0.25,
        Haze = 1.2,
    },
    Bloom = {
        Intensity = 0.25,
        Size = 16,
        Threshold = 2.0,
    },
    ColorCorrection = {
        Brightness = 0.01,
        Contrast = 0.1,
        Saturation = 0.1,
        TintColor = Color3.fromRGB(255, 254, 250),
    },
    SunRays = {
        Intensity = 0.08,
        Spread = 0.7,
    }
}

return table.freeze(EnvironmentConfig)

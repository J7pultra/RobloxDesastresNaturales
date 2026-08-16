--!strict
--[[
    IslandGeneration.lua (Fase 3 - Realismo Avanzado y Anti-Clipping)
    
    Características Principales:
    1. Sistema Anti-Clipping con Raycasting (workspace:Raycast) y Cimientos Inteligentes Subterráneos.
    2. Terreno Realista y Continuo: Bloques profundos solapados y soporte para Smooth Terrain nativo.
    3. Urbanismo Completo:
       - Rascacielos Corporativo de 6 Pisos con Helipuerto y Muro Cortina.
       - Edificio Tecnológico de 4 Pisos con azotea y parapeto.
       - Torre de Observación con Escalera en Espiral.
       - Búnker Militar Blindado.
       - Muelle Costero de Madera (Pier) sobre pilotes en el mar.
    4. Mobiliario Urbano y Densidad:
       - Postes de luz / Farolas con PointLight cálida.
       - Bancos de parque (Madera y Metal).
       - Vallas de seguridad.
       - Arbustos densos, rocas asimétricas y bosques orgánicos agrupados.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentConfig = require(ReplicatedStorage.SharedConfigs.EnvironmentConfig)
local PartTextures = require(script.Parent.Parent.VisualEffects.PartTextures)

local IslandGeneration = {}

-- ============================================================================
-- UTILIDAD: RAYCASTING ANTI-CLIPPING Y ALTURA DE SUPERFICIE
-- ============================================================================

local function getSurfaceY(x: number, z: number, fallbackY: number, targetFolder: Instance?): (number, Vector3)
    local rayOrigin = Vector3.new(x, 500, z)
    local rayDir = Vector3.new(0, -1000, 0)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local filterList = {}
    local currentMap = Workspace:FindFirstChild("CurrentMap")
    if currentMap then
        table.insert(filterList, currentMap)
    end
    if targetFolder then
        table.insert(filterList, targetFolder)
    end

    params.FilterDescendantsInstances = filterList

    local result = Workspace:Raycast(rayOrigin, rayDir, params)
    if result then
        return result.Position.Y, result.Normal
    end
    return fallbackY, Vector3.new(0, 1, 0)
end

-- ============================================================================
-- 1. CONSTRUCCIÓN DE CIMIENTOS INTELIGENTES Y PRISMAS ESTRUCTURALES
-- ============================================================================

local function buildFoundationPlinth(parent: Instance, centerPos: Vector3, size: Vector3, theme: any): Part
    -- Cimiento extendido hacia el subsuelo para evitar huecos en pendientes
    local plinthDepth = 22
    local plinth = PartTextures.CreatePart({
        Name = "DeepFoundationPlinth",
        Size = Vector3.new(size.X + 4, plinthDepth, size.Z + 4),
        CFrame = CFrame.new(centerPos.X, centerPos.Y - (plinthDepth / 2) + 2, centerPos.Z),
        Material = theme.CorporateConcrete.Material,
        Color = Color3.fromRGB(125, 128, 132),
        Parent = parent,
    })
    return plinth
end

local function buildAdvancedFloor(props: {
    Parent: Instance,
    Name: string,
    CenterPos: Vector3,
    Size: Vector3,
    WallThickness: number?,
    Theme: any,
    MullionSpacing: number?,
    Doorway: { Face: "Front" | "Back" | "Left" | "Right", Width: number, Height: number }?,
    IsGroundFloor: boolean?,
}): { Floor: Part, Roof: Part, Model: Model }
    local floorModel = Instance.new("Model")
    floorModel.Name = props.Name
    floorModel.Parent = props.Parent

    local c = props.CenterPos
    local w = props.Size.X
    local h = props.Size.Y
    local d = props.Size.Z
    local t = props.WallThickness or 1.4
    local theme = props.Theme
    local spacing = props.MullionSpacing or 6.0

    local halfW = w / 2
    local halfH = h / 2
    local halfD = d / 2

    -- Losa de Suelo
    local floorSlab = PartTextures.CreatePart({
        Name = "FloorSlab",
        Size = Vector3.new(w, 1.2, d),
        CFrame = CFrame.new(c.X, c.Y + 0.6, c.Z),
        Material = theme.CorporateConcrete.Material,
        Color = Color3.fromRGB(65, 68, 74),
        Parent = floorModel,
    })

    -- Losa de Techo
    local roofSlab = PartTextures.CreatePart({
        Name = "RoofSlab",
        Size = Vector3.new(w + 0.4, 1.2, d + 0.4),
        CFrame = CFrame.new(c.X, c.Y + h - 0.6, c.Z),
        Material = theme.CorporateConcrete.Material,
        Color = theme.CorporateConcrete.Color,
        Parent = floorModel,
    })

    -- Columnas de esquina estructurales continuas
    local cornerPositions = {
        Vector3.new(-halfW + t * 0.8, halfH, -halfD + t * 0.8),
        Vector3.new(halfW - t * 0.8, halfH, -halfD + t * 0.8),
        Vector3.new(-halfW + t * 0.8, halfH, halfD - t * 0.8),
        Vector3.new(halfW - t * 0.8, halfH, halfD - t * 0.8),
    }
    for i, cp in ipairs(cornerPositions) do
        PartTextures.CreatePart({
            Name = "CornerPillar_" .. i,
            Size = Vector3.new(t * 1.6, h, t * 1.6),
            CFrame = CFrame.new(c + cp),
            Material = theme.DarkMullion.Material,
            Color = theme.DarkMullion.Color,
            Parent = floorModel,
        })
    end

    -- Tratamiento de fachadas
    local function generateFace(face: "Front" | "Back" | "Left" | "Right")
        local isFront = (face == "Front")
        local isBack = (face == "Back")
        local isLeft = (face == "Left")
        local isRight = (face == "Right")

        local faceWidth = if (isFront or isBack) then (w - t * 2) else (d - t * 2)
        local count = math.max(2, math.floor(faceWidth / spacing))
        local step = faceWidth / count

        local hasDoor = (props.Doorway and props.Doorway.Face == face)

        if hasDoor and props.Doorway then
            local doorW = props.Doorway.Width
            local doorH = props.Doorway.Height
            local sideW = (faceWidth - doorW) / 2

            PartTextures.CreatePart({
                Name = face .. "_EntranceL",
                Size = Vector3.new(sideW, h, t),
                CFrame = CFrame.new(c.X - halfW + t + sideW / 2, c.Y + halfH, c.Z + halfD - t / 2),
                Material = theme.CorporateConcrete.Material,
                Color = theme.CorporateConcrete.Color,
                Parent = floorModel,
            })
            PartTextures.CreatePart({
                Name = face .. "_EntranceR",
                Size = Vector3.new(sideW, h, t),
                CFrame = CFrame.new(c.X + halfW - t - sideW / 2, c.Y + halfH, c.Z + halfD - t / 2),
                Material = theme.CorporateConcrete.Material,
                Color = theme.CorporateConcrete.Color,
                Parent = floorModel,
            })

            -- Marco y dintel de entrada
            PartTextures.CreatePart({
                Name = face .. "_DoorFrameTop",
                Size = Vector3.new(doorW, h - doorH, t),
                CFrame = CFrame.new(c.X, c.Y + doorH + (h - doorH) / 2, c.Z + halfD - t / 2),
                Material = theme.DarkMullion.Material,
                Color = theme.DarkMullion.Color,
                Parent = floorModel,
            })
            return
        end

        -- Cristal reflectante de fachada
        local glassCFrame = if isFront then CFrame.new(c.X, c.Y + halfH, c.Z + halfD - t / 2)
            elseif isBack then CFrame.new(c.X, c.Y + halfH, c.Z - halfD + t / 2)
            elseif isLeft then CFrame.new(c.X - halfW + t / 2, c.Y + halfH, c.Z)
            else CFrame.new(c.X + halfW - t / 2, c.Y + halfH, c.Z)

        local glassSize = if (isFront or isBack) then Vector3.new(faceWidth, h - 1.2, 0.4)
            else Vector3.new(0.4, h - 1.2, faceWidth)

        PartTextures.CreatePart({
            Name = "CurtainGlass_" .. face,
            Size = glassSize,
            CFrame = glassCFrame,
            Material = theme.CurtainGlass.Material,
            Color = theme.CurtainGlass.Color,
            Transparency = theme.CurtainGlass.Transparency,
            Reflectance = theme.CurtainGlass.Reflectance,
            Parent = floorModel,
        })

        -- Montantes verticales arquitectónicos
        for i = 1, count - 1 do
            local off = -faceWidth / 2 + (i * step)
            local mCF = if isFront then CFrame.new(c.X + off, c.Y + halfH, c.Z + halfD - t / 2)
                elseif isBack then CFrame.new(c.X + off, c.Y + halfH, c.Z - halfD + t / 2)
                elseif isLeft then CFrame.new(c.X - halfW + t / 2, c.Y + halfH, c.Z + off)
                else CFrame.new(c.X + halfW - t / 2, c.Y + halfH, c.Z + off)

            PartTextures.CreatePart({
                Name = "Mullion_" .. face .. "_" .. i,
                Size = Vector3.new(0.8, h, 0.8),
                CFrame = mCF,
                Material = theme.DarkMullion.Material,
                Color = theme.DarkMullion.Color,
                Parent = floorModel,
            })
        end
    end

    generateFace("Front")
    generateFace("Back")
    generateFace("Left")
    generateFace("Right")

    return { Floor = floorSlab, Roof = roofSlab, Model = floorModel }
end

-- ============================================================================
-- 2. EDIFICIOS CORPORATIVOS Y REFUGIOS (4 A 6 PISOS CON PARAPETOS)
-- ============================================================================

-- Rascacielos Corporativo de 6 Pisos
local function buildCorporateSkyscraper(parent: Instance, basePos: Vector3, theme: any): Model
    local tower = Instance.new("Model")
    tower.Name = "Skyscraper_Corporate_6Story"
    tower.Parent = parent

    local bWidth = 54
    local bDepth = 48
    local floorH = 11
    local totalFloors = 6

    -- Cimiento profundo
    buildFoundationPlinth(tower, basePos, Vector3.new(bWidth, 1, bDepth), theme)

    -- Pisos
    for f = 1, totalFloors do
        local floorY = basePos.Y + 2 + ((f - 1) * floorH)
        local isGround = (f == 1)

        local doorConfig = nil
        if isGround then
            doorConfig = { Face = "Front" :: "Front", Width = 14, Height = 8.5 }
        end

        buildAdvancedFloor({
            Parent = tower,
            Name = string.format("Floor_Level_%d", f),
            CenterPos = Vector3.new(basePos.X, floorY, basePos.Z),
            Size = Vector3.new(bWidth, floorH, bDepth),
            Theme = theme,
            MullionSpacing = 5.5,
            Doorway = doorConfig,
            IsGroundFloor = isGround,
        })
    end

    -- Escalera interior continua
    for fl = 1, totalFloors - 1 do
        local sBaseY = basePos.Y + 2 + ((fl - 1) * floorH)
        for s = 1, 10 do
            local sY = sBaseY + (s * (floorH / 10))
            local sZ = (basePos.Z - bDepth / 4) + (s * 1.5)
            PartTextures.CreatePart({
                Name = string.format("Stair_Fl%d_S%d", fl, s),
                Size = Vector3.new(6, 0.6, 1.8),
                CFrame = CFrame.new(basePos.X - bWidth / 3, sY, sZ),
                Material = theme.DarkMullion.Material,
                Color = theme.DarkMullion.Color,
                Parent = tower,
            })
        end
    end

    -- Azotea con Parapeto de Seguridad y Helipuerto
    local roofY = basePos.Y + 2 + (totalFloors * floorH)
    local parapetH = 3.5
    local parapets = {
        { Size = Vector3.new(bWidth + 2, parapetH, 1.2), Pos = Vector3.new(0, parapetH / 2, -bDepth / 2) },
        { Size = Vector3.new(bWidth + 2, parapetH, 1.2), Pos = Vector3.new(0, parapetH / 2, bDepth / 2) },
        { Size = Vector3.new(1.2, parapetH, bDepth), Pos = Vector3.new(-bWidth / 2, parapetH / 2, 0) },
        { Size = Vector3.new(1.2, parapetH, bDepth), Pos = Vector3.new(bWidth / 2, parapetH / 2, 0) },
    }
    for i, p in ipairs(parapets) do
        PartTextures.CreatePart({
            Name = "RoofParapet_" .. i,
            Size = p.Size,
            CFrame = CFrame.new(basePos.X + p.Pos.X, roofY + p.Pos.Y, basePos.Z + p.Pos.Z),
            Material = theme.DarkMullion.Material,
            Color = theme.DarkMullion.Color,
            Parent = tower,
        })
    end

    -- Helipuerto
    local helipad = PartTextures.CreateCylinder({
        Name = "Helipad",
        Size = Vector3.new(1.5, 30, 30),
        CFrame = CFrame.new(basePos.X, roofY + 0.8, basePos.Z) * CFrame.Angles(0, 0, math.rad(90)),
        Material = theme.DarkMullion.Material,
        Color = Color3.fromRGB(38, 40, 45),
        Parent = tower,
    })

    PartTextures.CreatePart({
        Name = "Helipad_H1",
        Size = Vector3.new(2, 0.2, 14),
        CFrame = CFrame.new(basePos.X - 4, roofY + 1.6, basePos.Z),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(245, 245, 248),
        Parent = helipad,
    })
    PartTextures.CreatePart({
        Name = "Helipad_H2",
        Size = Vector3.new(2, 0.2, 14),
        CFrame = CFrame.new(basePos.X + 4, roofY + 1.6, basePos.Z),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(245, 245, 248),
        Parent = helipad,
    })
    PartTextures.CreatePart({
        Name = "Helipad_HBar",
        Size = Vector3.new(8, 0.2, 2.5),
        CFrame = CFrame.new(basePos.X, roofY + 1.6, basePos.Z),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(245, 245, 248),
        Parent = helipad,
    })

    return tower
end

-- Edificio de Tecnología de 4 Pisos
local function buildTechCenter(parent: Instance, basePos: Vector3, theme: any): Model
    local model = Instance.new("Model")
    model.Name = "TechCenter_4Story"
    model.Parent = parent

    local bWidth = 44
    local bDepth = 40
    local floorH = 11
    local totalFloors = 4

    buildFoundationPlinth(model, basePos, Vector3.new(bWidth, 1, bDepth), theme)

    for f = 1, totalFloors do
        local floorY = basePos.Y + 2 + ((f - 1) * floorH)
        local isGround = (f == 1)

        local doorConfig = nil
        if isGround then
            doorConfig = { Face = "Front" :: "Front", Width = 12, Height = 8.5 }
        end

        buildAdvancedFloor({
            Parent = model,
            Name = string.format("Floor_Level_%d", f),
            CenterPos = Vector3.new(basePos.X, floorY, basePos.Z),
            Size = Vector3.new(bWidth, floorH, bDepth),
            Theme = theme,
            MullionSpacing = 6.0,
            Doorway = doorConfig,
            IsGroundFloor = isGround,
        })
    end

    -- Parapeto de azotea
    local roofY = basePos.Y + 2 + (totalFloors * floorH)
    PartTextures.CreatePart({
        Name = "RooftopMachinery",
        Size = Vector3.new(18, 6, 16),
        CFrame = CFrame.new(basePos.X, roofY + 3, basePos.Z),
        Material = theme.DarkMullion.Material,
        Color = theme.DarkMullion.Color,
        Parent = model,
    })

    return model
end

-- Torre de Observación
local function buildObservationTower(parent: Instance, basePos: Vector3, theme: any): Model
    local tower = Instance.new("Model")
    tower.Name = "CoastalObservationTower"
    tower.Parent = parent

    local tW = 18
    local tH = 54
    local wallT = 1.8

    buildFoundationPlinth(tower, basePos, Vector3.new(tW, 1, tW), theme)

    -- Muros verticales cerrados
    local shaftH = tH - 12
    PartTextures.CreatePart({
        Name = "ShaftWallBack",
        Size = Vector3.new(tW, shaftH, wallT),
        CFrame = CFrame.new(basePos.X, basePos.Y + shaftH / 2 + 2, basePos.Z - tW / 2 + wallT / 2),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = tower,
    })
    PartTextures.CreatePart({
        Name = "ShaftWallLeft",
        Size = Vector3.new(wallT, shaftH, tW - wallT * 2),
        CFrame = CFrame.new(basePos.X - tW / 2 + wallT / 2, basePos.Y + shaftH / 2 + 2, basePos.Z),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = tower,
    })
    PartTextures.CreatePart({
        Name = "ShaftWallRight",
        Size = Vector3.new(wallT, shaftH, tW - wallT * 2),
        CFrame = CFrame.new(basePos.X + tW / 2 - wallT / 2, basePos.Y + shaftH / 2 + 2, basePos.Z),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = tower,
    })

    -- Entrada frontal
    local doorH = 9
    local doorW = 8
    local sideW = (tW - doorW) / 2
    PartTextures.CreatePart({
        Name = "ShaftFrontL",
        Size = Vector3.new(sideW, doorH, wallT),
        CFrame = CFrame.new(basePos.X - tW / 2 + sideW / 2, basePos.Y + doorH / 2 + 2, basePos.Z + tW / 2 - wallT / 2),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = tower,
    })
    PartTextures.CreatePart({
        Name = "ShaftFrontR",
        Size = Vector3.new(sideW, doorH, wallT),
        CFrame = CFrame.new(basePos.X + tW / 2 - sideW / 2, basePos.Y + doorH / 2 + 2, basePos.Z + tW / 2 - wallT / 2),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = tower,
    })
    PartTextures.CreatePart({
        Name = "ShaftFrontUpper",
        Size = Vector3.new(tW, shaftH - doorH, wallT),
        CFrame = CFrame.new(basePos.X, basePos.Y + doorH + (shaftH - doorH) / 2 + 2, basePos.Z + tW / 2 - wallT / 2),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = tower,
    })

    -- Escalera helicoidal
    for s = 1, 26 do
        local ang = s * (math.pi / 3.5)
        local sY = basePos.Y + 2.5 + (s * (shaftH / 26))
        local rad = 5.2
        PartTextures.CreatePart({
            Name = "SpiralStep_" .. s,
            Size = Vector3.new(5, 0.7, 1.8),
            CFrame = CFrame.new(basePos.X + math.cos(ang) * rad, sY, basePos.Z + math.sin(ang) * rad) * CFrame.Angles(0, -ang + math.pi / 2, 0),
            Material = theme.DarkMullion.Material,
            Color = theme.DarkMullion.Color,
            Parent = tower,
        })
    end

    -- Cabina 360°
    local cabinY = basePos.Y + shaftH + 2
    local cabinW = tW + 4
    buildAdvancedFloor({
        Parent = tower,
        Name = "ObservationCabin",
        CenterPos = Vector3.new(basePos.X, cabinY, basePos.Z),
        Size = Vector3.new(cabinW, 12, cabinW),
        Theme = theme,
        MullionSpacing = 4.5,
    })

    return tower
end

-- Búnker Militar
local function buildMilitaryBunker(parent: Instance, basePos: Vector3, theme: any): Model
    local bunker = Instance.new("Model")
    bunker.Name = "MilitaryBunker"
    bunker.Parent = parent

    local bW = 54
    local bH = 16
    local bD = 40
    local wallT = 3.5

    buildFoundationPlinth(bunker, basePos, Vector3.new(bW, 1, bD), theme)

    -- Muros blindados
    PartTextures.CreatePart({
        Name = "BunkerWallBack",
        Size = Vector3.new(bW, bH, wallT),
        CFrame = CFrame.new(basePos.X, basePos.Y + bH / 2 + 2, basePos.Z - bD / 2 + wallT / 2),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunker,
    })
    PartTextures.CreatePart({
        Name = "BunkerWallLeft",
        Size = Vector3.new(wallT, bH, bD - wallT * 2),
        CFrame = CFrame.new(basePos.X - bW / 2 + wallT / 2, basePos.Y + bH / 2 + 2, basePos.Z),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunker,
    })
    PartTextures.CreatePart({
        Name = "BunkerWallRight",
        Size = Vector3.new(wallT, bH, bD - wallT * 2),
        CFrame = CFrame.new(basePos.X + bW / 2 - wallT / 2, basePos.Y + bH / 2 + 2, basePos.Z),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunker,
    })

    local doorW = 16
    local sideFrontW = (bW - doorW) / 2
    PartTextures.CreatePart({
        Name = "BunkerFrontL",
        Size = Vector3.new(sideFrontW, bH, wallT),
        CFrame = CFrame.new(basePos.X - bW / 2 + sideFrontW / 2, basePos.Y + bH / 2 + 2, basePos.Z + bD / 2 - wallT / 2),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunker,
    })
    PartTextures.CreatePart({
        Name = "BunkerFrontR",
        Size = Vector3.new(sideFrontW, bH, wallT),
        CFrame = CFrame.new(basePos.X + bW / 2 - sideFrontW / 2, basePos.Y + bH / 2 + 2, basePos.Z + bD / 2 - wallT / 2),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunker,
    })
    PartTextures.CreatePart({
        Name = "BunkerDoorHeader",
        Size = Vector3.new(doorW, 6, wallT),
        CFrame = CFrame.new(basePos.X, basePos.Y + bH - 1, basePos.Z + bD / 2 - wallT / 2),
        Material = theme.IndustrialMetal.Material,
        Color = theme.IndustrialMetal.Color,
        Parent = bunker,
    })

    -- Techo reforzado
    PartTextures.CreatePart({
        Name = "BunkerHeavyRoof",
        Size = Vector3.new(bW + 4, 3, bD + 4),
        CFrame = CFrame.new(basePos.X, basePos.Y + bH + 3.5, basePos.Z),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunker,
    })

    return bunker
end

-- ============================================================================
-- 3. PUNTO DE INTERÉS: MUELLE COSTERO DE MADERA (PIER)
-- ============================================================================

local function buildCoastalPier(parent: Instance, startPos: Vector3, length: number, theme: any): Model
    local pier = Instance.new("Model")
    pier.Name = "CoastalWoodPier"
    pier.Parent = parent

    local pierWidth = 14
    local deckY = 4.5
    local pileSpacing = 16
    local pileCount = math.floor(length / pileSpacing)

    -- Tablones principales del muelle
    PartTextures.CreatePart({
        Name = "PierDeck",
        Size = Vector3.new(pierWidth, 1.2, length),
        CFrame = CFrame.new(startPos.X, deckY, startPos.Z + (length / 2)),
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(115, 80, 50),
        Parent = pier,
    })

    -- Pilotes de madera que entran al agua
    for i = 0, pileCount do
        local pZ = startPos.Z + (i * pileSpacing)
        local pileHeight = 24
        -- Pilote izquierdo
        PartTextures.CreateCylinder({
            Name = "PierStilt_L_" .. i,
            Size = Vector3.new(pileHeight, 2.2, 2.2),
            CFrame = CFrame.new(startPos.X - (pierWidth / 2) + 1.2, deckY - (pileHeight / 2) + 0.6, pZ) * CFrame.Angles(0, 0, math.rad(90)),
            Material = Enum.Material.Wood,
            Color = Color3.fromRGB(75, 50, 32),
            Parent = pier,
        })
        -- Pilote derecho
        PartTextures.CreateCylinder({
            Name = "PierStilt_R_" .. i,
            Size = Vector3.new(pileHeight, 2.2, 2.2),
            CFrame = CFrame.new(startPos.X + (pierWidth / 2) - 1.2, deckY - (pileHeight / 2) + 0.6, pZ) * CFrame.Angles(0, 0, math.rad(90)),
            Material = Enum.Material.Wood,
            Color = Color3.fromRGB(75, 50, 32),
            Parent = pier,
        })

        -- Bolardos de amarre
        PartTextures.CreateCylinder({
            Name = "MooringBollard_" .. i,
            Size = Vector3.new(2.2, 1.2, 1.2),
            CFrame = CFrame.new(startPos.X + (pierWidth / 2) - 0.8, deckY + 1.7, pZ) * CFrame.Angles(0, 0, math.rad(90)),
            Material = theme.IndustrialMetal.Material,
            Color = theme.IndustrialMetal.Color,
            Parent = pier,
        })
    end

    -- Farol al final del muelle
    local endZ = startPos.Z + length - 2
    local post = PartTextures.CreateCylinder({
        Name = "PierLanternPost",
        Size = Vector3.new(10, 0.8, 0.8),
        CFrame = CFrame.new(startPos.X, deckY + 5.6, endZ) * CFrame.Angles(0, 0, math.rad(90)),
        Material = theme.DarkMullion.Material,
        Color = theme.DarkMullion.Color,
        Parent = pier,
    })
    local lampHead = PartTextures.CreatePart({
        Name = "LanternBulb",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(1.8, 1.8, 1.8),
        CFrame = CFrame.new(startPos.X, deckY + 10.8, endZ),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(255, 225, 150),
        Parent = pier,
    })
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 230, 160)
    light.Range = 24
    light.Brightness = 2.5
    light.Parent = lampHead

    return pier
end

-- ============================================================================
-- 4. MOBILIARIO URBANO (FAROLAS, BANCOS, ARBUSTOS, ROCAS Y CAMINOS)
-- ============================================================================

local function spawnStreetLamp(parent: Instance, pos: Vector3, theme: any)
    local lampModel = Instance.new("Model")
    lampModel.Name = "StreetLamp"

    -- Poste
    PartTextures.CreateCylinder({
        Name = "Pole",
        Size = Vector3.new(14, 0.9, 0.9),
        CFrame = CFrame.new(pos.X, pos.Y + 7, pos.Z) * CFrame.Angles(0, 0, math.rad(90)),
        Material = theme.DarkMullion.Material,
        Color = theme.DarkMullion.Color,
        Parent = lampModel,
    })

    -- Brazo voladizo
    PartTextures.CreatePart({
        Name = "Arm",
        Size = Vector3.new(3, 0.6, 0.6),
        CFrame = CFrame.new(pos.X + 1.2, pos.Y + 13.8, pos.Z),
        Material = theme.DarkMullion.Material,
        Color = theme.DarkMullion.Color,
        Parent = lampModel,
    })

    -- Bombilla / Luminaria
    local bulb = PartTextures.CreatePart({
        Name = "LampBulb",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(1.6, 1.6, 1.6),
        CFrame = CFrame.new(pos.X + 2.4, pos.Y + 13.2, pos.Z),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(255, 230, 160),
        Parent = lampModel,
    })

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 235, 175)
    light.Range = 26
    light.Brightness = 2.0
    light.Parent = bulb

    lampModel.Parent = parent
end

local function spawnParkBench(parent: Instance, pos: Vector3, angle: number, theme: any)
    local bench = Instance.new("Model")
    bench.Name = "ParkBench"

    local cf = CFrame.new(pos) * CFrame.Angles(0, angle, 0)

    -- Asiento de madera
    PartTextures.CreatePart({
        Name = "BenchSeat",
        Size = Vector3.new(7, 0.5, 2.4),
        CFrame = cf * CFrame.new(0, 1.2, 0),
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(115, 80, 50),
        Parent = bench,
    })
    -- Respaldo
    PartTextures.CreatePart({
        Name = "BenchBack",
        Size = Vector3.new(7, 1.8, 0.4),
        CFrame = cf * CFrame.new(0, 2.2, -1.0),
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(115, 80, 50),
        Parent = bench,
    })
    -- Patas de metal
    PartTextures.CreatePart({
        Name = "LegL",
        Size = Vector3.new(0.5, 1.6, 2.4),
        CFrame = cf * CFrame.new(-3.1, 0.8, 0),
        Material = theme.DarkMullion.Material,
        Color = theme.DarkMullion.Color,
        Parent = bench,
    })
    PartTextures.CreatePart({
        Name = "LegR",
        Size = Vector3.new(0.5, 1.6, 2.4),
        CFrame = cf * CFrame.new(3.1, 0.8, 0),
        Material = theme.DarkMullion.Material,
        Color = theme.DarkMullion.Color,
        Parent = bench,
    })

    bench.Parent = parent
end

local function spawnBush(parent: Instance, pos: Vector3, scale: number, theme: any)
    local bush = PartTextures.CreatePart({
        Name = "Bush",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(6 * scale, 4 * scale, 6 * scale),
        CFrame = CFrame.new(pos.X, pos.Y + (2 * scale), pos.Z),
        Material = theme.TreeLeaves.Material,
        Color = theme.TreeLeaves.Color,
        Parent = parent,
    })
end

local function spawnOrganicTree(parent: Instance, pos: Vector3, scale: number, theme: any)
    local treeModel = Instance.new("Model")
    treeModel.Name = "Tree"

    local trunkH = (14 + math.random(-2, 4)) * scale
    local trunkR = (1.6 + (math.random(-2, 2) * 0.1)) * scale

    PartTextures.CreateCylinder({
        Name = "Trunk",
        Size = Vector3.new(trunkH, trunkR * 2, trunkR * 2),
        CFrame = CFrame.new(pos.X, pos.Y + (trunkH / 2), pos.Z) * CFrame.Angles(0, 0, math.rad(90)),
        Material = theme.TreeTrunk.Material,
        Color = theme.TreeTrunk.Color,
        Parent = treeModel,
    })

    for l = 1, 3 do
        local cSize = (14 - (l * 3) + math.random(-1, 2)) * scale
        local cY = pos.Y + (trunkH * (0.65 + (l * 0.28)))
        PartTextures.CreatePart({
            Name = "Canopy_" .. l,
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(cSize, cSize * 0.85, cSize),
            CFrame = CFrame.new(pos.X, cY, pos.Z),
            Material = theme.TreeLeaves.Material,
            Color = theme.TreeLeaves.Color,
            Parent = treeModel,
        })
    end

    treeModel.Parent = parent
end

local function spawnRockCluster(parent: Instance, pos: Vector3, scale: number, theme: any)
    local rockModel = Instance.new("Model")
    rockModel.Name = "RockCluster"

    local count = math.random(3, 5)
    for i = 1, count do
        local rSize = Vector3.new(
            math.random(7, 15) * scale,
            math.random(5, 11) * scale,
            math.random(7, 15) * scale
        )
        local offset = Vector3.new(
            math.random(-5, 5) * scale,
            (rSize.Y / 2) - 1,
            math.random(-5, 5) * scale
        )
        local rot = CFrame.Angles(
            math.rad(math.random(-25, 25)),
            math.rad(math.random(0, 360)),
            math.rad(math.random(-25, 25))
        )

        PartTextures.CreatePart({
            Name = "Rock_" .. i,
            Size = rSize,
            CFrame = CFrame.new(pos + offset) * rot,
            Material = theme.RockFormation.Material,
            Color = theme.RockFormation.Color,
            Reflectance = theme.RockFormation.Reflectance,
            Parent = rockModel,
        })
    end

    rockModel.Parent = parent
end

-- ============================================================================
-- 5. CONSTRUCCIÓN DE CAMINOS Y RED VIAL RAYCASTED
-- ============================================================================

local function buildOrganicPath(startP: Vector3, endP: Vector3, radius: number)
    local dist = (endP - startP).Magnitude
    local segments = math.max(2, math.floor(dist / 4))
    
    for i = 0, segments do
        local alpha = i / segments
        local targetX = startP.X + (endP.X - startP.X) * alpha
        local targetZ = startP.Z + (endP.Z - startP.Z) * alpha
        
        -- Raycast para encontrar la superficie en ese punto
        local surfaceY, _ = getSurfaceY(targetX, targetZ, 5.0, nil)
        
        Workspace.Terrain:FillBall(
            Vector3.new(targetX, surfaceY, targetZ),
            radius,
            Enum.Material.Cobblestone
        )
    end
end

-- ============================================================================
-- GENERACIÓN PRINCIPAL DE LA ISLA (840x840 STUDS)
-- ============================================================================

function IslandGeneration.BuildIsland(): Folder
    -- Destruir Baseplate al inicio de la generación
    if Workspace:FindFirstChild("Baseplate") then
        Workspace.Baseplate:Destroy()
    end

    -- Limpieza previa del mapa y terreno nativo
    Workspace.Terrain:Clear()
    local existingMap = Workspace:FindFirstChild("CurrentMap")
    if existingMap then
        existingMap:Destroy()
    end

    local mapFolder = Instance.new("Folder")
    mapFolder.Name = "CurrentMap"
    mapFolder.Parent = Workspace -- Asignar al Workspace temprano para el raycast Exclude

    local cfg = EnvironmentConfig.Island
    local center = cfg.Position
    local dims = cfg.Dimensions
    local res = cfg.GridResolution
    local baseSeaH = cfg.BaseSeaElevation
    local peakH = cfg.PeakElevation
    local theme = cfg.Theme

    local urbanFolder = Instance.new("Folder")
    urbanFolder.Name = "UrbanInfrastructure"
    urbanFolder.Parent = mapFolder

    local natureFolder = Instance.new("Folder")
    natureFolder.Name = "NatureAndProps"
    natureFolder.Parent = mapFolder

    -- 1. Generación de Océano Masivo y Profundo (Smooth Terrain)
    Workspace.Terrain:FillBlock(
        CFrame.new(center.X, -31, center.Z),
        Vector3.new(2000, 58, 2000), -- Y desde -60 hasta -2 (centro -31)
        Enum.Material.Water
    )

    -- 2. Esculpido Orgánico de la Isla (Loop de Ruido con FillBall)
    local radiusX = 300
    local radiusZ = 300
    local step = 5

    local noiseMacro = 0.005
    local noiseMicro = 0.02

    for x = -radiusX, radiusX, step do
        for z = -radiusZ, radiusZ, step do
            local dist = math.sqrt(x * x + z * z)
            if dist <= radiusX then
                local normDist = math.clamp(dist / radiusX, 0, 1)
                
                -- Caída cónica hacia los bordes
                local islandMask = math.cos(normDist * (math.pi / 2))
                
                local n1 = math.noise(x * noiseMacro, z * noiseMacro, 3.2) * 45
                local n2 = math.noise(x * noiseMicro, z * noiseMicro, 7.8) * 8
                local totalNoise = n1 + n2

                local heightY = -2 + (islandMask * 40) + (totalNoise * islandMask)
                
                -- Aplanamiento urbano en el centro
                local urbanRadius = 120
                local urbanWeight = math.clamp(1 - (dist / urbanRadius), 0, 1)
                heightY = (heightY * (1 - urbanWeight)) + (8.0 * urbanWeight)

                local mat = Enum.Material.Grass
                if heightY < 4 then
                    mat = Enum.Material.Sand
                end

                Workspace.Terrain:FillBall(
                    Vector3.new(center.X + x, heightY, center.Z + z),
                    6,
                    mat
                )
            end
        end
    end

    -- 3. Urbanismo: Plaza Central y Rascacielos Asentados con Raycasting
    local plazaCenterY = getSurfaceY(center.X, center.Z, 8.0, mapFolder)

    -- Gran Plaza Pavimentada Central
    PartTextures.CreatePart({
        Name = "UrbanPlazaFloor",
        Size = Vector3.new(190, 0.4, 190),
        CFrame = CFrame.new(center.X, plazaCenterY + 0.2, center.Z),
        Material = theme.RoadPavement.Material,
        Color = theme.RoadPavement.Color,
        Parent = urbanFolder,
    })

    -- Rascacielos Corporativo de 6 Pisos
    local skyscraperX = center.X + 38
    local skyscraperZ = center.Z + 32
    local skyscraperY = getSurfaceY(skyscraperX, skyscraperZ, 8.0, mapFolder)
    buildCorporateSkyscraper(urbanFolder, Vector3.new(skyscraperX, skyscraperY, skyscraperZ), theme)

    -- Edificio de Tecnología de 4 Pisos
    local techX = center.X - 42
    local techZ = center.Z - 38
    local techY = getSurfaceY(techX, techZ, 8.0, mapFolder)
    buildTechCenter(urbanFolder, Vector3.new(techX, techY, techZ), theme)

    -- Torre de Observación (Cresta Este)
    local towerX = center.X + 230
    local towerZ = center.Z - 150
    local towerY = getSurfaceY(towerX, towerZ, 26.0, mapFolder)
    buildObservationTower(urbanFolder, Vector3.new(towerX, towerY, towerZ), theme)

    -- Búnker Militar Blindado (Costa Oeste)
    local bunkerX = center.X - 250
    local bunkerZ = center.Z + 130
    local bunkerY = getSurfaceY(bunkerX, bunkerZ, 6.0, mapFolder)
    buildMilitaryBunker(urbanFolder, Vector3.new(bunkerX, bunkerY, bunkerZ), theme)

    -- Muelle Costero de Madera (Playa Sur)
    local pierStartX = center.X - 20
    local pierStartZ = center.Z + 280
    buildCoastalPier(urbanFolder, Vector3.new(pierStartX, 4, pierStartZ), 110, theme)

    -- 4. Caminos Sutiles (Dirt/Cobblestone)
    local cityCenterV3 = Vector3.new(center.X, plazaCenterY + 0.2, center.Z)
    buildOrganicPath(cityCenterV3, Vector3.new(skyscraperX, skyscraperY, skyscraperZ), 4)
    buildOrganicPath(cityCenterV3, Vector3.new(techX, techY, techZ), 4)
    buildOrganicPath(cityCenterV3, Vector3.new(towerX, towerY, towerZ), 3)
    buildOrganicPath(cityCenterV3, Vector3.new(bunkerX, bunkerY, bunkerZ), 4)
    buildOrganicPath(cityCenterV3, Vector3.new(pierStartX, 4, pierStartZ), 3)

    -- 5. Mobiliario Urbano (Farolas y Bancos)
    local lampCoordinates = {
        Vector3.new(center.X - 18, plazaCenterY, center.Z - 60),
        Vector3.new(center.X + 18, plazaCenterY, center.Z - 60),
        Vector3.new(center.X - 18, plazaCenterY, center.Z + 60),
        Vector3.new(center.X + 18, plazaCenterY, center.Z + 60),
        Vector3.new(center.X - 60, plazaCenterY, center.Z - 18),
        Vector3.new(center.X - 60, plazaCenterY, center.Z + 18),
        Vector3.new(center.X + 60, plazaCenterY, center.Z - 18),
        Vector3.new(center.X + 60, plazaCenterY, center.Z + 18),
        Vector3.new(bunkerX + 45, bunkerY, bunkerZ),
        Vector3.new(towerX - 40, towerY, towerZ),
    }
    for _, lPos in ipairs(lampCoordinates) do
        local lY = getSurfaceY(lPos.X, lPos.Z, lPos.Y, mapFolder)
        spawnStreetLamp(urbanFolder, Vector3.new(lPos.X, lY, lPos.Z), theme)
    end

    local benchCoordinates = {
        { Pos = Vector3.new(center.X - 15, plazaCenterY, center.Z - 25), Angle = 0 },
        { Pos = Vector3.new(center.X + 15, plazaCenterY, center.Z - 25), Angle = 0 },
        { Pos = Vector3.new(center.X - 15, plazaCenterY, center.Z + 25), Angle = math.pi },
        { Pos = Vector3.new(center.X + 15, plazaCenterY, center.Z + 25), Angle = math.pi },
        { Pos = Vector3.new(center.X - 25, plazaCenterY, center.Z), Angle = math.pi / 2 },
        { Pos = Vector3.new(center.X + 25, plazaCenterY, center.Z), Angle = -math.pi / 2 },
    }
    for _, bData in ipairs(benchCoordinates) do
        local bY = getSurfaceY(bData.Pos.X, bData.Pos.Z, bData.Pos.Y, mapFolder)
        spawnParkBench(urbanFolder, Vector3.new(bData.Pos.X, bY, bData.Pos.Z), bData.Angle, theme)
    end

    -- 6. Arbustos Alrededor de Edificios y Plaza
    local bushOffsets = {
        Vector3.new(skyscraperX - 30, 0, skyscraperZ - 26),
        Vector3.new(skyscraperX - 30, 0, skyscraperZ + 26),
        Vector3.new(skyscraperX + 30, 0, skyscraperZ - 26),
        Vector3.new(skyscraperX + 30, 0, skyscraperZ + 26),
        Vector3.new(techX - 25, 0, techZ - 22),
        Vector3.new(techX - 25, 0, techZ + 22),
        Vector3.new(techX + 25, 0, techZ - 22),
        Vector3.new(techX + 25, 0, techZ + 22),
        Vector3.new(center.X - 85, 0, center.Z - 85),
        Vector3.new(center.X + 85, 0, center.Z - 85),
        Vector3.new(center.X - 85, 0, center.Z + 85),
        Vector3.new(center.X + 85, 0, center.Z + 85),
    }
    for _, bOff in ipairs(bushOffsets) do
        local bY = getSurfaceY(bOff.X, bOff.Z, 8.0, mapFolder)
        spawnBush(natureFolder, Vector3.new(bOff.X, bY, bOff.Z), math.random(8, 12) * 0.1, theme)
    end

    -- 7. Vegetación Basada en Raycast Estricto (Solo en Grass)
    local rng = Random.new()
    for i = 1, 150 do
        -- Escoger coordenadas aleatorias dentro de la isla
        local ang = rng:NextNumber(0, math.pi * 2)
        local rad = rng:NextNumber(40, 280)
        local tx = center.X + math.cos(ang) * rad
        local tz = center.Z + math.sin(ang) * rad
        
        local rayOrigin = Vector3.new(tx, 500, tz)
        local rayDir = Vector3.new(0, -1000, 0)
        
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {mapFolder}
        
        local result = Workspace:Raycast(rayOrigin, rayDir, params)
        -- CONDICIÓN CRÍTICA: Solo instanciar si el material es Grass
        if result and result.Material == Enum.Material.Grass then
            local treeScale = rng:NextNumber(0.8, 1.45)
            spawnOrganicTree(natureFolder, result.Position, treeScale, theme)
        end
    end

    print(string.format("[IslandGeneration] Isla Masiva 840x840 generada con Sistema Anti-Clipping, Mobiliario Urbano y Muelle Costero."))
    return mapFolder
end

return IslandGeneration

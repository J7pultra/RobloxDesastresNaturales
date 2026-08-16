--!strict
--[[
    IslandGeneration.lua
    Módulo para la generación de la Isla Masiva (840x840 studs) con Topografía Orgánica (math.noise),
    Urbanismo Estructurado (Zona Urbana Central, Caminos y Zonas Periféricas),
    Fachadas con Tratamiento de Caras Avanzado (Muros cortina y montantes verticales de 4 a 6 pisos),
    y Bosques Agrupados en Clústeres.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentConfig = require(ReplicatedStorage.SharedConfigs.EnvironmentConfig)
local PartTextures = require(script.Parent.Parent.VisualEffects.PartTextures)

local IslandGeneration = {}

-- ============================================================================
-- UTILIDAD: CONSTRUCCIÓN DE PRISMA ARQUITECTÓNICO CERRADO CON MONTANTES VERTICALES
-- ============================================================================

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
    local spacing = props.MullionSpacing or 6.5

    local halfW = w / 2
    local halfH = h / 2
    local halfD = d / 2

    -- 1. Losa de Suelo
    local floorSlab = PartTextures.CreatePart({
        Name = "FloorSlab",
        Size = Vector3.new(w, 1.2, d),
        CFrame = CFrame.new(c.X, c.Y + 0.6, c.Z),
        Material = theme.CorporateConcrete.Material,
        Color = Color3.fromRGB(70, 74, 80),
        Parent = floorModel,
    })

    -- 2. Losa de Techo
    local roofSlab = PartTextures.CreatePart({
        Name = "RoofSlab",
        Size = Vector3.new(w + 0.6, 1.2, d + 0.6),
        CFrame = CFrame.new(c.X, c.Y + h - 0.6, c.Z),
        Material = theme.CorporateConcrete.Material,
        Color = theme.CorporateConcrete.Color,
        Parent = floorModel,
    })

    -- 3. Columnas de Esquina Estructurales
    local cornerSize = Vector3.new(t * 1.8, h, t * 1.8)
    local cornerPositions = {
        Vector3.new(-halfW + t * 0.9, halfH, -halfD + t * 0.9),
        Vector3.new(halfW - t * 0.9, halfH, -halfD + t * 0.9),
        Vector3.new(-halfW + t * 0.9, halfH, halfD - t * 0.9),
        Vector3.new(halfW - t * 0.9, halfH, halfD - t * 0.9),
    }
    for i, cp in ipairs(cornerPositions) do
        PartTextures.CreatePart({
            Name = "CornerPillar_" .. i,
            Size = cornerSize,
            CFrame = CFrame.new(c + cp),
            Material = theme.DarkMullion.Material,
            Color = theme.DarkMullion.Color,
            Reflectance = theme.DarkMullion.Reflectance,
            Parent = floorModel,
        })
    end

    -- 4. Tratamiento de Caras: Muros Cortina de Cristal y Montantes Verticales Rítmicos
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
            local sideWidth = (faceWidth - doorW) / 2

            -- Muro lateral izquierdo de la entrada
            PartTextures.CreatePart({
                Name = face .. "_EntranceWall_L",
                Size = Vector3.new(sideWidth, h, t),
                CFrame = CFrame.new(c.X - halfW + t + sideWidth / 2, c.Y + halfH, c.Z + halfD - t / 2),
                Material = theme.CorporateConcrete.Material,
                Color = theme.CorporateConcrete.Color,
                Parent = floorModel,
            })
            -- Muro lateral derecho de la entrada
            PartTextures.CreatePart({
                Name = face .. "_EntranceWall_R",
                Size = Vector3.new(sideWidth, h, t),
                CFrame = CFrame.new(c.X + halfW - t - sideWidth / 2, c.Y + halfH, c.Z + halfD - t / 2),
                Material = theme.CorporateConcrete.Material,
                Color = theme.CorporateConcrete.Color,
                Parent = floorModel,
            })
            -- Dintel sobre la entrada
            local lintelH = h - doorH
            if lintelH > 0 then
                PartTextures.CreatePart({
                    Name = face .. "_DoorLintel",
                    Size = Vector3.new(doorW, lintelH, t),
                    CFrame = CFrame.new(c.X, c.Y + doorH + lintelH / 2, c.Z + halfD - t / 2),
                    Material = theme.DarkMullion.Material,
                    Color = theme.DarkMullion.Color,
                    Parent = floorModel,
                })
            end
            return
        end

        -- Cristal continuo de fondo de la fachada
        if isFront then
            PartTextures.CreatePart({
                Name = "Glass_Front",
                Size = Vector3.new(faceWidth, h - 1.2, 0.4),
                CFrame = CFrame.new(c.X, c.Y + halfH, c.Z + halfD - t / 2),
                Material = theme.CurtainGlass.Material,
                Color = theme.CurtainGlass.Color,
                Transparency = theme.CurtainGlass.Transparency,
                Reflectance = theme.CurtainGlass.Reflectance,
                Parent = floorModel,
            })
        elseif isBack then
            PartTextures.CreatePart({
                Name = "Glass_Back",
                Size = Vector3.new(faceWidth, h - 1.2, 0.4),
                CFrame = CFrame.new(c.X, c.Y + halfH, c.Z - halfD + t / 2),
                Material = theme.CurtainGlass.Material,
                Color = theme.CurtainGlass.Color,
                Transparency = theme.CurtainGlass.Transparency,
                Reflectance = theme.CurtainGlass.Reflectance,
                Parent = floorModel,
            })
        elseif isLeft then
            PartTextures.CreatePart({
                Name = "Glass_Left",
                Size = Vector3.new(0.4, h - 1.2, faceWidth),
                CFrame = CFrame.new(c.X - halfW + t / 2, c.Y + halfH, c.Z),
                Material = theme.CurtainGlass.Material,
                Color = theme.CurtainGlass.Color,
                Transparency = theme.CurtainGlass.Transparency,
                Reflectance = theme.CurtainGlass.Reflectance,
                Parent = floorModel,
            })
        elseif isRight then
            PartTextures.CreatePart({
                Name = "Glass_Right",
                Size = Vector3.new(0.4, h - 1.2, faceWidth),
                CFrame = CFrame.new(c.X + halfW - t / 2, c.Y + halfH, c.Z),
                Material = theme.CurtainGlass.Material,
                Color = theme.CurtainGlass.Color,
                Transparency = theme.CurtainGlass.Transparency,
                Reflectance = theme.CurtainGlass.Reflectance,
                Parent = floorModel,
            })
        end

        -- Montantes verticales de metal superpuestos a la fachada
        for i = 1, count - 1 do
            local offset = -faceWidth / 2 + (i * step)
            if isFront then
                PartTextures.CreatePart({
                    Name = "Mullion_F_" .. i,
                    Size = Vector3.new(0.8, h, 0.8),
                    CFrame = CFrame.new(c.X + offset, c.Y + halfH, c.Z + halfD - t / 2),
                    Material = theme.DarkMullion.Material,
                    Color = theme.DarkMullion.Color,
                    Parent = floorModel,
                })
            elseif isBack then
                PartTextures.CreatePart({
                    Name = "Mullion_B_" .. i,
                    Size = Vector3.new(0.8, h, 0.8),
                    CFrame = CFrame.new(c.X + offset, c.Y + halfH, c.Z - halfD + t / 2),
                    Material = theme.DarkMullion.Material,
                    Color = theme.DarkMullion.Color,
                    Parent = floorModel,
                })
            elseif isLeft then
                PartTextures.CreatePart({
                    Name = "Mullion_L_" .. i,
                    Size = Vector3.new(0.8, h, 0.8),
                    CFrame = CFrame.new(c.X - halfW + t / 2, c.Y + halfH, c.Z + offset),
                    Material = theme.DarkMullion.Material,
                    Color = theme.DarkMullion.Color,
                    Parent = floorModel,
                })
            elseif isRight then
                PartTextures.CreatePart({
                    Name = "Mullion_R_" .. i,
                    Size = Vector3.new(0.8, h, 0.8),
                    CFrame = CFrame.new(c.X + halfW - t / 2, c.Y + halfH, c.Z + offset),
                    Material = theme.DarkMullion.Material,
                    Color = theme.DarkMullion.Color,
                    Parent = floorModel,
                })
            end
        end
    end

    generateFace("Front")
    generateFace("Back")
    generateFace("Left")
    generateFace("Right")

    return { Floor = floorSlab, Roof = roofSlab, Model = floorModel }
end

-- ============================================================================
-- 1. RASCACIELOS CORPORATIVO CENTRAL (6 PISOS CON HELIPUERTO)
-- ============================================================================
local function buildCorporateSkyscraper(parent: Instance, basePos: Vector3, theme: any): Model
    local tower = Instance.new("Model")
    tower.Name = "Skyscraper_CorporateHeadquarters_6Story"
    tower.Parent = parent

    local bWidth = 52
    local bDepth = 46
    local floorH = 11
    local totalFloors = 6

    -- Base / Plinto de entrada
    PartTextures.CreatePart({
        Name = "PlazaPlinth",
        Size = Vector3.new(bWidth + 8, 2, bDepth + 8),
        CFrame = CFrame.new(basePos.X, basePos.Y + 1, basePos.Z),
        Material = theme.CorporateConcrete.Material,
        Color = theme.CorporateConcrete.Color,
        Parent = tower,
    })

    -- Construcción piso por piso con tratamiento de caras y muros cortina
    for f = 1, totalFloors do
        local floorY = basePos.Y + 2 + ((f - 1) * floorH)
        local isGround = (f == 1)

        local doorConfig = nil
        if isGround then
            doorConfig = {
                Face = "Front" :: "Front",
                Width = 14,
                Height = 8.5,
            }
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

    -- Escalera interior continua de 6 tramos
    for fl = 1, totalFloors - 1 do
        local stairBaseY = basePos.Y + 2 + ((fl - 1) * floorH)
        for s = 1, 10 do
            local sY = stairBaseY + (s * (floorH / 10))
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

    -- Azotea con Helipuerto y Parapeto
    local roofY = basePos.Y + 2 + (totalFloors * floorH)
    local parapetH = 3.5

    -- Parapeto perimetral
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
        Color = Color3.fromRGB(40, 42, 48),
        Parent = tower,
    })

    -- Letra 'H'
    PartTextures.CreatePart({
        Name = "Helipad_H1",
        Size = Vector3.new(2, 0.2, 14),
        CFrame = CFrame.new(basePos.X - 4, roofY + 1.6, basePos.Z),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(240, 242, 245),
        Parent = helipad,
    })
    PartTextures.CreatePart({
        Name = "Helipad_H2",
        Size = Vector3.new(2, 0.2, 14),
        CFrame = CFrame.new(basePos.X + 4, roofY + 1.6, basePos.Z),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(240, 242, 245),
        Parent = helipad,
    })
    PartTextures.CreatePart({
        Name = "Helipad_HBar",
        Size = Vector3.new(8, 0.2, 2.5),
        CFrame = CFrame.new(basePos.X, roofY + 1.6, basePos.Z),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(240, 242, 245),
        Parent = helipad,
    })

    return tower
end

-- ============================================================================
-- 2. EDIFICIO DE TECNOLOGÍA Y OFICINAS (4 PISOS)
-- ============================================================================
local function buildTechCenter(parent: Instance, basePos: Vector3, theme: any): Model
    local model = Instance.new("Model")
    model.Name = "OfficeBuilding_TechCenter_4Story"
    model.Parent = parent

    local bWidth = 44
    local bDepth = 40
    local floorH = 11
    local totalFloors = 4

    PartTextures.CreatePart({
        Name = "TechPlinth",
        Size = Vector3.new(bWidth + 6, 2, bDepth + 6),
        CFrame = CFrame.new(basePos.X, basePos.Y + 1, basePos.Z),
        Material = theme.CorporateConcrete.Material,
        Color = theme.CorporateConcrete.Color,
        Parent = model,
    })

    for f = 1, totalFloors do
        local floorY = basePos.Y + 2 + ((f - 1) * floorH)
        local isGround = (f == 1)

        local doorConfig = nil
        if isGround then
            doorConfig = {
                Face = "Front" :: "Front",
                Width = 12,
                Height = 8.5,
            }
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

    -- Escalera interior
    for fl = 1, totalFloors - 1 do
        local stairBaseY = basePos.Y + 2 + ((fl - 1) * floorH)
        for s = 1, 10 do
            local sY = stairBaseY + (s * (floorH / 10))
            local sZ = (basePos.Z - bDepth / 4) + (s * 1.5)
            PartTextures.CreatePart({
                Name = string.format("Stair_Fl%d_S%d", fl, s),
                Size = Vector3.new(5.5, 0.6, 1.8),
                CFrame = CFrame.new(basePos.X + bWidth / 3, sY, sZ),
                Material = theme.DarkMullion.Material,
                Color = theme.DarkMullion.Color,
                Parent = model,
            })
        end
    end

    -- Cuarto de climatización en la azotea
    local roofY = basePos.Y + 2 + (totalFloors * floorH)
    PartTextures.CreatePart({
        Name = "RooftopACUnit",
        Size = Vector3.new(16, 7, 14),
        CFrame = CFrame.new(basePos.X, roofY + 3.5, basePos.Z),
        Material = theme.DarkMullion.Material,
        Color = theme.DarkMullion.Color,
        Parent = model,
    })

    return model
end

-- ============================================================================
-- 3. TORRE DE OBSERVACIÓN COSTERA (PERIFERIA ESTE)
-- ============================================================================
local function buildObservationTower(parent: Instance, basePos: Vector3, theme: any): Model
    local towerModel = Instance.new("Model")
    towerModel.Name = "Shelter_CoastalObservationTower"
    towerModel.Parent = parent

    local towerWidth = 18
    local towerHeight = 56
    local coreWallT = 1.8

    -- Base
    PartTextures.CreatePart({
        Name = "FoundationPlinth",
        Size = Vector3.new(towerWidth + 6, 3, towerWidth + 6),
        CFrame = CFrame.new(basePos + Vector3.new(0, 1.5, 0)),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = towerModel,
    })

    -- Núcleo
    PartTextures.CreatePart({
        Name = "CentralCorePillar",
        Size = Vector3.new(4, towerHeight, 4),
        CFrame = CFrame.new(basePos + Vector3.new(0, towerHeight / 2 + 3, 0)),
        Material = theme.DarkMullion.Material,
        Color = theme.DarkMullion.Color,
        Parent = towerModel,
    })

    local towerH = towerHeight - 12
    -- Muro Trasero
    PartTextures.CreatePart({
        Name = "Shaft_WallBack",
        Size = Vector3.new(towerWidth, towerH, coreWallT),
        CFrame = CFrame.new(basePos + Vector3.new(0, towerH / 2 + 3, -towerWidth / 2 + coreWallT / 2)),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = towerModel,
    })
    -- Muro Izquierdo
    PartTextures.CreatePart({
        Name = "Shaft_WallLeft",
        Size = Vector3.new(coreWallT, towerH, towerWidth - coreWallT * 2),
        CFrame = CFrame.new(basePos + Vector3.new(-towerWidth / 2 + coreWallT / 2, towerH / 2 + 3, 0)),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = towerModel,
    })
    -- Muro Derecho
    PartTextures.CreatePart({
        Name = "Shaft_WallRight",
        Size = Vector3.new(coreWallT, towerH, towerWidth - coreWallT * 2),
        CFrame = CFrame.new(basePos + Vector3.new(towerWidth / 2 - coreWallT / 2, towerH / 2 + 3, 0)),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = towerModel,
    })
    -- Muro Frontal
    local doorH = 9
    local doorW = 8
    local frontSideW = (towerWidth - doorW) / 2
    PartTextures.CreatePart({
        Name = "Shaft_WallFrontL",
        Size = Vector3.new(frontSideW, doorH, coreWallT),
        CFrame = CFrame.new(basePos + Vector3.new(-towerWidth / 2 + frontSideW / 2, doorH / 2 + 3, towerWidth / 2 - coreWallT / 2)),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = towerModel,
    })
    PartTextures.CreatePart({
        Name = "Shaft_WallFrontR",
        Size = Vector3.new(frontSideW, doorH, coreWallT),
        CFrame = CFrame.new(basePos + Vector3.new(towerWidth / 2 - frontSideW / 2, doorH / 2 + 3, towerWidth / 2 - coreWallT / 2)),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = towerModel,
    })
    PartTextures.CreatePart({
        Name = "Shaft_WallFrontUpper",
        Size = Vector3.new(towerWidth, towerH - doorH, coreWallT),
        CFrame = CFrame.new(basePos + Vector3.new(0, doorH + (towerH - doorH) / 2 + 3, towerWidth / 2 - coreWallT / 2)),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = towerModel,
    })

    -- Escalera helicoidal
    local stepCount = 26
    for s = 1, stepCount do
        local stepAngle = s * (math.pi / 3.5)
        local stepY = 3.5 + (s * (towerH / stepCount))
        local stepRad = 5.2
        local sx = math.cos(stepAngle) * stepRad
        local sz = math.sin(stepAngle) * stepRad

        PartTextures.CreatePart({
            Name = "SpiralStep_" .. s,
            Size = Vector3.new(5, 0.7, 1.8),
            CFrame = CFrame.new(basePos + Vector3.new(sx, stepY, sz)) * CFrame.Angles(0, -stepAngle + math.pi / 2, 0),
            Material = theme.DarkMullion.Material,
            Color = theme.DarkMullion.Color,
            Parent = towerModel,
        })
    end

    -- Cabina Superior 360°
    local cabinY = basePos.Y + towerH + 3
    local cabinW = towerWidth + 4
    local cabinH = 12

    buildAdvancedFloor({
        Parent = towerModel,
        Name = "ObservationCabin",
        CenterPos = Vector3.new(basePos.X, cabinY, basePos.Z),
        Size = Vector3.new(cabinW, cabinH, cabinW),
        Theme = theme,
        MullionSpacing = 4.5,
    })

    -- Antena
    PartTextures.CreateCylinder({
        Name = "RoofAntenna",
        Size = Vector3.new(10, 2.2, 2.2),
        CFrame = CFrame.new(basePos.X, cabinY + cabinH + 5, basePos.Z) * CFrame.Angles(0, 0, math.rad(90)),
        Material = theme.DarkMullion.Material,
        Color = theme.DarkMullion.Color,
        Parent = towerModel,
    })

    return towerModel
end

-- ============================================================================
-- 4. BÚNKER MILITAR BLINDADO (PERIFERIA OESTE)
-- ============================================================================
local function buildMilitaryBunker(parent: Instance, basePos: Vector3, theme: any): Model
    local bunkerModel = Instance.new("Model")
    bunkerModel.Name = "Shelter_MilitaryBunker"
    bunkerModel.Parent = parent

    local bWidth = 52
    local bHeight = 16
    local bDepth = 38
    local wallT = 3.5

    -- Suelo
    PartTextures.CreatePart({
        Name = "BunkerBase",
        Size = Vector3.new(bWidth + 8, 3, bDepth + 8),
        CFrame = CFrame.new(basePos.X, basePos.Y + 1.5, basePos.Z),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunkerModel,
    })

    -- Muros macizos
    -- Muro Trasero
    PartTextures.CreatePart({
        Name = "WallBack",
        Size = Vector3.new(bWidth, bHeight, wallT),
        CFrame = CFrame.new(basePos.X, basePos.Y + bHeight / 2 + 3, basePos.Z - bDepth / 2 + wallT / 2),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunkerModel,
    })
    -- Muro Izquierdo
    PartTextures.CreatePart({
        Name = "WallLeft",
        Size = Vector3.new(wallT, bHeight, bDepth - wallT * 2),
        CFrame = CFrame.new(basePos.X - bWidth / 2 + wallT / 2, basePos.Y + bHeight / 2 + 3, basePos.Z),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunkerModel,
    })
    -- Muro Derecho
    PartTextures.CreatePart({
        Name = "WallRight",
        Size = Vector3.new(wallT, bHeight, bDepth - wallT * 2),
        CFrame = CFrame.new(basePos.X + bWidth / 2 - wallT / 2, basePos.Y + bHeight / 2 + 3, basePos.Z),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunkerModel,
    })
    -- Muro Frontal con Portón
    local doorW = 16
    local sideFrontW = (bWidth - doorW) / 2
    PartTextures.CreatePart({
        Name = "WallFrontL",
        Size = Vector3.new(sideFrontW, bHeight, wallT),
        CFrame = CFrame.new(basePos.X - bWidth / 2 + sideFrontW / 2, basePos.Y + bHeight / 2 + 3, basePos.Z + bDepth / 2 - wallT / 2),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunkerModel,
    })
    PartTextures.CreatePart({
        Name = "WallFrontR",
        Size = Vector3.new(sideFrontW, bHeight, wallT),
        CFrame = CFrame.new(basePos.X + bWidth / 2 - sideFrontW / 2, basePos.Y + bHeight / 2 + 3, basePos.Z + bDepth / 2 - wallT / 2),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunkerModel,
    })
    PartTextures.CreatePart({
        Name = "DoorHeader",
        Size = Vector3.new(doorW, 6, wallT),
        CFrame = CFrame.new(basePos.X, basePos.Y + bHeight - 0.5, basePos.Z + bDepth / 2 - wallT / 2),
        Material = theme.IndustrialMetal.Material,
        Color = theme.IndustrialMetal.Color,
        Parent = bunkerModel,
    })

    -- Techo pesado
    PartTextures.CreatePart({
        Name = "HeavyRoof",
        Size = Vector3.new(bWidth + 4, 3, bDepth + 4),
        CFrame = CFrame.new(basePos.X, basePos.Y + bHeight + 4.5, basePos.Z),
        Material = theme.BunkerConcrete.Material,
        Color = theme.BunkerConcrete.Color,
        Parent = bunkerModel,
    })

    return bunkerModel
end

-- ============================================================================
-- 5. VEGETACIÓN Y ROCAS EN CLÚSTERES ORGÁNICOS
-- ============================================================================

local function spawnOrganicTree(parent: Instance, position: Vector3, scale: number, theme: any)
    local treeModel = Instance.new("Model")
    treeModel.Name = "Tree_Organic"

    local trunkH = (14 + math.random(-2, 4)) * scale
    local trunkR = (1.6 + (math.random(-2, 3) * 0.1)) * scale
    local tiltAngle = math.rad(math.random(-6, 6))

    -- Tronco con ligera inclinación natural
    PartTextures.CreateCylinder({
        Name = "Trunk",
        Size = Vector3.new(trunkH, trunkR * 2, trunkR * 2),
        CFrame = CFrame.new(position + Vector3.new(0, trunkH / 2, 0)) * CFrame.Angles(tiltAngle, math.rad(math.random(0, 360)), math.rad(90)),
        Material = theme.TreeTrunk.Material,
        Color = theme.TreeTrunk.Color,
        Parent = treeModel,
    })

    -- Copas esféricas volumétricas variadas
    local layers = 3
    for l = 1, layers do
        local cSize = (14 - (l * 3) + math.random(-1, 2)) * scale
        local cY = (trunkH * (0.6 + (l * 0.3)))
        local xOff = math.random(-1, 1) * scale
        local zOff = math.random(-1, 1) * scale

        PartTextures.CreatePart({
            Name = "Canopy_" .. l,
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(cSize, cSize * 0.85, cSize),
            CFrame = CFrame.new(position + Vector3.new(xOff, cY, zOff)),
            Material = theme.TreeLeaves.Material,
            Color = theme.TreeLeaves.Color,
            Parent = treeModel,
        })
    end

    treeModel.Parent = parent
end

local function spawnOrganicRockCluster(parent: Instance, position: Vector3, scale: number, theme: any)
    local rockModel = Instance.new("Model")
    rockModel.Name = "RockCluster"

    local count = math.random(3, 5)
    for i = 1, count do
        local rSize = Vector3.new(
            math.random(8, 16) * scale,
            math.random(6, 12) * scale,
            math.random(8, 16) * scale
        )
        local offset = Vector3.new(
            math.random(-6, 6) * scale,
            (rSize.Y / 2) - 1,
            math.random(-6, 6) * scale
        )
        local rot = CFrame.Angles(
            math.rad(math.random(-25, 25)),
            math.rad(math.random(0, 360)),
            math.rad(math.random(-25, 25))
        )

        PartTextures.CreatePart({
            Name = "Rock_" .. i,
            Size = rSize,
            CFrame = CFrame.new(position + offset) * rot,
            Material = theme.RockFormation.Material,
            Color = theme.RockFormation.Color,
            Reflectance = theme.RockFormation.Reflectance,
            Parent = rockModel,
        })
    end

    rockModel.Parent = parent
end

-- ============================================================================
-- GENERACIÓN DE LA RED VIAL / CAMINOS ESTRUCTURADOS
-- ============================================================================

local function buildRoadSegment(parent: Instance, p1: Vector3, p2: Vector3, roadWidth: number, theme: any)
    local dist = (p2 - p1).Magnitude
    local mid = (p1 + p2) / 2
    local dir = (p2 - p1).Unit
    local cf = CFrame.lookAt(mid, p2)

    -- Calzada principal
    PartTextures.CreatePart({
        Name = "Road_Asphalt",
        Size = Vector3.new(roadWidth, 0.4, dist),
        CFrame = cf,
        Material = theme.RoadConcrete.Material,
        Color = theme.RoadConcrete.Color,
        Reflectance = theme.RoadConcrete.Reflectance,
        Parent = parent,
    })

    -- Acera izquierda
    local sidewalkW = 2.5
    PartTextures.CreatePart({
        Name = "Sidewalk_L",
        Size = Vector3.new(sidewalkW, 0.6, dist),
        CFrame = cf * CFrame.new(-roadWidth / 2 - sidewalkW / 2, 0.1, 0),
        Material = theme.RoadPavement.Material,
        Color = theme.RoadPavement.Color,
        Parent = parent,
    })
    -- Acera derecha
    PartTextures.CreatePart({
        Name = "Sidewalk_R",
        Size = Vector3.new(sidewalkW, 0.6, dist),
        CFrame = cf * CFrame.new(roadWidth / 2 + sidewalkW / 2, 0.1, 0),
        Material = theme.RoadPavement.Material,
        Color = theme.RoadPavement.Color,
        Parent = parent,
    })
end

-- ============================================================================
-- GENERACIÓN PRINCIPAL DE LA ISLA (RUIDO PERLIN + URBANISMO)
-- ============================================================================

function IslandGeneration.BuildIsland(): Folder
    -- Limpieza previa del mapa
    local existingMap = Workspace:FindFirstChild("CurrentMap")
    if existingMap then
        existingMap:Destroy()
    end

    local mapFolder = Instance.new("Folder")
    mapFolder.Name = "CurrentMap"

    local cfg = EnvironmentConfig.Island
    local center = cfg.Position
    local dims = cfg.Dimensions
    local res = cfg.GridResolution
    local baseSeaH = cfg.BaseSeaElevation
    local peakH = cfg.PeakElevation
    local theme = cfg.Theme

    local terrainFolder = Instance.new("Folder")
    terrainFolder.Name = "PerlinTerrain"
    terrainFolder.Parent = mapFolder

    local roadsFolder = Instance.new("Folder")
    roadsFolder.Name = "RoadNetwork"
    roadsFolder.Parent = mapFolder

    local cityFolder = Instance.new("Folder")
    cityFolder.Name = "CityDistrict"
    cityFolder.Parent = mapFolder

    local natureFolder = Instance.new("Folder")
    natureFolder.Name = "ForestsAndRocks"
    natureFolder.Parent = mapFolder

    -- 1. Topografía Orgánica con Ruido Perlin (math.noise)
    local halfX = dims.X / 2
    local halfZ = dims.Y / 2
    local stepsX = math.floor(dims.X / res)
    local stepsZ = math.floor(dims.Y / res)

    local surfaceHeights: { [string]: number } = {}

    -- Parámetros de ruido Perlin
    local noiseScaleMacro = 0.004
    local noiseScaleMeso = 0.012
    local noiseScaleMicro = 0.035

    for ix = 0, stepsX do
        local x = -halfX + (ix * res)
        for iz = 0, stepsZ do
            local z = -halfZ + (iz * res)

            local distFromCenter = math.sqrt(x * x + z * z)
            local normalizedDist = math.clamp(distFromCenter / (halfX * 0.94), 0, 1)

            -- Gradiente de caída hacia el océano
            local islandMask = math.cos(normalizedDist * (math.pi / 2)) -- 1 en el centro, 0 en la costa

            -- Ruido Perlin multi-octava
            local nMacro = math.noise(x * noiseScaleMacro, z * noiseScaleMacro, 4.5) * 32
            local nMeso = math.noise(x * noiseScaleMeso, z * noiseScaleMeso, 8.2) * 14
            local nMicro = math.noise(x * noiseScaleMicro, z * noiseScaleMicro, 12.1) * 5
            local totalNoise = (nMacro + nMeso + nMicro)

            -- Aplanamiento dinámico para la Zona Urbana Central (Radio de 135 studs)
            local urbanRadius = 135
            local urbanWeight = math.clamp(1 - (distFromCenter / urbanRadius), 0, 1)
            local naturalHeight = baseSeaH + (islandMask * peakH) + (totalNoise * islandMask)

            -- En la zona urbana se aplana suavemente hacia Y = 8 para asentar calles y rascacielos
            local calculatedH = (naturalHeight * (1 - urbanWeight)) + (8.0 * urbanWeight)
            if calculatedH < 1.5 then
                calculatedH = 1.5
            end

            surfaceHeights[string.format("%d_%d", ix, iz)] = calculatedH

            -- Materiales según cota y distancia
            local mat = theme.LowlandGrass.Material
            local col = theme.LowlandGrass.Color

            if normalizedDist > 0.82 or calculatedH <= 3.5 then
                mat = theme.CoastSand.Material
                col = theme.CoastSand.Color
            elseif calculatedH > 28 then
                mat = theme.RidgeRock.Material
                col = theme.RidgeRock.Color
            elseif calculatedH > 16 then
                mat = theme.HighlandGrass.Material
                col = theme.HighlandGrass.Color
            end

            local columnHeight = calculatedH + 16
            local blockCenterY = center.Y + (calculatedH / 2) - 8

            local terrainBlock = PartTextures.CreatePart({
                Name = string.format("Terrain_%d_%d", ix, iz),
                Size = Vector3.new(res + 0.1, columnHeight, res + 0.1),
                CFrame = CFrame.new(center.X + x, blockCenterY, center.Z + z),
                Material = mat,
                Color = col,
                CastShadow = true,
                Parent = terrainFolder,
            })
        end
    end

    -- 2. Océano Perimetral Infinito (Glass translúcido sin colisión)
    local oceanDims = cfg.OceanDimensions
    PartTextures.CreatePart({
        Name = "OceanSurface",
        Size = Vector3.new(oceanDims.X, 4, oceanDims.Y),
        CFrame = CFrame.new(center.X, cfg.WaterLevel, center.Z),
        Material = theme.Ocean.Material,
        Color = theme.Ocean.Color,
        Transparency = theme.Ocean.Transparency,
        Reflectance = theme.Ocean.Reflectance,
        CanCollide = false,
        CastShadow = false,
        Parent = terrainFolder,
    })

    -- 3. Urbanismo: Plaza Central y Rascacielos Corporativos
    local cityCenterPos = center + Vector3.new(0, 8, 0)

    -- Plaza de pavimento urbano
    PartTextures.CreatePart({
        Name = "UrbanPlazaFloor",
        Size = Vector3.new(180, 0.4, 180),
        CFrame = CFrame.new(cityCenterPos.X, cityCenterPos.Y + 0.2, cityCenterPos.Z),
        Material = theme.RoadPavement.Material,
        Color = theme.RoadPavement.Color,
        Parent = cityFolder,
    })

    -- Rascacielos Corporativo de 6 Pisos (Edificio Principal)
    local skyscraperPos = cityCenterPos + Vector3.new(35, 0, 30)
    buildCorporateSkyscraper(cityFolder, skyscraperPos, theme)

    -- Edificio de Tecnología de 4 Pisos
    local techCenterPos = cityCenterPos + Vector3.new(-38, 0, -35)
    buildTechCenter(cityFolder, techCenterPos, theme)

    -- 4. Estructuras Periféricas Estratégicas
    -- Torre de Observación en la Cresta Este
    local towerPos = center + Vector3.new(220, 24, -140)
    buildObservationTower(cityFolder, towerPos, theme)

    -- Búnker Militar Blindado en la Costa Oeste
    local bunkerPos = center + Vector3.new(-240, 6, 120)
    buildMilitaryBunker(cityFolder, bunkerPos, theme)

    -- 5. Red Vial / Calles Conectoras
    local roadWidth = 14
    -- Avenida Principal Central (Eje Norte-Sur)
    buildRoadSegment(roadsFolder, cityCenterPos + Vector3.new(0, 0.2, -80), cityCenterPos + Vector3.new(0, 0.2, 80), roadWidth, theme)
    -- Avenida Principal Central (Eje Este-Oeste)
    buildRoadSegment(roadsFolder, cityCenterPos + Vector3.new(-80, 0.2, 0), cityCenterPos + Vector3.new(80, 0.2, 0), roadWidth, theme)

    -- Carretera Conectora: Centro -> Búnker Oeste
    buildRoadSegment(roadsFolder, cityCenterPos + Vector3.new(-80, 0.2, 0), bunkerPos + Vector3.new(35, 0.2, 0), 12, theme)

    -- Carretera Conectora: Centro -> Torre de Observación Este
    buildRoadSegment(roadsFolder, cityCenterPos + Vector3.new(80, 0.2, 0), towerPos + Vector3.new(-25, 0.2, 0), 12, theme)

    -- 6. Bosques y Clústeres Agrupados de Naturaleza
    local forestCenters = {
        { Pos = center + Vector3.new(-160, 10, -180), TreeCount = 28, RockCount = 8, Radius = 65 },
        { Pos = center + Vector3.new(180, 14, 160), TreeCount = 32, RockCount = 10, Radius = 75 },
        { Pos = center + Vector3.new(-180, 8, 220), TreeCount = 24, RockCount = 6, Radius = 55 },
        { Pos = center + Vector3.new(140, 18, -220), TreeCount = 30, RockCount = 9, Radius = 70 },
        { Pos = center + Vector3.new(0, 8, 240), TreeCount = 22, RockCount = 5, Radius = 50 },
    }

    local rng = Random.new(87654)

    for _, forest in ipairs(forestCenters) do
        -- Árboles agrupados en el bosque
        for t = 1, forest.TreeCount do
            local ang = rng:NextNumber(0, math.pi * 2)
            local rad = rng:NextNumber(5, forest.Radius)
            local tx = forest.Pos.X + math.cos(ang) * rad
            local tz = forest.Pos.Z + math.sin(ang) * rad

            local gX = math.clamp(math.floor((tx + halfX) / res), 0, stepsX)
            local gZ = math.clamp(math.floor((tz + halfZ) / res), 0, stepsZ)
            local ty = surfaceHeights[string.format("%d_%d", gX, gZ)] or forest.Pos.Y

            if ty > 3.5 then
                local treeScale = rng:NextNumber(0.85, 1.45)
                spawnOrganicTree(natureFolder, Vector3.new(tx, ty, tz), treeScale, theme)
            end
        end

        -- Rocas dentro del bosque
        for r = 1, forest.RockCount do
            local ang = rng:NextNumber(0, math.pi * 2)
            local rad = rng:NextNumber(8, forest.Radius)
            local rx = forest.Pos.X + math.cos(ang) * rad
            local rz = forest.Pos.Z + math.sin(ang) * rad

            local gX = math.clamp(math.floor((rx + halfX) / res), 0, stepsX)
            local gZ = math.clamp(math.floor((rz + halfZ) / res), 0, stepsZ)
            local ry = surfaceHeights[string.format("%d_%d", gX, gZ)] or forest.Pos.Y

            local rockScale = rng:NextNumber(0.8, 1.5)
            spawnOrganicRockCluster(natureFolder, Vector3.new(rx, ry, rz), rockScale, theme)
        end
    end

    mapFolder.Parent = Workspace
    print(string.format("[IslandGeneration] Isla Masiva 840x840 studs generada con Topografía Perlin, Rascacielos de 6 Pisos, Red Vial y 5 Bosques."))

    return mapFolder
end

return IslandGeneration

--!strict
--[[
    PartTextures.lua
    Módulo de sombreado y configuración PBR procedural con paleta sobria, moderna y limpia.
    Elimina por completo el uso de colores neón chillones y aplica tonos neutros (grises oscuros,
    blancos suaves, metal mate, madera noble, roca pizarra y Pebble orgánico).
]]

export type PBRPartProps = {
    Name: string?,
    Shape: Enum.PartType?,
    Size: Vector3,
    CFrame: CFrame,
    Material: Enum.Material?,
    Color: Color3?,
    Reflectance: number?,
    Transparency: number?,
    CanCollide: boolean?,
    CastShadow: boolean?,
    Parent: Instance?,
}

local PartTextures = {}

-- ============================================================================
-- GENERADOR DE INSTANCIAS CON ESTÁNDAR PBR LIMPIO
-- ============================================================================

function PartTextures.CreatePart(props: PBRPartProps): Part
    local part = Instance.new("Part")
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    part.Name = props.Name or "ModernPart"
    if props.Shape then
        part.Shape = props.Shape
    end

    part.Size = props.Size
    part.CFrame = props.CFrame
    part.Material = props.Material or Enum.Material.SmoothPlastic
    part.Color = props.Color or Color3.fromRGB(45, 45, 50)
    part.Reflectance = props.Reflectance or 0
    part.Transparency = props.Transparency or 0

    if props.CanCollide ~= nil then
        part.CanCollide = props.CanCollide
    else
        part.CanCollide = true
    end

    if props.CastShadow ~= nil then
        part.CastShadow = props.CastShadow
    else
        part.CastShadow = true
    end

    if props.Parent then
        part.Parent = props.Parent
    end

    return part
end

function PartTextures.CreateWedge(props: PBRPartProps): WedgePart
    local wedge = Instance.new("WedgePart")
    wedge.Anchored = true
    wedge.TopSurface = Enum.SurfaceType.Smooth
    wedge.BottomSurface = Enum.SurfaceType.Smooth

    wedge.Name = props.Name or "ModernWedge"
    wedge.Size = props.Size
    wedge.CFrame = props.CFrame
    wedge.Material = props.Material or Enum.Material.Metal
    wedge.Color = props.Color or Color3.fromRGB(45, 45, 50)
    wedge.Reflectance = props.Reflectance or 0
    wedge.Transparency = props.Transparency or 0

    if props.CanCollide ~= nil then
        wedge.CanCollide = props.CanCollide
    else
        wedge.CanCollide = true
    end

    if props.CastShadow ~= nil then
        wedge.CastShadow = props.CastShadow
    else
        wedge.CastShadow = true
    end

    if props.Parent then
        wedge.Parent = props.Parent
    end

    return wedge
end

function PartTextures.CreateCylinder(props: PBRPartProps): Part
    local cylinder = Instance.new("Part")
    cylinder.Shape = Enum.PartType.Cylinder
    cylinder.Anchored = true
    cylinder.TopSurface = Enum.SurfaceType.Smooth
    cylinder.BottomSurface = Enum.SurfaceType.Smooth

    cylinder.Name = props.Name or "ModernCylinder"
    cylinder.Size = props.Size
    cylinder.CFrame = props.CFrame
    cylinder.Material = props.Material or Enum.Material.Metal
    cylinder.Color = props.Color or Color3.fromRGB(45, 45, 50)
    cylinder.Reflectance = props.Reflectance or 0
    cylinder.Transparency = props.Transparency or 0

    if props.CanCollide ~= nil then
        cylinder.CanCollide = props.CanCollide
    else
        cylinder.CanCollide = true
    end

    if props.CastShadow ~= nil then
        cylinder.CastShadow = props.CastShadow
    else
        cylinder.CastShadow = true
    end

    if props.Parent then
        cylinder.Parent = props.Parent
    end

    return cylinder
end

-- ============================================================================
-- APLICADOR DE TEXTURAS DE TERRENO ORGÁNICO PBR
-- ============================================================================

function PartTextures.ApplyTerrainPBR(part: BasePart, heightFactor: number, noiseVal: number)
    local r = 68 + math.floor(noiseVal * 8)
    local g = 82 + math.floor(noiseVal * 10)
    local b = 58 + math.floor(noiseVal * 6)

    if heightFactor > 0.65 then
        -- Cumbres rocosas de pizarra
        part.Material = Enum.Material.Slate
        part.Color = Color3.fromRGB(78 + math.floor(noiseVal * 6), 82 + math.floor(noiseVal * 6), 86 + math.floor(noiseVal * 6))
        part.Reflectance = 0.04
    elseif heightFactor < 0.12 then
        -- Arena de costa
        part.Material = Enum.Material.Sand
        part.Color = Color3.fromRGB(205 + math.floor(noiseVal * 8), 190 + math.floor(noiseVal * 6), 150 + math.floor(noiseVal * 4))
        part.Reflectance = 0.02
    else
        -- Suelo base con Pebble orgánico y textura irregular
        part.Material = Enum.Material.Pebble
        part.Color = Color3.fromRGB(math.clamp(r, 45, 85), math.clamp(g, 65, 105), math.clamp(b, 40, 75))
        part.Reflectance = 0.02
    end
end

return PartTextures

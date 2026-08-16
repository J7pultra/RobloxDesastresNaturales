--!strict
--[[
    LightingManager.lua
    Módulo para configurar la iluminación gráfica avanzada de Roblox.
    Establece obligatoriamente Future Lighting, objeto Atmosphere y post-procesamiento.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentConfig = require(ReplicatedStorage.SharedConfigs.EnvironmentConfig)

local LightingManager = {}

function LightingManager.SetupLighting()
    local cfg = EnvironmentConfig.Lighting

    -- 1. Tecnología de Iluminación Future (Se asigna mediante pcall si el nivel de script lo permite)
    pcall(function()
        Lighting.Technology = Enum.Technology.Future
    end)
    Lighting.GlobalShadows = true
    Lighting.ClockTime = cfg.ClockTime
    Lighting.GeographicLatitude = cfg.GeographicLatitude
    Lighting.Brightness = cfg.Brightness
    Lighting.OutdoorAmbient = cfg.OutdoorAmbient
    Lighting.Ambient = cfg.Ambient
    Lighting.ColorShift_Top = cfg.ColorShift_Top
    Lighting.ColorShift_Bottom = cfg.ColorShift_Bottom
    Lighting.EnvironmentDiffuseScale = cfg.EnvironmentDiffuseScale
    Lighting.EnvironmentSpecularScale = cfg.EnvironmentSpecularScale
    Lighting.ShadowSoftness = cfg.ShadowSoftness

    -- 2. Limpieza de efectos de iluminación anteriores
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("SunRaysEffect") or child:IsA("Sky") then
            child:Destroy()
        end
    end

    -- 3. Objeto Atmosphere (Atmósfera PBR y niebla de horizonte)
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "CustomAtmosphere"
    atmosphere.Density = cfg.Atmosphere.Density
    atmosphere.Offset = cfg.Atmosphere.Offset
    atmosphere.Color = cfg.Atmosphere.Color
    atmosphere.Decay = cfg.Atmosphere.Decay
    atmosphere.Glare = cfg.Atmosphere.Glare
    atmosphere.Haze = cfg.Atmosphere.Haze
    atmosphere.Parent = Lighting

    -- 4. Post-procesado: Bloom Effect (Resplandor para Neón y reflejos)
    local bloom = Instance.new("BloomEffect")
    bloom.Name = "CustomBloom"
    bloom.Intensity = cfg.Bloom.Intensity
    bloom.Size = cfg.Bloom.Size
    bloom.Threshold = cfg.Bloom.Threshold
    bloom.Parent = Lighting

    -- 5. Post-procesado: ColorCorrection (Contraste cinematográfico)
    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "CustomColorCorrection"
    colorCorrection.Brightness = cfg.ColorCorrection.Brightness
    colorCorrection.Contrast = cfg.ColorCorrection.Contrast
    colorCorrection.Saturation = cfg.ColorCorrection.Saturation
    colorCorrection.TintColor = cfg.ColorCorrection.TintColor
    colorCorrection.Parent = Lighting

    -- 6. Rayos Solares (SunRays)
    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Name = "CustomSunRays"
    sunRays.Intensity = cfg.SunRays.Intensity
    sunRays.Spread = cfg.SunRays.Spread
    sunRays.Parent = Lighting

    -- 7. Cielo cinemático procedural
    local sky = Instance.new("Sky")
    sky.Name = "CustomSky"
    sky.CelestialBodiesShown = true
    sky.StarCount = 3000
    sky.SunAngularSize = 18
    sky.MoonAngularSize = 11
    sky.Parent = Lighting

    print("[LightingManager] Iluminación 'Future' y Atmósfera PBR configuradas exitosamente.")
end

return LightingManager

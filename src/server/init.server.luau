--[[
    HORROR GAME - SEWER MAP V15
    Complete architectural rebuild of the sewer map.
    Preserves first-person movement, stamina (client), jumping and spawn intent.
    No flashlight tool. No Roblox Lighting.Technology write (sandbox restricted).
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local TweenService = game:GetService("TweenService")

local WORLD_Y_OFFSET = 10.5
local FLOOR_LOCAL_Y = -10.5
local WATER_TOP = 0.30
local WATER_DEPTH = 3.0
local WATER_LOCAL_Y = WATER_TOP - WORLD_Y_OFFSET

local C = {
    concrete = Color3.fromRGB(79, 91, 94),
    concreteLight = Color3.fromRGB(105, 116, 116),
    concreteDark = Color3.fromRGB(38, 49, 53),
    concreteEdge = Color3.fromRGB(126, 134, 128),
    steel = Color3.fromRGB(36, 48, 52),
    steelMid = Color3.fromRGB(62, 78, 81),
    steelBright = Color3.fromRGB(119, 137, 135),
    rust = Color3.fromRGB(100, 61, 43),
    rustDark = Color3.fromRGB(61, 43, 36),
    teal = Color3.fromRGB(70, 190, 173),
    tealDim = Color3.fromRGB(44, 103, 98),
    amber = Color3.fromRGB(224, 165, 63),
    amberDark = Color3.fromRGB(111, 73, 32),
    red = Color3.fromRGB(191, 49, 39),
    water = Color3.fromRGB(48, 53, 43),
}

-- Remove the former prototype and any default Roblox base/spawn plates.
local baseplate = Workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end
for _, item in ipairs(Workspace:GetDescendants()) do
    if item:IsA("SpawnLocation") then item:Destroy() end
end

local oldWorld = Workspace:FindFirstChild("SewerWorld")
if oldWorld then oldWorld:Destroy() end
local oldClinic = Workspace:FindFirstChild("HorrorWorld")
if oldClinic then oldClinic:Destroy() end

local oldTool = StarterPack:FindFirstChild("Taschenlampe")
if oldTool then oldTool:Destroy() end
for _, player in ipairs(Players:GetPlayers()) do
    local backpack = player:FindFirstChildOfClass("Backpack")
    local tool = backpack and backpack:FindFirstChild("Taschenlampe")
    if tool then tool:Destroy() end
    local characterTool = player.Character and player.Character:FindFirstChild("Taschenlampe")
    if characterTool then characterTool:Destroy() end
end

local world = Instance.new("Folder")
world.Name = "SewerWorld"
world.Parent = Workspace

local function makePart(name, size, cframe, material, color, parent, transparency, canCollide)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = CFrame.new(0, WORLD_Y_OFFSET, 0) * cframe
    p.Anchored = true
    p.CanCollide = canCollide ~= false
    p.CanTouch = canCollide ~= false
    p.CanQuery = true
    p.Material = material or Enum.Material.Concrete
    p.Color = color or C.concrete
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.CastShadow = true
    p.Transparency = transparency or 0
    p.Parent = parent or world
    return p
end

local function part(name, size, position, material, color, parent, transparency, canCollide)
    return makePart(name, size, CFrame.new(position), material, color, parent, transparency, canCollide)
end

local function cylinder(name, length, diameter, position, material, color, parent, axis)
    local rotation = CFrame.identity
    if axis == "Z" then
        rotation = CFrame.Angles(0, math.rad(90), 0)
    elseif axis == "Y" then
        rotation = CFrame.Angles(0, 0, math.rad(90))
    end
    local p = makePart(
        name,
        Vector3.new(length, diameter, diameter),
        CFrame.new(position) * rotation,
        material or Enum.Material.Metal,
        color or C.steel,
        parent
    )
    p.Shape = Enum.PartType.Cylinder
    return p
end

local function newModel(name, parent)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent or world
    return m
end

local function segmentsWithoutGaps(first, last, gaps)
    local segments = {{first, last}}
    for _, gap in ipairs(gaps or {}) do
        local cutA = gap[1] - gap[2] / 2
        local cutB = gap[1] + gap[2] / 2
        local nextSegments = {}
        for _, segment in ipairs(segments) do
            local a, b = segment[1], segment[2]
            if cutB <= a or cutA >= b then
                table.insert(nextSegments, segment)
            else
                if cutA > a then table.insert(nextSegments, {a, math.min(cutA, b)}) end
                if cutB < b then table.insert(nextSegments, {math.max(cutB, a), b}) end
            end
        end
        segments = nextSegments
    end
    return segments
end

local function configureLighting()
    Lighting.ClockTime = 0.35
    Lighting.Brightness = 2.25
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.fromRGB(95, 108, 110)
    Lighting.OutdoorAmbient = Color3.fromRGB(69, 82, 84)
    Lighting.FogColor = Color3.fromRGB(54, 68, 72)
    Lighting.FogStart = 185
    Lighting.FogEnd = 650
    Lighting.EnvironmentDiffuseScale = 0.55
    Lighting.EnvironmentSpecularScale = 0.35

    pcall(function()
        local terrain = Workspace.Terrain
        terrain.WaterColor = C.water
        terrain.WaterReflectance = 0.32
        terrain.WaterTransparency = 0.12
        terrain.WaterWaveSize = 0.24
        terrain.WaterWaveSpeed = 9
    end)

    for _, name in ipairs({"SewerAtmosphere", "SewerColor", "SewerBloom"}) do
        local old = Lighting:FindFirstChild(name)
        if old then old:Destroy() end
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "SewerAtmosphere"
    atmosphere.Density = 0.055
    atmosphere.Offset = 0.02
    atmosphere.Color = Color3.fromRGB(164, 178, 174)
    atmosphere.Decay = Color3.fromRGB(58, 71, 72)
    atmosphere.Glare = 0
    atmosphere.Haze = 0.16
    atmosphere.Parent = Lighting

    local grade = Instance.new("ColorCorrectionEffect")
    grade.Name = "SewerColor"
    grade.Brightness = 0.025
    grade.Contrast = 0.12
    grade.Saturation = -0.09
    grade.TintColor = Color3.fromRGB(205, 222, 218)
    grade.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "SewerBloom"
    bloom.Intensity = 0.13
    bloom.Size = 18
    bloom.Threshold = 1.55
    bloom.Parent = Lighting
end

local function addWater(name, axis, centerX, centerZ, length, width, parent)
    local size = axis == "X"
        and Vector3.new(length, WATER_DEPTH, width)
        or Vector3.new(width, WATER_DEPTH, length)
    local center = Vector3.new(centerX, WATER_TOP - WATER_DEPTH / 2, centerZ)

    local ok, err = pcall(function()
        local terrain = Workspace.Terrain
        terrain:FillBlock(CFrame.new(center), size, Enum.Material.Water)
    end)

    if not ok then
        warn("[Horror Game] Terrain water fallback for " .. name .. ": " .. tostring(err))
        local fallbackSize = axis == "X"
            and Vector3.new(length, 0.12, width)
            or Vector3.new(width, 0.12, length)
        local fallbackPosition = Vector3.new(centerX, WATER_LOCAL_Y, centerZ)
        local surface = part(name .. "_Water_Surface", fallbackSize, fallbackPosition, Enum.Material.Glass, C.water, parent, 0.16, false)
        surface.Reflectance = 0.2
    end

    -- Tiny oily streaks drift above the water; native Terrain Water supplies waves.
    local count = math.clamp(math.floor(length / 58), 2, 6)
    for index = 1, count do
        local fraction = (index - 1) / math.max(1, count - 1)
        local across = (((index * 7) % 11) / 11 - 0.5) * width * 0.55
        local startAlong = -length * 0.43 + fraction * length * 0.22
        local finishAlong = math.min(length * 0.44, startAlong + 24 + (index % 3) * 7)
        local initial, final, streakSize
        if axis == "X" then
            initial = Vector3.new(centerX + startAlong, WATER_LOCAL_Y + 0.06, centerZ + across)
            final = Vector3.new(centerX + finishAlong, WATER_LOCAL_Y + 0.06, centerZ + across)
            streakSize = Vector3.new(3.5 + index % 3, 0.025, 0.08 + (index % 2) * 0.04)
        else
            initial = Vector3.new(centerX + across, WATER_LOCAL_Y + 0.06, centerZ + startAlong)
            final = Vector3.new(centerX + across, WATER_LOCAL_Y + 0.06, centerZ + finishAlong)
            streakSize = Vector3.new(0.08 + (index % 2) * 0.04, 0.025, 3.5 + index % 3)
        end

        local fleck = part(name .. "_Oil_Fleck", streakSize, initial, Enum.Material.SmoothPlastic, Color3.fromRGB(103, 100, 76), parent, 0.62, false)
        fleck.CastShadow = false
        task.spawn(function()
            while fleck.Parent do
                local tween = TweenService:Create(
                    fleck,
                    TweenInfo.new(7 + (index % 3) * 1.4, Enum.EasingStyle.Linear),
                    {Position = final}
                )
                tween:Play()
                local state = tween.Completed:Wait()
                if state ~= Enum.PlaybackState.Completed or not fleck.Parent then break end
                fleck.Position = initial
            end
        end)
    end
end

local function buildChannelFloor(name, axis, centerX, centerZ, length, totalWidth, channelWidth, parent)
    local dryWidth = (totalWidth - channelWidth) / 2
    local dryOffset = channelWidth / 2 + dryWidth / 2
    local bedY = -12.5

    if axis == "X" then
        part(name .. "_West_Walkway", Vector3.new(length, 1, dryWidth), Vector3.new(centerX, FLOOR_LOCAL_Y, centerZ - dryOffset), Enum.Material.Concrete, C.concrete, parent)
        part(name .. "_East_Walkway", Vector3.new(length, 1, dryWidth), Vector3.new(centerX, FLOOR_LOCAL_Y, centerZ + dryOffset), Enum.Material.Concrete, C.concrete, parent)
        part(name .. "_Recessed_Riverbed", Vector3.new(length, 1, channelWidth), Vector3.new(centerX, bedY, centerZ), Enum.Material.Slate, C.concreteDark, parent)
    else
        part(name .. "_West_Walkway", Vector3.new(dryWidth, 1, length), Vector3.new(centerX - dryOffset, FLOOR_LOCAL_Y, centerZ), Enum.Material.Concrete, C.concrete, parent)
        part(name .. "_East_Walkway", Vector3.new(dryWidth, 1, length), Vector3.new(centerX + dryOffset, FLOOR_LOCAL_Y, centerZ), Enum.Material.Concrete, C.concrete, parent)
        part(name .. "_Recessed_Riverbed", Vector3.new(channelWidth, 1, length), Vector3.new(centerX, bedY, centerZ), Enum.Material.Slate, C.concreteDark, parent)
    end
end

local function addRiverWallsX(name, first, last, centerZ, channelWidth, parent, crossings, southOpenings, northOpenings)
    local commonGaps = {}
    for _, x in ipairs(crossings or {}) do table.insert(commonGaps, {x, 8.4}) end
    for _, side in ipairs({-1, 1}) do
        local gaps = {}
        for _, gap in ipairs(commonGaps) do table.insert(gaps, gap) end
        local sideOpenings = side < 0 and (southOpenings or {}) or (northOpenings or {})
        for _, gap in ipairs(sideOpenings) do table.insert(gaps, gap) end
        local segments = segmentsWithoutGaps(first, last, gaps)
        for _, segment in ipairs(segments) do
            local len = segment[2] - segment[1]
            local x = (segment[1] + segment[2]) / 2
            part(name .. "_Concrete_River_Wall", Vector3.new(len, 2.3, 0.9), Vector3.new(x, -11.1, centerZ + side * (channelWidth / 2 + 0.42)), Enum.Material.Concrete, C.concreteDark, parent)
            part(name .. "_Stone_Coping", Vector3.new(len, 0.18, 1.08), Vector3.new(x, -9.83, centerZ + side * (channelWidth / 2 + 0.42)), Enum.Material.Concrete, C.concreteLight, parent)
        end
    end
end

local function addRiverWallsZ(name, first, last, centerX, channelWidth, parent, crossings)
    local gaps = {}
    for _, z in ipairs(crossings or {}) do table.insert(gaps, {z, 8.4}) end
    local segments = segmentsWithoutGaps(first, last, gaps)
    for _, side in ipairs({-1, 1}) do
        for _, segment in ipairs(segments) do
            local len = segment[2] - segment[1]
            local z = (segment[1] + segment[2]) / 2
            part(name .. "_Concrete_River_Wall", Vector3.new(0.9, 2.3, len), Vector3.new(centerX + side * (channelWidth / 2 + 0.42), -11.1, z), Enum.Material.Concrete, C.concreteDark, parent)
            part(name .. "_Stone_Coping", Vector3.new(1.08, 0.18, len), Vector3.new(centerX + side * (channelWidth / 2 + 0.42), -9.83, z), Enum.Material.Concrete, C.concreteLight, parent)
        end
    end
end

local function addBridge(name, axis, centerX, centerZ, parent)
    local deckSize = axis == "X" and Vector3.new(8.0, 0.26, 12.2) or Vector3.new(12.2, 0.26, 8.0)
    local deck = part(name .. "_Heavy_Steel_Grating", deckSize, Vector3.new(centerX, -10.0, centerZ), Enum.Material.DiamondPlate, C.steelMid, parent)
    deck.Reflectance = 0.1

    for index = 1, 19 do
        local offset = (index - 10) * 0.38
        local ribSize, ribPosition
        if axis == "X" then
            ribSize = Vector3.new(0.07, 0.045, 11.9)
            ribPosition = Vector3.new(centerX + offset, -9.835, centerZ)
        else
            ribSize = Vector3.new(11.9, 0.045, 0.07)
            ribPosition = Vector3.new(centerX, -9.835, centerZ + offset)
        end
        part(name .. "_Grating_Bar", ribSize, ribPosition, Enum.Material.Metal, C.steelBright, parent, 0, false)
    end

    for _, side in ipairs({-1, 1}) do
        for _, offset in ipairs({-3.35, 3.35}) do
            local postPosition
            if axis == "X" then
                postPosition = Vector3.new(centerX + offset, -9.15, centerZ + side * 6.1)
            else
                postPosition = Vector3.new(centerX + side * 6.1, -9.15, centerZ + offset)
            end
            part(name .. "_Handrail_Post", Vector3.new(0.18, 1.55, 0.18), postPosition, Enum.Material.Metal, C.steel, parent)
        end

        local railSize, railPosition
        if axis == "X" then
            railSize = Vector3.new(7.2, 0.16, 0.16)
            railPosition = Vector3.new(centerX, -8.38, centerZ + side * 6.1)
        else
            railSize = Vector3.new(0.16, 0.16, 7.2)
            railPosition = Vector3.new(centerX + side * 6.1, -8.38, centerZ)
        end
        part(name .. "_Upper_Handrail", railSize, railPosition, Enum.Material.Metal, C.steelBright, parent)
    end

    for _, side in ipairs({-1, 1}) do
        local stripeSize, stripePosition
        if axis == "X" then
            stripeSize = Vector3.new(6.8, 0.06, 0.16)
            stripePosition = Vector3.new(centerX, -9.84, centerZ + side * 5.95)
        else
            stripeSize = Vector3.new(0.16, 0.06, 6.8)
            stripePosition = Vector3.new(centerX + side * 5.95, -9.84, centerZ)
        end
        part(name .. "_Amber_Edge_Marker", stripeSize, stripePosition, Enum.Material.Neon, C.amber, parent, 0.08, false)
    end
end

local function addBridgesX(name, crossings, centerZ, parent)
    for index, x in ipairs(crossings) do addBridge(name .. "_" .. index, "X", x, centerZ, parent) end
end

local function addBridgesZ(name, crossings, centerX, parent)
    for index, z in ipairs(crossings) do addBridge(name .. "_" .. index, "Z", centerX, z, parent) end
end

local function buildArchX(name, first, last, centerZ, radius, parent, centerY)
    centerY = centerY or -1.5
    for degrees = -90, 90, 15 do
        local angle = math.rad(degrees)
        local y = centerY + radius * math.cos(angle)
        local z = centerZ + radius * math.sin(angle)
        local cf = CFrame.new((first + last) / 2, y, z) * CFrame.Angles(angle, 0, 0)
        makePart(name .. "_Vault_Concrete_Segment", Vector3.new(last - first, 2.0, 4.55), cf, Enum.Material.Concrete, C.concreteDark, parent)
    end
end

local function buildArchZ(name, first, last, centerX, radius, parent, centerY)
    centerY = centerY or -1.5
    for degrees = -90, 90, 15 do
        local angle = math.rad(degrees)
        local y = centerY + radius * math.cos(angle)
        local x = centerX + radius * math.sin(angle)
        local cf = CFrame.new(x, y, (first + last) / 2) * CFrame.Angles(0, 0, -angle)
        makePart(name .. "_Vault_Concrete_Segment", Vector3.new(4.55, 2.0, last - first), cf, Enum.Material.Concrete, C.concreteDark, parent)
    end
end

local function addVaultRibsX(name, first, last, centerZ, radius, parent, skipGaps)
    for x = first + 8, last - 8, 18 do
        local skip = false
        for _, gap in ipairs(skipGaps or {}) do
            if math.abs(x - gap[1]) < gap[2] / 2 + 3 then skip = true break end
        end
        if not skip then
            for degrees = -90, 90, 15 do
                local angle = math.rad(degrees)
                local cf = CFrame.new(x, -1.5 + radius * math.cos(angle), centerZ + radius * math.sin(angle)) * CFrame.Angles(angle, 0, 0)
                makePart(name .. "_Heavy_Rib", Vector3.new(0.8, 0.7, 4.5), cf, Enum.Material.Metal, C.steel, parent)
            end
        end
    end
end

local function addVaultRibsZ(name, first, last, centerX, radius, parent)
    for z = first + 8, last - 8, 18 do
        for degrees = -90, 90, 15 do
            local angle = math.rad(degrees)
            local cf = CFrame.new(centerX + radius * math.sin(angle), -1.5 + radius * math.cos(angle), z) * CFrame.Angles(0, 0, -angle)
            makePart(name .. "_Heavy_Rib", Vector3.new(4.5, 0.7, 0.8), cf, Enum.Material.Metal, C.steel, parent)
        end
    end
end

local function addWallRunX(name, first, last, centerZ, halfWidth, side, parent, gaps)
    local z = centerZ + side * (halfWidth - 0.55)
    for _, segment in ipairs(segmentsWithoutGaps(first, last, gaps)) do
        local len = segment[2] - segment[1]
        if len > 2 then
            local x = (segment[1] + segment[2]) / 2
            part(name .. "_Massive_Concrete_Wall", Vector3.new(len, 9, 1.1), Vector3.new(x, -6.0, z), Enum.Material.Concrete, C.concrete, parent)
        end
    end
end

local function addWallRunZ(name, first, last, centerX, halfWidth, side, parent)
    local x = centerX + side * (halfWidth - 0.55)
    part(name .. "_Massive_Concrete_Wall", Vector3.new(1.1, 9, last - first), Vector3.new(x, -6.0, (first + last) / 2), Enum.Material.Concrete, C.concrete, parent)
end

local function addEndWallX(name, x, zCenter, halfWidth, parent, gaps)
    for _, segment in ipairs(segmentsWithoutGaps(zCenter - halfWidth, zCenter + halfWidth, gaps)) do
        local len = segment[2] - segment[1]
        if len > 2 then
            part(name .. "_End_Wall", Vector3.new(1.2, 18, len), Vector3.new(x, -1.5, (segment[1] + segment[2]) / 2), Enum.Material.Concrete, C.concrete, parent)
        end
    end
end

local function addEndWallZ(name, z, xCenter, halfWidth, parent, gaps)
    for _, segment in ipairs(segmentsWithoutGaps(xCenter - halfWidth, xCenter + halfWidth, gaps)) do
        local len = segment[2] - segment[1]
        if len > 2 then
            part(name .. "_End_Wall", Vector3.new(len, 18, 1.2), Vector3.new((segment[1] + segment[2]) / 2, -1.5, z), Enum.Material.Concrete, C.concrete, parent)
        end
    end
end

local function addLamp(name, position, parent, brightness, range, tint)
    local housing = part(name .. "_Recessed_Housing", Vector3.new(6.4, 0.55, 2.1), position, Enum.Material.Metal, C.steel, parent)
    part(name .. "_LED_Diffuser_Left", Vector3.new(5.7, 0.1, 0.28), position + Vector3.new(0, -0.31, -0.48), Enum.Material.Neon, tint or Color3.fromRGB(200, 228, 218), parent, 0, false)
    local rightLens = part(name .. "_LED_Diffuser_Right", Vector3.new(5.7, 0.1, 0.28), position + Vector3.new(0, -0.31, 0.48), Enum.Material.Neon, tint or Color3.fromRGB(200, 228, 218), parent, 0, false)
    local light = Instance.new("SurfaceLight")
    light.Name = name .. "_Wide_Downlight"
    light.Face = Enum.NormalId.Bottom
    light.Color = tint or Color3.fromRGB(200, 228, 218)
    light.Brightness = brightness or 2.4
    light.Range = range or 38
    light.Angle = 120
    light.Shadows = true
    light.Parent = rightLens
    local fill = Instance.new("PointLight")
    fill.Name = name .. "_Soft_Fill"
    fill.Color = light.Color
    fill.Brightness = 0.28
    fill.Range = 15
    fill.Shadows = false
    fill.Parent = housing
end

local function addWallPanelsX(name, first, last, centerZ, halfWidth, parent, negativeGaps, positiveGaps)
    -- Panels are mounted just inside the concrete face, not buried inside the wall.
    for _, side in ipairs({-1, 1}) do
        local z = centerZ + side * (halfWidth - 1.2)
        local sideGaps = side < 0 and (negativeGaps or {}) or (positiveGaps or {})
        for _, segment in ipairs(segmentsWithoutGaps(first, last, sideGaps)) do
            for x = segment[1] + 6, segment[2] - 5, 14 do
                local panel = part(name .. "_Armoured_Wall_Module", Vector3.new(10.4, 4.2, 0.16), Vector3.new(x, -4.8, z), Enum.Material.DiamondPlate, Color3.fromRGB(46, 59, 62), parent, 0, false)
                panel.Reflectance = 0.05
                for _, edge in ipairs({-4.95, 4.95}) do
                    part(name .. "_Panel_Outer_Frame", Vector3.new(0.16, 4.45, 0.22), Vector3.new(x + edge, -4.8, z - side * 0.12), Enum.Material.Metal, C.steel, parent, 0, false)
                end
                for _, y in ipairs({-6.9, -2.7}) do
                    part(name .. "_Panel_Horizontal_Rail", Vector3.new(10.25, 0.12, 0.2), Vector3.new(x, y, z - side * 0.12), Enum.Material.Metal, C.steelMid, parent, 0, false)
                end
                for louver = -2, 2 do
                    part(name .. "_Panel_Vent_Slat", Vector3.new(0.12, 1.25, 0.08), Vector3.new(x + louver * 0.55, -4.95, z - side * 0.2), Enum.Material.Metal, C.steelBright, parent, 0, false)
                end
                local status = part(name .. "_Teal_Module_Status", Vector3.new(0.12, 0.48, 0.08), Vector3.new(x + 4.35, -3.5, z - side * 0.2), Enum.Material.Neon, C.teal, parent, 0, false)
                status.CastShadow = false
            end
        end
    end
end

local function addWallPanelsZ(name, first, last, centerX, halfWidth, parent)
    for _, side in ipairs({-1, 1}) do
        -- Panels sit just inside the inner face of the tunnel wall.
        local x = centerX + side * (halfWidth - 1.2)
        for z = first + 6, last - 5, 14 do
            part(name .. "_Armoured_Wall_Module", Vector3.new(0.16, 4.2, 10.4), Vector3.new(x, -4.8, z), Enum.Material.DiamondPlate, Color3.fromRGB(46, 59, 62), parent, 0, false)
            for _, offset in ipairs({-4.95, 4.95}) do
                part(name .. "_Panel_Outer_Frame", Vector3.new(0.22, 4.45, 0.16), Vector3.new(x - side * 0.12, -4.8, z + offset), Enum.Material.Metal, C.steel, parent, 0, false)
            end
            for _, y in ipairs({-6.9, -2.7}) do
                part(name .. "_Panel_Horizontal_Rail", Vector3.new(0.2, 0.12, 10.25), Vector3.new(x - side * 0.12, y, z), Enum.Material.Metal, C.steelMid, parent, 0, false)
            end
            for louver = -2, 2 do
                part(name .. "_Panel_Vent_Slat", Vector3.new(0.08, 1.25, 0.12), Vector3.new(x - side * 0.2, -4.95, z + louver * 0.55), Enum.Material.Metal, C.steelBright, parent, 0, false)
            end
            part(name .. "_Teal_Module_Status", Vector3.new(0.08, 0.48, 0.12), Vector3.new(x - side * 0.2, -3.5, z + 4.35), Enum.Material.Neon, C.teal, parent, 0, false)
        end
    end
end

local function addPipeRunX(name, first, last, centerZ, side, parent, gaps)
    -- Stop large wall-mounted pipes before every door opening. This keeps the
    -- side routes fully clear instead of running a pipe through the entrance.
    for _, segment in ipairs(segmentsWithoutGaps(first, last, gaps)) do
        local segmentStart, segmentEnd = segment[1], segment[2]
        local segmentLength = segmentEnd - segmentStart
        if segmentLength > 8 then
            local z = centerZ + side * 15.1
            local middle = (segmentStart + segmentEnd) / 2
            local mainPipe = cylinder(name .. "_Primary_Pressure_Main", segmentLength, 1.05, Vector3.new(middle, -4.6, z), Enum.Material.CorrodedMetal, C.rust, parent)
            mainPipe.Reflectance = 0.1
            cylinder(name .. "_Secondary_Service_Line", segmentLength, 0.48, Vector3.new(middle, -2.7, z - side * 1.5), Enum.Material.Metal, C.steelMid, parent)
            cylinder(name .. "_Cable_Conduit", segmentLength, 0.24, Vector3.new(middle, -1.7, z - side * 2.6), Enum.Material.Metal, C.steelBright, parent)

            for x = segmentStart + 12, segmentEnd - 10, 18 do
                part(name .. "_Pipe_Saddle", Vector3.new(0.9, 1.3, 1.1), Vector3.new(x, -4.6, z), Enum.Material.Metal, C.steel, parent)
            end
            for x = segmentStart + 24, segmentEnd - 16, 48 do
                local flange = cylinder(name .. "_Bolted_Flange", 0.24, 1.32, Vector3.new(x, -4.6, z), Enum.Material.CorrodedMetal, C.rustDark, parent)
                flange.Reflectance = 0.08
            end
        end
    end
end

local function addPipeRunZ(name, first, last, centerX, side, parent)
    local x = centerX + side * 12.9
    local mainPipe = cylinder(name .. "_Primary_Pressure_Main", last - first, 0.98, Vector3.new(x, -4.6, (first + last) / 2), Enum.Material.CorrodedMetal, C.rust, parent, "Z")
    mainPipe.Reflectance = 0.1
    cylinder(name .. "_Secondary_Service_Line", last - first, 0.45, Vector3.new(x - side * 1.5, -2.7, (first + last) / 2), Enum.Material.Metal, C.steelMid, parent, "Z")
    for z = first + 12, last - 10, 18 do
        part(name .. "_Pipe_Saddle", Vector3.new(1.1, 1.2, 0.9), Vector3.new(x, -4.6, z), Enum.Material.Metal, C.steel, parent)
    end
end

local function addWalkwayLinesX(name, first, last, centerZ, parent, halfChannel)
    for _, side in ipairs({-1, 1}) do
        local line = part(name .. "_Amber_Safety_Line", Vector3.new(last - first, 0.035, 0.15), Vector3.new((first + last) / 2, -9.97, centerZ + side * (halfChannel + 1.15)), Enum.Material.Neon, C.amber, parent, 0.12, false)
        line.CastShadow = false
    end
end

local function addWalkwayLinesZ(name, first, last, centerX, parent, halfChannel)
    for _, side in ipairs({-1, 1}) do
        local line = part(name .. "_Amber_Safety_Line", Vector3.new(0.15, 0.035, last - first), Vector3.new(centerX + side * (halfChannel + 1.15), -9.97, (first + last) / 2), Enum.Material.Neon, C.amber, parent, 0.12, false)
        line.CastShadow = false
    end
end

local function buildTunnelX(name, first, last, centerZ, width, parent, negativeGaps, positiveGaps, bridges)
    local model = newModel(name, parent)
    local half = width / 2
    local channel = 10
    buildChannelFloor(name, "X", (first + last) / 2, centerZ, last - first, width, channel, model)
    addWallRunX(name .. "_South", first, last, centerZ, half, -1, model, negativeGaps)
    addWallRunX(name .. "_North", first, last, centerZ, half, 1, model, positiveGaps)
    buildArchX(name, first, last, centerZ, half, model, -1.5)
    local skipped = {}
    for _, gap in ipairs(negativeGaps or {}) do table.insert(skipped, gap) end
    for _, gap in ipairs(positiveGaps or {}) do table.insert(skipped, gap) end
    addVaultRibsX(name, first, last, centerZ, half - 0.32, model, skipped)

    addWater(name .. "_River", "X", (first + last) / 2, centerZ, last - first, channel, model)
    addRiverWallsX(name, first, last, centerZ, channel, model, bridges, negativeGaps, positiveGaps)
    addBridgesX(name, bridges, centerZ, model)

    addWallPanelsX(name, first + 6, last - 6, centerZ, half, model, negativeGaps, positiveGaps)
    addPipeRunX(name .. "_South", first + 4, last - 4, centerZ, -1, model, negativeGaps)
    addPipeRunX(name .. "_North", first + 4, last - 4, centerZ, 1, model, positiveGaps)
    addWalkwayLinesX(name, first + 3, last - 3, centerZ, model, channel / 2)

    for x = first + 18, last - 12, 28 do
        addLamp(name .. "_Linear_LED", Vector3.new(x, 7.0, centerZ), model, 2.8, 44)
    end
    return model
end

local function buildTunnelZ(name, centerX, first, last, width, parent, bridges)
    local model = newModel(name, parent)
    local half = width / 2
    local channel = 10
    buildChannelFloor(name, "Z", centerX, (first + last) / 2, last - first, width, channel, model)
    addWallRunZ(name .. "_West", first, last, centerX, half, -1, model)
    addWallRunZ(name .. "_East", first, last, centerX, half, 1, model)
    buildArchZ(name, first, last, centerX, half, model, -1.5)
    addVaultRibsZ(name, first, last, centerX, half - 0.32, model)

    addWater(name .. "_River", "Z", centerX, (first + last) / 2, last - first, channel, model)
    addRiverWallsZ(name, first, last, centerX, channel, model, bridges)
    addBridgesZ(name, bridges, centerX, model)

    addWallPanelsZ(name, first + 6, last - 6, centerX, half, model)
    addPipeRunZ(name .. "_West", first + 4, last - 4, centerX, -1, model)
    addPipeRunZ(name .. "_East", first + 4, last - 4, centerX, 1, model)
    addWalkwayLinesZ(name, first + 3, last - 3, centerX, model, channel / 2)

    for z = first + 18, last - 12, 28 do
        addLamp(name .. "_Linear_LED", Vector3.new(centerX, 7.0, z), model, 2.65, 42)
    end
    return model
end

local function addIndustrialSign(name, text, position, size, face, parent)
    local plate = part(name .. "_Backplate", size, position, Enum.Material.Metal, C.steel, parent)
    local gui = Instance.new("SurfaceGui")
    gui.Name = name .. "_Surface"
    gui.Face = face
    gui.PixelsPerStud = 34
    gui.Parent = plate

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = C.teal
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.steelBright
    stroke.Thickness = 1
    stroke.Parent = label
    return plate
end

local function addPumpAssembly(name, position, parent, scale)
    scale = scale or 1
    local x, y, z = position.X, position.Y, position.Z
    part(name .. "_Foundation", Vector3.new(11 * scale, 0.8, 8 * scale), Vector3.new(x, y - 1.3 * scale, z), Enum.Material.Metal, C.steel, parent)

    local motor = part(name .. "_Motor_Housing", Vector3.new(5.3 * scale, 3.2 * scale, 4.2 * scale), Vector3.new(x + 1.1 * scale, y + 0.7 * scale, z), Enum.Material.CorrodedMetal, Color3.fromRGB(57, 68, 66), parent)
    motor.Reflectance = 0.08
    cylinder(name .. "_Motor_Fan_Cover", 0.28 * scale, 3.2 * scale, Vector3.new(x + 3.8 * scale, y + 0.7 * scale, z), Enum.Material.Metal, C.steelBright, parent)
    cylinder(name .. "_Pump_Coupling", 2.3 * scale, 1.4 * scale, Vector3.new(x - 2.1 * scale, y + 0.8 * scale, z), Enum.Material.Metal, C.rust, parent)

    local volute = cylinder(name .. "_Pump_Volute", 2.5 * scale, 4.1 * scale, Vector3.new(x - 4.0 * scale, y + 1.1 * scale, z), Enum.Material.CorrodedMetal, C.steelMid, parent)
    volute.Reflectance = 0.12
    cylinder(name .. "_Pump_Inlet", 6.5 * scale, 1.65 * scale, Vector3.new(x - 5.0 * scale, y + 1.0 * scale, z), Enum.Material.CorrodedMetal, C.rust, parent)
    cylinder(name .. "_Pump_Outlet", 6.0 * scale, 1.4 * scale, Vector3.new(x - 4.0 * scale, y + 3.2 * scale, z), Enum.Material.Metal, C.steelBright, parent)

    for bolt = 1, 4 do
        local angle = math.rad((bolt - 1) * 90)
        local boltPart = part(
            name .. "_Housing_Bolt",
            Vector3.new(0.16, 0.16, 0.16),
            Vector3.new(x + math.cos(angle) * 2.0 * scale, y + 2.35 * scale, z + math.sin(angle) * 1.6 * scale),
            Enum.Material.Metal,
            C.steelBright,
            parent
        )
        boltPart.Shape = Enum.PartType.Ball
    end
end

local function buildPumpHall()
    local hall = newModel("Grand_Pump_Hall")
    local centerX, centerZ = -55, -166
    local width, length = 82, 60
    buildChannelFloor("Pump_Hall", "Z", centerX, centerZ, length, width, 10, hall)
    addRiverWallsZ("Pump_Hall", centerZ - length / 2, centerZ + length / 2, centerX, 10, hall, {-166, -146})
    addWater("Pump_Hall_River", "Z", centerX, centerZ, length, 10, hall)
    addBridgesZ("Pump_Hall", {-166, -146}, centerX, hall)

    part("Pump_Hall_West_Wall", Vector3.new(1.3, 19, length), Vector3.new(centerX - width / 2, -1.0, centerZ), Enum.Material.Concrete, C.concrete, hall)
    part("Pump_Hall_East_Wall", Vector3.new(1.3, 19, length), Vector3.new(centerX + width / 2, -1.0, centerZ), Enum.Material.Concrete, C.concrete, hall)
    addEndWallZ("Pump_Hall_North_End", centerZ - length / 2, centerX, width / 2, hall)
    addEndWallZ("Pump_Hall_South_End", centerZ + length / 2, centerX, width / 2, hall, {{centerX, 30}})

    part("Pump_Hall_Raised_Roof", Vector3.new(width, 1.8, length), Vector3.new(centerX, 8.8, centerZ), Enum.Material.Concrete, C.concreteDark, hall)
    for x = centerX - width / 2 + 4, centerX + width / 2 - 4, 12 do
        part("Pump_Hall_Ceiling_Girder", Vector3.new(0.65, 1.1, length - 3), Vector3.new(x, 7.6, centerZ), Enum.Material.Metal, C.steel, hall)
    end

    -- Two huge pump skids stand on the dry platforms either side of the river.
    -- Machine skids sit directly on the dry floor instead of floating above it.
    addPumpAssembly("Pump_Alpha", Vector3.new(-83, -9.0, -155), hall, 1.2)
    addPumpAssembly("Pump_Beta", Vector3.new(-27, -9.0, -177), hall, 1.2)

    for _, z in ipairs({-188, -144}) do
        cylinder("Pump_Hall_Overhead_Header", 70, 1.15, Vector3.new(centerX, 4.5, z), Enum.Material.CorrodedMetal, C.rust, hall)
        cylinder("Pump_Hall_Header_Secondary", 70, 0.5, Vector3.new(centerX, 5.9, z + 3), Enum.Material.Metal, C.steelBright, hall)
    end

    -- A suspended service gantry spans the equipment bay.
    for _, x in ipairs({-91, -19}) do
        for _, z in ipairs({-188, -144}) do
            part("Pump_Gantry_Column", Vector3.new(0.7, 15, 0.7), Vector3.new(x, 1.0, z), Enum.Material.Metal, C.steel, hall)
        end
    end
    part("Pump_Gantry_Main_Beam", Vector3.new(72, 0.8, 0.8), Vector3.new(centerX, 8.0, -166), Enum.Material.Metal, C.steelMid, hall)
    part("Pump_Gantry_Cross_Beam", Vector3.new(0.8, 0.8, 44), Vector3.new(centerX, 8.0, -166), Enum.Material.Metal, C.steelMid, hall)

    for _, z in ipairs({-188, -166, -144}) do
        addLamp("Pump_Hall_LED", Vector3.new(centerX, 7.0, z), hall, 3.0, 48)
    end

    addIndustrialSign("Pump_Hall_Sign", "PUMP STATION  /  02", Vector3.new(centerX + width / 2 - 0.8, 4.2, centerZ), Vector3.new(0.2, 3.2, 12), Enum.NormalId.Left, hall)

    local emergency = part("Pump_Hall_Emergency_Beacon", Vector3.new(1.4, 0.8, 1.4), Vector3.new(centerX + 31, 6.6, centerZ - 8), Enum.Material.Neon, C.red, hall, 0, false)
    local redLight = Instance.new("PointLight")
    redLight.Color = C.red
    redLight.Brightness = 1.7
    redLight.Range = 28
    redLight.Parent = emergency
end

local function buildSluiceHall()
    local hall = newModel("Grand_Sluice_Hall")
    local centerX, centerZ = 231, 150
    local width, depth = 82, 84
    local firstX, lastX = centerX - width / 2, centerX + width / 2

    buildChannelFloor("Sluice_Hall", "X", centerX, centerZ, width, depth, 10, hall)
    addWater("Sluice_Hall_River", "X", centerX, centerZ, width, 10, hall)
    addRiverWallsX("Sluice_Hall", firstX, lastX, centerZ, 10, hall, {208, 252})
    addBridgesX("Sluice_Hall", {208, 252}, centerZ, hall)

    part("Sluice_Hall_North_Wall", Vector3.new(width, 19, 1.3), Vector3.new(centerX, -1.0, centerZ + depth / 2), Enum.Material.Concrete, C.concrete, hall)
    part("Sluice_Hall_South_Wall", Vector3.new(width, 19, 1.3), Vector3.new(centerX, -1.0, centerZ - depth / 2), Enum.Material.Concrete, C.concrete, hall)
    addEndWallX("Sluice_Hall_West_Entry", firstX, centerZ, depth / 2, hall, {{centerZ, 30}})
    addEndWallX("Sluice_Hall_East_Wall", lastX, centerZ, depth / 2, hall)

    part("Sluice_Hall_Raised_Roof", Vector3.new(width, 1.8, depth), Vector3.new(centerX, 8.8, centerZ), Enum.Material.Concrete, C.concreteDark, hall)
    for z = centerZ - depth / 2 + 5, centerZ + depth / 2 - 5, 12 do
        part("Sluice_Hall_Ceiling_Girder", Vector3.new(width - 4, 1.1, 0.7), Vector3.new(centerX, 7.6, z), Enum.Material.Metal, C.steel, hall)
    end

    -- A very large sluice gate is mounted over the flow, with the bottom bars kept above the crossing route.
    part("Sluice_Gate_Top_Housing", Vector3.new(2.2, 3.2, 14), Vector3.new(260, 2.0, centerZ), Enum.Material.Metal, C.steel, hall)
    for z = centerZ - 5.5, centerZ + 5.5, 1.1 do
        part("Sluice_Gate_Heavy_Bar", Vector3.new(0.45, 5.0, 0.45), Vector3.new(260, -1.7, z), Enum.Material.CorrodedMetal, C.rust, hall)
    end
    for _, z in ipairs({centerZ - 6.6, centerZ + 6.6}) do
        part("Sluice_Gate_Guide_Rail", Vector3.new(0.65, 8, 0.65), Vector3.new(260, -2.4, z), Enum.Material.Metal, C.steelBright, hall)
    end

    -- Filter columns and a large pressure manifold flank the eastern end.
    for _, z in ipairs({centerZ - 28, centerZ + 28}) do
        local tank = cylinder("Sluice_Filter_Column", 13, 8, Vector3.new(245, -3.2, z), Enum.Material.CorrodedMetal, C.steelMid, hall, "Y")
        tank.Reflectance = 0.12
        cylinder("Sluice_Filter_Collar", 0.45, 8.6, Vector3.new(245, -8.0, z), Enum.Material.Metal, C.steelBright, hall, "Y")
        cylinder("Sluice_Filter_Collar", 0.45, 8.6, Vector3.new(245, 1.6, z), Enum.Material.Metal, C.steelBright, hall, "Y")
    end
    cylinder("Sluice_Upper_Manifold", 66, 1.3, Vector3.new(231, 5.2, centerZ + 34), Enum.Material.CorrodedMetal, C.rust, hall)
    cylinder("Sluice_Lower_Manifold", 66, 0.7, Vector3.new(231, 3.8, centerZ - 34), Enum.Material.Metal, C.steelBright, hall)

    for _, x in ipairs({205, 231, 257}) do
        addLamp("Sluice_Hall_LED", Vector3.new(x, 7.0, centerZ), hall, 3.0, 48)
    end
    addIndustrialSign("Sluice_Hall_Sign", "MAIN SLUICE  /  04", Vector3.new(271.2, 4.5, centerZ), Vector3.new(0.2, 3.2, 13), Enum.NormalId.Left, hall)

    local beacon = part("Sluice_Red_Beacon", Vector3.new(1.6, 0.8, 1.6), Vector3.new(255, 6.4, centerZ + 33), Enum.Material.Neon, C.red, hall, 0, false)
    local redLight = Instance.new("PointLight")
    redLight.Color = C.red
    redLight.Brightness = 1.4
    redLight.Range = 24
    redLight.Parent = beacon
end

local function addMainTunnelGate()
    local gate = newModel("Main_Restricted_Gate")
    local x = 118
    for _, z in ipairs({-15.6, 15.6}) do
        part("Gate_Heavy_Pillar", Vector3.new(1.4, 13, 1.4), Vector3.new(x, -4.0, z), Enum.Material.Metal, C.steel, gate)
    end
    part("Gate_Top_Beam", Vector3.new(1.5, 1.3, 31), Vector3.new(x, 2.4, 0), Enum.Material.Metal, C.steelMid, gate)
    for z = -14, 14, 1.6 do
        part("Gate_Vertical_Bar", Vector3.new(0.4, 10.5, 0.4), Vector3.new(x, -4.2, z), Enum.Material.CorrodedMetal, C.rust, gate)
    end
    part("Gate_Warning_Plate", Vector3.new(0.4, 2.8, 10), Vector3.new(x - 0.3, -2.0, 0), Enum.Material.Metal, C.steel, gate)
    addIndustrialSign("Gate_Zone_Sign", "RESTRICTED  /  SECTOR 04", Vector3.new(x - 0.75, -2.0, -0.1), Vector3.new(0.15, 2.8, 9), Enum.NormalId.Right, gate)

    local warning = part("Gate_Alarm_Beacon", Vector3.new(0.7, 0.7, 0.7), Vector3.new(x - 1, 1.1, -13.5), Enum.Material.Neon, C.red, gate, 0, false)
    local light = Instance.new("PointLight")
    light.Color = C.red
    light.Brightness = 1.4
    light.Range = 20
    light.Parent = warning
end

local function buildMainSewer()
    local main = buildTunnelX(
        "Main_Concourse",
        -140,
        140,
        0,
        34,
        world,
        {{-55, 30}},
        {{65, 30}},
        {-108, -55, -22, 28, 65, 91}
    )

    -- A sealed beginning and far end keep the player inside the playable facility.
    addEndWallX("Main_Entrance_Seal", -140, 0, 17, main)
    addEndWallX("Main_Far_Seal", 140, 0, 17, main)

    addIndustrialSign("Main_Concourse_ID", "DRAINAGE CONCOURSE  /  LINE 01", Vector3.new(-98, -2.3, -15.78), Vector3.new(13, 3.2, 0.22), Enum.NormalId.Back, main)

    -- Heavy maintenance supports at the entrance and along the main gallery.
    for x = -126, 126, 36 do
        for _, side in ipairs({-1, 1}) do
            part("Main_Gallery_Wall_Pilaster", Vector3.new(1.25, 9.3, 1.4), Vector3.new(x, -6.0, side * 16.0), Enum.Material.Metal, C.steel, main)
            part("Main_Gallery_Pilaster_Foot", Vector3.new(2.0, 0.35, 1.8), Vector3.new(x, -9.82, side * 16.0), Enum.Material.Metal, C.steelMid, main)
        end
    end

    -- Extra overhead service conduits, anchored to the roof crown.
    cylinder("Main_Crown_Manifold", 255, 1.25, Vector3.new(-12, 11.4, 0), Enum.Material.Metal, C.steelMid, main)
    cylinder("Main_Crown_Conduit_A", 255, 0.42, Vector3.new(-12, 10.1, -3.0), Enum.Material.CorrodedMetal, C.rust, main)
    cylinder("Main_Crown_Conduit_B", 255, 0.42, Vector3.new(-12, 10.1, 3.0), Enum.Material.CorrodedMetal, C.rust, main)
    for x = -120, 120, 24 do
        part("Main_Crown_Manifold_Hanger", Vector3.new(0.42, 2.0, 0.42), Vector3.new(x, 10.0, 0), Enum.Material.Metal, C.steel, main)
    end

    addMainTunnelGate()
end

local function buildWestRoute()
    local branch = buildTunnelZ("West_Collector_Tunnel", -55, -17, -137, 30, world, {-42, -91, -122})

    -- Short lined water connector bridges the 12-stud offset between the
    -- branch channel mouth and the main concourse river.
    part("West_T_Junction_Riverbed", Vector3.new(10, 1, 13), Vector3.new(-55, -12.5, -11), Enum.Material.Slate, C.concreteDark, world)
    addWater("West_T_Junction_Water", "Z", -55, -9, 18, 10, world)
    addRiverWallsZ("West_T_Junction", -17, -5, -55, 10, world, {})

    local hall = buildPumpHall()
    addIndustrialSign("West_Collector_ID", "COLLECTOR  /  PUMP ACCESS", Vector3.new(-68.75, -2.2, -18), Vector3.new(0.22, 3, 10), Enum.NormalId.Right, branch)
    return branch, hall
end

local function buildEastRoute()
    local branch = buildTunnelZ("East_Service_Tunnel", 65, 17, 137, 30, world, {45, 92, 121})

    -- Water and the lowered bed continue through the short T-junction into
    -- the cross-gallery; the tunnel side walls stop at the actual doorway.
    part("East_T_Junction_Riverbed", Vector3.new(10, 1, 18), Vector3.new(65, -12.5, 142), Enum.Material.Slate, C.concreteDark, world)
    addWater("East_T_Junction_Water", "Z", 65, 142, 20, 10, world)
    addRiverWallsZ("East_T_Junction", 137, 150, 65, 10, world, {})

    -- A large cross-gallery receives the east branch through an opening in its south wall.
    local cross = buildTunnelX("East_Transfer_Gallery", 50, 190, 150, 34, world, {{65, 30}}, {}, {82, 142})
    addEndWallX("East_Transfer_West_End", 50, 150, 17, cross)
    local hall = buildSluiceHall()
    addIndustrialSign("East_Service_ID", "EAST SERVICE  /  LINE 02", Vector3.new(78.75, -2.2, 18), Vector3.new(0.22, 3, 10), Enum.NormalId.Left, branch)
    return branch, cross, hall
end

local function buildEntrance()
    local entry = newModel("Sewer_Entry_Portal")
    -- The entry platform is on the right-hand dry walkway, not over the river.
    part("Entry_Heavy_Grate", Vector3.new(12, 0.32, 8), Vector3.new(-125, -9.82, 11.5), Enum.Material.DiamondPlate, C.steelMid, entry)
    for x = -130, -120, 1 do
        part("Entry_Grate_Rib", Vector3.new(0.09, 0.06, 7.7), Vector3.new(x, -9.62, 11.5), Enum.Material.Metal, C.steelBright, entry, 0, false)
    end
    for _, z in ipairs({7.2, 15.8}) do
        part("Entry_Railing", Vector3.new(12, 1.2, 0.18), Vector3.new(-125, -8.95, z), Enum.Material.Metal, C.steel, entry)
        for _, x in ipairs({-130, -125, -120}) do
            part("Entry_Railing_Post", Vector3.new(0.22, 1.5, 0.22), Vector3.new(x, -9.1, z), Enum.Material.Metal, C.steelMid, entry)
        end
    end
    addIndustrialSign("Entry_Portal_ID", "ACCESS 04  /  DRAINAGE", Vector3.new(-130, -2.1, -15.78), Vector3.new(11, 3, 0.25), Enum.NormalId.Back, entry)
end

local function placePlayer(player, character, spawn)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if humanoid then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 42
        humanoid.JumpHeight = 5
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    end
    if root then
        character:PivotTo(spawn.CFrame * CFrame.new(0, 3.1, 0))
    else
        warn("[Horror Game] Character root not ready for spawn placement.")
    end
end

-- Clear only the old sewer's broad Terrain area, including the previous river beds.
pcall(function()
    Workspace.Terrain:FillBlock(CFrame.new(40, -8, 0), Vector3.new(760, 34, 520), Enum.Material.Air)
end)

configureLighting()

-- COMPLETE NEW MAP LAYOUT:
-- 1) Huge arched main concourse
-- 2) West collector branch and full-size pump hall
-- 3) East service branch, transfer gallery and monumental sluice hall
buildMainSewer()
buildWestRoute()
buildEastRoute()
buildEntrance()

local spawn = Instance.new("SpawnLocation")
spawn.Name = "SewerSpawn"
spawn.Size = Vector3.new(6, 1, 8)
spawn.CFrame = CFrame.new(-125, 0.5, 11.5) * CFrame.Angles(0, math.rad(-90), 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Transparency = 1
spawn.CanCollide = false
spawn.CanTouch = true
spawn.CanQuery = true
spawn.Parent = world

local function bindPlayer(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.2)
        placePlayer(player, character, spawn)
    end)
    if player.Character then
        task.spawn(placePlayer, player, player.Character, spawn)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    bindPlayer(player)
end
Players.PlayerAdded:Connect(bindPlayer)

-- Remove the old unsupported/mismatched prototype reference if any old object remains.
for _, instance in ipairs(game:GetDescendants()) do
    if instance:IsA("Sound") and string.find(instance.SoundId, "203785492", 1, true) then
        instance.SoundId = ""
    elseif instance:IsA("Decal") and string.find(instance.Texture, "203785492", 1, true) then
        instance.Texture = ""
    elseif instance:IsA("Texture") and string.find(instance.Texture, "203785492", 1, true) then
        instance.Texture = ""
    elseif instance:IsA("ImageLabel") and string.find(instance.Image, "203785492", 1, true) then
        instance.Image = ""
    elseif instance:IsA("ImageButton") and string.find(instance.Image, "203785492", 1, true) then
        instance.Image = ""
    end
end

print("[Horror Game] Sewer V15 COMPLETE REBUILD loaded: monumental arched concourse, west pump hall, east transfer gallery and sluice hall, new water channels, bridges, steelwork and architectural lighting.")

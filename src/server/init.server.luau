--[[
    HORROR GAME - SEWER LEVEL V10
    A fully enclosed, walkable sewer with an arched main tunnel, branch tunnel,
    pump room, service details, ceiling lights with animated dirty water and no flashlight.
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")

-- The first Rojo template may leave its default Baseplate in an existing Studio place.
-- It would cover the sewer because the old blockout used negative Y coordinates.
local oldBaseplate = Workspace:FindFirstChild("Baseplate")
if oldBaseplate and oldBaseplate:IsA("BasePart") then
    oldBaseplate:Destroy()
end

-- Raise every generated part as one consistent level so the sewer sits at ground level.
local WORLD_Y_OFFSET = 10.5

-- Remove any leftover default/template spawn pads, including their large built-in star decals.
for _, item in ipairs(Workspace:GetDescendants()) do
    if item:IsA("SpawnLocation") then
        item:Destroy()
    end
end

-- Remove any old flashlight inventory objects from earlier prototypes.
local oldStarterFlashlight = StarterPack:FindFirstChild("Taschenlampe")
if oldStarterFlashlight then oldStarterFlashlight:Destroy() end
for _, player in ipairs(Players:GetPlayers()) do
    local backpack = player:FindFirstChildOfClass("Backpack")
    local oldTool = backpack and backpack:FindFirstChild("Taschenlampe")
    if oldTool then oldTool:Destroy() end
    local characterTool = player.Character and player.Character:FindFirstChild("Taschenlampe")
    if characterTool then characterTool:Destroy() end
end

local previous = Workspace:FindFirstChild("SewerWorld")
if previous then previous:Destroy() end
local oldClinic = Workspace:FindFirstChild("HorrorWorld")
if oldClinic then oldClinic:Destroy() end

local world = Instance.new("Folder")
world.Name = "SewerWorld"
world.Parent = Workspace

local function makePart(name, size, cframe, material, color, parent, transparency)
    local item = Instance.new("Part")
    item.Name = name
    item.Size = size
    item.CFrame = CFrame.new(0, WORLD_Y_OFFSET, 0) * cframe
    item.Anchored = true
    item.CanCollide = true
    item.CanTouch = true
    item.CanQuery = true
    item.Material = material or Enum.Material.Concrete
    item.Color = color or Color3.fromRGB(70, 74, 71)
    item.TopSurface = Enum.SurfaceType.Smooth
    item.BottomSurface = Enum.SurfaceType.Smooth
    item.CastShadow = true
    item.Transparency = transparency or 0
    item.Parent = parent or world
    return item
end

local function part(name, size, position, material, color, parent, transparency)
    return makePart(name, size, CFrame.new(position), material, color, parent, transparency)
end

local function cylinder(name, length, diameter, position, material, color, parent, orientation)
    local item = part(
        name,
        Vector3.new(length, diameter, diameter),
        position,
        material or Enum.Material.Metal,
        color or Color3.fromRGB(55, 61, 59),
        parent
    )
    item.Shape = Enum.PartType.Cylinder
    item.Orientation = orientation or Vector3.new(0, 0, 0)
    return item
end

local function makeModel(name, parent)
    local result = Instance.new("Model")
    result.Name = name
    result.Parent = parent or world
    return result
end

-- Muddy current with moving surface streaks and quiet positional water ambience.
-- Uses Roblox Terrain Water instead of flat Parts. Terrain Water has built-in
-- animated waves and reflections, giving the channels a continuous natural surface.
local function addFlowingWater(name, axis, center, length, width, parent, bankOpenings, bankRange)
    local size = axis == "X"
        and Vector3.new(length, 4, width)
        or Vector3.new(width, 4, length)

    -- Exact voxel-aligned surface: water ends at world Y=0, below the walkways.
    local waterFrame = CFrame.new(center.X, -2, center.Z)

    -- Clear and refill only the channel volume. Terrain access/editing can be
    -- restricted by Studio sandbox capabilities, so keep a safe visual fallback.
    local terrainWaterOk, terrainWaterError = pcall(function()
        local terrain = Workspace.Terrain
        terrain:FillBlock(waterFrame, size, Enum.Material.Air)
        terrain:FillBlock(waterFrame, size, Enum.Material.Water)
    end)

    if not terrainWaterOk then
        warn("[Horror Game] Terrain water unavailable; using a surface fallback: " .. tostring(terrainWaterError))
        local fallbackSize = axis == "X"
            and Vector3.new(length, 0.12, width)
            or Vector3.new(width, 0.12, length)
        local surface = part(
            name .. "_Water_Surface_Fallback",
            fallbackSize,
            Vector3.new(center.X, -10.56, center.Z),
            Enum.Material.Glass,
            Color3.fromRGB(58, 62, 50),
            parent,
            0.18
        )
        surface.CanCollide = false
        surface.CanTouch = false
        surface.CanQuery = false
        surface.Reflectance = 0.18
    end

    -- At an elbow, shorten the concrete banks around the joining passage.
    -- This keeps each stream open through the junction instead of making a curb wall.
    if bankOpenings == false then
        return
    end

    local axisCenter = axis == "X" and center.X or center.Z
    local axisStart = axisCenter - length / 2
    local axisEnd = axisCenter + length / 2
    if bankRange then
        axisStart = math.max(axisStart, bankRange[1])
        axisEnd = math.min(axisEnd, bankRange[2])
    end
    if axisEnd <= axisStart then return end

    local segments = {{axisStart, axisEnd}}
    if bankOpenings then
        for _, opening in ipairs(bankOpenings) do
            local cutStart = opening[1] - opening[2] / 2
            local cutEnd = opening[1] + opening[2] / 2
            local nextSegments = {}
            for _, segment in ipairs(segments) do
                local segmentStart, segmentEnd = segment[1], segment[2]
                if cutEnd <= segmentStart or cutStart >= segmentEnd then
                    table.insert(nextSegments, segment)
                else
                    if cutStart > segmentStart then
                        table.insert(nextSegments, {segmentStart, math.min(cutStart, segmentEnd)})
                    end
                    if cutEnd < segmentEnd then
                        table.insert(nextSegments, {math.max(cutEnd, segmentStart), segmentEnd})
                    end
                end
            end
            segments = nextSegments
        end
    end

    local bankY = -10.25
    local bankColor = Color3.fromRGB(67, 72, 66)
    for _, side in ipairs({-1, 1}) do
        for _, segment in ipairs(segments) do
            local segmentLength = segment[2] - segment[1]
            if segmentLength > 1 then
                local positionAlong = (segment[1] + segment[2]) / 2
                if axis == "X" then
                    part(
                        name .. "_Raised_Channel_Bank",
                        Vector3.new(segmentLength, 1.0, 0.55),
                        Vector3.new(positionAlong, bankY, center.Z + side * 4.0),
                        Enum.Material.Concrete,
                        bankColor,
                        parent
                    )
                else
                    part(
                        name .. "_Raised_Channel_Bank",
                        Vector3.new(0.55, 1.0, segmentLength),
                        Vector3.new(center.X + side * 4.0, bankY, positionAlong),
                        Enum.Material.Concrete,
                        bankColor,
                        parent
                    )
                end
            end
        end
    end
end

local function configureLighting()
    Lighting.ClockTime = 0.35
    Lighting.Brightness = 2.45
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.fromRGB(119, 122, 113)
    Lighting.OutdoorAmbient = Color3.fromRGB(91, 96, 88)
    Lighting.FogColor = Color3.fromRGB(79, 84, 77)
    Lighting.FogStart = 175
    Lighting.FogEnd = 620
    Lighting.EnvironmentDiffuseScale = 0.56
    Lighting.EnvironmentSpecularScale = 0.32

    local waterSettingsOk, waterSettingsError = pcall(function()
        local terrain = Workspace.Terrain
            terrain.WaterColor = Color3.fromRGB(48, 52, 42)
        terrain.WaterReflectance = 0.38
        terrain.WaterTransparency = 0.11
        terrain.WaterWaveSize = 0.3
        terrain.WaterWaveSpeed = 8
    end)
    if not waterSettingsOk then
        warn("[Horror Game] Terrain water settings restricted; fallback water surfaces will be used: " .. tostring(waterSettingsError))
    end

    for _, name in ipairs({"SewerAtmosphere", "SewerColor", "SewerBloom"}) do
        local old = Lighting:FindFirstChild(name)
        if old then old:Destroy() end
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "SewerAtmosphere"
    atmosphere.Density = 0.06
    atmosphere.Offset = 0.015
    atmosphere.Color = Color3.fromRGB(172, 174, 163)
    atmosphere.Decay = Color3.fromRGB(79, 83, 74)
    atmosphere.Glare = 0
    atmosphere.Haze = 0.16
    atmosphere.Parent = Lighting

    local color = Instance.new("ColorCorrectionEffect")
    color.Name = "SewerColor"
    color.Brightness = 0.025
    color.Contrast = 0.09
    color.Saturation = -0.08
    color.TintColor = Color3.fromRGB(229, 231, 220)
    color.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "SewerBloom"
    bloom.Intensity = 0.1
    bloom.Size = 16
    bloom.Threshold = 1.6
    bloom.Parent = Lighting
end

local concrete = Color3.fromRGB(101, 103, 98)
local concreteDark = Color3.fromRGB(63, 68, 65)
local concreteEdge = Color3.fromRGB(98, 101, 95)
local metal = Color3.fromRGB(54, 61, 59)
local rust = Color3.fromRGB(73, 51, 42)
local yellow = Color3.fromRGB(176, 140, 61)

-- Creates a barrel-vault roof. The long dimension follows the tunnel axis;
-- each angled section overlaps its neighbours to form a continuous arch.
local function buildArch(axis, centerX, centerZ, centerY, radius, length, parent, name, material, color, thickness)
    for degrees = -90, 90, 20 do
        local angle = math.rad(degrees)
        local x = centerX
        local z = centerZ
        local y = centerY + radius * math.cos(angle)
        if axis == "X" then
            z = centerZ + radius * math.sin(angle)
            local cf = CFrame.new(x, y, z) * CFrame.Angles(angle, 0, 0)
            makePart(name .. "_RoofSection", Vector3.new(length, thickness or 1.5, 2.9), cf, material, color, parent)
        else
            x = centerX + radius * math.sin(angle)
            local cf = CFrame.new(x, y, z) * CFrame.Angles(0, 0, -angle)
            makePart(name .. "_RoofSection", Vector3.new(2.9, thickness or 1.5, length), cf, material, color, parent)
        end
    end
end

local function buildArchRibs(axis, centerX, centerZ, centerY, radius, positions, parent, name)
    for _, along in ipairs(positions) do
        for degrees = -90, 90, 20 do
            local angle = math.rad(degrees)
            local x = centerX
            local z = centerZ
            local y = centerY + radius * math.cos(angle)
            if axis == "X" then
                x = along
                z = centerZ + radius * math.sin(angle)
                local cf = CFrame.new(x, y, z) * CFrame.Angles(angle, 0, 0)
                makePart(name .. "_Steel_Rib", Vector3.new(0.72, 0.62, 2.82), cf, Enum.Material.Metal, Color3.fromRGB(48, 55, 52), parent)
            else
                z = along
                x = centerX + radius * math.sin(angle)
                local cf = CFrame.new(x, y, z) * CFrame.Angles(0, 0, -angle)
                makePart(name .. "_Steel_Rib", Vector3.new(2.82, 0.62, 0.72), cf, Enum.Material.Metal, Color3.fromRGB(48, 55, 52), parent)
            end
        end
    end
end

local function addCeilingLamp(position, parent, name, color, brightness, range)
    local fixture = part(name .. "_Housing", Vector3.new(3.8, 0.35, 1.45), position, Enum.Material.Metal, metal, parent)
    local lens = part(name .. "_Lens", Vector3.new(3.15, 0.13, 0.92), Vector3.new(position.X, position.Y - 0.22, position.Z), Enum.Material.Neon, color, parent)
    lens.CanCollide = false
    lens.CastShadow = false

    -- Broad downward light gives a soft fluorescent pool instead of a harsh orb.
    local surface = Instance.new("SurfaceLight")
    surface.Name = name .. "_Downward_Light"
    surface.Face = Enum.NormalId.Bottom
    surface.Color = color
    surface.Brightness = (brightness or 1.7) * 0.82
    surface.Range = (range or 30) * 0.9
    surface.Angle = 105
    surface.Shadows = true
    surface.Parent = lens

    local fill = Instance.new("PointLight")
    fill.Name = name .. "_Soft_Fill"
    fill.Color = color
    fill.Brightness = 0.3
    fill.Range = 14
    fill.Shadows = false
    fill.Parent = lens
    return fixture
end

-- Builds a recessed channel floor: two dry walking ledges and a lowered
-- concrete riverbed. Axis X means the tunnel runs left/right; Z means forward.
local function buildChannelFloor(name, axis, center, length, totalWidth, channelWidth, parent)
    local walkWidth = (totalWidth - channelWidth) / 2
    local offset = channelWidth / 2 + walkWidth / 2
    local bedCenterY = center.Y - 2.25

    if axis == "X" then
        part(
            name .. "_Left_Walkway",
            Vector3.new(length, 1, walkWidth),
            Vector3.new(center.X, center.Y, center.Z - offset),
            Enum.Material.Concrete,
            concrete,
            parent
        )
        part(
            name .. "_Right_Walkway",
            Vector3.new(length, 1, walkWidth),
            Vector3.new(center.X, center.Y, center.Z + offset),
            Enum.Material.Concrete,
            concrete,
            parent
        )
        part(
            name .. "_Lowered_Channel_Bed",
            Vector3.new(length, 0.5, channelWidth),
            Vector3.new(center.X, bedCenterY, center.Z),
            Enum.Material.Slate,
            concreteDark,
            parent
        )
    else
        part(
            name .. "_Left_Walkway",
            Vector3.new(walkWidth, 1, length),
            Vector3.new(center.X - offset, center.Y, center.Z),
            Enum.Material.Concrete,
            concrete,
            parent
        )
        part(
            name .. "_Right_Walkway",
            Vector3.new(walkWidth, 1, length),
            Vector3.new(center.X + offset, center.Y, center.Z),
            Enum.Material.Concrete,
            concrete,
            parent
        )
        part(
            name .. "_Lowered_Channel_Bed",
            Vector3.new(channelWidth, 0.5, length),
            Vector3.new(center.X, bedCenterY, center.Z),
            Enum.Material.Slate,
            concreteDark,
            parent
        )
    end
end

local function buildMainTunnel()
    local tunnel = makeModel("Main_Sewer_Tunnel")

    -- Flat, continuous walking floor and tall side walls.
    buildChannelFloor("Main", "X", Vector3.new(40, -10.5, 0), 320, 18, 8, tunnel)

    -- Two gaps in the long side walls create real junctions for the branch tunnels.
    part("Main_Left_Side_Wall_A", Vector3.new(60, 7, 1), Vector3.new(-90, -6.5, -8), Enum.Material.Concrete, concrete, tunnel)
    part("Main_Left_Side_Wall_B", Vector3.new(240, 7, 1), Vector3.new(80, -6.5, -8), Enum.Material.Concrete, concrete, tunnel)
    part("Main_Right_Wall_A", Vector3.new(145, 7, 1), Vector3.new(-47.5, -6.5, 8), Enum.Material.Concrete, concrete, tunnel)
    part("Main_Right_Wall_B", Vector3.new(155, 7, 1), Vector3.new(122.5, -6.5, 8), Enum.Material.Concrete, concrete, tunnel)

    -- Extended arched roof and repeating steel support frames.
    buildArch("X", 40, 0, -3, 7.5, 320, tunnel, "Main", Enum.Material.Concrete, concreteDark, 1.55)
    local ribPositions = {}
    for x = -112, 192, 16 do
        -- No full arch rib directly across either side-tunnel portal.
        local atLeftPortal = x >= -64 and x <= -32
        local atRightPortal = x >= 24 and x <= 48
        if not atLeftPortal and not atRightPortal then
            table.insert(ribPositions, x)
        end
    end
    buildArchRibs("X", 0, 0, -3, 7.02, ribPositions, tunnel, "Main")

    -- The main stream branches into the side corridors at both junctions.
    addFlowingWater("Main_Channel", "X", Vector3.new(40, -9.94, 0), 312, 8, tunnel, {{-50, 18}, {35, 18}})
    addFlowingWater("Main_Right_Junction", "Z", Vector3.new(35, -9.94, 4.5), 12, 8, tunnel, false)
    addFlowingWater("Main_Left_Junction", "Z", Vector3.new(-50, -9.94, -4.5), 12, 8, tunnel, false)

    -- Wall pipes are split at both side-tunnel portals, so pipes never cross an entrance.
    for _, side in ipairs({-1, 1}) do
        local pipeZ = side * 6.75
        local pipeRanges
        if side == -1 then
            pipeRanges = {{-90, 60}, {80, 240}}
        else
            pipeRanges = {{-47.5, 145}, {122.5, 155}}
        end

        for _, segment in ipairs(pipeRanges) do
            local pipeCenter, pipeLength = segment[1], segment[2]
            local mainPipe = cylinder("Main_Rusted_Service_Pipe", pipeLength, 0.66, Vector3.new(pipeCenter, -5.2, pipeZ), Enum.Material.CorrodedMetal, Color3.fromRGB(83, 57, 43), tunnel)
            local upperPipe = cylinder("Main_Upper_Service_Pipe", pipeLength, 0.3, Vector3.new(pipeCenter, -3.6, side * 7.05), Enum.Material.Metal, metal, tunnel)
            mainPipe.Reflectance = 0.12
            upperPipe.Reflectance = 0.08
        end

        for x = -104, 184, 16 do
            local inLeftPortal = side == -1 and x >= -60 and x <= -40
            local inRightPortal = side == 1 and x >= 25 and x <= 45
            if not inLeftPortal and not inRightPortal then
                part("Main_Pipe_Anchor", Vector3.new(0.85, 1.45, 1.25), Vector3.new(x, -5.2, side * 7.25), Enum.Material.Metal, metal, tunnel)
            end
        end

        -- Repeated bolted flange joints make the long pipe runs read as industrial pipework.
        for x = -80, 160, 48 do
            local flange = cylinder("Main_Pipe_Flange", 0.2, 0.93, Vector3.new(x, -5.2, pipeZ), Enum.Material.CorrodedMetal, Color3.fromRGB(72, 54, 43), tunnel)
            flange.Reflectance = 0.1
            for boltIndex = 0, 3 do
                local angle = math.rad(boltIndex * 90)
                local bolt = part(
                    "Main_Flange_Bolt",
                    Vector3.new(0.12, 0.12, 0.12),
                    Vector3.new(x, -5.2 + math.sin(angle) * 0.39, pipeZ + math.cos(angle) * 0.39),
                    Enum.Material.Metal,
                    Color3.fromRGB(130, 128, 111),
                    tunnel
                )
                bolt.Shape = Enum.PartType.Ball
            end
        end
    end

    -- Moisture lines and expansion joints break up the uninterrupted concrete wall faces.
    for x = -104, 184, 24 do
        for _, side in ipairs({-1, 1}) do
            local seam = part(
                "Wall_Expansion_Joint",
                Vector3.new(0.12, 6.6, 0.045),
                Vector3.new(x, -6.5, side * 7.47),
                Enum.Material.Slate,
                Color3.fromRGB(56, 61, 57),
                tunnel
            )
            seam.CanCollide = false

            if x % 48 == 8 then
                local dampPatch = part(
                    "Wall_Damp_Stain",
                    Vector3.new(3.5, 1.7, 0.035),
                    Vector3.new(x + 5, -8.0, side * 7.47),
                    Enum.Material.Slate,
                    Color3.fromRGB(64, 69, 53),
                    tunnel,
                    0.28
                )
                dampPatch.CanCollide = false
            end
        end
    end

    -- Cable tray under the roof, visibly attached with short hangers.
    cylinder("Main_Ceiling_Cable_Tray", 298, 0.55, Vector3.new(40, 2.2, -3.5), Enum.Material.Metal, metal, tunnel)
    for x = -102, 186, 24 do
        part("Cable_Tray_Hanger", Vector3.new(0.5, 1.5, 0.55), Vector3.new(x, 2.95, -3.5), Enum.Material.Metal, rust, tunnel)
    end

    for x = -92, 188, 30 do
        addCeilingLamp(Vector3.new(x, 3.05, 0), tunnel, "Main_Tunnel_Lamp", Color3.fromRGB(196, 211, 190), 2.25, 38)
    end

    -- Grounded floor drains and wall recesses make the long corridor readable.
    for x = -100, 180, 25 do
        local drain = part("Floor_Drain", Vector3.new(2.6, 0.08, 1.15), Vector3.new(x, -9.96, -5.4), Enum.Material.DiamondPlate, metal, tunnel)
        drain.CanCollide = false
        for line = 1, 5 do
            part("Drain_Grille_Slot", Vector3.new(0.08, 0.035, 0.85), Vector3.new(x - 1.0 + line * 0.4, -9.90, -5.4), Enum.Material.Metal, Color3.fromRGB(31, 37, 34), tunnel)
        end
    end

    -- Recessed service cabinets and wall seams are mounted flush to the concrete.
    for x = -88, 176, 44 do
        for _, side in ipairs({-1, 1}) do
            local panelZ = side * 7.42
            local cabinet = part(
                "Wall_Service_Cabinet",
                Vector3.new(3.2, 2.25, 0.22),
                Vector3.new(x, -6.0, panelZ),
                Enum.Material.DiamondPlate,
                Color3.fromRGB(56, 64, 60),
                tunnel
            )
            local stripe = part(
                "Cabinet_Warning_Stripe",
                Vector3.new(0.24, 1.45, 0.06),
                Vector3.new(x + 1.12, -6.0, side * 7.28),
                Enum.Material.Metal,
                yellow,
                tunnel
            )
            stripe.CanCollide = false

            for boltX = -1, 1, 2 do
                local bolt = part(
                    "Cabinet_Fixing_Bolt",
                    Vector3.new(0.12, 0.12, 0.08),
                    Vector3.new(x + boltX * 1.32, -5.1, side * 7.28),
                    Enum.Material.Metal,
                    concreteEdge,
                    tunnel
                )
                bolt.Shape = Enum.PartType.Ball
                bolt.CanCollide = false
            end
        end
    end

    -- Seal both ends of the main tunnel. A real barred gate can replace these
    -- caps later when the key/exit gameplay is ready.
    part("Main_Entrance_End_Wall", Vector3.new(1, 14, 18), Vector3.new(-120.25, -3.5, 0), Enum.Material.Concrete, concreteDark, tunnel)
    part("Main_End_Wall", Vector3.new(1, 14, 18), Vector3.new(200.25, -3.5, 0), Enum.Material.Concrete, concreteDark, tunnel)

    -- The entrance portal is a thicker metal arch at the start of the tunnel.
    buildArch("X", -117.5, 0, -3, 7.65, 1.6, tunnel, "Entrance_Portal", Enum.Material.Metal, rust, 0.85)
    part("Entrance_Left_Pillar", Vector3.new(1.5, 7, 1.5), Vector3.new(-117.5, -6.5, -7.8), Enum.Material.Metal, rust, tunnel)
    part("Entrance_Right_Pillar", Vector3.new(1.5, 7, 1.5), Vector3.new(-117.5, -6.5, 7.8), Enum.Material.Metal, rust, tunnel)

    -- Direction signs are fixed directly against the concrete walls.
    local sign = part("Main_Tunnel_Sign", Vector3.new(7, 3.2, 0.25), Vector3.new(-82, -3.1, -7.35), Enum.Material.Metal, concreteDark, tunnel)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "TunnelSign"
    gui.Face = Enum.NormalId.Front
    gui.PixelsPerStud = 28
    gui.Parent = sign
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "KANAL 04  /  OST"
    label.TextColor3 = Color3.fromRGB(205, 210, 194)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
end

local function buildBranchAndPumpRoom()
    local branch = makeModel("Pump_Room_Access")

    -- Branch tunnel joins the opening in the main tunnel's right-hand wall.
    buildChannelFloor("Branch", "Z", Vector3.new(35, -10.5, 60), 104, 18, 8, branch)
    part("Branch_Left_Wall", Vector3.new(1, 7, 104), Vector3.new(26, -6.5, 60), Enum.Material.Concrete, concrete, branch)
    part("Branch_Right_Wall", Vector3.new(1, 7, 104), Vector3.new(44, -6.5, 60), Enum.Material.Concrete, concrete, branch)
    buildArch("Z", 35, 60, -3, 7.5, 104, branch, "Branch", Enum.Material.Concrete, concreteDark, 1.55)
    local branchRibs = {}
    for z = 16, 104, 16 do table.insert(branchRibs, z) end
    buildArchRibs("Z", 35, 60, -3, 7.02, branchRibs, branch, "Branch")

    addFlowingWater("Branch_Channel", "Z", Vector3.new(35, -9.94, 60), 104, 8, branch, nil)

    for _, x in ipairs({27.2, 42.8}) do
        local branchPipe = cylinder("Branch_Rusted_Pipe", 96, 0.6, Vector3.new(x, -5.2, 60), Enum.Material.CorrodedMetal, Color3.fromRGB(83, 57, 43), branch, Vector3.new(0, 90, 0))
        branchPipe.Reflectance = 0.1
        for z = 18, 102, 18 do
            part("Branch_Pipe_Bracket", Vector3.new(1.5, 1.25, 0.9), Vector3.new(x, -5.2, z), Enum.Material.Metal, metal, branch)
        end
    end

    for z = 24, 84, 30 do
        addCeilingLamp(Vector3.new(35, 3.05, z), branch, "Branch_Tunnel_Lamp", Color3.fromRGB(192, 207, 188), 2.0, 34)
    end

    -- A broad pump chamber sits at the end of the side tunnel.
    local room = makeModel("Old_Pump_Room")
    buildChannelFloor("Pump_Room", "Z", Vector3.new(35, -10.5, 134), 48, 50, 8, room)
    part("Pump_Room_Ceiling", Vector3.new(50, 1.5, 48), Vector3.new(35, 4.15, 134), Enum.Material.Concrete, concreteDark, room)
    part("Pump_Room_Left_Wall", Vector3.new(1, 14, 48), Vector3.new(10, -3.5, 134), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Right_Wall", Vector3.new(1, 14, 48), Vector3.new(60, -3.5, 134), Enum.Material.Concrete, concrete, room)
    -- Rear wall split around a doorway for the extended east drain passage.
    part("Pump_Room_Back_Wall_Left", Vector3.new(16, 14, 1), Vector3.new(18, -3.5, 158), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Back_Wall_Right", Vector3.new(16, 14, 1), Vector3.new(52, -3.5, 158), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Back_Header", Vector3.new(14, 2, 1), Vector3.new(35, 2.5, 158), Enum.Material.Concrete, concreteDark, room)

    -- Front wall is split around the connected branch entrance at z=110.
    part("Pump_Entry_Left_Wall", Vector3.new(16, 14, 1), Vector3.new(18, -3.5, 110), Enum.Material.Concrete, concrete, room)
    part("Pump_Entry_Right_Wall", Vector3.new(16, 14, 1), Vector3.new(52, -3.5, 110), Enum.Material.Concrete, concrete, room)
    part("Pump_Entry_Header", Vector3.new(18, 2, 1), Vector3.new(35, 2.5, 110), Enum.Material.Concrete, concreteDark, room)

    addFlowingWater("Pump_Room_Channel", "Z", Vector3.new(35, -9.94, 134), 48, 8, room, nil)
    part("Pump_Base", Vector3.new(13, 1.2, 10), Vector3.new(17.5, -9.35, 142), Enum.Material.Metal, rust, room)
    local filterTank = cylinder("Pump_Filter_Tank", 10, 7.5, Vector3.new(17.5, -4.1, 142), Enum.Material.CorrodedMetal, Color3.fromRGB(68, 75, 68), room, Vector3.new(0, 0, 90))
    filterTank.Reflectance = 0.12
    part("Pump_Tank_Cap", Vector3.new(7.8, 0.45, 7.8), Vector3.new(17.5, 0.95, 142), Enum.Material.CorrodedMetal, rust, room)

    -- Tank collars, inspection plate and rivets.
    for _, y in ipairs({-7.2, -1.2}) do
        local collar = cylinder("Pump_Tank_Collar", 0.28, 7.9, Vector3.new(17.5, y, 142), Enum.Material.Metal, Color3.fromRGB(75, 81, 73), room, Vector3.new(0, 0, 90))
        collar.Reflectance = 0.12
    end
    part("Pump_Tank_Inspection_Plate", Vector3.new(0.3, 2.5, 2.2), Vector3.new(21.5, -4.1, 142), Enum.Material.DiamondPlate, metal, room)

    -- Pump motor and coupling sit on a bolted steel plinth beside the filter tank.
    part("Pump_Motor_Platform", Vector3.new(8.5, 0.75, 5.5), Vector3.new(47.2, -9.35, 142), Enum.Material.Metal, rust, room)
    part("Pump_Motor_Housing", Vector3.new(5.5, 3.0, 3.8), Vector3.new(47.2, -7.45, 142), Enum.Material.CorrodedMetal, Color3.fromRGB(58, 67, 61), room)
    cylinder("Pump_Motor_Fan_End", 0.35, 3.2, Vector3.new(50.1, -7.45, 142), Enum.Material.Metal, metal, room)
    cylinder("Pump_Motor_Coupling", 2.4, 1.3, Vector3.new(42.9, -7.1, 142), Enum.Material.Metal, rust, room)
    for boltX = 43, 50, 2 do
        local motorBolt = part("Pump_Motor_Fixing_Bolt", Vector3.new(0.16, 0.16, 0.16), Vector3.new(boltX, -8.9, 144.2), Enum.Material.Metal, Color3.fromRGB(143, 139, 121), room)
        motorBolt.Shape = Enum.PartType.Ball
    end

    cylinder("Pump_Outlet_Pipe", 14, 0.8, Vector3.new(52, -2.5, 142), Enum.Material.CorrodedMetal, rust, room)
    cylinder("Pump_Inlet_Pipe", 30, 0.72, Vector3.new(33, -2.5, 142), Enum.Material.Metal, metal, room)

    -- Valve wheel and control panel are mounted close to the rear-right wall.
    cylinder("Valve_Hub", 1.2, 2.6, Vector3.new(57.9, -4.1, 147), Enum.Material.Metal, rust, room, Vector3.new(0, 90, 0))
    part("Valve_Wheel_Vertical", Vector3.new(0.35, 4.2, 0.35), Vector3.new(57.2, -4.1, 147), Enum.Material.Metal, yellow, room)
    part("Valve_Wheel_Horizontal", Vector3.new(0.35, 0.35, 4.2), Vector3.new(57.2, -4.1, 147), Enum.Material.Metal, yellow, room)

    -- A small pressure gauge and wall-mounted control cabinet give the pump a readable purpose.
    part("Pump_Control_Cabinet", Vector3.new(0.55, 4.2, 5.5), Vector3.new(59.25, -5.2, 127), Enum.Material.DiamondPlate, Color3.fromRGB(48, 58, 54), room)
    part("Pump_Cabinet_Display", Vector3.new(0.12, 1.1, 2.2), Vector3.new(58.92, -4.1, 127), Enum.Material.Neon, Color3.fromRGB(91, 140, 111), room).CanCollide = false
    for index = 1, 3 do
        local indicator = part("Pump_Status_Indicator", Vector3.new(0.13, 0.2, 0.2), Vector3.new(58.9, -5.0, 125.7 + index * 0.65), Enum.Material.Neon, index == 1 and Color3.fromRGB(178, 58, 43) or Color3.fromRGB(130, 151, 104), room)
        indicator.CanCollide = false
    end

    local emergency = part("Pump_Red_Emergency_Lamp", Vector3.new(3.2, 0.25, 1.0), Vector3.new(35, 3.25, 128), Enum.Material.Neon, Color3.fromRGB(185, 56, 43), room)
    emergency.CanCollide = false
    local red = Instance.new("PointLight")
    red.Color = Color3.fromRGB(255, 77, 59)
    red.Brightness = 1.1
    red.Range = 24
    red.Parent = emergency

    addCeilingLamp(Vector3.new(20, 3.35, 132), room, "Pump_Room_Lamp", Color3.fromRGB(185, 203, 187), 2.1, 34)
    addCeilingLamp(Vector3.new(49, 3.35, 145), room, "Pump_Room_Lamp", Color3.fromRGB(185, 203, 187), 1.8, 30)
end

local function buildSecurityGate()
    local gate = makeModel("Restricted_Tunnel_Gate")
    local x = 181
    part("Gate_Post_Left", Vector3.new(1, 12, 1), Vector3.new(x, -4.5, -7.5), Enum.Material.Metal, rust, gate)
    part("Gate_Post_Right", Vector3.new(1, 12, 1), Vector3.new(x, -4.5, 7.5), Enum.Material.Metal, rust, gate)
    part("Gate_Header", Vector3.new(1, 1, 16), Vector3.new(x, 1, 0), Enum.Material.Metal, rust, gate)
    for z = -6.5, 6.5, 1.45 do
        part("Gate_Vertical_Bar", Vector3.new(0.45, 10.5, 0.45), Vector3.new(x, -4.6, z), Enum.Material.Metal, metal, gate)
    end
    part("Gate_Warning_Plate", Vector3.new(0.35, 2.6, 8), Vector3.new(x - 0.3, -2.3, 0), Enum.Material.Metal, Color3.fromRGB(82, 47, 38), gate)

    local alarm = part("Gate_Alarm_Light", Vector3.new(0.55, 0.55, 0.55), Vector3.new(x - 0.8, 0.1, -6.4), Enum.Material.Neon, Color3.fromRGB(200, 48, 39), gate)
    alarm.CanCollide = false
    local red = Instance.new("PointLight")
    red.Color = Color3.fromRGB(255, 57, 45)
    red.Brightness = 0.9
    red.Range = 15
    red.Parent = alarm
end

local function buildWestServiceRoute()
    local route = makeModel("West_Service_Route")

    -- From the left-hand junction, the passage runs north and makes a clear 90-degree turn west.
    buildChannelFloor("West_Leg", "Z", Vector3.new(-50, -10.5, -62), 108, 18, 8, route)
    -- Stop the vertical side walls before the elbow so they do not block the 90-degree turn.
    part("West_Leg_Left_Wall", Vector3.new(1, 7, 90), Vector3.new(-59, -6.5, -53), Enum.Material.Concrete, concrete, route)
    part("West_Leg_Right_Wall", Vector3.new(1, 7, 90), Vector3.new(-41, -6.5, -53), Enum.Material.Concrete, concrete, route)
    buildArch("Z", -50, -62, -3, 7.5, 108, route, "West_Leg", Enum.Material.Concrete, concreteDark, 1.55)
    local ribs = {}
    for z = -108, -16, 16 do
        -- Leave the final elbow bay free of a cross-frame.
        if z > -100 then table.insert(ribs, z) end
    end
    buildArchRibs("Z", -50, -62, -3, 7.02, ribs, route, "West_Leg")
    addFlowingWater("West_Leg_Channel", "Z", Vector3.new(-50, -9.94, -62), 108, 8, route, nil, {-98, -8})
    for z = -96, -24, 30 do
        addCeilingLamp(Vector3.new(-50, 3.05, z), route, "West_Leg_Lamp", Color3.fromRGB(193, 208, 188), 1.9, 32)
    end
    cylinder("West_Leg_Service_Pipe", 90, 0.62, Vector3.new(-58, -5.2, -53), Enum.Material.CorrodedMetal, rust, route, Vector3.new(0, 90, 0))
    cylinder("West_Leg_Service_Pipe", 90, 0.62, Vector3.new(-42, -5.2, -53), Enum.Material.CorrodedMetal, rust, route, Vector3.new(0, 90, 0))

    -- The bend is a full-width elbow: this tunnel heads west after the northbound run.
    buildChannelFloor("West_Turn", "X", Vector3.new(-100, -10.5, -108), 120, 18, 8, route)
    -- Keep the north wall open across x=-60..-40 for the incoming west leg.
    part("West_Turn_North_Wall_Left", Vector3.new(100, 7, 1), Vector3.new(-110, -6.5, -99), Enum.Material.Concrete, concrete, route)
    part("West_Turn_South_Wall", Vector3.new(120, 7, 1), Vector3.new(-100, -6.5, -117), Enum.Material.Concrete, concrete, route)
    -- The outer east edge of the elbow joins the short side wall of the approach.
    part("West_Turn_East_Side_Wall", Vector3.new(1, 7, 19), Vector3.new(-40, -6.5, -107.5), Enum.Material.Concrete, concrete, route)
    buildArch("X", -100, -108, -3, 7.5, 120, route, "West_Turn", Enum.Material.Concrete, concreteDark, 1.55)
    local turnRibs = {}
    for x = -152, -48, 16 do
        if x < -64 or x > -40 then table.insert(turnRibs, x) end
    end
    buildArchRibs("X", -100, -108, -3, 7.02, turnRibs, route, "West_Turn")
    addFlowingWater("West_Turn_Channel", "X", Vector3.new(-100, -9.94, -108), 120, 8, route, {{-50, 18}})
    for x = -144, -64, 30 do
        addCeilingLamp(Vector3.new(x, 3.05, -108), route, "West_Turn_Lamp", Color3.fromRGB(190, 205, 186), 1.85, 30)
    end

    -- A remote valve chamber closes the long west route.
    local chamber = makeModel("West_Valve_Chamber", route)
    buildChannelFloor("West_Chamber", "X", Vector3.new(-185, -10.5, -108), 50, 46, 8, chamber)
    part("West_Chamber_Ceiling", Vector3.new(50, 1.5, 46), Vector3.new(-185, 4.0, -108), Enum.Material.Concrete, concreteDark, chamber)
    part("West_Chamber_West_Wall", Vector3.new(1, 14, 46), Vector3.new(-210, -3.5, -108), Enum.Material.Concrete, concrete, chamber)
    part("West_Chamber_North_Wall", Vector3.new(50, 14, 1), Vector3.new(-185, -3.5, -131), Enum.Material.Concrete, concrete, chamber)
    part("West_Chamber_South_Wall", Vector3.new(50, 14, 1), Vector3.new(-185, -3.5, -85), Enum.Material.Concrete, concrete, chamber)
    part("West_Chamber_Entry_Wall_North", Vector3.new(1, 14, 14), Vector3.new(-160, -3.5, -124), Enum.Material.Concrete, concrete, chamber)
    part("West_Chamber_Entry_Wall_South", Vector3.new(1, 14, 14), Vector3.new(-160, -3.5, -92), Enum.Material.Concrete, concrete, chamber)
    part("West_Chamber_Entry_Header", Vector3.new(1, 2, 18), Vector3.new(-160, 2.5, -108), Enum.Material.Concrete, concreteDark, chamber)

    addFlowingWater("West_Chamber_Runoff", "X", Vector3.new(-185, -9.94, -108), 50, 8, chamber, nil)
    local wheelHub = cylinder("West_Main_Valve_Hub", 1.1, 3.1, Vector3.new(-204, -3.7, -108), Enum.Material.Metal, rust, chamber, Vector3.new(0, 90, 0))
    part("West_Valve_Wheel_Vertical", Vector3.new(0.35, 5, 0.35), Vector3.new(-204.8, -3.7, -108), Enum.Material.Metal, yellow, chamber)
    part("West_Valve_Wheel_Horizontal", Vector3.new(0.35, 0.35, 5), Vector3.new(-204.8, -3.7, -108), Enum.Material.Metal, yellow, chamber)
    for _, x in ipairs({-198, -178}) do
        addCeilingLamp(Vector3.new(x, 3.15, -108), chamber, "West_Chamber_Lamp", Color3.fromRGB(187, 201, 183), 1.7, 28)
    end
end

local function buildEastDrainExtension()
    local route = makeModel("East_Drain_Extension")

    -- Continue straight out of the pump room, then turn east at the end.
    buildChannelFloor("East_Leg", "Z", Vector3.new(35, -10.5, 210), 108, 18, 8, route)
    -- End the vertical side walls at the elbow entrance; the turn itself stays open.
    part("East_Leg_Left_Wall", Vector3.new(1, 7, 97), Vector3.new(26, -6.5, 204.5), Enum.Material.Concrete, concrete, route)
    part("East_Leg_Right_Wall", Vector3.new(1, 7, 97), Vector3.new(44, -6.5, 204.5), Enum.Material.Concrete, concrete, route)
    buildArch("Z", 35, 210, -3, 7.5, 108, route, "East_Leg", Enum.Material.Concrete, concreteDark, 1.55)
    local ribs = {}
    for z = 168, 252, 16 do
        if z < 248 then table.insert(ribs, z) end
    end
    buildArchRibs("Z", 35, 210, -3, 7.02, ribs, route, "East_Leg")
    addFlowingWater("East_Leg_Channel", "Z", Vector3.new(35, -9.94, 210), 106, 8, route, nil, {157, 253})
    for z = 180, 240, 30 do
        addCeilingLamp(Vector3.new(35, 3.05, z), route, "East_Leg_Lamp", Color3.fromRGB(193, 207, 188), 1.9, 32)
    end

    -- Extend the elbow west far enough to overlap the full incoming side tunnel.
    buildChannelFloor("East_Turn", "X", Vector3.new(85.5, -10.5, 262), 119, 18, 8, route)
    -- Leave the south-side wall open across x=26..44: this is the actual doorway
    -- from the long east leg, not a wall directly in front of the player.
    part("East_Turn_North_Wall", Vector3.new(100, 7, 1), Vector3.new(95, -6.5, 253), Enum.Material.Concrete, concrete, route)
    -- Keep the south entry open across x=26..44 so the incoming drain can turn east.
    part("East_Turn_South_Wall_Right", Vector3.new(101, 7, 1), Vector3.new(94.5, -6.5, 271), Enum.Material.Concrete, concrete, route)
    -- Continue the outside wall around the corner so the player cannot step off into open space.
    part("East_Turn_West_Side_Wall", Vector3.new(1, 7, 18), Vector3.new(26, -6.5, 262), Enum.Material.Concrete, concrete, route)
    buildArch("X", 85.5, 262, -3, 7.5, 119, route, "East_Turn", Enum.Material.Concrete, concreteDark, 1.55)
    local turnRibs = {}
    for x = 32, 144, 16 do
        if x > 48 then table.insert(turnRibs, x) end
    end
    buildArchRibs("X", 85.5, 262, -3, 7.02, turnRibs, route, "East_Turn")
    addFlowingWater("East_Turn_Channel", "X", Vector3.new(85.5, -9.94, 262), 119, 8, route, {{35, 18}})
    for x = 50, 130, 30 do
        addCeilingLamp(Vector3.new(x, 3.05, 262), route, "East_Turn_Lamp", Color3.fromRGB(190, 205, 186), 1.85, 30)
    end

    -- A final sluice chamber, with a doorway at its west side.
    local chamber = makeModel("East_Sluice_Chamber", route)
    buildChannelFloor("Sluice", "X", Vector3.new(160, -10.5, 262), 50, 44, 8, chamber)
    part("Sluice_Ceiling", Vector3.new(50, 1.5, 44), Vector3.new(160, 4.0, 262), Enum.Material.Concrete, concreteDark, chamber)
    part("Sluice_East_Wall", Vector3.new(1, 14, 44), Vector3.new(185, -3.5, 262), Enum.Material.Concrete, concrete, chamber)
    part("Sluice_North_Wall", Vector3.new(50, 14, 1), Vector3.new(160, -3.5, 240), Enum.Material.Concrete, concrete, chamber)
    part("Sluice_South_Wall", Vector3.new(50, 14, 1), Vector3.new(160, -3.5, 284), Enum.Material.Concrete, concrete, chamber)
    part("Sluice_Entry_North", Vector3.new(1, 14, 13), Vector3.new(135, -3.5, 246.5), Enum.Material.Concrete, concrete, chamber)
    part("Sluice_Entry_South", Vector3.new(1, 14, 13), Vector3.new(135, -3.5, 277.5), Enum.Material.Concrete, concrete, chamber)
    part("Sluice_Entry_Header", Vector3.new(1, 2, 18), Vector3.new(135, 2.5, 262), Enum.Material.Concrete, concreteDark, chamber)

    addFlowingWater("Sluice_Runoff", "X", Vector3.new(160, -9.94, 262), 50, 8, chamber, nil)
    local tank = cylinder("Sluice_Filter_Tank", 11, 8, Vector3.new(174, -4.1, 270), Enum.Material.Metal, Color3.fromRGB(67, 76, 69), chamber, Vector3.new(0, 0, 90))
    tank.Material = Enum.Material.CorrodedMetal
    part("Sluice_Tank_Cap", Vector3.new(8.5, 0.45, 8.5), Vector3.new(174, 1.05, 270), Enum.Material.Metal, rust, chamber)
    local emergency = part("Sluice_Red_Lamp", Vector3.new(3, 0.25, 1), Vector3.new(160, 3.2, 247), Enum.Material.Neon, Color3.fromRGB(176, 50, 39), chamber)
    emergency.CanCollide = false
    local warning = Instance.new("PointLight")
    warning.Color = Color3.fromRGB(255, 65, 49)
    warning.Brightness = 1.0
    warning.Range = 22
    warning.Parent = emergency
    for _, x in ipairs({145, 175}) do
        addCeilingLamp(Vector3.new(x, 3.15, 262), chamber, "Sluice_Lamp", Color3.fromRGB(187, 201, 183), 1.7, 28)
    end
end

local function buildEntrance()
    local entrance = makeModel("Sewer_Entrance")
    part("Entry_Grated_Platform", Vector3.new(12, 0.35, 11), Vector3.new(-108, -9.78, 0), Enum.Material.DiamondPlate, metal, entrance)
    for x = -113, -103, 1.5 do
        part("Entry_Grate_Slot", Vector3.new(0.12, 0.12, 10.2), Vector3.new(x, -9.57, 0), Enum.Material.Metal, concreteEdge, entrance)
    end
    for _, z in ipairs({-5.4, 5.4}) do
        part("Entry_Safety_Rail", Vector3.new(12, 1.0, 0.18), Vector3.new(-108, -8.95, z), Enum.Material.Metal, rust, entrance)
        for _, x in ipairs({-113, -108, -103}) do
            part("Entry_Rail_Post", Vector3.new(0.28, 1.5, 0.28), Vector3.new(x, -9.2, z), Enum.Material.Metal, metal, entrance)
        end
    end
    part("Entry_Sign_Back", Vector3.new(8, 3.2, 0.3), Vector3.new(-106, -2.6, -7.35), Enum.Material.Metal, concreteDark, entrance)
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.PixelsPerStud = 26
    signGui.Parent = entrance.Entry_Sign_Back
    local signText = Instance.new("TextLabel")
    signText.Size = UDim2.fromScale(1, 1)
    signText.BackgroundTransparency = 1
    signText.Text = "ZUGANG 04"
    signText.TextScaled = true
    signText.Font = Enum.Font.GothamBold
    signText.TextColor3 = Color3.fromRGB(210, 196, 157)
    signText.Parent = signGui
end

-- Flashlight inventory was intentionally removed: the sewer lighting is bright enough.

configureLighting()
buildMainTunnel()
buildWestServiceRoute()
buildBranchAndPumpRoom()
buildEastDrainExtension()
buildSecurityGate()
buildEntrance()

-- A solid but invisible spawn pad sits flush with the dry right-hand walkway.
-- The earlier script removed the template spawn and failed before creating this one.
local spawn = Instance.new("SpawnLocation")
spawn.Name = "SewerSpawn"
spawn.Size = Vector3.new(8, 1, 4)
spawn.Position = Vector3.new(-88, 0, 6.5)
spawn.CFrame = CFrame.new(-88, 0, 6.5)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Transparency = 1
spawn.CanCollide = true
spawn.CanTouch = true
spawn.CanQuery = true
spawn.Parent = world

local function configureSewerPlayer(player, character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    end

    -- Move an already-spawned character as well as future characters onto
    -- the confirmed dry walkway. The root stands about 3.2 studs above the pad.
    character:PivotTo(spawn.CFrame * CFrame.new(0, 3.2, 0))
end

local function bindSewerPlayer(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.15)
        configureSewerPlayer(player, character)
    end)

    if player.Character then
        task.spawn(configureSewerPlayer, player, player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    bindSewerPlayer(player)
end
Players.PlayerAdded:Connect(bindSewerPlayer)

-- SpawnLocation adds a default star decal. Delete all appearance children so it stays invisible.
for _, child in ipairs(spawn:GetDescendants()) do
    if child:IsA("Decal") or child:IsA("Texture") then
        child:Destroy()
    end
end
for _, child in ipairs(spawn:GetChildren()) do
    if child:IsA("Decal") or child:IsA("Texture") then
        child:Destroy()
    end
end

-- The old invalid ID was reported by Studio as a type mismatch. Remove any leftover
-- instance that still requests it, without affecting unrelated assets.
for _, instance in ipairs(game:GetDescendants()) do
    if instance:IsA("Sound") then
        if string.find(instance.SoundId, "203785492", 1, true) then
            instance.SoundId = ""
        end
    elseif instance:IsA("Decal") or instance:IsA("Texture") then
        if string.find(instance.Texture, "203785492", 1, true) then
            instance.Texture = ""
        end
    elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
        if string.find(instance.Image, "203785492", 1, true) then
            instance.Image = ""
        end
    elseif instance:IsA("MeshPart") then
        if string.find(instance.MeshId, "203785492", 1, true) then
            instance:Destroy()
        end
    elseif instance:IsA("SpecialMesh") then
        if string.find(instance.MeshId, "203785492", 1, true) then
            instance.MeshId = ""
        end
    elseif instance:IsA("Animation") then
        if string.find(instance.AnimationId, "203785492", 1, true) then
            instance.AnimationId = ""
        end
    end
end

print("[Horror Game] Sewer V10 loaded: spawn fixed on dry walkway, all water channels generated, open 90-degree turns and improved dirty-water surface. No flashlight.")

--[[
    HORROR GAME - SEWER LEVEL V2
    A fully enclosed, walkable sewer with an arched main tunnel, branch tunnel,
    pump room, service details, ceiling lights and an inventory flashlight Tool.
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local TweenService = game:GetService("TweenService")

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
local function addFlowingWater(name, axis, center, length, width, parent, flowDirection)
    flowDirection = flowDirection or 1
    local size = axis == "X"
        and Vector3.new(length, 0.11, width)
        or Vector3.new(width, 0.11, length)

    local water = part(
        name .. "_Dirty_Water",
        size,
        center,
        Enum.Material.Water,
        Color3.fromRGB(65, 69, 48),
        parent,
        0.12
    )
    water.CanCollide = false
    water.CanTouch = false

    local ambience = Instance.new("Sound")
    ambience.Name = name .. "_Flow_Ambience"
    ambience.SoundId = "rbxassetid://6564308795"
    ambience.Volume = 0.12
    ambience.PlaybackSpeed = 0.78
    ambience.Looped = true
    ambience.RollOffMode = Enum.RollOffMode.InverseTapered
    ambience.RollOffMinDistance = 10
    ambience.RollOffMaxDistance = 110
    ambience.Parent = water
    ambience:Play()

    local streakCount = math.max(5, math.floor(length / 38))
    local stride = 27
    for index = 1, streakCount do
        local fraction = (index - 1) / streakCount
        local along = -length * 0.5 + fraction * length
        local across = (((index * 7) % 13) / 13 - 0.5) * width * 0.72
        local streakSize
        local startPosition
        local function positionAt(offset)
            if axis == "X" then
                return Vector3.new(center.X + offset, center.Y + WORLD_Y_OFFSET + 0.085, center.Z + across)
            end
            return Vector3.new(center.X + across, center.Y + WORLD_Y_OFFSET + 0.085, center.Z + offset)
        end

        if axis == "X" then
            streakSize = Vector3.new(6 + (index % 3) * 2, 0.025, 0.11 + (index % 2) * 0.07)
        else
            streakSize = Vector3.new(0.11 + (index % 2) * 0.07, 0.025, 6 + (index % 3) * 2)
        end

        startPosition = positionAt(along)
        local streak = part(
            name .. "_Moving_Current",
            streakSize,
            Vector3.new(startPosition.X, startPosition.Y - WORLD_Y_OFFSET, startPosition.Z),
            Enum.Material.SmoothPlastic,
            Color3.fromRGB(126, 129, 99),
            parent,
            0.42
        )
        streak.CanCollide = false
        streak.CanTouch = false
        streak.CanQuery = false

        task.spawn(function()
            local current = along
            while streak.Parent do
                local nextOffset = current + stride * flowDirection
                if nextOffset > length * 0.5 then
                    nextOffset = -length * 0.5
                elseif nextOffset < -length * 0.5 then
                    nextOffset = length * 0.5
                end
                local target = positionAt(nextOffset)
                local tween = TweenService:Create(
                    streak,
                    TweenInfo.new(5.5 + (index % 4) * 0.8, Enum.EasingStyle.Linear),
                    {Position = target}
                )
                tween:Play()
                tween.Completed:Wait()
                current = nextOffset
            end
        end)
    end

    return water
end

local function configureLighting()
    Lighting.ClockTime = 0.35
    Lighting.Brightness = 2.6
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.fromRGB(101, 105, 100)
    Lighting.OutdoorAmbient = Color3.fromRGB(76, 82, 77)
    Lighting.FogColor = Color3.fromRGB(68, 76, 72)
    Lighting.FogStart = 135
    Lighting.FogEnd = 480
    Lighting.EnvironmentDiffuseScale = 0.5
    Lighting.EnvironmentSpecularScale = 0.32

    for _, name in ipairs({"SewerAtmosphere", "SewerColor", "SewerBloom"}) do
        local old = Lighting:FindFirstChild(name)
        if old then old:Destroy() end
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "SewerAtmosphere"
    atmosphere.Density = 0.11
    atmosphere.Offset = 0.04
    atmosphere.Color = Color3.fromRGB(164, 170, 163)
    atmosphere.Decay = Color3.fromRGB(65, 72, 68)
    atmosphere.Glare = 0.01
    atmosphere.Haze = 0.35
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
    local light = Instance.new("PointLight")
    light.Name = name .. "_Light"
    light.Color = color
    light.Brightness = brightness or 2
    light.Range = range or 34
    light.Shadows = true
    light.Parent = lens
    return fixture
end

local function buildMainTunnel()
    local tunnel = makeModel("Main_Sewer_Tunnel")

    -- Flat, continuous walking floor and tall side walls.
    part("Main_Walking_Floor", Vector3.new(320, 1, 18), Vector3.new(40, -10.5, 0), Enum.Material.Concrete, concrete, tunnel)

    -- Two gaps in the long side walls create real junctions for the branch tunnels.
    part("Main_Left_Side_Wall_A", Vector3.new(62, 7, 1), Vector3.new(-89, -6.5, -8), Enum.Material.Concrete, concrete, tunnel)
    part("Main_Left_Side_Wall_B", Vector3.new(242, 7, 1), Vector3.new(79, -6.5, -8), Enum.Material.Concrete, concrete, tunnel)
    part("Main_Right_Wall_A", Vector3.new(146, 7, 1), Vector3.new(-47, -6.5, 8), Enum.Material.Concrete, concrete, tunnel)
    part("Main_Right_Wall_B", Vector3.new(156, 7, 1), Vector3.new(122, -6.5, 8), Enum.Material.Concrete, concrete, tunnel)

    -- Extended arched roof and repeating steel support frames.
    buildArch("X", 40, 0, -3, 7.5, 320, tunnel, "Main", Enum.Material.Concrete, concreteDark, 1.55)
    local ribPositions = {}
    for x = -112, 192, 16 do table.insert(ribPositions, x) end
    buildArchRibs("X", 0, 0, -3, 7.02, ribPositions, tunnel, "Main")

    -- A visible shallow water channel runs through the centre of the floor.
    addFlowingWater("Main_Channel", "X", Vector3.new(40, -9.94, 0), 312, 4.8, tunnel, 1)
    part("Main_Channel_Curb_Left", Vector3.new(312, 0.42, 0.35), Vector3.new(40, -9.76, -2.6), Enum.Material.Concrete, concreteDark, tunnel)
    part("Main_Channel_Curb_Right", Vector3.new(312, 0.42, 0.35), Vector3.new(40, -9.76, 2.6), Enum.Material.Concrete, concreteDark, tunnel)

    -- Pipes are fixed to the walls with brackets at regular intervals.
    for _, side in ipairs({-1, 1}) do
        local pipeZ = side * 6.75
        cylinder("Main_Rusted_Service_Pipe", 306, 0.85, Vector3.new(40, -5.2, pipeZ), Enum.Material.Metal, rust, tunnel)
        cylinder("Main_Upper_Service_Pipe", 306, 0.38, Vector3.new(40, -3.6, side * 7.05), Enum.Material.Metal, metal, tunnel)
        for x = -104, 184, 16 do
            part("Main_Pipe_Anchor", Vector3.new(0.85, 1.45, 1.25), Vector3.new(x, -5.2, side * 7.25), Enum.Material.Metal, metal, tunnel)
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
    part("Branch_Walking_Floor", Vector3.new(18, 1, 104), Vector3.new(35, -10.5, 60), Enum.Material.Concrete, concrete, branch)
    part("Branch_Left_Wall", Vector3.new(1, 7, 104), Vector3.new(26, -6.5, 60), Enum.Material.Concrete, concrete, branch)
    part("Branch_Right_Wall", Vector3.new(1, 7, 104), Vector3.new(44, -6.5, 60), Enum.Material.Concrete, concrete, branch)
    buildArch("Z", 35, 60, -3, 7.5, 104, branch, "Branch", Enum.Material.Concrete, concreteDark, 1.55)
    local branchRibs = {}
    for z = 16, 104, 16 do table.insert(branchRibs, z) end
    buildArchRibs("Z", 35, 60, -3, 7.02, branchRibs, branch, "Branch")

    addFlowingWater("Branch_Channel", "Z", Vector3.new(35, -9.94, 60), 98, 4.5, branch, 1)
    for _, x in ipairs({33.2, 36.8}) do
        part("Branch_Channel_Curb", Vector3.new(0.35, 0.42, 98), Vector3.new(x, -9.76, 60), Enum.Material.Concrete, concreteDark, branch)
    end

    for _, x in ipairs({27.2, 42.8}) do
        cylinder("Branch_Rusted_Pipe", 96, 0.75, Vector3.new(x, -5.2, 60), Enum.Material.Metal, rust, branch, Vector3.new(0, 90, 0))
        for z = 18, 102, 18 do
            part("Branch_Pipe_Bracket", Vector3.new(1.5, 1.25, 0.9), Vector3.new(x, -5.2, z), Enum.Material.Metal, metal, branch)
        end
    end

    for z = 24, 84, 30 do
        addCeilingLamp(Vector3.new(35, 3.05, z), branch, "Branch_Tunnel_Lamp", Color3.fromRGB(192, 207, 188), 2.0, 34)
    end

    -- A broad pump chamber sits at the end of the side tunnel.
    local room = makeModel("Old_Pump_Room")
    part("Pump_Room_Floor", Vector3.new(50, 1, 48), Vector3.new(35, -10.5, 134), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Ceiling", Vector3.new(50, 1.5, 48), Vector3.new(35, 4.15, 134), Enum.Material.Concrete, concreteDark, room)
    part("Pump_Room_Left_Wall", Vector3.new(1, 14, 48), Vector3.new(10, -3.5, 134), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Right_Wall", Vector3.new(1, 14, 48), Vector3.new(60, -3.5, 134), Enum.Material.Concrete, concrete, room)
    -- Rear wall split around a doorway for the extended east drain passage.
    part("Pump_Room_Back_Wall_Left", Vector3.new(18, 14, 1), Vector3.new(19, -3.5, 158), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Back_Wall_Right", Vector3.new(18, 14, 1), Vector3.new(51, -3.5, 158), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Back_Header", Vector3.new(14, 2, 1), Vector3.new(35, 2.5, 158), Enum.Material.Concrete, concreteDark, room)

    -- Front wall is split around the connected branch entrance at z=110.
    part("Pump_Entry_Left_Wall", Vector3.new(16, 14, 1), Vector3.new(18, -3.5, 110), Enum.Material.Concrete, concrete, room)
    part("Pump_Entry_Right_Wall", Vector3.new(16, 14, 1), Vector3.new(52, -3.5, 110), Enum.Material.Concrete, concrete, room)
    part("Pump_Entry_Header", Vector3.new(18, 2, 1), Vector3.new(35, 2.5, 110), Enum.Material.Concrete, concreteDark, room)

    addFlowingWater("Pump_Room_Channel", "X", Vector3.new(35, -9.94, 133), 42, 5, room, 1)
    part("Pump_Base", Vector3.new(13, 1.2, 10), Vector3.new(35, -9.35, 142), Enum.Material.Metal, rust, room)
    cylinder("Pump_Filter_Tank", 10, 7.5, Vector3.new(35, -4.1, 142), Enum.Material.Metal, Color3.fromRGB(67, 76, 69), room, Vector3.new(0, 0, 90))
    part("Pump_Tank_Cap", Vector3.new(7.8, 0.45, 7.8), Vector3.new(35, 0.95, 142), Enum.Material.Metal, rust, room)
    cylinder("Pump_Outlet_Pipe", 13, 1.0, Vector3.new(44, -2.5, 142), Enum.Material.Metal, rust, room)
    cylinder("Pump_Inlet_Pipe", 15, 0.9, Vector3.new(35, -2.5, 150), Enum.Material.Metal, metal, room, Vector3.new(0, 90, 0))

    -- Valve wheel and control panel are mounted close to the rear-right wall.
    cylinder("Valve_Hub", 1.2, 2.6, Vector3.new(57.9, -4.1, 147), Enum.Material.Metal, rust, room, Vector3.new(0, 90, 0))
    part("Valve_Wheel_Vertical", Vector3.new(0.35, 4.2, 0.35), Vector3.new(57.2, -4.1, 147), Enum.Material.Metal, yellow, room)
    part("Valve_Wheel_Horizontal", Vector3.new(0.35, 0.35, 4.2), Vector3.new(57.2, -4.1, 147), Enum.Material.Metal, yellow, room)

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
    part("West_Leg_Floor", Vector3.new(18, 1, 108), Vector3.new(-50, -10.5, -62), Enum.Material.Concrete, concrete, route)
    part("West_Leg_Left_Wall", Vector3.new(1, 7, 108), Vector3.new(-59, -6.5, -62), Enum.Material.Concrete, concrete, route)
    part("West_Leg_Right_Wall", Vector3.new(1, 7, 108), Vector3.new(-41, -6.5, -62), Enum.Material.Concrete, concrete, route)
    buildArch("Z", -50, -62, -3, 7.5, 108, route, "West_Leg", Enum.Material.Concrete, concreteDark, 1.55)
    local ribs = {}
    for z = -108, -16, 16 do table.insert(ribs, z) end
    buildArchRibs("Z", -50, -62, -3, 7.02, ribs, route, "West_Leg")
    addFlowingWater("West_Leg_Channel", "Z", Vector3.new(-50, -9.94, -62), 102, 4.4, route, 1)
    for z = -96, -24, 30 do
        addCeilingLamp(Vector3.new(-50, 3.05, z), route, "West_Leg_Lamp", Color3.fromRGB(193, 208, 188), 1.9, 32)
    end
    cylinder("West_Leg_Service_Pipe", 98, 0.78, Vector3.new(-58, -5.2, -62), Enum.Material.Metal, rust, route, Vector3.new(0, 90, 0))
    cylinder("West_Leg_Service_Pipe", 98, 0.78, Vector3.new(-42, -5.2, -62), Enum.Material.Metal, rust, route, Vector3.new(0, 90, 0))

    -- The bend is a full-width elbow: this tunnel heads west after the northbound run.
    part("West_Turn_Floor", Vector3.new(110, 1, 18), Vector3.new(-105, -10.5, -108), Enum.Material.Concrete, concrete, route)
    part("West_Turn_North_Wall", Vector3.new(110, 7, 1), Vector3.new(-105, -6.5, -99), Enum.Material.Concrete, concrete, route)
    part("West_Turn_South_Wall", Vector3.new(110, 7, 1), Vector3.new(-105, -6.5, -117), Enum.Material.Concrete, concrete, route)
    buildArch("X", -105, -108, -3, 7.5, 110, route, "West_Turn", Enum.Material.Concrete, concreteDark, 1.55)
    local turnRibs = {}
    for x = -152, -56, 16 do table.insert(turnRibs, x) end
    buildArchRibs("X", -105, -108, -3, 7.02, turnRibs, route, "West_Turn")
    addFlowingWater("West_Turn_Channel", "X", Vector3.new(-105, -9.94, -108), 104, 4.4, route, 1)
    for x = -144, -64, 30 do
        addCeilingLamp(Vector3.new(x, 3.05, -108), route, "West_Turn_Lamp", Color3.fromRGB(190, 205, 186), 1.85, 30)
    end

    -- A remote valve chamber closes the long west route.
    local chamber = makeModel("West_Valve_Chamber", route)
    part("West_Chamber_Floor", Vector3.new(50, 1, 46), Vector3.new(-185, -10.5, -108), Enum.Material.Concrete, concrete, chamber)
    part("West_Chamber_Ceiling", Vector3.new(50, 1.5, 46), Vector3.new(-185, 4.0, -108), Enum.Material.Concrete, concreteDark, chamber)
    part("West_Chamber_West_Wall", Vector3.new(1, 14, 46), Vector3.new(-210, -3.5, -108), Enum.Material.Concrete, concrete, chamber)
    part("West_Chamber_North_Wall", Vector3.new(50, 14, 1), Vector3.new(-185, -3.5, -131), Enum.Material.Concrete, concrete, chamber)
    part("West_Chamber_South_Wall", Vector3.new(50, 14, 1), Vector3.new(-185, -3.5, -85), Enum.Material.Concrete, concrete, chamber)
    part("West_Chamber_Entry_Wall_North", Vector3.new(1, 14, 14), Vector3.new(-160, -3.5, -124), Enum.Material.Concrete, concrete, chamber)
    part("West_Chamber_Entry_Wall_South", Vector3.new(1, 14, 14), Vector3.new(-160, -3.5, -92), Enum.Material.Concrete, concrete, chamber)
    part("West_Chamber_Entry_Header", Vector3.new(1, 2, 18), Vector3.new(-160, 2.5, -108), Enum.Material.Concrete, concreteDark, chamber)

    addFlowingWater("West_Chamber_Runoff", "X", Vector3.new(-185, -9.94, -108), 44, 5.2, chamber, 1)
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
    part("East_Leg_Floor", Vector3.new(18, 1, 108), Vector3.new(35, -10.5, 210), Enum.Material.Concrete, concrete, route)
    part("East_Leg_Left_Wall", Vector3.new(1, 7, 108), Vector3.new(26, -6.5, 210), Enum.Material.Concrete, concrete, route)
    part("East_Leg_Right_Wall", Vector3.new(1, 7, 108), Vector3.new(44, -6.5, 210), Enum.Material.Concrete, concrete, route)
    buildArch("Z", 35, 210, -3, 7.5, 108, route, "East_Leg", Enum.Material.Concrete, concreteDark, 1.55)
    local ribs = {}
    for z = 168, 252, 16 do table.insert(ribs, z) end
    buildArchRibs("Z", 35, 210, -3, 7.02, ribs, route, "East_Leg")
    addFlowingWater("East_Leg_Channel", "Z", Vector3.new(35, -9.94, 210), 102, 4.4, route, 1)
    for z = 180, 240, 30 do
        addCeilingLamp(Vector3.new(35, 3.05, z), route, "East_Leg_Lamp", Color3.fromRGB(193, 207, 188), 1.9, 32)
    end

    part("East_Turn_Floor", Vector3.new(110, 1, 18), Vector3.new(90, -10.5, 262), Enum.Material.Concrete, concrete, route)
    part("East_Turn_North_Wall", Vector3.new(110, 7, 1), Vector3.new(90, -6.5, 253), Enum.Material.Concrete, concrete, route)
    part("East_Turn_South_Wall", Vector3.new(110, 7, 1), Vector3.new(90, -6.5, 271), Enum.Material.Concrete, concrete, route)
    buildArch("X", 90, 262, -3, 7.5, 110, route, "East_Turn", Enum.Material.Concrete, concreteDark, 1.55)
    local turnRibs = {}
    for x = 40, 140, 16 do table.insert(turnRibs, x) end
    buildArchRibs("X", 90, 262, -3, 7.02, turnRibs, route, "East_Turn")
    addFlowingWater("East_Turn_Channel", "X", Vector3.new(90, -9.94, 262), 104, 4.4, route, 1)
    for x = 50, 130, 30 do
        addCeilingLamp(Vector3.new(x, 3.05, 262), route, "East_Turn_Lamp", Color3.fromRGB(190, 205, 186), 1.85, 30)
    end

    -- A final sluice chamber, with a doorway at its west side.
    local chamber = makeModel("East_Sluice_Chamber", route)
    part("Sluice_Floor", Vector3.new(50, 1, 44), Vector3.new(160, -10.5, 262), Enum.Material.Concrete, concrete, chamber)
    part("Sluice_Ceiling", Vector3.new(50, 1.5, 44), Vector3.new(160, 4.0, 262), Enum.Material.Concrete, concreteDark, chamber)
    part("Sluice_East_Wall", Vector3.new(1, 14, 44), Vector3.new(185, -3.5, 262), Enum.Material.Concrete, concrete, chamber)
    part("Sluice_North_Wall", Vector3.new(50, 14, 1), Vector3.new(160, -3.5, 240), Enum.Material.Concrete, concrete, chamber)
    part("Sluice_South_Wall", Vector3.new(50, 14, 1), Vector3.new(160, -3.5, 284), Enum.Material.Concrete, concrete, chamber)
    part("Sluice_Entry_North", Vector3.new(1, 14, 13), Vector3.new(135, -3.5, 255.5), Enum.Material.Concrete, concrete, chamber)
    part("Sluice_Entry_South", Vector3.new(1, 14, 13), Vector3.new(135, -3.5, 268.5), Enum.Material.Concrete, concrete, chamber)
    part("Sluice_Entry_Header", Vector3.new(1, 2, 18), Vector3.new(135, 2.5, 262), Enum.Material.Concrete, concreteDark, chamber)

    addFlowingWater("Sluice_Runoff", "X", Vector3.new(160, -9.94, 262), 44, 5.2, chamber, 1)
    local tank = cylinder("Sluice_Filter_Tank", 11, 8, Vector3.new(174, -4.1, 270), Enum.Material.Metal, Color3.fromRGB(67, 76, 69), chamber, Vector3.new(0, 0, 90))
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

local spawn = Instance.new("SpawnLocation")
spawn.Name = "SewerSpawn"
spawn.Size = Vector3.new(1, 0.2, 1)
spawn.Position = Vector3.new(-108, -9.58 + WORLD_Y_OFFSET, 0)
spawn.CFrame = CFrame.new(-108, -9.58 + WORLD_Y_OFFSET, 0) * CFrame.Angles(0, math.rad(-90), 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Transparency = 1
spawn.CanCollide = false
spawn.CanTouch = false
spawn.CanQuery = false
spawn.Parent = world

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

print("[Horror Game] Sewer V4 loaded: longer connected routes, 90-degree turns, flowing muddy water. Flashlight removed.")

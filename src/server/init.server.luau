--[[
    HORROR GAME - WORLD FOUNDATION
    Builds the first playable environment: a remote forest and an abandoned clinic.
    All generated objects are kept inside Workspace.HorrorWorld so the scene can
    be rebuilt safely without deleting unrelated Studio objects.
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local oldWorld = Workspace:FindFirstChild("HorrorWorld")
if oldWorld then
    oldWorld:Destroy()
end

local world = Instance.new("Folder")
world.Name = "HorrorWorld"
world.Parent = Workspace

local function makePart(name, size, position, material, color, parent, anchored)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = anchored ~= false
    part.Material = material or Enum.Material.Concrete
    part.Color = color or Color3.fromRGB(70, 70, 70)
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent or world
    return part
end

local function makeModel(name)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = world
    return model
end

local function setAtmosphere()
    Lighting.Technology = Enum.Technology.Future
    Lighting.ClockTime = 1.4
    Lighting.Brightness = 1.15
    Lighting.GlobalShadows = true
    Lighting.EnvironmentDiffuseScale = 0.22
    Lighting.EnvironmentSpecularScale = 0.18
    Lighting.Ambient = Color3.fromRGB(24, 29, 35)
    Lighting.OutdoorAmbient = Color3.fromRGB(13, 18, 23)
    Lighting.FogColor = Color3.fromRGB(29, 38, 43)
    Lighting.FogStart = 45
    Lighting.FogEnd = 210

    for _, effectName in ipairs({"ClinicAtmosphere", "ClinicColor", "ClinicBloom"}) do
        local existing = Lighting:FindFirstChild(effectName)
        if existing then existing:Destroy() end
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "ClinicAtmosphere"
    atmosphere.Density = 0.38
    atmosphere.Offset = 0.08
    atmosphere.Color = Color3.fromRGB(117, 133, 139)
    atmosphere.Decay = Color3.fromRGB(34, 43, 48)
    atmosphere.Glare = 0.08
    atmosphere.Haze = 2.1
    atmosphere.Parent = Lighting

    local color = Instance.new("ColorCorrectionEffect")
    color.Name = "ClinicColor"
    color.Brightness = -0.08
    color.Contrast = 0.18
    color.Saturation = -0.38
    color.TintColor = Color3.fromRGB(190, 207, 211)
    color.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "ClinicBloom"
    bloom.Intensity = 0.18
    bloom.Size = 22
    bloom.Threshold = 1.35
    bloom.Parent = Lighting
end

local function makeTree(x, z, index)
    local tree = makeModel("DeadTree_" .. index)
    local height = 17 + ((index * 7) % 9)
    local trunk = makePart(
        "Trunk",
        Vector3.new(2.1, height, 2.1),
        Vector3.new(x, height / 2, z),
        Enum.Material.Wood,
        Color3.fromRGB(42, 38, 34),
        tree
    )
    trunk.Shape = Enum.PartType.Cylinder
    trunk.Orientation = Vector3.new(0, 0, 90)

    for branch = 1, 3 do
        local branchPart = makePart(
            "BareBranch",
            Vector3.new(1, 8 - branch, 1),
            Vector3.new(x + (branch - 2) * 2.7, height * 0.62 + branch, z),
            Enum.Material.Wood,
            Color3.fromRGB(48, 43, 38),
            tree
        )
        branchPart.Shape = Enum.PartType.Cylinder
        branchPart.Orientation = Vector3.new(0, 0, 35 * (branch - 2))
    end
end

local function makeWall(name, size, position, parent, color)
    return makePart(
        name,
        size,
        position,
        Enum.Material.Concrete,
        color or Color3.fromRGB(83, 87, 84),
        parent
    )
end

local function makeFluorescentLight(position, parent, brightness)
    local fixture = makePart(
        "Old_Fluorescent_Fixture",
        Vector3.new(7, 0.25, 1.2),
        position,
        Enum.Material.Metal,
        Color3.fromRGB(105, 111, 108),
        parent
    )
    local light = Instance.new("SurfaceLight")
    light.Name = "FlickeringCeilingLight"
    light.Face = Enum.NormalId.Bottom
    light.Range = 25
    light.Angle = 105
    light.Brightness = brightness or 0.8
    light.Color = Color3.fromRGB(190, 207, 194)
    light.Shadows = true
    light.Parent = fixture
end

local function buildClinic()
    local clinic = makeModel("AbandonedClinic")

    -- Main floor and the open roof keep the interior visible while developing.
    makePart(
        "Clinic_Foundation",
        Vector3.new(126, 2, 82),
        Vector3.new(0, -1, 0),
        Enum.Material.Concrete,
        Color3.fromRGB(58, 61, 59),
        clinic
    )
    makePart(
        "Interior_Floor",
        Vector3.new(122, 0.35, 78),
        Vector3.new(0, 0.18, 0),
        Enum.Material.Concrete,
        Color3.fromRGB(91, 91, 83),
        clinic
    )

    local wallY = 10
    local wallHeight = 20
    local wallThickness = 2

    -- Exterior shell. The south side has a wide entrance opening.
    makeWall("North_Exterior_Wall", Vector3.new(126, wallHeight, wallThickness), Vector3.new(0, wallY, -41), clinic)
    makeWall("West_Exterior_Wall", Vector3.new(wallThickness, wallHeight, 82), Vector3.new(-63, wallY, 0), clinic)
    makeWall("East_Exterior_Wall", Vector3.new(wallThickness, wallHeight, 82), Vector3.new(63, wallY, 0), clinic)
    makeWall("South_Wall_Left", Vector3.new(43, wallHeight, wallThickness), Vector3.new(-41.5, wallY, 41), clinic)
    makeWall("South_Wall_Right", Vector3.new(43, wallHeight, wallThickness), Vector3.new(41.5, wallY, 41), clinic)
    makeWall("Entrance_Header", Vector3.new(40, 7, wallThickness), Vector3.new(0, 16.5, 41), clinic, Color3.fromRGB(69, 73, 70))

    -- Corridor runs through the middle of the building.
    makeWall("North_Corridor_Wall_Left", Vector3.new(32, 18, 1.5), Vector3.new(-46, 9, -8), clinic)
    makeWall("North_Corridor_Wall_Right", Vector3.new(32, 18, 1.5), Vector3.new(46, 9, -8), clinic)
    makeWall("South_Corridor_Wall_Left", Vector3.new(32, 18, 1.5), Vector3.new(-46, 9, 8), clinic)
    makeWall("South_Corridor_Wall_Right", Vector3.new(32, 18, 1.5), Vector3.new(46, 9, 8), clinic)

    -- Room dividers, leaving door-sized gaps near the corridor.
    for _, x in ipairs({-30, 0, 30}) do
        makeWall("North_Room_Divider_A", Vector3.new(1.5, 18, 25), Vector3.new(x, 9, -21), clinic)
        makeWall("South_Room_Divider_B", Vector3.new(1.5, 18, 25), Vector3.new(x, 9, 21), clinic)
    end

    -- Door frames and old doors along the corridor.
    for _, x in ipairs({-45, -15, 15, 45}) do
        for _, z in ipairs({-8, 8}) do
            local door = makePart(
                "Old_Clinic_Door",
                Vector3.new(5.5, 11, 0.65),
                Vector3.new(x, 5.7, z),
                Enum.Material.Wood,
                Color3.fromRGB(48, 52, 49),
                clinic
            )
            door:SetAttribute("DoorState", "Closed")
        end
    end

    -- Dirty window panels on the long exterior walls.
    for _, x in ipairs({-48, -24, 0, 24, 48}) do
        for _, z in ipairs({-42.1, 42.1}) do
            local window = makePart(
                "Dirty_Window",
                Vector3.new(10, 5, 0.18),
                Vector3.new(x, 12, z),
                Enum.Material.Glass,
                Color3.fromRGB(53, 69, 72),
                clinic
            )
            window.Transparency = 0.38
            window.CanCollide = false
        end
    end

    for _, x in ipairs({-48, -16, 16, 48}) do
        makeFluorescentLight(Vector3.new(x, 19.2, 0), clinic, 0.72)
    end

    -- Reception desk and a few environmental details.
    makePart("Reception_Counter", Vector3.new(15, 4, 3), Vector3.new(-37, 2.2, 27), Enum.Material.WoodPlanks, Color3.fromRGB(55, 49, 42), clinic)
    makePart("Reception_Back_Counter", Vector3.new(15, 0.35, 3.2), Vector3.new(-37, 4.35, 27), Enum.Material.Wood, Color3.fromRGB(91, 79, 62), clinic)
    makePart("Reception_Notice_Board", Vector3.new(9, 5, 0.35), Vector3.new(-37, 11, 39.7), Enum.Material.Wood, Color3.fromRGB(47, 50, 47), clinic)

    local sign = makePart("Clinic_Entrance_Sign", Vector3.new(22, 3, 0.5), Vector3.new(0, 19.5, 42.4), Enum.Material.Metal, Color3.fromRGB(37, 43, 42), clinic)
    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 35
    surface.Parent = sign

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "ST. AGNES  •  CLINIC"
    label.TextColor3 = Color3.fromRGB(170, 181, 172)
    label.TextScaled = true
    label.Font = Enum.Font.GothamMedium
    label.Parent = surface
end

local function buildForest()
    -- Large ground plane, with a rough gravel approach to the clinic.
    makePart("Forest_Ground", Vector3.new(650, 4, 650), Vector3.new(0, -3, 0), Enum.Material.Ground, Color3.fromRGB(34, 42, 35), world)
    makePart("Gravel_Approach", Vector3.new(17, 0.3, 95), Vector3.new(0, -0.72, 90), Enum.Material.Pebble, Color3.fromRGB(65, 66, 59), world)

    local index = 0
    for x = -270, 270, 30 do
        for z = -270, 270, 30 do
            local nearClinic = math.abs(x) < 95 and math.abs(z) < 105
            local nearPath = math.abs(x) < 15 and z > 35 and z < 155
            if not nearClinic and not nearPath then
                index += 1
                local offsetX = ((index * 13) % 17) - 8
                local offsetZ = ((index * 7) % 19) - 9
                makeTree(x + offsetX, z + offsetZ, index)
            end
        end
    end

    -- Sparse dead grass and stones break up the flat ground near the path.
    for i = 1, 42 do
        local x = ((i * 37) % 190) - 95
        local z = ((i * 53) % 250) - 115
        if not (math.abs(x) < 70 and math.abs(z) < 48) then
            local stone = makePart(
                "Forest_Rock",
                Vector3.new(2 + (i % 4), 1 + (i % 2), 2 + (i % 3)),
                Vector3.new(x, -0.65, z),
                Enum.Material.Slate,
                Color3.fromRGB(48, 53, 49),
                world
            )
            stone.Shape = Enum.PartType.Ball
        end
    end
end

setAtmosphere()
buildForest()
buildClinic()

local spawn = Instance.new("SpawnLocation")
spawn.Name = "PlayerSpawn"
spawn.Size = Vector3.new(7, 1, 7)
spawn.Position = Vector3.new(0, 1, 76)
spawn.Anchored = true
spawn.Neutral = true
spawn.Material = Enum.Material.Concrete
spawn.Color = Color3.fromRGB(55, 61, 57)
spawn.Transparency = 0.25
spawn.Parent = world

print("[Horror Game] Forest and abandoned clinic generated.")

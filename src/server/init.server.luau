--[[
    HORROR GAME - SEWER LEVEL
    A connected underground sewer blockout replaces the old clinic/forest scene.
    Everything is anchored and grouped in Workspace.SewerWorld.
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local oldWorld = Workspace:FindFirstChild("SewerWorld")
if oldWorld then
    oldWorld:Destroy()
end

local oldClinicWorld = Workspace:FindFirstChild("HorrorWorld")
if oldClinicWorld then
    oldClinicWorld:Destroy()
end

local world = Instance.new("Folder")
world.Name = "SewerWorld"
world.Parent = Workspace

local function part(name, size, position, material, color, parent, transparency)
    local item = Instance.new("Part")
    item.Name = name
    item.Size = size
    item.Position = position
    item.Anchored = true
    item.CanCollide = true
    item.Material = material or Enum.Material.Concrete
    item.Color = color or Color3.fromRGB(70, 74, 71)
    item.TopSurface = Enum.SurfaceType.Smooth
    item.BottomSurface = Enum.SurfaceType.Smooth
    item.CastShadow = true
    item.Transparency = transparency or 0
    item.Parent = parent or world
    return item
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

local function model(name)
    local result = Instance.new("Model")
    result.Name = name
    result.Parent = world
    return result
end

local function configureLighting()
    Lighting.ClockTime = 0.4
    Lighting.Brightness = 1.65
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.fromRGB(62, 69, 66)
    Lighting.OutdoorAmbient = Color3.fromRGB(38, 45, 42)
    Lighting.FogColor = Color3.fromRGB(48, 59, 57)
    Lighting.FogStart = 38
    Lighting.FogEnd = 235
    Lighting.EnvironmentDiffuseScale = 0.35
    Lighting.EnvironmentSpecularScale = 0.25

    for _, name in ipairs({"SewerAtmosphere", "SewerColor", "SewerBloom"}) do
        local old = Lighting:FindFirstChild(name)
        if old then old:Destroy() end
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "SewerAtmosphere"
    atmosphere.Density = 0.24
    atmosphere.Offset = 0.08
    atmosphere.Color = Color3.fromRGB(128, 143, 137)
    atmosphere.Decay = Color3.fromRGB(43, 52, 49)
    atmosphere.Glare = 0.03
    atmosphere.Haze = 1.25
    atmosphere.Parent = Lighting

    local color = Instance.new("ColorCorrectionEffect")
    color.Name = "SewerColor"
    color.Brightness = -0.015
    color.Contrast = 0.11
    color.Saturation = -0.22
    color.TintColor = Color3.fromRGB(205, 218, 207)
    color.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "SewerBloom"
    bloom.Intensity = 0.12
    bloom.Size = 18
    bloom.Threshold = 1.45
    bloom.Parent = Lighting
end

local concrete = Color3.fromRGB(77, 82, 78)
local darkConcrete = Color3.fromRGB(48, 54, 51)
local metal = Color3.fromRGB(54, 63, 61)
local rust = Color3.fromRGB(91, 57, 42)
local warningYellow = Color3.fromRGB(181, 145, 58)

local function buildMainTunnel()
    local tunnel = model("Main_Sewer_Tunnel")

    -- Main passage: roughly 200 studs long, 18 wide and 12 high.
    part("Main_Floor", Vector3.new(200, 1, 18), Vector3.new(0, -10.5, 0), Enum.Material.Concrete, concrete, tunnel)
    part("Main_Ceiling", Vector3.new(200, 1, 18), Vector3.new(0, 1.5, 0), Enum.Material.Concrete, darkConcrete, tunnel)
    part("Main_Wall_Left", Vector3.new(200, 12, 1), Vector3.new(0, -4.5, -9), Enum.Material.Concrete, concrete, tunnel)

    -- Split the right wall to leave a real opening into the side tunnel.
    part("Main_Wall_Right_A", Vector3.new(126, 12, 1), Vector3.new(-37, -4.5, 9), Enum.Material.Concrete, concrete, tunnel)
    part("Main_Wall_Right_B", Vector3.new(56, 12, 1), Vector3.new(72, -4.5, 9), Enum.Material.Concrete, concrete, tunnel)

    -- Shallow runoff channel and raised channel edges.
    part("Runoff_Water_Main", Vector3.new(196, 0.08, 4), Vector3.new(0, -9.92, 0), Enum.Material.Glass, Color3.fromRGB(55, 91, 86), tunnel, 0.34).CanCollide = false
    part("Channel_Curb_Left", Vector3.new(198, 0.45, 0.35), Vector3.new(0, -9.76, -2.2), Enum.Material.Concrete, darkConcrete, tunnel)
    part("Channel_Curb_Right", Vector3.new(198, 0.45, 0.35), Vector3.new(0, -9.76, 2.2), Enum.Material.Concrete, darkConcrete, tunnel)

    -- Long wall pipes, with visible brackets so nothing looks suspended.
    for _, z in ipairs({-7.15, 7.15}) do
        cylinder("Wall_Pipe_Main", 190, 1.0, Vector3.new(0, -3.0, z), Enum.Material.Metal, rust, tunnel)
        for x = -82, 82, 24 do
            part("Pipe_Wall_Bracket", Vector3.new(0.65, 1.8, 0.8), Vector3.new(x, -3.0, z + (z < 0 and -0.95 or 0.95)), Enum.Material.Metal, metal, tunnel)
        end
    end

    -- Ceiling conduit and cable trays.
    cylinder("Ceiling_Service_Pipe", 185, 0.55, Vector3.new(0, 0.15, -4.5), Enum.Material.Metal, metal, tunnel)
    for x = -82, 82, 26 do
        part("Ceiling_Pipe_Hanger", Vector3.new(0.35, 0.8, 0.45), Vector3.new(x, 0.7, -4.5), Enum.Material.Metal, rust, tunnel)
    end

    for x = -72, 88, 40 do
        local fixture = part("Ceiling_Lamp", Vector3.new(3.8, 0.3, 1.5), Vector3.new(x, 0.82, 0), Enum.Material.Neon, Color3.fromRGB(151, 174, 154), tunnel)
        fixture.CanCollide = false
        local light = Instance.new("PointLight")
        light.Name = "Sewer_Ceiling_Light"
        light.Color = Color3.fromRGB(188, 205, 187)
        light.Brightness = 1.45
        light.Range = 31
        light.Shadows = true
        light.Parent = fixture
    end

    -- A small amount of grounded wear breaks up the clean concrete floor.
    for i = 1, 16 do
        local x = -88 + i * 11
        local stain = part(
            "Floor_Stain",
            Vector3.new(3 + (i % 3), 0.025, 1.4 + (i % 2)),
            Vector3.new(x, -9.985, (i % 2 == 0 and -5.2 or 5.2)),
            Enum.Material.Slate,
            Color3.fromRGB(56, 61, 57),
            tunnel
        )
        stain.CanCollide = false
    end

    local sign = part("Tunnel_Number_Sign", Vector3.new(8, 3.5, 0.25), Vector3.new(-79, -3.4, -8.35), Enum.Material.Metal, darkConcrete, tunnel)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "TunnelSign"
    gui.Face = Enum.NormalId.Back
    gui.PixelsPerStud = 30
    gui.Parent = sign
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "KANAL 04"
    label.TextColor3 = Color3.fromRGB(191, 204, 190)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
end

local function buildSideTunnelAndPumpRoom()
    local branch = model("Pump_Room_Access")

    -- Side tunnel connects to the opening in the main tunnel wall.
    part("Branch_Floor", Vector3.new(18, 1, 82), Vector3.new(35, -10.5, 41), Enum.Material.Concrete, concrete, branch)
    part("Branch_Ceiling", Vector3.new(18, 1, 82), Vector3.new(35, 1.5, 41), Enum.Material.Concrete, darkConcrete, branch)
    part("Branch_Wall_Left", Vector3.new(1, 12, 82), Vector3.new(26, -4.5, 41), Enum.Material.Concrete, concrete, branch)
    part("Branch_Wall_Right", Vector3.new(1, 12, 82), Vector3.new(44, -4.5, 41), Enum.Material.Concrete, concrete, branch)

    part("Runoff_Water_Branch", Vector3.new(4, 0.08, 78), Vector3.new(35, -9.92, 40), Enum.Material.Glass, Color3.fromRGB(55, 91, 86), branch, 0.34).CanCollide = false
    for _, x in ipairs({32.8, 37.2}) do
        part("Branch_Channel_Curb", Vector3.new(0.35, 0.45, 80), Vector3.new(x, -9.76, 40), Enum.Material.Concrete, darkConcrete, branch)
    end

    cylinder("Branch_Wall_Pipe", 76, 0.85, Vector3.new(27.4, -3.1, 40), Enum.Material.Metal, rust, branch, Vector3.new(0, 90, 0))
    cylinder("Branch_Wall_Pipe", 76, 0.85, Vector3.new(42.6, -3.1, 40), Enum.Material.Metal, metal, branch, Vector3.new(0, 90, 0))
    for z = 14, 74, 20 do
        part("Branch_Pipe_Bracket", Vector3.new(0.8, 1.5, 0.55), Vector3.new(27.6, -3.1, z), Enum.Material.Metal, metal, branch)
        part("Branch_Pipe_Bracket", Vector3.new(0.8, 1.5, 0.55), Vector3.new(42.4, -3.1, z), Enum.Material.Metal, metal, branch)
    end

    for z = 18, 78, 30 do
        local fixture = part("Branch_Ceiling_Lamp", Vector3.new(2.2, 0.3, 1.1), Vector3.new(35, 0.82, z), Enum.Material.Neon, Color3.fromRGB(147, 166, 149), branch)
        fixture.CanCollide = false
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(183, 201, 181)
        light.Brightness = 1.25
        light.Range = 27
        light.Shadows = true
        light.Parent = fixture
    end

    -- Pump room: proper floor, ceiling and connected walls.
    local room = model("Old_Pump_Room")
    part("Pump_Room_Floor", Vector3.new(48, 1, 46), Vector3.new(35, -10.5, 104), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Ceiling", Vector3.new(48, 1, 46), Vector3.new(35, 1.5, 104), Enum.Material.Concrete, darkConcrete, room)
    part("Pump_Room_Left_Wall", Vector3.new(1, 12, 46), Vector3.new(11, -4.5, 104), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Right_Wall", Vector3.new(1, 12, 46), Vector3.new(59, -4.5, 104), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Back_Wall", Vector3.new(48, 12, 1), Vector3.new(35, -4.5, 127), Enum.Material.Concrete, concrete, room)

    -- The front wall has a centred doorway leading from the side tunnel.
    part("Pump_Room_Entry_Left", Vector3.new(17, 12, 1), Vector3.new(20.5, -4.5, 81), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Entry_Right", Vector3.new(17, 12, 1), Vector3.new(49.5, -4.5, 81), Enum.Material.Concrete, concrete, room)
    part("Pump_Room_Entry_Header", Vector3.new(14, 2, 1), Vector3.new(35, 0.5, 81), Enum.Material.Concrete, darkConcrete, room)

    part("Pump_Room_Water", Vector3.new(42, 0.08, 4), Vector3.new(35, -9.92, 103), Enum.Material.Glass, Color3.fromRGB(52, 87, 82), room, 0.34).CanCollide = false

    -- Old industrial pump and tank, fixed to a concrete plinth.
    part("Pump_Base", Vector3.new(12, 1.2, 9), Vector3.new(35, -9.35, 108), Enum.Material.Metal, rust, room)
    local tank = cylinder("Old_Filter_Tank", 11, 8, Vector3.new(35, -4.0, 108), Enum.Material.Metal, Color3.fromRGB(65, 73, 68), room, Vector3.new(0, 0, 90))
    tank.Material = Enum.Material.CorrodedMetal
    part("Tank_Top_Cap", Vector3.new(8.5, 0.45, 8.5), Vector3.new(35, 1.05, 108), Enum.Material.Metal, rust, room)

    cylinder("Pump_Outlet_Pipe", 13, 1.2, Vector3.new(45, -2.8, 108), Enum.Material.Metal, rust, room)
    cylinder("Pump_Inlet_Pipe", 15, 1.0, Vector3.new(35, -2.8, 117), Enum.Material.Metal, metal, room, Vector3.new(0, 90, 0))

    -- Large hand valve attached to the wall, with a visible wheel and spokes.
    cylinder("Valve_Hub", 1.2, 2.8, Vector3.new(56.8, -4.0, 115), Enum.Material.Metal, rust, room, Vector3.new(0, 90, 0))
    part("Valve_Wheel_Top", Vector3.new(0.35, 4.8, 0.35), Vector3.new(56.1, -4.0, 115), Enum.Material.Metal, warningYellow, room)
    part("Valve_Wheel_Side", Vector3.new(0.35, 0.35, 4.8), Vector3.new(56.1, -4.0, 115), Enum.Material.Metal, warningYellow, room)

    local roomLamp = part("Pump_Room_Emergency_Lamp", Vector3.new(3.5, 0.3, 1.3), Vector3.new(35, 0.82, 104), Enum.Material.Neon, Color3.fromRGB(180, 54, 42), room)
    roomLamp.CanCollide = false
    local redLight = Instance.new("PointLight")
    redLight.Color = Color3.fromRGB(255, 72, 55)
    redLight.Brightness = 0.8
    redLight.Range = 20
    redLight.Shadows = true
    redLight.Parent = roomLamp

    local plaque = part("Pump_Control_Plaque", Vector3.new(8, 3, 0.3), Vector3.new(52, -4.3, 126.35), Enum.Material.Metal, darkConcrete, room)
    local plaqueGui = Instance.new("SurfaceGui")
    plaqueGui.Face = Enum.NormalId.Back
    plaqueGui.PixelsPerStud = 28
    plaqueGui.Parent = plaque
    local plaqueText = Instance.new("TextLabel")
    plaqueText.Size = UDim2.fromScale(1, 1)
    plaqueText.BackgroundTransparency = 1
    plaqueText.Text = "PUMPE  /  02"
    plaqueText.TextScaled = true
    plaqueText.Font = Enum.Font.GothamBold
    plaqueText.TextColor3 = Color3.fromRGB(196, 184, 149)
    plaqueText.Parent = plaqueGui
end

local function buildSecurityGate()
    local gate = model("Restricted_Tunnel_Gate")
    local x = 94
    part("Gate_Frame_Top", Vector3.new(0.8, 0.7, 16), Vector3.new(x, 0.25, 0), Enum.Material.Metal, rust, gate)
    part("Gate_Frame_Bottom", Vector3.new(0.8, 0.7, 16), Vector3.new(x, -9.7, 0), Enum.Material.Metal, rust, gate)
    for z = -7, 7, 1.8 do
        part("Gate_Bar", Vector3.new(0.45, 10, 0.45), Vector3.new(x, -4.7, z), Enum.Material.Metal, metal, gate)
    end
    part("Gate_Sign", Vector3.new(0.3, 3.5, 10), Vector3.new(x - 0.7, -3.3, 0), Enum.Material.Metal, Color3.fromRGB(74, 42, 35), gate)

    local alarm = part("Gate_Alarm_Lens", Vector3.new(1, 0.6, 0.6), Vector3.new(x - 1.1, -1.4, -6), Enum.Material.Neon, Color3.fromRGB(180, 45, 38), gate)
    alarm.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 55, 45)
    light.Brightness = 0.7
    light.Range = 13
    light.Parent = alarm
end

local function buildEntryDetails()
    local entrance = model("Sewer_Entry_Details")
    -- A grounded maintenance access platform at the beginning of the tunnel.
    part("Entry_Platform", Vector3.new(18, 0.35, 12), Vector3.new(-82, -9.78, -5.4), Enum.Material.Metal, metal, entrance)
    for x = -89, -75, 2 do
        part("Platform_Grate_Slat", Vector3.new(0.12, 0.12, 11), Vector3.new(x, -9.55, -5.4), Enum.Material.Metal, Color3.fromRGB(105, 111, 103), entrance)
    end
    part("Entry_Rail_Left", Vector3.new(18, 1.2, 0.18), Vector3.new(-82, -8.95, -11.1), Enum.Material.Metal, rust, entrance)
    part("Entry_Rail_End", Vector3.new(0.18, 1.2, 11), Vector3.new(-91, -8.95, -5.4), Enum.Material.Metal, rust, entrance)

    -- Maintenance platform details are attached directly to the platform and rails.
end

configureLighting()
buildMainTunnel()
buildSideTunnelAndPumpRoom()
buildSecurityGate()
buildEntryDetails()

local spawn = Instance.new("SpawnLocation")
spawn.Name = "SewerSpawn"
spawn.Size = Vector3.new(4, 0.4, 4)
spawn.Position = Vector3.new(-82, -9.65, -5.4)
spawn.CFrame = CFrame.new(-82, -9.65, -5.4) * CFrame.Angles(0, math.rad(-90), 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = world

print("[Horror Game] Sewer level generated: main tunnel, branch, pump room and security gate.")

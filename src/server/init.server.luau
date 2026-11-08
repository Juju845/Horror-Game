--[[
    HORROR GAME - SEWER LEVEL V2
    A fully enclosed, walkable sewer with an arched main tunnel, branch tunnel,
    pump room, service details, ceiling lights and an inventory flashlight Tool.
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")

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
    item.CFrame = cframe
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

local function configureLighting()
    Lighting.ClockTime = 0.2
    Lighting.Brightness = 2.1
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.fromRGB(83, 91, 85)
    Lighting.OutdoorAmbient = Color3.fromRGB(56, 64, 59)
    Lighting.FogColor = Color3.fromRGB(56, 68, 63)
    Lighting.FogStart = 95
    Lighting.FogEnd = 330
    Lighting.EnvironmentDiffuseScale = 0.45
    Lighting.EnvironmentSpecularScale = 0.3

    for _, name in ipairs({"SewerAtmosphere", "SewerColor", "SewerBloom"}) do
        local old = Lighting:FindFirstChild(name)
        if old then old:Destroy() end
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "SewerAtmosphere"
    atmosphere.Density = 0.17
    atmosphere.Offset = 0.05
    atmosphere.Color = Color3.fromRGB(151, 164, 154)
    atmosphere.Decay = Color3.fromRGB(55, 67, 61)
    atmosphere.Glare = 0.02
    atmosphere.Haze = 0.8
    atmosphere.Parent = Lighting

    local color = Instance.new("ColorCorrectionEffect")
    color.Name = "SewerColor"
    color.Brightness = 0.015
    color.Contrast = 0.08
    color.Saturation = -0.16
    color.TintColor = Color3.fromRGB(218, 226, 215)
    color.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "SewerBloom"
    bloom.Intensity = 0.1
    bloom.Size = 16
    bloom.Threshold = 1.6
    bloom.Parent = Lighting
end

local concrete = Color3.fromRGB(88, 93, 87)
local concreteDark = Color3.fromRGB(57, 64, 59)
local concreteEdge = Color3.fromRGB(105, 108, 98)
local metal = Color3.fromRGB(61, 70, 66)
local rust = Color3.fromRGB(105, 66, 48)
local yellow = Color3.fromRGB(194, 157, 67)

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
                makePart(name .. "_Steel_Rib", Vector3.new(0.85, 0.7, 2.75), cf, Enum.Material.Metal, rust, parent)
            else
                z = along
                x = centerX + radius * math.sin(angle)
                local cf = CFrame.new(x, y, z) * CFrame.Angles(0, 0, -angle)
                makePart(name .. "_Steel_Rib", Vector3.new(2.75, 0.7, 0.85), cf, Enum.Material.Metal, rust, parent)
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
    part("Main_Walking_Floor", Vector3.new(240, 1, 18), Vector3.new(0, -10.5, 0), Enum.Material.Concrete, concrete, tunnel)
    part("Main_Left_Side_Wall", Vector3.new(240, 7, 1), Vector3.new(0, -6.5, -8), Enum.Material.Concrete, concrete, tunnel)
    part("Main_Right_Wall_A", Vector3.new(126, 7, 1), Vector3.new(-37, -6.5, 8), Enum.Material.Concrete, concrete, tunnel)
    part("Main_Right_Wall_B", Vector3.new(194, 7, 1), Vector3.new(143, -6.5, 8), Enum.Material.Concrete, concrete, tunnel)

    -- Continuous arched roof and repeating steel support frames.
    buildArch("X", 0, 0, -3, 7.5, 240, tunnel, "Main", Enum.Material.Concrete, concreteDark, 1.55)
    local ribPositions = {}
    for x = -112, 112, 16 do table.insert(ribPositions, x) end
    buildArchRibs("X", 0, 0, -3, 7.02, ribPositions, tunnel, "Main")

    -- A visible shallow water channel runs through the centre of the floor.
    part("Main_Water_Channel", Vector3.new(232, 0.07, 3.1), Vector3.new(0, -9.94, 0), Enum.Material.Glass, Color3.fromRGB(63, 103, 96), tunnel, 0.3).CanCollide = false
    part("Main_Channel_Curb_Left", Vector3.new(232, 0.42, 0.35), Vector3.new(0, -9.76, -1.8), Enum.Material.Concrete, concreteDark, tunnel)
    part("Main_Channel_Curb_Right", Vector3.new(232, 0.42, 0.35), Vector3.new(0, -9.76, 1.8), Enum.Material.Concrete, concreteDark, tunnel)

    -- Pipes are fixed to the walls with brackets at regular intervals.
    for _, side in ipairs({-1, 1}) do
        local pipeZ = side * 6.75
        cylinder("Main_Rusted_Service_Pipe", 226, 0.85, Vector3.new(0, -5.2, pipeZ), Enum.Material.Metal, rust, tunnel)
        cylinder("Main_Upper_Service_Pipe", 226, 0.38, Vector3.new(0, -3.6, side * 7.05), Enum.Material.Metal, metal, tunnel)
        for x = -104, 104, 16 do
            part("Main_Pipe_Anchor", Vector3.new(0.85, 1.45, 1.25), Vector3.new(x, -5.2, side * 7.25), Enum.Material.Metal, metal, tunnel)
        end
    end

    -- Cable tray under the roof, visibly attached with short hangers.
    cylinder("Main_Ceiling_Cable_Tray", 218, 0.55, Vector3.new(0, 2.2, -3.5), Enum.Material.Metal, metal, tunnel)
    for x = -102, 102, 24 do
        part("Cable_Tray_Hanger", Vector3.new(0.5, 1.0, 0.55), Vector3.new(x, 2.7, -3.5), Enum.Material.Metal, rust, tunnel)
    end

    for x = -92, 92, 30 do
        addCeilingLamp(Vector3.new(x, 3.05, 0), tunnel, "Main_Tunnel_Lamp", Color3.fromRGB(196, 211, 190), 2.25, 38)
    end

    -- Grounded floor drains and wall recesses make the long corridor readable.
    for x = -100, 100, 25 do
        local drain = part("Floor_Drain", Vector3.new(2.6, 0.08, 1.15), Vector3.new(x, -9.96, -5.4), Enum.Material.DiamondPlate, metal, tunnel)
        drain.CanCollide = false
        for line = 1, 5 do
            part("Drain_Grille_Slot", Vector3.new(0.08, 0.035, 0.85), Vector3.new(x - 1.0 + line * 0.4, -9.90, -5.4), Enum.Material.Metal, Color3.fromRGB(31, 37, 34), tunnel)
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

    part("Branch_Water_Channel", Vector3.new(3.1, 0.07, 98), Vector3.new(35, -9.94, 60), Enum.Material.Glass, Color3.fromRGB(63, 103, 96), branch, 0.3).CanCollide = false
    for _, x in ipairs({33.2, 36.8}) do
        part("Branch_Channel_Curb", Vector3.new(0.35, 0.42, 98), Vector3.new(x, -9.76, 60), Enum.Material.Concrete, concreteDark, branch)
    end

    for _, x in ipairs({27.2, 42.8}) do
        cylinder("Branch_Rusted_Pipe", 96, 0.75, Vector3.new(x, -5.2, 60), Enum.Material.Metal, rust, branch, Vector3.new(0, 90, 0))
        for z = 18, 102, 18 do
            part("Branch_Pipe_Bracket", Vector3.new(1.15, 1.25, 0.9), Vector3.new(x, -5.2, z), Enum.Material.Metal, metal, branch)
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
    part("Pump_Room_Back_Wall", Vector3.new(50, 14, 1), Vector3.new(35, -3.5, 158), Enum.Material.Concrete, concrete, room)

    -- Front wall is split around the connected branch entrance at z=110.
    part("Pump_Entry_Left_Wall", Vector3.new(16, 14, 1), Vector3.new(18, -3.5, 110), Enum.Material.Concrete, concrete, room)
    part("Pump_Entry_Right_Wall", Vector3.new(16, 14, 1), Vector3.new(52, -3.5, 110), Enum.Material.Concrete, concrete, room)
    part("Pump_Entry_Header", Vector3.new(18, 2, 1), Vector3.new(35, 2.5, 110), Enum.Material.Concrete, concreteDark, room)

    part("Pump_Room_Water", Vector3.new(44, 0.07, 5), Vector3.new(35, -9.94, 133), Enum.Material.Glass, Color3.fromRGB(55, 94, 86), room, 0.3).CanCollide = false
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
    local x = 101
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

local function buildEntrance()
    local entrance = makeModel("Sewer_Entrance")
    part("Entry_Grated_Platform", Vector3.new(12, 0.35, 11), Vector3.new(-108, -9.78, 0), Enum.Material.DiamondPlate, metal, entrance)
    for x = -113, -103, 1.5 do
        part("Entry_Grate_Slot", Vector3.new(0.12, 0.12, 10.2), Vector3.new(x, -9.57, 0), Enum.Material.Metal, concreteEdge, entrance)
    end
    for z = -7, 7, 2 do
        part("Entry_Safety_Rail", Vector3.new(12, 1.0, 0.18), Vector3.new(-108, -8.95, z), Enum.Material.Metal, rust, entrance)
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

local function createFlashlightInventoryItem()
    local oldTool = StarterPack:FindFirstChild("Taschenlampe")
    if oldTool then oldTool:Destroy() end

    local tool = Instance.new("Tool")
    tool.Name = "Taschenlampe"
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    tool.ToolTip = "Taschenlampe ausrüsten oder wegstecken"
    tool.Parent = StarterPack

    local function giveToPlayer(player)
        local backpack = player:WaitForChild("Backpack", 10)
        if not backpack then return end
        if backpack:FindFirstChild("Taschenlampe") then return end
        if player.Character and player.Character:FindFirstChild("Taschenlampe") then return end
        tool:Clone().Parent = backpack
    end

    Players.PlayerAdded:Connect(function(player)
        task.spawn(giveToPlayer, player)
    end)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(giveToPlayer, player)
    end
end

configureLighting()
buildMainTunnel()
buildBranchAndPumpRoom()
buildSecurityGate()
buildEntrance()
createFlashlightInventoryItem()

local spawn = Instance.new("SpawnLocation")
spawn.Name = "SewerSpawn"
spawn.Size = Vector3.new(4, 0.4, 4)
spawn.Position = Vector3.new(-108, -9.58, 0)
spawn.CFrame = CFrame.new(-108, -9.58, 0) * CFrame.Angles(0, math.rad(-90), 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = world

print("[Horror Game] Sewer V2 loaded: enclosed arched tunnel, connected pump-room branch, lights and flashlight inventory.")

--[[
    HORROR GAME - FIRST PERSON, FLASHLIGHT AND STAMINA
    Shift: sprint while moving. Release Shift to recover stamina.
    F: toggle the flashlight beam. G: equip or stow the flashlight.
]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local backpack = player:WaitForChild("Backpack")

local WALK_SPEED = 12
local SPRINT_SPEED = 19
local MAX_STAMINA = 100
local STAMINA_DRAIN_PER_SECOND = 23
local STAMINA_REGEN_PER_SECOND = 19
local REGEN_DELAY = 0.85
local EXHAUSTED_RECOVERY = 28

player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMinZoomDistance = 0.5
player.CameraMaxZoomDistance = 0.5
UserInputService.MouseIconEnabled = false

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
end)

-- Rebuild the HUD cleanly if Studio restarts this LocalScript.
local oldGui = playerGui:FindFirstChild("HorrorHUD")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "HorrorHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local dot = Instance.new("Frame")
dot.Name = "CenterDot"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(4, 4)
dot.BackgroundColor3 = Color3.fromRGB(239, 244, 231)
dot.BackgroundTransparency = 0.02
dot.BorderSizePixel = 0
dot.Parent = gui

local dotRound = Instance.new("UICorner")
dotRound.CornerRadius = UDim.new(1, 0)
dotRound.Parent = dot

local dotStroke = Instance.new("UIStroke")
dotStroke.Color = Color3.fromRGB(16, 21, 18)
dotStroke.Thickness = 1
dotStroke.Parent = dot

-- Compact stamina display, kept separate from the flashlight hint.
local staminaPanel = Instance.new("Frame")
staminaPanel.Name = "StaminaPanel"
staminaPanel.AnchorPoint = Vector2.new(0, 1)
staminaPanel.Position = UDim2.new(0, 24, 1, -54)
staminaPanel.Size = UDim2.fromOffset(235, 34)
staminaPanel.BackgroundColor3 = Color3.fromRGB(12, 16, 14)
staminaPanel.BackgroundTransparency = 0.28
staminaPanel.BorderSizePixel = 0
staminaPanel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 5)
panelCorner.Parent = staminaPanel

local staminaLabel = Instance.new("TextLabel")
staminaLabel.Name = "StaminaLabel"
staminaLabel.Position = UDim2.fromOffset(9, 2)
staminaLabel.Size = UDim2.new(1, -18, 0, 13)
staminaLabel.BackgroundTransparency = 1
staminaLabel.Text = "AUSDAUER     SHIFT HALTEN: SPRINTEN"
staminaLabel.TextColor3 = Color3.fromRGB(214, 222, 211)
staminaLabel.TextSize = 10
staminaLabel.Font = Enum.Font.GothamSemibold
staminaLabel.TextXAlignment = Enum.TextXAlignment.Left
staminaLabel.Parent = staminaPanel

local staminaBack = Instance.new("Frame")
staminaBack.Name = "BarBackground"
staminaBack.Position = UDim2.fromOffset(9, 19)
staminaBack.Size = UDim2.new(1, -18, 0, 8)
staminaBack.BackgroundColor3 = Color3.fromRGB(47, 54, 49)
staminaBack.BorderSizePixel = 0
staminaBack.Parent = staminaPanel

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = staminaBack

local staminaFill = Instance.new("Frame")
staminaFill.Name = "BarFill"
staminaFill.Size = UDim2.fromScale(1, 1)
staminaFill.BackgroundColor3 = Color3.fromRGB(142, 177, 132)
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaBack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = staminaFill

local flashlightStatus = Instance.new("TextLabel")
flashlightStatus.Name = "FlashlightStatus"
flashlightStatus.AnchorPoint = Vector2.new(0, 1)
flashlightStatus.Position = UDim2.new(0, 25, 1, -22)
flashlightStatus.Size = UDim2.fromOffset(430, 18)
flashlightStatus.BackgroundTransparency = 1
flashlightStatus.Text = "TASCHENLAMPE WIRD GELADEN ..."
flashlightStatus.TextColor3 = Color3.fromRGB(218, 227, 214)
flashlightStatus.TextSize = 12
flashlightStatus.Font = Enum.Font.GothamMedium
flashlightStatus.TextXAlignment = Enum.TextXAlignment.Left
flashlightStatus.Parent = gui

-- A Creator Store breathing clip plays only when stamina has been fully depleted.
local breathingSound = Instance.new("Sound")
breathingSound.Name = "PlayerExhaustedBreathing"
breathingSound.SoundId = "rbxassetid://6814463121"
breathingSound.Volume = 0.42
breathingSound.PlaybackSpeed = 0.96
breathingSound.Looped = true
breathingSound.Parent = SoundService

local function setBreathing(enabled)
    if enabled then
        if not breathingSound.IsPlaying then
            pcall(function()
                breathingSound:Play()
            end)
        end
    elseif breathingSound.IsPlaying then
        breathingSound:Stop()
    end
end

-- Flashlight inventory and its compact first-person view model.
local flashlightTool
local equipped = false
local lightOn = true
local viewModel
local spotLight
local fillLight
local lens
local boundTools = {}

local function makeViewPart(parent, name, size, color, material, shape)
    local item = Instance.new("Part")
    item.Name = name
    item.Size = size
    item.Anchored = true
    item.CanCollide = false
    item.CanTouch = false
    item.CanQuery = false
    item.CastShadow = false
    item.Massless = true
    item.Material = material
    item.Color = color
    if shape then item.Shape = shape end
    item.Parent = parent
    return item
end

local function destroyViewModel()
    if viewModel then
        viewModel:Destroy()
        viewModel = nil
    end
    spotLight = nil
    fillLight = nil
    lens = nil
end

local function createViewModel()
    destroyViewModel()
    if not equipped then return end

    local camera = Workspace.CurrentCamera
    if not camera then return end

    viewModel = Instance.new("Model")
    viewModel.Name = "EquippedFlashlightViewModel"
    viewModel.Parent = camera

    -- Cylinders make the flashlight look like a real torch instead of a block.
    local body = makeViewPart(
        viewModel, "Flashlight_Body", Vector3.new(0.58, 0.145, 0.145),
        Color3.fromRGB(31, 37, 35), Enum.Material.Metal, Enum.PartType.Cylinder
    )
    local grip = makeViewPart(
        viewModel, "Flashlight_Grip", Vector3.new(0.15, 0.24, 0.15),
        Color3.fromRGB(20, 24, 22), Enum.Material.Rubber
    )
    local head = makeViewPart(
        viewModel, "Flashlight_Head", Vector3.new(0.14, 0.22, 0.22),
        Color3.fromRGB(71, 78, 72), Enum.Material.Metal, Enum.PartType.Cylinder
    )
    local bezel = makeViewPart(
        viewModel, "Flashlight_Bezel", Vector3.new(0.055, 0.245, 0.245),
        Color3.fromRGB(37, 44, 40), Enum.Material.Metal, Enum.PartType.Cylinder
    )
    lens = makeViewPart(
        viewModel, "Flashlight_Lens", Vector3.new(0.025, 0.17, 0.17),
        Color3.fromRGB(231, 241, 213), Enum.Material.Neon, Enum.PartType.Cylinder
    )

    local beamAttachment = Instance.new("Attachment")
    beamAttachment.Name = "BeamDirection"
    -- The model's cylinder axis is rotated to point along the camera's forward axis.
    beamAttachment.CFrame = CFrame.Angles(0, math.rad(-90), 0)
    beamAttachment.Parent = lens

    spotLight = Instance.new("SpotLight")
    spotLight.Name = "Flashlight_Main_Beam"
    spotLight.Face = Enum.NormalId.Front
    spotLight.Angle = 66
    spotLight.Brightness = 7
    spotLight.Range = 78
    spotLight.Shadows = true
    spotLight.Color = Color3.fromRGB(245, 247, 225)
    spotLight.Enabled = lightOn
    spotLight.Parent = beamAttachment

    fillLight = Instance.new("PointLight")
    fillLight.Name = "Flashlight_Near_Fill"
    fillLight.Brightness = 1.15
    fillLight.Range = 18
    fillLight.Shadows = false
    fillLight.Color = Color3.fromRGB(234, 239, 218)
    fillLight.Enabled = lightOn
    fillLight.Parent = beamAttachment

    viewModel.PrimaryPart = body
end

local function updateLightState()
    if spotLight then spotLight.Enabled = equipped and lightOn end
    if fillLight then fillLight.Enabled = equipped and lightOn end

    if lens then
        lens.Material = (equipped and lightOn) and Enum.Material.Neon or Enum.Material.Glass
        lens.Color = (equipped and lightOn)
            and Color3.fromRGB(231, 241, 213)
            or Color3.fromRGB(65, 70, 65)
    end

    if not flashlightTool then
        flashlightStatus.Text = "TASCHENLAMPE NICHT GEFUNDEN"
    elseif equipped then
        flashlightStatus.Text = lightOn
            and "TASCHENLAMPE  •  F LICHT AUS  •  G WEGSTECKEN"
            or "TASCHENLAMPE  •  F LICHT AN  •  G WEGSTECKEN"
    else
        flashlightStatus.Text = "TASCHENLAMPE IM INVENTAR  •  G HERVORHOLEN"
    end
end

local function setEquipped(state)
    equipped = state
    if equipped then
        lightOn = true
        createViewModel()
    else
        lightOn = false
        destroyViewModel()
    end
    updateLightState()
end

local function toggleBeam()
    if not equipped then return end
    lightOn = not lightOn
    updateLightState()
end

local function bindTool(tool)
    if not tool:IsA("Tool") or tool.Name ~= "Taschenlampe" or boundTools[tool] then return end
    boundTools[tool] = true
    flashlightTool = tool

    tool.Equipped:Connect(function()
        setEquipped(true)
    end)
    tool.Unequipped:Connect(function()
        setEquipped(false)
    end)
    tool.Activated:Connect(toggleBeam)

    updateLightState()

    task.defer(function()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and tool.Parent == backpack and not equipped then
            humanoid:EquipTool(tool)
        end
    end)
end

local function findTool()
    local found = backpack:FindFirstChild("Taschenlampe")
    if not found and player.Character then
        found = player.Character:FindFirstChild("Taschenlampe")
    end
    if found then bindTool(found) end
    return found
end

backpack.ChildAdded:Connect(bindTool)
backpack.ChildRemoved:Connect(function(child)
    if child == flashlightTool and child.Parent ~= player.Character then
        updateLightState()
    end
end)

local function setupCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.WalkSpeed = WALK_SPEED
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 36
        humanoid.AutoRotate = true
    end

    character.ChildAdded:Connect(bindTool)
    task.wait(0.5)

    local tool = findTool()
    if tool and tool.Parent == backpack and humanoid then
        humanoid:EquipTool(tool)
    end
end

if player.Character then
    task.spawn(setupCharacter, player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

local stamina = MAX_STAMINA
local sprintHeld = false
local exhausted = false
local lastStaminaUse = 0

local function updateStaminaBar()
    local ratio = math.clamp(stamina / MAX_STAMINA, 0, 1)
    staminaFill.Size = UDim2.fromScale(ratio, 1)

    if exhausted then
        staminaFill.BackgroundColor3 = Color3.fromRGB(190, 72, 61)
        staminaLabel.Text = "ERSCHÖPFT  •  KURZ ERHOLEN"
        staminaLabel.TextColor3 = Color3.fromRGB(239, 180, 159)
    else
        staminaLabel.Text = "AUSDAUER     SHIFT HALTEN: SPRINTEN"
        staminaLabel.TextColor3 = Color3.fromRGB(214, 222, 211)
        if ratio > 0.55 then
            staminaFill.BackgroundColor3 = Color3.fromRGB(142, 177, 132)
        elseif ratio > 0.25 then
            staminaFill.BackgroundColor3 = Color3.fromRGB(194, 163, 88)
        else
            staminaFill.BackgroundColor3 = Color3.fromRGB(190, 105, 67)
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        sprintHeld = true
    elseif input.KeyCode == Enum.KeyCode.F then
        toggleBeam()
    elseif input.KeyCode == Enum.KeyCode.G then
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local tool = findTool()
        if humanoid and tool then
            if equipped then
                humanoid:UnequipTools()
            elseif tool.Parent == backpack then
                humanoid:EquipTool(tool)
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        sprintHeld = false
    end
end)

RunService:BindToRenderStep("HorrorGamePlayerSystems", Enum.RenderPriority.Camera.Value + 2, function(deltaTime)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local now = os.clock()
    local moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.05

    local sprinting = sprintHeld and moving and stamina > 0 and not exhausted
    if sprinting then
        stamina = math.max(0, stamina - STAMINA_DRAIN_PER_SECOND * deltaTime)
        lastStaminaUse = now
        if stamina <= 0 then
            stamina = 0
            exhausted = true
            sprintHeld = false
            sprinting = false
        end
    elseif not sprintHeld and now - lastStaminaUse >= REGEN_DELAY then
        stamina = math.min(MAX_STAMINA, stamina + STAMINA_REGEN_PER_SECOND * deltaTime)
        if exhausted and stamina >= EXHAUSTED_RECOVERY then
            exhausted = false
        end
    end

    if humanoid then
        humanoid.WalkSpeed = sprinting and SPRINT_SPEED or WALK_SPEED
    end

    setBreathing(exhausted)
    updateStaminaBar()

    local camera = Workspace.CurrentCamera
    if camera then
        local breathingPulse = exhausted and ((math.sin(now * 2.5) + 1) * 0.5) or 0
        local targetFov = 70 + (sprinting and 1.5 or 0) - breathingPulse * 1.0
        camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * math.min(deltaTime * 5, 1)

        if equipped then
            if not viewModel or viewModel.Parent ~= camera then
                createViewModel()
                updateLightState()
            end

            if viewModel then
                local cameraFrame = camera.CFrame * CFrame.new(0.46, -0.39, -0.92)
                local cylinderFacing = CFrame.Angles(0, math.rad(90), 0)

                local body = viewModel:FindFirstChild("Flashlight_Body")
                local grip = viewModel:FindFirstChild("Flashlight_Grip")
                local head = viewModel:FindFirstChild("Flashlight_Head")
                local bezel = viewModel:FindFirstChild("Flashlight_Bezel")

                if body and grip and head and bezel and lens then
                    body.CFrame = cameraFrame * cylinderFacing
                    grip.CFrame = cameraFrame * CFrame.new(-0.03, -0.14, 0.06) * CFrame.Angles(0, 0, math.rad(-8))
                    head.CFrame = cameraFrame * CFrame.new(0, 0, -0.28) * cylinderFacing
                    bezel.CFrame = cameraFrame * CFrame.new(0, 0, -0.37) * cylinderFacing
                    lens.CFrame = cameraFrame * CFrame.new(0, 0, -0.415) * cylinderFacing
                end
            end
        end
    end
end)

findTool()
updateLightState()
updateStaminaBar()

print("[Horror Game] Player systems ready: flashlight, stamina sprint and exhaustion breathing.")

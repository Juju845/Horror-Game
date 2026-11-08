--[[
    HORROR GAME - FIRST PERSON, STAMINA AND FOOTSTEPS
    Hold Left Shift / Right Shift to sprint. Release to recover stamina.
    The flashlight has been removed completely.
]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local backpack = player:WaitForChild("Backpack")

local WALK_SPEED = 12
local SPRINT_SPEED = 19
local MAX_STAMINA = 100
local STAMINA_DRAIN_PER_SECOND = 23
local STAMINA_REGEN_PER_SECOND = 19
local REGEN_DELAY = 2.2
local EXHAUSTED_RECOVERY = 40
local MIN_EXHAUSTED_TIME = 7.0

player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMinZoomDistance = 0.5
player.CameraMaxZoomDistance = 0.5
UserInputService.MouseIconEnabled = false

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
end)

-- Remove any flashlight left in a Backpack from an earlier prototype.
local function removeOldFlashlights(container)
    if not container then return end
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") and item.Name == "Taschenlampe" then
            item:Destroy()
        end
    end
end
removeOldFlashlights(backpack)
if player.Character then removeOldFlashlights(player.Character) end
backpack.ChildAdded:Connect(function(item)
    if item:IsA("Tool") and item.Name == "Taschenlampe" then
        item:Destroy()
    end
end)

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

-- Compact stamina display.
local staminaPanel = Instance.new("Frame")
staminaPanel.Name = "StaminaPanel"
staminaPanel.AnchorPoint = Vector2.new(0, 1)
staminaPanel.Position = UDim2.new(0, 24, 1, -24)
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

-- Breathing is deliberately a longer recording, not a tiny clip repeatedly restarted.
local staminaBreathing = Instance.new("Sound")
staminaBreathing.Name = "ExhaustedBreathing"
staminaBreathing.SoundId = "rbxassetid://3725917109"
staminaBreathing.Volume = 0.48
staminaBreathing.PlaybackSpeed = 0.88
staminaBreathing.Looped = true
local breathReverb = Instance.new("ReverbSoundEffect")
breathReverb.DecayTime = 1.7
breathReverb.Density = 0.8
breathReverb.Diffusion = 0.72
breathReverb.DryLevel = 0
breathReverb.WetLevel = -8
breathReverb.Parent = staminaBreathing
staminaBreathing.Parent = gui

local function setBreathing(enabled)
    if enabled then
        if not staminaBreathing.IsPlaying then
            staminaBreathing:Play()
        end
    elseif staminaBreathing.IsPlaying then
        staminaBreathing:Stop()
    end
end

local stamina = MAX_STAMINA
local sprintHeld = false
local exhausted = false
local exhaustedAt = 0
local lastStaminaUse = 0
local stepTimer = 0

local currentCharacter
local currentHumanoid
local rootPart
local concreteStep
local wetStep

local function makeStepSound(parent, name, soundId, volume, playbackSpeed)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = soundId
    sound.Volume = volume
    sound.PlaybackSpeed = playbackSpeed
    sound.Looped = false
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 4
    sound.RollOffMaxDistance = 48

    local reverb = Instance.new("ReverbSoundEffect")
    reverb.DecayTime = 1.15
    reverb.Density = 0.72
    reverb.Diffusion = 0.78
    reverb.DryLevel = 0
    reverb.WetLevel = -10
    reverb.Parent = sound

    sound.Parent = parent
    return sound
end

local function setupCharacter(character)
    currentCharacter = character
    currentHumanoid = character:WaitForChild("Humanoid", 10)
    rootPart = character:WaitForChild("HumanoidRootPart", 10)
    stepTimer = 0

    removeOldFlashlights(character)

    if currentHumanoid then
        currentHumanoid.WalkSpeed = WALK_SPEED
        currentHumanoid.UseJumpPower = true
        -- Players may jump out of the recessed water channel and back onto the walkway.
        currentHumanoid.JumpPower = 40
        currentHumanoid.JumpHeight = 5
        currentHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        currentHumanoid.AutoRotate = true
    end

    -- The built-in Roblox character script creates its own "Running" sound.
    -- Mute standard movement loops so the custom sewer footsteps play alone.
    local function muteDefaultFootstep(instance)
        if not instance:IsA("Sound") then return end
        local name = string.lower(instance.Name)
        if name == "running" or name == "walking" or name == "footsteps" or name == "walk" then
            instance:Stop()
            instance.Volume = 0
            instance:GetPropertyChangedSignal("Volume"):Connect(function()
                if instance.Parent and instance.Volume ~= 0 then
                    instance.Volume = 0
                end
            end)
        end
    end

    for _, descendant in ipairs(character:GetDescendants()) do
        muteDefaultFootstep(descendant)
    end
    character.DescendantAdded:Connect(muteDefaultFootstep)

    if rootPart then
        local oldConcrete = rootPart:FindFirstChild("SewerConcreteFootsteps")
        local oldWet = rootPart:FindFirstChild("SewerWetFootsteps")
        if oldConcrete then oldConcrete:Destroy() end
        if oldWet then oldWet:Destroy() end

        -- Short one-step clips are triggered in time with the character's stride.
        concreteStep = makeStepSound(
            rootPart,
            "SewerConcreteFootsteps",
            "rbxassetid://6362185620",
            0.24,
            0.96
        )
        wetStep = makeStepSound(
            rootPart,
            "SewerWetFootsteps",
            "rbxassetid://9120589946",
            0.23,
            0.92
        )
    end
end

if player.Character then
    task.spawn(setupCharacter, player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

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

local function playFootstep(sprinting)
    if not rootPart or not rootPart.Parent then return end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {currentCharacter}

    rayParams.IgnoreWater = false
    local result = Workspace:Raycast(rootPart.Position, Vector3.new(0, -6, 0), rayParams)
    if not result then return end

    local hitName = string.lower(result.Instance.Name)
    local onWater = result.Material == Enum.Material.Water
        or string.find(hitName, "dirty_water", 1, true) ~= nil

    local sound = onWater and wetStep or concreteStep
    if not sound then return end

    sound.PlaybackSpeed = sprinting and 1.08 or 0.94
    sound.Volume = onWater and 0.28 or 0.25
    sound:Stop()
    sound.TimePosition = 0
    sound:Play()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        sprintHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        sprintHeld = false
    end
end)

RunService:BindToRenderStep("HorrorGamePlayerSystems", Enum.RenderPriority.Camera.Value + 2, function(deltaTime)
    local humanoid = currentHumanoid
    local character = currentCharacter
    local now = os.clock()
    local moving = humanoid ~= nil
        and humanoid.Health > 0
        and humanoid.MoveDirection.Magnitude > 0.05

    local sprinting = sprintHeld and moving and stamina > 0 and not exhausted
    if sprinting then
        stamina = math.max(0, stamina - STAMINA_DRAIN_PER_SECOND * deltaTime)
        lastStaminaUse = now
        if stamina <= 0 then
            stamina = 0
            exhausted = true
            exhaustedAt = now
            sprintHeld = false
            sprinting = false
        end
    elseif not sprintHeld and now - lastStaminaUse >= REGEN_DELAY then
        stamina = math.min(MAX_STAMINA, stamina + STAMINA_REGEN_PER_SECOND * deltaTime)
        if exhausted
            and stamina >= EXHAUSTED_RECOVERY
            and now - exhaustedAt >= MIN_EXHAUSTED_TIME then
            exhausted = false
        end
    end

    if humanoid then
        humanoid.WalkSpeed = sprinting and SPRINT_SPEED or WALK_SPEED
    end

    setBreathing(exhausted)
    updateStaminaBar()

    -- Trigger individual steps at a steady human walking/running cadence.
    if moving then
        stepTimer += deltaTime
        local stepInterval = sprinting and 0.34 or 0.48
        if stepTimer >= stepInterval then
            stepTimer = 0
            playFootstep(sprinting)
        end
    else
        stepTimer = 0
        if concreteStep and concreteStep.IsPlaying then concreteStep:Stop() end
        if wetStep and wetStep.IsPlaying then wetStep:Stop() end
    end

    local camera = Workspace.CurrentCamera
    if camera then
        local breathingPulse = exhausted and ((math.sin(now * 2.5) + 1) * 0.5) or 0
        local targetFov = 70 + (sprinting and 1.5 or 0) - breathingPulse * 1.0
        camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * math.min(deltaTime * 5, 1)
    end
end)

updateStaminaBar()
print("[Horror Game] Player systems ready: no flashlight, custom concrete/water steps, muted default running sound, delayed recovery and longer panting.")

--[[
    HORROR GAME - FIRST PERSON AND FLASHLIGHT INVENTORY
    The flashlight is a real Backpack Tool. Press 1 or G to equip/stow it.
    Press F (or click while equipped) to switch the beam on/off.
]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local backpack = player:WaitForChild("Backpack")

player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMinZoomDistance = 0.5
player.CameraMaxZoomDistance = 0.5
UserInputService.MouseIconEnabled = false

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
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

local status = Instance.new("TextLabel")
status.Name = "FlashlightStatus"
status.AnchorPoint = Vector2.new(0, 1)
status.Position = UDim2.new(0, 24, 1, -22)
status.Size = UDim2.fromOffset(360, 25)
status.BackgroundTransparency = 1
status.Text = "TASCHENLAMPE WIRD GELADEN ..."
status.TextColor3 = Color3.fromRGB(218, 227, 214)
status.TextSize = 13
status.Font = Enum.Font.GothamMedium
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = gui

local flashlightTool
local equipped = false
local lightOn = true
local viewModel
local spotLight
local fillLight
local lens
local boundTools = {}

local function makeViewPart(parent, name, size, color, material)
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

    local body = makeViewPart(viewModel, "Flashlight_Body", Vector3.new(0.25, 0.25, 0.66), Color3.fromRGB(32, 38, 35), Enum.Material.Metal)
    local grip = makeViewPart(viewModel, "Flashlight_Grip", Vector3.new(0.20, 0.29, 0.3), Color3.fromRGB(20, 24, 22), Enum.Material.Rubber)
    local head = makeViewPart(viewModel, "Flashlight_Head", Vector3.new(0.35, 0.35, 0.2), Color3.fromRGB(73, 80, 72), Enum.Material.Metal)
    lens = makeViewPart(viewModel, "Flashlight_Lens", Vector3.new(0.245, 0.245, 0.035), Color3.fromRGB(238, 245, 218), Enum.Material.Neon)

    local beamAttachment = Instance.new("Attachment")
    beamAttachment.Name = "BeamDirection"
    beamAttachment.Parent = lens

    spotLight = Instance.new("SpotLight")
    spotLight.Name = "Flashlight_Main_Beam"
    spotLight.Angle = 78
    spotLight.Brightness = 9
    spotLight.Range = 95
    spotLight.Shadows = false
    spotLight.Color = Color3.fromRGB(244, 247, 225)
    spotLight.Enabled = lightOn
    spotLight.Parent = beamAttachment

    -- A soft nearby fill prevents the beam from looking weak when aiming down
    -- at the floor or close objects. The SpotLight still provides the main beam.
    fillLight = Instance.new("PointLight")
    fillLight.Name = "Flashlight_Near_Fill"
    fillLight.Brightness = 1.65
    fillLight.Range = 24
    fillLight.Shadows = false
    fillLight.Color = Color3.fromRGB(232, 238, 215)
    fillLight.Enabled = lightOn
    fillLight.Parent = beamAttachment

    viewModel:SetAttribute("PartsReady", true)
    viewModel.PrimaryPart = body
end

local function updateLightState()
    if spotLight then spotLight.Enabled = equipped and lightOn end
    if fillLight then fillLight.Enabled = equipped and lightOn end
    if lens then
        lens.Material = (equipped and lightOn) and Enum.Material.Neon or Enum.Material.Glass
        lens.Color = (equipped and lightOn) and Color3.fromRGB(238, 245, 218) or Color3.fromRGB(65, 70, 65)
    end

    if not flashlightTool then
        status.Text = "TASCHENLAMPE NICHT GEFUNDEN"
    elseif equipped then
        status.Text = lightOn and "TASCHENLAMPE  •  F LICHT AUS  •  G WEGSTECKEN" or "TASCHENLAMPE  •  F LICHT AN  •  G WEGSTECKEN"
    else
        status.Text = "TASCHENLAMPE IM INVENTAR  •  G HERVORHOLEN"
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
        humanoid.WalkSpeed = 12
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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F then
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

RunService:BindToRenderStep("HorrorFlashlightViewModel", Enum.RenderPriority.Camera.Value + 1, function()
    if not equipped or not viewModel then return end

    local camera = Workspace.CurrentCamera
    if not camera then return end
    if viewModel.Parent ~= camera then
        viewModel.Parent = camera
    end

    local base = camera.CFrame
        * CFrame.new(0.48, -0.34, -0.88)
        * CFrame.Angles(math.rad(-4), math.rad(-7), math.rad(-9))

    local body = viewModel:FindFirstChild("Flashlight_Body")
    local grip = viewModel:FindFirstChild("Flashlight_Grip")
    local head = viewModel:FindFirstChild("Flashlight_Head")
    if body and grip and head and lens then
        body.CFrame = base
        grip.CFrame = base * CFrame.new(0, -0.13, 0.12)
        head.CFrame = base * CFrame.new(0, 0, -0.34)
        lens.CFrame = base * CFrame.new(0, 0, -0.445)
    end
end)

backpack.ChildAdded:Connect(function(child)
    if child.Name == "Taschenlampe" then
        task.defer(function()
            bindTool(child)
            updateLightState()
        end)
    end
end)

findTool()
updateLightState()

print("[Horror Game] Flashlight inventory ready: 1/G equip or stow, F toggles beam.")

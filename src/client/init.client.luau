--[[
    HORROR GAME - FIRST-PERSON CONTROLS
    A visible first-person flashlight starts on and toggles with F.
]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMinZoomDistance = 0.5
player.CameraMaxZoomDistance = 0.5
UserInputService.MouseIconEnabled = false

-- Clean up a previous copy if Studio restarts the LocalScript.
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
dot.BackgroundColor3 = Color3.fromRGB(235, 240, 232)
dot.BackgroundTransparency = 0.04
dot.BorderSizePixel = 0
dot.Parent = gui

local round = Instance.new("UICorner")
round.CornerRadius = UDim.new(1, 0)
round.Parent = dot

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(19, 24, 22)
outline.Thickness = 1
outline.Parent = dot

local hint = Instance.new("TextLabel")
hint.Name = "FlashlightHint"
hint.AnchorPoint = Vector2.new(0, 1)
hint.Position = UDim2.new(0, 25, 1, -24)
hint.Size = UDim2.fromOffset(220, 25)
hint.BackgroundTransparency = 1
hint.Text = "F   TASCHENLAMPE  •  AN"
hint.TextColor3 = Color3.fromRGB(210, 220, 211)
hint.TextTransparency = 0.08
hint.TextSize = 14
hint.Font = Enum.Font.GothamMedium
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = gui

local flashlightOn = true
local flashlightModel
local flashlightLight
local flashlightLens
local attachedCamera

local function makeViewPart(name, size, color, material)
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
    item.Parent = flashlightModel
    return item
end

local function attachFlashlight(camera)
    if flashlightModel then
        flashlightModel:Destroy()
        flashlightModel = nil
    end

    if not camera then return end

    flashlightModel = Instance.new("Model")
    flashlightModel.Name = "FirstPersonFlashlight"
    flashlightModel.Parent = camera
    attachedCamera = camera

    local body = makeViewPart("Flashlight_Body", Vector3.new(0.22, 0.22, 0.62), Color3.fromRGB(32, 38, 35), Enum.Material.Metal)
    local grip = makeViewPart("Flashlight_Grip", Vector3.new(0.19, 0.27, 0.28), Color3.fromRGB(21, 25, 23), Enum.Material.Rubber)
    local head = makeViewPart("Flashlight_Head", Vector3.new(0.31, 0.31, 0.18), Color3.fromRGB(58, 64, 59), Enum.Material.Metal)
    flashlightLens = makeViewPart("Flashlight_Lens", Vector3.new(0.22, 0.22, 0.025), Color3.fromRGB(225, 235, 207), Enum.Material.Neon)

    flashlightLight = Instance.new("SpotLight")
    flashlightLight.Name = "Flashlight_Beam"
    flashlightLight.Face = Enum.NormalId.Front
    flashlightLight.Angle = 58
    flashlightLight.Brightness = 4.2
    flashlightLight.Range = 58
    flashlightLight.Shadows = true
    flashlightLight.Color = Color3.fromRGB(225, 235, 213)
    flashlightLight.Enabled = flashlightOn
    flashlightLight.Parent = flashlightLens

    -- Parts are positioned every frame relative to the camera, so the beam
    -- follows the exact direction the player is looking.
    local function update()
        if not camera or not flashlightModel or flashlightModel.Parent ~= camera then return end
        local base = camera.CFrame * CFrame.new(0.43, -0.36, -0.88) * CFrame.Angles(math.rad(-5), math.rad(-7), math.rad(-8))
        body.CFrame = base
        grip.CFrame = base * CFrame.new(0, -0.12, 0.12)
        head.CFrame = base * CFrame.new(0, 0, -0.32)
        flashlightLens.CFrame = base * CFrame.new(0, 0, -0.415)
    end

    update()
end

local function updateFlashlightState()
    if flashlightLight then
        flashlightLight.Enabled = flashlightOn
    end
    if flashlightLens then
        flashlightLens.Material = flashlightOn and Enum.Material.Neon or Enum.Material.Glass
        flashlightLens.Color = flashlightOn and Color3.fromRGB(225, 235, 207) or Color3.fromRGB(62, 68, 61)
    end
    hint.Text = flashlightOn and "F   TASCHENLAMPE  •  AN" or "F   TASCHENLAMPE  •  AUS"
    hint.TextColor3 = flashlightOn and Color3.fromRGB(210, 220, 211) or Color3.fromRGB(140, 148, 141)
end

local function configureCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.WalkSpeed = 12
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 36
        humanoid.AutoRotate = true
    end
end

if player.Character then
    configureCharacter(player.Character)
end
player.CharacterAdded:Connect(configureCharacter)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        flashlightOn = not flashlightOn
        updateFlashlightState()
    end
end)

RunService:BindToRenderStep("HorrorFlashlightFollow", Enum.RenderPriority.Camera.Value + 1, function()
    local camera = Workspace.CurrentCamera
    if camera and camera ~= attachedCamera then
        attachFlashlight(camera)
        updateFlashlightState()
    end
    if flashlightModel and camera == attachedCamera then
        local body = flashlightModel:FindFirstChild("Flashlight_Body")
        local grip = flashlightModel:FindFirstChild("Flashlight_Grip")
        local head = flashlightModel:FindFirstChild("Flashlight_Head")
        if body and grip and head and flashlightLens then
            local base = camera.CFrame * CFrame.new(0.43, -0.36, -0.88) * CFrame.Angles(math.rad(-5), math.rad(-7), math.rad(-8))
            body.CFrame = base
            grip.CFrame = base * CFrame.new(0, -0.12, 0.12)
            head.CFrame = base * CFrame.new(0, 0, -0.32)
            flashlightLens.CFrame = base * CFrame.new(0, 0, -0.415)
        end
    end
end)

if Workspace.CurrentCamera then
    attachFlashlight(Workspace.CurrentCamera)
end
updateFlashlightState()

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
end)

print("[Horror Game] First-person controls and flashlight ready. Press F to toggle.")

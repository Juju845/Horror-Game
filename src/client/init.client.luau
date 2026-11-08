--[[
    HORROR GAME - PLAYER CONTROLS
    Locked first-person camera, a minimal centre-dot reticle and a toggleable flashlight.
]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMinZoomDistance = 0.5
player.CameraMaxZoomDistance = 0.5
UserInputService.MouseIconEnabled = false

-- Minimal aiming dot, instead of the default mouse pointer.
local oldReticle = playerGui:FindFirstChild("HorrorReticle")
if oldReticle then
    oldReticle:Destroy()
end

local reticleGui = Instance.new("ScreenGui")
reticleGui.Name = "HorrorReticle"
reticleGui.IgnoreGuiInset = true
reticleGui.ResetOnSpawn = false
reticleGui.DisplayOrder = 20
reticleGui.Parent = playerGui

local dot = Instance.new("Frame")
dot.Name = "CenterDot"
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(5, 5)
dot.BackgroundColor3 = Color3.fromRGB(235, 240, 232)
dot.BackgroundTransparency = 0.08
dot.BorderSizePixel = 0
dot.Parent = reticleGui

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

local dotOutline = Instance.new("UIStroke")
dotOutline.Color = Color3.fromRGB(20, 25, 23)
dotOutline.Thickness = 1
dotOutline.Transparency = 0.2
dotOutline.Parent = dot

local function configureCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local head = character:WaitForChild("Head", 10)
    if humanoid then
        humanoid.WalkSpeed = 12
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 38
        humanoid.AutoRotate = true
    end

    if not head then return end

    local oldLight = head:FindFirstChild("PlayerFlashlight")
    if oldLight then
        oldLight:Destroy()
    end

    local flashlight = Instance.new("SpotLight")
    flashlight.Name = "PlayerFlashlight"
    flashlight.Enabled = false
    flashlight.Angle = 72
    flashlight.Brightness = 2.2
    flashlight.Range = 34
    flashlight.Shadows = true
    flashlight.Color = Color3.fromRGB(220, 231, 222)
    flashlight.Face = Enum.NormalId.Front
    flashlight.Parent = head
end

if player.Character then
    configureCharacter(player.Character)
end
player.CharacterAdded:Connect(configureCharacter)

local flashlightOn = false
local function setFlashlight(enabled)
    flashlightOn = enabled
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    local flashlight = head and head:FindFirstChild("PlayerFlashlight")
    if flashlight and flashlight:IsA("SpotLight") then
        flashlight.Enabled = flashlightOn
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        setFlashlight(not flashlightOn)
    end
end)

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
end)

print("[Horror Game] First-person controls, centre dot and flashlight loaded. Press F to toggle the flashlight.")

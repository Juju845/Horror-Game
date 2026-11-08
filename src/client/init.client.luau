--[[
    HORROR GAME - PLAYER SETUP
    First-person camera and restrained movement settings for the prototype.
]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMinZoomDistance = 0.5
player.CameraMaxZoomDistance = 0.5

local function configureCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end

    humanoid.WalkSpeed = 12
    humanoid.JumpPower = 38
    humanoid.AutoRotate = true
end

if player.Character then
    configureCharacter(player.Character)
end

player.CharacterAdded:Connect(configureCharacter)

-- Keep the standard Roblox controls for now; a custom horror HUD will replace
-- them only after the core movement and interaction systems are in place.
pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
end)

print("[Horror Game] First-person player setup loaded.")

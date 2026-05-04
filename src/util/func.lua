local plrs = game:GetService("Players")
local lplr = plrs.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local GetMouseLocation = UserInputService.GetMouseLocation

local functions = {}

functions.GetScreenPosition = function(Vector)
    local Camera = workspace.CurrentCamera
    if not Camera then return Vector2.new(0, 0), false end
    
    local Vec3, OnScreen = Camera:WorldToViewportPoint(Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

functions.IsTool = function(Tool)
    return Tool:IsA("Tool")
end

functions.IsAlive = function(Plr)
    return Plr.Character and Plr.Character:FindFirstChild("Humanoid") and Plr.Character.Humanoid.Health > 0
end

functions.TeamCheck = function(Plr)
    if not Plr or not lplr then return true end
    return Plr.Team ~= lplr.Team
end

functions.GetMousePosition = function()
    return GetMouseLocation(UserInputService)
end

functions.GetGun = function()
    local Character = lplr.Character
    if not Character then return end
    for _, v in ipairs(Character:GetChildren()) do
        if v:IsA("Tool") then
            return v
        end
    end
end

functions.HitChance = function(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end

functions.Direction = function(Origin, Pos)
    return (Pos - Origin).Unit * 1000
end

return functions

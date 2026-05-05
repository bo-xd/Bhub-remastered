local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GITHUB_TOKEN = "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"
local REPO = "bo-xd/Bhub-remastered"
local BRANCH = "main"

local function loadFile(path)
    if isfile and readfile then
        local localPath = "Bhub-remastered/" .. path
        if isfile(localPath) then
            local ok, res = pcall(function() return loadstring(readfile(localPath))() end)
            if ok and res then return res end
        end
    end
    local url = string.format("https://raw.githubusercontent.com/%s/%s/%s", REPO, BRANCH, path)
    local req = (http and http.request) or http_request or request
    if req then
        local response = req({ Url = url, Method = "GET", Headers = { ["Authorization"] = "token " .. GITHUB_TOKEN, ["Accept"] = "application/vnd.github.v3.raw" } })
        if response.Success then
            local ok, res = pcall(function() return loadstring(response.Body)() end)
            if ok and res then return res end
        end
    end
    return nil
end

local Library = loadFile("src/util/DrawingUILib.lua")
local Window = Library:CreateWindow({ Title = 'BHub Remastered' })
local ESP = loadFile("src/util/Esp.lua")

local supportedGames = {
    [131756752872026] = "src/games/divedown.lua",
    [126509999114328] = "src/games/99nights.lua"
}
local gamePath = supportedGames[game.PlaceId]
if gamePath then
    local gameScript = loadFile(gamePath)
    if gameScript then task.spawn(function() gameScript(Window, ESP, Library) end) end
end

local Tabs = {
    Universal = Window:AddTab('Universal'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local EspGroup = Tabs.Universal:AddLeftGroupbox('Universal ESP')
EspGroup:AddToggle('EspEnable',   { Text = 'Enable ESP',      Default = false, Callback = function(v) ESP.Enabled     = v end })
EspGroup:AddToggle('EspBoxes',    { Text = 'Show Boxes',      Default = true,  Callback = function(v) ESP.ShowBoxes   = v end }):AddColorPicker('BoxColor',  { Default = Color3.new(1,1,1), Title = 'Box Color',  Callback = function(v) ESP.BoxColor  = v end })
EspGroup:AddToggle('EspNames',    { Text = 'Show Names',      Default = true,  Callback = function(v) ESP.ShowNames   = v end }):AddColorPicker('TextColor', { Default = Color3.new(1,1,1), Title = 'Text Color', Callback = function(v) ESP.TextColor = v end })
EspGroup:AddToggle('EspDistance', { Text = 'Show Distance',   Default = true,  Callback = function(v) ESP.ShowDistance = v end })
EspGroup:AddToggle('EspHealth',   { Text = 'Show Health Bar', Default = true,  Callback = function(v) ESP.ShowHealth  = v end })
EspGroup:AddToggle('EspTracers',  { Text = 'Show Tracers',    Default = false, Callback = function(v) ESP.ShowTracers = v end })

local CharGroup = Tabs.Universal:AddRightGroupbox('Character')
local wsVal, jpVal = 16, 50
CharGroup:AddSlider('WalkSpeed', { Text = 'WalkSpeed', Min = 16, Max = 250, Default = 16, Rounding = 0, Callback = function(v) wsVal = v end })
CharGroup:AddSlider('JumpPower', { Text = 'JumpPower', Min = 50, Max = 500, Default = 50, Rounding = 0, Callback = function(v) jpVal = v end })

local infJump = false
CharGroup:AddToggle('InfJump', { Text = 'Infinite Jump', Default = false, Callback = function(v) infJump = v end })

UserInputService.JumpRequest:Connect(function()
    if infJump then pcall(function() plr.Character.Humanoid:ChangeState("Jumping") end) end
end)

-- Optimized Heartbeat: Only sets values if they differ from target
RunService.Heartbeat:Connect(function()
    local char = plr.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        if hum.WalkSpeed ~= wsVal then hum.WalkSpeed = wsVal end
        if hum.JumpPower ~= jpVal then hum.JumpPower = jpVal end
        hum.UseJumpPower = true
    end
end)

local function setupPlayer(p)
    local function add(char)
        task.delay(0.5, function()
            if char and char.Parent then
                ESP:Add(char, {
                    Name = p.Name,
                    IsEnabled = function()
                        local hum = char:FindFirstChild("Humanoid")
                        return ESP.Enabled and p.Character == char and hum and hum.Health > 0
                    end
                })
            end
        end)
    end
    p.CharacterAdded:Connect(add)
    if p.Character then add(p.Character) end
end

for _, p in pairs(plrs:GetPlayers()) do if p ~= plr then setupPlayer(p) end end
plrs.PlayerAdded:Connect(setupPlayer)
plrs.PlayerRemoving:Connect(function(p) if p.Character then ESP:Remove(p.Character) end end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
local AppearanceGroup = Tabs['UI Settings']:AddRightGroupbox('Appearance')
local uc = false
MenuGroup:AddButton({ Text = 'Unload', Func = function()
    if uc then
        ESP:Unload()
        Library:Unload()
    else
        uc = true
        Library:Notify("Press again to confirm unload", 3)
        task.delay(3, function() uc = false end)
    end
end })

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Delete then
        Window:SetVisible(not Window.Visible)
    end
end)
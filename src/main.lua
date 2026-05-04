local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local mouse = plr:GetMouse()
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Window = Library:CreateWindow({
    Title = 'BHub Remastered',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local GITHUB_TOKEN = "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"
local REPO = "bo-xd/Bhub-remastered"
local BRANCH = "main"

local function loadFile(path)
    if isfile and readfile then
        local localPath = "Bhub-remastered/" .. path
        if isfile(localPath) then
            local success, result = pcall(function() return loadstring(readfile(localPath))() end)
            if success and result then return result end
        end
    end
    local url = string.format("https://raw.githubusercontent.com/%s/%s/%s", REPO, BRANCH, path)
    local req = (http and http.request) or http_request or request
    if req then
        local response = req({ Url = url, Method = "GET", Headers = { ["Authorization"] = "token " .. GITHUB_TOKEN, ["Accept"] = "application/vnd.github.v3.raw" } })
        if response.Success then
            local success, result = pcall(function() return loadstring(response.Body)() end)
            if success and result then return result end
        end
    end
    return nil
end

local ESP = loadFile("src/util/Esp.lua")

local supportedGames = { [131756752872026] = "src/games/divedown.lua" }
local gamePath = supportedGames[game.PlaceId]
if gamePath then
    local gameScript = loadFile(gamePath)
    if gameScript then task.spawn(function() gameScript(Window, ESP, Library) end) end
end
task.wait(0.2)

local Tabs = {
    Universal = Window:AddTab('Universal'),
    Visuals = Window:AddTab('Visuals'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local EspGroup = Tabs.Universal:AddLeftGroupbox('Universal ESP')
EspGroup:AddToggle('EspEnable', { Text = 'Enable ESP', Default = false, Callback = function(v) ESP.Enabled = v end })
EspGroup:AddToggle('EspBoxes', { Text = 'Show Boxes', Default = true, Callback = function(v) ESP.ShowBoxes = v end }):AddColorPicker('BoxColorPicker', { Default = Color3.new(1,1,1), Title = 'Box Color', Callback = function(v) ESP.BoxColor = v end })
EspGroup:AddToggle('EspNames', { Text = 'Show Names', Default = true, Callback = function(v) ESP.ShowNames = v end }):AddColorPicker('TextColorPicker', { Default = Color3.new(1,1,1), Title = 'Text Color', Callback = function(v) ESP.TextColor = v end })
EspGroup:AddToggle('EspDistance', { Text = 'Show Distance', Default = true, Callback = function(v) ESP.ShowDistance = v end })
EspGroup:AddToggle('EspHealth', { Text = 'Show Health Bar', Default = true, Callback = function(v) ESP.ShowHealth = v end })

local CharGroup = Tabs.Universal:AddRightGroupbox('Character')
local wsVal, jpVal = 16, 50
CharGroup:AddSlider('WalkSpeed', { Text = 'WalkSpeed', Min = 16, Max = 250, Default = 16, Rounding = 0, Callback = function(v) wsVal = v end })
CharGroup:AddSlider('JumpPower', { Text = 'JumpPower', Min = 50, Max = 500, Default = 50, Rounding = 0, Callback = function(v) jpVal = v end })

local infJump = false
CharGroup:AddToggle('InfJump', { Text = 'Infinite Jump', Default = false, Callback = function(v) infJump = v end })
game:GetService("UserInputService").JumpRequest:Connect(function() if infJump then pcall(function() plr.Character.Humanoid:ChangeState("Jumping") end) end end)

local noclip = false
CharGroup:AddToggle('Noclip', { Text = 'Noclip', Default = false, Callback = function(v) noclip = v end })
RunService.Stepped:Connect(function()
    pcall(function()
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.WalkSpeed = wsVal
            plr.Character.Humanoid.JumpPower = jpVal
            plr.Character.Humanoid.UseJumpPower = true
        end
        if noclip and plr.Character then
            for _, v in pairs(plr.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        end
    end)
end)

local function setupPlayer(p)
    local function add(char)
        task.delay(0.5, function()
            if char and char.Parent then
                ESP:Add(char, { Name = p.Name, IsEnabled = function() return ESP.Enabled and p.Character == char and (p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0) end })
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
local uc = false
MenuGroup:AddButton({ Text = 'Unload', Func = function() if uc then ESP:Unload() Library:Unload() else uc = true Library:Notify("Press again to confirm unload", 3) task.delay(3, function() uc = false end) end end })
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'Delete', NoUI = true, Text = 'Menu keybind' })
task.spawn(function() while not Options.MenuKeybind do task.wait() end Library.ToggleKeybind = Options.MenuKeybind end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder('BHubRemastered')
SaveManager:SetFolder('BHubRemastered/Games')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

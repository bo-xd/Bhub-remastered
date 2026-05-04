local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'BHub Remastered | ESP Test',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab('Main'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local LeftGroupBox = Tabs.Main:AddLeftGroupbox('ESP Settings')

local GITHUB_TOKEN = "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"
local REPO = "bo-xd/Bhub-remastered"
local BRANCH = "main"

local function loadFile(path)
    if isfile and readfile then
        local localPath = "Bhub-remastered/" .. path
        if isfile(localPath) then
            local success, result = pcall(function()
                return loadstring(readfile(localPath))()
            end)
            if success and result then return result end
        end
    end

    local url = string.format("https://raw.githubusercontent.com/%s/%s/%s", REPO, BRANCH, path)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    
    if req then
        local response = req({
            Url = url,
            Method = "GET",
            Headers = {
                ["Authorization"] = "token " .. GITHUB_TOKEN,
                ["Accept"] = "application/vnd.github.v3.raw"
            }
        })
        
        if response.Success then
            local success, result = pcall(function()
                return loadstring(response.Body)()
            end)
            if success and result then return result end
        end
    end
    
    warn("Failed to load: " .. path)
    return nil
end

local ESP = loadFile("src/util/Esp.lua")

LeftGroupBox:AddToggle('EspEnable', {
    Text = 'Enable ESP',
    Default = false,
    Tooltip = 'Toggles the master ESP switch',
    Callback = function(Value)
        ESP.Enabled = Value
    end
})

LeftGroupBox:AddToggle('EspBoxes', {
    Text = 'Show Boxes',
    Default = true,
    Callback = function(Value)
        ESP.ShowBoxes = Value
    end
}):AddColorPicker('BoxColorPicker', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Box Color',
    Callback = function(Value)
        ESP.BoxColor = Value
    end
})

LeftGroupBox:AddToggle('EspNames', {
    Text = 'Show Names',
    Default = true,
    Callback = function(Value)
        ESP.ShowNames = Value
    end
}):AddColorPicker('TextColorPicker', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Text Color',
    Callback = function(Value)
        ESP.TextColor = Value
    end
})

LeftGroupBox:AddToggle('EspDistance', {
    Text = 'Show Distance',
    Default = true,
    Callback = function(Value)
        ESP.ShowDistance = Value
    end
})

LeftGroupBox:AddToggle('EspHealth', {
    Text = 'Show Health Bar',
    Default = true,
    Callback = function(Value)
        ESP.ShowHealth = Value
    end
})

local TracerGroupBox = Tabs.Main:AddRightGroupbox('Tracer Settings')

TracerGroupBox:AddToggle('EspTracers', {
    Text = 'Show Tracers',
    Default = false,
    Callback = function(Value)
        ESP.ShowTracers = Value
    end
}):AddColorPicker('TracerColorPicker', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Tracer Color',
    Callback = function(Value)
        ESP.TracerColor = Value
    end
})

TracerGroupBox:AddDropdown('TracerOrigin', {
    Values = { 'Top', 'Middle', 'Bottom', 'Mouse' },
    Default = 3,
    Multi = false,
    Text = 'Tracer Position',
    Callback = function(Value)
        ESP.TracerOrigin = Value
    end
})

local function setupPlayer(plr)
    plr.CharacterAdded:Connect(function(char)
        task.delay(0.5, function()
            ESP:Add(char, {
                Name = plr.Name,
                Player = plr,
                IsEnabled = function()
                    return plr.Character == char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
                end
            })
        end)
    end)
    
    if plr.Character then
        ESP:Add(plr.Character, {
            Name = plr.Name,
            Player = plr,
            IsEnabled = function()
                return plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0
            end
        })
    end
end

for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
    if plr ~= game:GetService("Players").LocalPlayer then
        setupPlayer(plr)
    end
end

game:GetService("Players").PlayerAdded:Connect(function(plr)
    setupPlayer(plr)
end)

game:GetService("Players").PlayerRemoving:Connect(function(plr)
    if plr.Character then
        ESP:Remove(plr.Character)
    end
end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() 
    ESP:Unload()
    Library:Unload() 
end)

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('BHubRemastered')
SaveManager:SetFolder('BHubRemastered/Games')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

SaveManager:LoadAutoloadConfig()

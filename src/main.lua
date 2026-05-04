local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

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
            local success, result = pcall(function()
                return loadstring(readfile(localPath))()
            end)
            if success and result then return result end
        end
    end

    local url = string.format("https://raw.githubusercontent.com/%s/%s/%s", REPO, BRANCH, path)
    local req = (http and http.request) or http_request or request
    
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
    return nil
end

local ESP = loadFile("src/util/Esp.lua")

local supportedGames = {
    [131756752872026] = "src/games/divedown.lua",
}

local gamePath = supportedGames[game.PlaceId]
if gamePath then
    local gameScript = loadFile(gamePath)
    if gameScript then
        pcall(function()
            gameScript(Window, {}, ESP)
        end)
    end
end

local Tabs = {
    Main = Window:AddTab('Universal'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local EspGroup = Tabs.Main:AddLeftGroupbox('Universal ESP')
EspGroup:AddToggle('EspEnable', { Text = 'Enable ESP', Default = false, Callback = function(v) ESP.Enabled = v end })
EspGroup:AddToggle('EspBoxes', { Text = 'Show Boxes', Default = true, Callback = function(v) ESP.ShowBoxes = v end }):AddColorPicker('BoxColorPicker', { Default = Color3.new(1,1,1), Title = 'Box Color', Callback = function(v) ESP.BoxColor = v end })
EspGroup:AddToggle('EspNames', { Text = 'Show Names', Default = true, Callback = function(v) ESP.ShowNames = v end }):AddColorPicker('TextColorPicker', { Default = Color3.new(1,1,1), Title = 'Text Color', Callback = function(v) ESP.TextColor = v end })
EspGroup:AddToggle('EspDistance', { Text = 'Show Distance', Default = true, Callback = function(v) ESP.ShowDistance = v end })
EspGroup:AddToggle('EspHealth', { Text = 'Show Health Bar', Default = true, Callback = function(v) ESP.ShowHealth = v end })

local TracerGroup = Tabs.Main:AddRightGroupbox('Universal Tracers')
TracerGroup:AddToggle('EspTracers', { Text = 'Show Tracers', Default = false, Callback = function(v) ESP.ShowTracers = v end }):AddColorPicker('TracerColorPicker', { Default = Color3.new(1,1,1), Title = 'Tracer Color', Callback = function(v) ESP.TracerColor = v end })
TracerGroup:AddDropdown('TracerOrigin', { Values = { 'Top', 'Middle', 'Bottom', 'Mouse' }, Default = 3, Multi = false, Text = 'Tracer Position', Callback = function(v) ESP.TracerOrigin = v end })

local function setupPlayer(plr)
    local function add(char)
        task.delay(0.5, function()
            if char and char.Parent then
                ESP:Add(char, {
                    Name = plr.Name,
                    IsEnabled = function() return plr.Character == char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 end
                })
            end
        end)
    end
    plr.CharacterAdded:Connect(add)
    if plr.Character then add(plr.Character) end
end

for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
    if plr ~= game:GetService("Players").LocalPlayer then setupPlayer(plr) end
end
game:GetService("Players").PlayerAdded:Connect(setupPlayer)
game:GetService("Players").PlayerRemoving:Connect(function(plr) if plr.Character then ESP:Remove(plr.Character) end end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
local unloadConfirm = false
MenuGroup:AddButton({
    Text = 'Unload',
    Func = function() 
        if unloadConfirm then
            ESP:Unload()
            Library:Unload()
        else
            unloadConfirm = true
            Library:Notify("Press again to confirm unload", 3)
            task.delay(3, function() unloadConfirm = false end)
        end
    end
})

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'Delete', NoUI = true, Text = 'Menu keybind' })
task.spawn(function()
    while not Options.MenuKeybind do task.wait() end
    Library.ToggleKeybind = Options.MenuKeybind
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('BHubRemastered')
SaveManager:SetFolder('BHubRemastered/Games')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

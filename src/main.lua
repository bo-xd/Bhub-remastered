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
    -- Try local first (dev mode)
    if isfile and readfile then
        local localPath = "Bhub-remastered/" .. path
        if isfile(localPath) then
            local success, result = pcall(function()
                return loadstring(readfile(localPath))()
            end)
            if success and result then return result end
        end
    end

    -- Fallback to Private GitHub
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
})

LeftGroupBox:AddToggle('EspNames', {
    Text = 'Show Names',
    Default = true,
    Callback = function(Value)
        ESP.ShowNames = Value
    end
})

LeftGroupBox:AddToggle('EspDistance', {
    Text = 'Show Distance',
    Default = true,
    Callback = function(Value)
        ESP.ShowDistance = Value
    end
})

LeftGroupBox:AddToggle('EspTracers', {
    Text = 'Show Tracers',
    Default = false,
    Callback = function(Value)
        ESP.ShowTracers = Value
    end
})

LeftGroupBox:AddToggle('EspHealth', {
    Text = 'Show Health Bar',
    Default = true,
    Callback = function(Value)
        ESP.ShowHealth = Value
    end
})

LeftGroupBox:AddLabel('Box Color'):AddColorPicker('BoxColorPicker', {
    Default = Color3.fromRGB(255, 0, 0), -- Default red for bots
    Title = 'Box Color',
    Callback = function(Value)
        ESP.BoxColor = Value
    end
})

LeftGroupBox:AddLabel('Text Color'):AddColorPicker('TextColorPicker', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Text Color',
    Callback = function(Value)
        ESP.TextColor = Value
    end
})

-- Setup the Bots
local function setupBot(bot)
    if bot:IsA("Model") then
        ESP:Add(bot, {
            Name = bot.Name,
            -- We don't need to specify color here if we want it to dynamically follow the ESP.BoxColor
            -- However, if you want each bot to have a fixed color, you can set `Color = Color3.fromRGB(255, 0, 0)`
            IsEnabled = function() 
                -- Example check: Only show if the bot is alive
                local hum = bot:FindFirstChild("Humanoid")
                return hum and hum.Health > 0 or not hum
            end
        })
    end
end

-- Initialize existing bots in workspace.Bots
if workspace:FindFirstChild("Bots") then
    for _, bot in ipairs(workspace.Bots:GetChildren()) do
        setupBot(bot)
    end
    
    -- Listen for new bots added to the folder
    workspace.Bots.ChildAdded:Connect(function(child)
        -- Short yield to ensure the bot's parts are fully loaded
        task.delay(0.1, function()
            setupBot(child)
        end)
    end)
else
    warn("Could not find workspace.Bots!")
end

-- UI Settings logic
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

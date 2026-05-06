local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local REPO = "bo-xd/Bhub-remastered"
local BRANCH = "main"

local function hasDrawingSupport()
    if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then
        return false
    end
    local ok, probe = pcall(function()
        local p = Drawing.new("Square")
        if p and p.Remove then
            p:Remove()
        end
        return true
    end)
    return ok and probe == true
end

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
        local headers = { ["Accept"] = "application/vnd.github.v3.raw" }
        local response = req({ Url = url, Method = "GET", Headers = headers })
        if response.Success then
            local ok, res = pcall(function() return loadstring(response.Body)() end)
            if ok and res then return res end
        end
    end
    return nil
end

local useDrawing = hasDrawingSupport()
local uiPath = useDrawing and "src/util/DrawingUILib.lua" or "src/util/NormalUILib.lua"
local Library = loadFile(uiPath)
if not Library and useDrawing then
    useDrawing = false
    uiPath = "src/util/NormalUILib.lua"
    Library = loadFile(uiPath)
end
if not Library then
    return warn("[BHub] Failed to load UI library")
end
local Loader = Library:CreateLoader({ Title = 'BHub Remastered', Subtitle = 'Starting up' })
Loader:SetStage('Loading UI library', 0.15)
local ESP = loadFile("src/util/Esp.lua")
if not ESP then
    return warn("[BHub] Failed to load ESP module")
end
Loader:SetStage('Preparing themes', 0.35)

Loader:SetStage('Building interface', 0.75)
local Window = Library:CreateWindow({ Title = 'BHub Remastered' })

local supportedGames = {
    [9872472334] = "src/games/evade.lua",
    [131756752872026] = "src/games/divedown.lua",
}
local gamePath = supportedGames[game.PlaceId]
if gamePath then
    local gameScript = loadFile(gamePath)
    Loader:SetStage('Preparing game module', 0.55)
    if gameScript then task.spawn(function() gameScript(Window, ESP, Library) end) end
end

local Tabs = {
    Universal = Window:AddTab('Universal'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local CommandPalette = Library:CreateCommandPalette({ Title = 'Quick Actions' })

local themeNames = Library:GetThemeNames()
local themeIndex = 1
local ThemePicker
for i, name in ipairs(themeNames) do
    if name == Library.CurrentThemeName then
        themeIndex = i
        break
    end
end

local function applyThemeByIndex(delta)
    if #themeNames == 0 then return end
    themeIndex = ((themeIndex - 1 + delta) % #themeNames) + 1
    local themeName = themeNames[themeIndex]
    Library:SetTheme(themeName)
    if ThemePicker and ThemePicker.SetValue then
        ThemePicker:SetValue(themeName)
    end
    Library:Notify('Theme: ' .. themeName, 2)
end

local EspGroup = Tabs.Universal:AddLeftGroupbox('Universal ESP')
EspGroup:AddToggle('EspEnable',   { Text = 'Enable ESP',      Default = false, Callback = function(v) ESP.Enabled     = v end })
EspGroup:AddToggle('EspBoxes',    { Text = 'Show Boxes',      Default = true,  Callback = function(v) ESP.ShowBoxes   = v end }):AddColorPicker('BoxColor',  { Default = Color3.new(1,1,1), Title = 'Box Color',  Callback = function(v) ESP.BoxColor  = v end })
EspGroup:AddToggle('EspNames',    { Text = 'Show Names',      Default = true,  Callback = function(v) ESP.ShowNames   = v end }):AddColorPicker('TextColor', { Default = Color3.new(1,1,1), Title = 'Text Color', Callback = function(v) ESP.TextColor = v end })
EspGroup:AddToggle('EspDistance', { Text = 'Show Distance',   Default = true,  Callback = function(v) ESP.ShowDistance = v end })
EspGroup:AddToggle('EspHealth',   { Text = 'Show Health Bar', Default = true,  Callback = function(v) ESP.ShowHealth  = v end })
EspGroup:AddToggle('EspTracers',  { Text = 'Show Tracers',    Default = false, Callback = function(v) ESP.ShowTracers = v end })

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

MenuGroup:AddButton({ Text = 'Save Config', Func = function()
    if Library:SaveConfig('default') then
        Library:Notify('Saved default config', 2, { Icon = 'S' })
    end
end })

MenuGroup:AddButton({ Text = 'Load Config', Func = function()
    if Library:LoadConfig('default') then
        Library:Notify('Loaded default config', 2, { Icon = 'L' })
    end
end })

MenuGroup:AddButton({ Text = 'Open Quick Actions', Func = function()
    CommandPalette:Open({
        { Text = 'Toggle Window', Callback = function() Window:SetVisible(not Window.Visible) end },
        { Text = 'Load Config', Callback = function() Library:LoadConfig('default') end },
        { Text = 'Save Config', Callback = function() Library:SaveConfig('default') end },
        { Text = 'Previous Theme', Callback = function() applyThemeByIndex(-1) end },
        { Text = 'Next Theme', Callback = function() applyThemeByIndex(1) end },
        { Text = 'Unload UI', Callback = function() Library:Unload() end },
    })
end })

MenuGroup:AddButton({ Text = 'Join Discord', Func = function()
    local inviteCode = "jTMB2gcQkY"
    local inviteUrl = "https://discord.gg/" .. inviteCode
    local HttpService = game:GetService("HttpService")
    local success = false

    local req = (http and http.request) or http_request or request
    if req then
        pcall(function()
            local body = HttpService:JSONEncode({ cmd = "INVITE_BROWSER", args = { code = inviteCode }, nonce = tostring(math.random()) })
            req({ Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
            success = true
        end)
    end

    pcall(function()
        local gs = game:GetService("GuiService")
        if gs and gs.OpenBrowserWindow then
            pcall(function() gs:OpenBrowserWindow("discord://discordapp.com/invite/" .. inviteCode) end)
            pcall(function() gs:OpenBrowserWindow(inviteUrl) end)
            success = true
        end
    end)

    local okcb = pcall(function() setclipboard(inviteUrl) end)
    if okcb then
        Library:Notify('Discord invite copied to clipboard', 4, { Icon = 'D' })
    else
        if success then
            Library:Notify('Attempted to open invite (check your Discord/browser)', 4, { Icon = 'D' })
        else
            Library:Notify('Could not open invite; manual link: ' .. inviteUrl, 6, { Icon = 'D' })
        end
    end
end })

ThemePicker = AppearanceGroup:AddDropdown('UiTheme', {
    Text = 'Theme',
    Values = themeNames,
    Default = Library.CurrentThemeName,
    Callback = function(v)
        Library:SetTheme(v)
        for i, name in ipairs(themeNames) do
            if name == v then
                themeIndex = i
                break
            end
        end
    end,
})

AppearanceGroup:AddButton({ Text = 'Previous Theme', Func = function() applyThemeByIndex(-1) end })
AppearanceGroup:AddButton({ Text = 'Next Theme', Func = function() applyThemeByIndex(1) end })
AppearanceGroup:AddToggle('ShadowEnabled', { Text = 'Window Shadow', Default = true, Callback = function(v) Window:SetShadowEnabled(v) end })
AppearanceGroup:AddSlider('ShadowAlpha', { Text = 'Shadow Alpha', Min = 0, Max = 1, Default = 0.35, Rounding = 2, Callback = function(v) Window:SetShadowTransparency(v) end })
AppearanceGroup:AddToggle('AccentOverride', { Text = 'Accent Override', Default = true, Callback = function(v) if not v then Library:ClearAccentColor() end end }):AddColorPicker('AccentColor', {
    Default = Library.Themes[Library.CurrentThemeName].Accent,
    Title = 'Accent Color',
    Callback = function(v) Library:SetAccentColor(v) end,
})

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
    elseif inp.KeyCode == Enum.KeyCode.K and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        CommandPalette:Open({
            { Text = 'Toggle Window', Callback = function() Window:SetVisible(not Window.Visible) end },
            { Text = 'Save Config', Callback = function() Library:SaveConfig('default') end },
            { Text = 'Load Config', Callback = function() Library:LoadConfig('default') end },
            { Text = 'Previous Theme', Callback = function() applyThemeByIndex(-1) end },
            { Text = 'Next Theme', Callback = function() applyThemeByIndex(1) end },
        })
    end
end)

Loader:SetStage('Done', 1)
task.delay(0.15, function()
    pcall(function() Loader:Close() end)
end)
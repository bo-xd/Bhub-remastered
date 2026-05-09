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

local function compileAndRun(src)
    if not src then return nil, "no source" end
    local loader = loadstring or load
    if not loader then return nil, "no loader available" end
    local chunk, err = loader(src)
    if not chunk then return nil, err end
    local ok, res = pcall(chunk)
    if not ok then return nil, res end
    return res, nil
end

local function safeRequest(url)
    local candidates = {
        function(u) if type(http) == "table" and type(http.request) == "function" then return http.request({Url = u, Method = "GET"}) end end,
        function(u) if type(http_request) == "function" then return http_request({Url = u, Method = "GET"}) end end,
        function(u) if type(request) == "function" then return request({Url = u, Method = "GET"}) end end,
        function(u) if type(game) == "userdata" and type(game.HttpGet) == "function" then local ok, body = pcall(function() return game:HttpGet(u) end); if ok then return { Success = true, Body = body } end end end,
    }

    for _, fn in ipairs(candidates) do
        local ok, resp = pcall(fn, url)
        if ok and resp ~= nil then
            if type(resp) == "string" then
                return { Success = true, Body = resp }
            elseif type(resp) == "table" then
                local body = resp.Body or resp.body or resp.Response or resp.response
                local success
                if resp.Success ~= nil then success = resp.Success
                elseif resp.success ~= nil then success = resp.success
                elseif resp.StatusCode ~= nil then success = tonumber(resp.StatusCode) >= 200 and tonumber(resp.StatusCode) < 400
                else success = body ~= nil and body ~= ""
                end
                return { Success = success, Body = (body or "") }
            end
        end
    end
    return { Success = false, Body = nil }
end

local function updateLocalBackup(path, content)
    if type(writefile) ~= "function" or type(makefolder) ~= "function" then return end
    
    pcall(function()
        if type(isfolder) == "function" and not isfolder("Bhub-remastered") then
            makefolder("Bhub-remastered")
        end

        local localPath = "Bhub-remastered/" .. path
        writefile(localPath, content)
    end)
end

local function loadFile(path)
    local url = string.format("https://raw.githubusercontent.com/%s/%s/%s", REPO, BRANCH, path)
    local resp = safeRequest(url)
    
    if resp and resp.Success and resp.Body and resp.Body ~= "" then
        local res, err = compileAndRun(resp.Body)
        
        if res ~= nil then
            updateLocalBackup(path, resp.Body)
            return res
        else
            warn("[BHub] Remote code for " .. path .. " has syntax errors: " .. tostring(err))
        end
    else
        warn("[BHub] Could not reach GitHub. Attempting to load local backup for: " .. path)
    end

    if type(isfile) == "function" and type(readfile) == "function" then
        local localPath = "Bhub-remastered/" .. path
        
        local ok_exists, exists = pcall(function() return isfile(localPath) end)
        if ok_exists and exists then
            local src = readfile(localPath)
            local res, err = compileAndRun(src)
            
            if res ~= nil then
                return res
            end
        end
    end

    warn("[BHub] Critical Error: Could not load " .. path .. " from Remote OR Local.")
    return nil
end

local Compat = loadFile("src/util/ExecutorCompat.lua")
if not Compat then
    local ok, g = pcall(function() return (type(getgenv) == "function" and getgenv()) or _G end)
    if ok and g and g.BHub_Compat then Compat = g.BHub_Compat end
end

local useDrawing
if Compat and type(Compat.Supports) == "table" and Compat.Supports["Drawing.new"] ~= nil then
    useDrawing = Compat.Supports["Drawing.new"]
else
    useDrawing = hasDrawingSupport()
end

local uiPath = useDrawing and "src/util/ui/DrawingUILib.lua" or "src/util/ui/NormalUILib.lua"
local Library = loadFile(uiPath)
if not Library and useDrawing then
    useDrawing = false
    uiPath = "src/util/ui/NormalUILib.lua"
    Library = loadFile(uiPath)
end

local function isFeatureDisabled(featureName)
    if not Compat or not Compat.DisabledFeatures then return false end
    return Compat.DisabledFeatures[featureName] == true
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
    if gameScript then
        task.spawn(function()
            local ok, err = pcall(function() gameScript(Window, ESP, Library, isFeatureDisabled) end)
            if not ok then
                pcall(function()
                    if Library and type(Library.Notify) == "function" then
                        Library:Notify("Game module error: " .. tostring(err), 6)
                    elseif Compat and type(Compat.SafeNotify) == "function" then
                        Compat.SafeNotify("Game module error", tostring(err), 6)
                    else
                        warn("[BHub] Game module error: " .. tostring(err))
                    end
                end)
            end
        end)
    end
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

local function canUseFileIO()
    if Compat and type(Compat.Supports) == 'table' then
        return Compat.Supports['isfile'] and Compat.Supports['readfile'] and Compat.Supports['writefile'] and Compat.Supports['isfolder'] and Compat.Supports['makefolder']
    end
    return type(isfile) == 'function' and type(readfile) == 'function' and type(writefile) == 'function' and type(isfolder) == 'function' and type(makefolder) == 'function'
end

MenuGroup:AddButton({ Text = 'Save Config', Func = function()
    if not canUseFileIO() then
        Library:Notify('Save disabled — executor does not support local file I/O', 4, { Icon = 'S' })
        return
    end
    if Library:SaveConfig('default') then
        Library:Notify('Saved default config', 2, { Icon = 'S' })
    end
end, Disabled = (not canUseFileIO()) })

MenuGroup:AddButton({ Text = 'Load Config', Func = function()
    if not canUseFileIO() then
        Library:Notify('Load disabled — executor does not support local file I/O', 4, { Icon = 'L' })
        return
    end
    if Library:LoadConfig('default') then
        Library:Notify('Loaded default config', 2, { Icon = 'L' })
    end
end, Disabled = (not canUseFileIO()) })

MenuGroup:AddButton({ Text = 'Open Quick Actions', Func = function()
    CommandPalette:Open({
        { Text = 'Toggle Window', Callback = function() Window:SetVisible(not Window.Visible) end },
        { Text = 'Load Config', Callback = function() if not canUseFileIO() then Library:Notify('Load disabled — executor does not support local file I/O', 4) return end; Library:LoadConfig('default') end },
        { Text = 'Save Config', Callback = function() if not canUseFileIO() then Library:Notify('Save disabled — executor does not support local file I/O', 4) return end; Library:SaveConfig('default') end },
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
end, Disabled = (isFeatureDisabled('HTTP') and isFeatureDisabled('ClipboardCopy')) })

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
            { Text = 'Save Config', Callback = function() if not canUseFileIO() then Library:Notify('Save disabled — executor does not support local file I/O', 4) return end; Library:SaveConfig('default') end },
            { Text = 'Load Config', Callback = function() if not canUseFileIO() then Library:Notify('Load disabled — executor does not support local file I/O', 4) return end; Library:LoadConfig('default') end },
            { Text = 'Previous Theme', Callback = function() applyThemeByIndex(-1) end },
            { Text = 'Next Theme', Callback = function() applyThemeByIndex(1) end },
        })
    end
end)

Loader:SetStage('Done', 1)
task.delay(0.15, function()
    pcall(function() Loader:Close() end)
end)


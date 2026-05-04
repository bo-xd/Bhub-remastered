local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local mouse = plr:GetMouse()
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Window = Library:CreateWindow({
    Title = 'BHub Remastered | Project Validus V2.1',
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
local func = loadFile("src/util/func.lua")

local supportedGames = { [131756752872026] = "src/games/divedown.lua" }
local gamePath = supportedGames[game.PlaceId]
if gamePath then
    local gameScript = loadFile(gamePath)
    if gameScript then task.spawn(function() gameScript(Window, ESP, Library) end) end
end
task.wait(0.2)

local Tabs = {
    Combat = Window:AddTab('Combat'),
    Universal = Window:AddTab('Universal'),
    Visuals = Window:AddTab('Visuals'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local Settings = {
    SilentEnabled = false,
    Camlock = false,
    TeamCheck = false,
    VisibleCheck = false,
    HitPart = "Head",
    Method = "Raycast",
    HitChance = 100,
    Smoothing = 50,
    FovVisible = false,
    FovRadius = 100,
    FovColor = Color3.fromRGB(255, 255, 255),
    FovTransparency = 0.5,
    BulletTracers = false,
    BulletColor = Color3.fromRGB(255, 0, 0),
    BulletMaterial = "ForceField"
}

local FovCircle = Drawing.new("Circle")
FovCircle.Thickness = 1
FovCircle.NumSides = 64
FovCircle.Filled = false

local function IsPlayerVisible(target)
    if not target or not target.Character then return false end
    local part = target.Character:FindFirstChild(Settings.HitPart) or target.Character:FindFirstChild("HumanoidRootPart")
    if not part then return false end
    local obs = Camera:GetPartsObscuringTarget({part.Position}, {plr.Character, target.Character})
    return #obs == 0
end

local function GetClosestPlayer()
    local closest, dist = nil, Settings.FovRadius
    for _, p in pairs(plrs:GetPlayers()) do
        if p ~= plr and func.IsAlive(p) then
            if Settings.TeamCheck and not func.TeamCheck(p) then continue end
            if Settings.VisibleCheck and not IsPlayerVisible(p) then continue end
            
            local part = p.Character:FindFirstChild(Settings.HitPart)
            if not part and Settings.HitPart == "Random" then
                local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
                part = p.Character:FindFirstChild(parts[math.random(1, #parts)])
            end
            part = part or p.Character:FindFirstChild("HumanoidRootPart")
            if not part then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local d = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                if d < dist then
                    closest = part
                    dist = d
                end
            end
        end
    end
    return closest
end

local SilentAimGroup = Tabs.Combat:AddLeftGroupbox('Silent Aim')
SilentAimGroup:AddToggle('SilentAim', { Text = 'Enabled', Default = false, Callback = function(v) Settings.SilentEnabled = v end }):AddKeyPicker('SilentBind', { Default = 'G', NoUI = true, Text = 'Silent Aim' })
SilentAimGroup:AddToggle('TeamCheck', { Text = 'Team Check', Default = false, Callback = function(v) Settings.TeamCheck = v end })
SilentAimGroup:AddToggle('VisCheck', { Text = 'Visible Check', Default = false, Callback = function(v) Settings.VisibleCheck = v end })
SilentAimGroup:AddDropdown('HitPart', { Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Random"}, Default = 1, Multi = false, Text = 'Hit Part', Callback = function(v) Settings.HitPart = v end })
SilentAimGroup:AddDropdown('Method', { Values = {"Raycast", "FindPartOnRay", "FindPartOnRayWithIgnoreList"}, Default = 1, Multi = false, Text = 'Method', Callback = function(v) Settings.Method = v end })
SilentAimGroup:AddSlider('HitChance', { Text = 'Hit Chance', Min = 1, Max = 100, Default = 100, Rounding = 0, Callback = function(v) Settings.HitChance = v end })

local CamlockGroup = Tabs.Combat:AddRightGroupbox('Camlock')
CamlockGroup:AddToggle('Camlock', { Text = 'Enabled', Default = false, Callback = function(v) Settings.Camlock = v end }):AddKeyPicker('CamBind', { Default = 'V', NoUI = true, Text = 'Camlock' })
CamlockGroup:AddSlider('Smoothing', { Text = 'Smoothing', Min = 1, Max = 100, Default = 50, Rounding = 0, Callback = function(v) Settings.Smoothing = v end })

local FovGroup = Tabs.Visuals:AddLeftGroupbox('FOV Settings')
FovGroup:AddToggle('FovEnabled', { Text = 'Show FOV', Default = false, Callback = function(v) Settings.FovVisible = v end }):AddColorPicker('FovColor', { Default = Color3.new(1,1,1), Title = 'FOV Color', Callback = function(v) Settings.FovColor = v end })
FovGroup:AddSlider('FovRadius', { Text = 'Radius', Min = 10, Max = 1000, Default = 100, Rounding = 0, Callback = function(v) Settings.FovRadius = v end })
FovGroup:AddSlider('FovTrans', { Text = 'Transparency', Min = 0, Max = 1, Default = 0.5, Rounding = 1, Callback = function(v) Settings.FovTransparency = v end })

local TracerPartGroup = Tabs.Visuals:AddRightGroupbox('Bullet Tracers')
TracerPartGroup:AddToggle('BulletTracers', { Text = 'Enabled', Default = false, Callback = function(v) Settings.BulletTracers = v end }):AddColorPicker('BulletColor', { Default = Color3.new(1,0,0), Title = 'Tracer Color', Callback = function(v) Settings.BulletColor = v end })
TracerPartGroup:AddDropdown('BulletMat', { Values = {'ForceField', 'Neon', 'Glass', 'Plastic'}, Default = 1, Multi = false, Text = 'Material', Callback = function(v) Settings.BulletMaterial = v end })

local function CreateTracer(from, to)
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.Material = Enum.Material[Settings.BulletMaterial]
    p.Color = Settings.BulletColor
    p.Size = Vector3.new(0.1, 0.1, (from - to).Magnitude)
    p.CFrame = CFrame.new(from, to) * CFrame.new(0, 0, -p.Size.Z/2)
    p.Parent = workspace
    task.delay(1, function()
        local t = game:GetService("TweenService"):Create(p, TweenInfo.new(0.5), {Transparency = 1})
        t:Play()
        t.Completed:Connect(function() p:Destroy() end)
    end)
end

local OldNC
OldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if not checkcaller() and Settings.SilentEnabled and func.HitChance(Settings.HitChance) then
        if (method == "Raycast" and Settings.Method == "Raycast") or (method == "FindPartOnRay" and Settings.Method == "FindPartOnRay") or (method == "FindPartOnRayWithIgnoreList" and Settings.Method == "FindPartOnRayWithIgnoreList") then
            local target = GetClosestPlayer()
            if target then
                local origin = (method == "Raycast" and args[1]) or args[1].Origin
                if method == "Raycast" then args[2] = func.Direction(origin, target.Position)
                else args[1] = Ray.new(origin, func.Direction(origin, target.Position)) end
                if Settings.BulletTracers then
                    local gun = func.GetGun()
                    local shootOrigin = (gun and gun:FindFirstChild("Handle") and gun.Handle.Position) or origin
                    CreateTracer(shootOrigin, target.Position)
                end
                return OldNC(self, unpack(args))
            end
        end
    end
    return OldNC(self, ...)
end))

RunService.RenderStepped:Connect(function()
    if Settings.FovVisible then
        FovCircle.Visible = true
        FovCircle.Radius = Settings.FovRadius
        FovCircle.Color = Settings.FovColor
        FovCircle.Transparency = Settings.FovTransparency
        FovCircle.Position = Vector2.new(mouse.X, mouse.Y + 36)
    else
        FovCircle.Visible = false
    end
    if Settings.Camlock then
        local target = GetClosestPlayer()
        if target then
            local goal = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, Settings.Smoothing / 1000)
        end
    end
end)

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
                ESP:Add(char, { Name = p.Name, IsEnabled = function() return ESP.Enabled and p.Character == char and func.IsAlive(p) end })
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
MenuGroup:AddButton({ Text = 'Unload', Func = function() if uc then ESP:Unload() FovCircle:Remove() Library:Unload() else uc = true Library:Notify("Press again to confirm unload", 3) task.delay(3, function() uc = false end) end end })
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'Delete', NoUI = true, Text = 'Menu keybind' })
task.spawn(function() while not Options.MenuKeybind do task.wait() end Library.ToggleKeybind = Options.MenuKeybind end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder('BHubRemastered')
SaveManager:SetFolder('BHubRemastered/Games')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

return function(Window, ESP, Library)
    local player = game:GetService("Players").LocalPlayer
    local RS = game:GetService("ReplicatedStorage")
    local CollectionService = game:GetService("CollectionService")
    local Client = require(player.PlayerScripts:WaitForChild("Client"))

    local OceanTab    = Window:AddTab('Ocean')
    local AutofarmTab = Window:AddTab('Autofarm')
    local VisualsTab  = Window:AddTab('Visuals')
    local MiscTab     = Window:AddTab('Misc')
    local AquariumTab = Window:AddTab('Aquarium')

    local game_folder = workspace:WaitForChild("Game")
    local Fish        = game_folder:WaitForChild("Fishes")
    local Markers     = game_folder:WaitForChild("OceanZoneMarkers")

    -- [[ ELITE DATA ]]
    local MutationTypes = {"Normal","Silver","Gold","Rainbow","Frozen","Shocked","Magma","Chocolate","Dry","Infected","Evil","YinYang","Hacker","Galaxy","Taco"}
    local HardcodedZones = {
        ["SunlightZone"]   = Vector3.new(-1935.5, 2466.8, -1420.5),
        ["Area1"]          = Vector3.new(-1934.9, 2447.1, -1429.0),
        ["Area2"]          = Vector3.new(-1929.5, 2338.1, -1423.4),
        ["CoralReef"]      = Vector3.new(-1934.0, 2336.6, -1418.3),
        ["TwilightZone"]   = Vector3.new(-1928.1, 2106.0, -1421.2),
        ["Area3"]          = Vector3.new(-1916.1, 2029.2, -1424.2),
        ["DeepOcean"]      = Vector3.new(-1924.9, 1722.5, -1422.4),
        ["TheDeepDark"]    = Vector3.new(-1938.6, 1004.3, -1422.2),
        ["TheTrenches"]    = Vector3.new(-1938.6,  310.9, -1422.2),
        ["Atlantis"]       = Vector3.new(-1932.6,  -17.7, -1423.0),
        ["AquaForest"]     = Vector3.new(-1932.6, -304.3, -1423.0),
        ["ShellReef"]      = Vector3.new(-1932.6, -645.4, -1423.0),
        ["KrakenWorld"]    = Vector3.new(-1932.6,-1107.9, -1423.0),
        ["MegalodonsLair"] = Vector3.new(-1927.7,-1591.8, -1418.6),
        ["IceArea"]        = Vector3.new(-1927.7,-1961.3, -1418.6),
        ["JellyfishFields"]= Vector3.new(-1927.7,-2373.8, -1418.6),
        ["SteampunkZone"]  = Vector3.new(-1927.7,-2885.3, -1418.6),
        ["DeadWaters"]     = Vector3.new(-1927.7,-3361.3, -1418.6),
        ["Prehistoric"]    = Vector3.new(-1927.7,-3820.8, -1418.6),
    }

    -- [[ ELITE FUNCTIONS ]]
    local function getFishData(fish)
        local mut, rar = "normal", "normal"
        for _, mType in ipairs(MutationTypes) do
            if fish:GetAttribute(mType) then mut = mType:lower(); break end
        end
        return mut, "normal"
    end

    local function checkFilters(mut, rar, mFilters, rFilters)
        local mCount, rCount = 0, 0
        if mFilters then for _, v in pairs(mFilters) do if v then mCount=mCount+1 end end end
        if mCount == 0 then return true end
        for k,v in pairs(mFilters) do if v and (mut:find(k:lower()) or (k == "Normal" and mut == "normal")) then return true end end
        return false
    end

    -- [[ ELITE AUTOFARM (MAP-WIDE) ]]
    local AutofarmGroup = AutofarmTab:AddLeftGroupbox('Elite Automations')
    local mapVacuumEnabled = false
    local autoFarmEnabled = false
    local autoSellEnabled = false
    local selectedMutationFilters = {}

    AutofarmGroup:AddToggle('MapVacuum', { Text = 'Global Map Vacuum (Infinite TNT)', Default = false, Callback = function(v) mapVacuumEnabled = v end })
    AutofarmGroup:AddToggle('TeleFarm', { Text = 'Ultra-Fast Teleport Farm', Default = false, Callback = function(v) autoFarmEnabled = v end })
    AutofarmGroup:AddToggle('AutoSell', { Text = 'Instant Auto-Sell', Default = false, Callback = function(v) autoSellEnabled = v end })

    AutofarmGroup:AddDropdown('MutFilter', { Values = MutationTypes, Default = 1, Multi = true, Text = 'Mutation Filter', Callback = function(v) selectedMutationFilters = v end })

    -- Map Vacuum Loop (No Radius Limit)
    task.spawn(function()
        while true do
            task.wait(0.3)
            if mapVacuumEnabled then
                pcall(function()
                    local fishes = {}
                    for _, v in pairs(CollectionService:GetTagged("SpawnedFish")) do
                        if v:IsA("Model") and v.Parent and not v:GetAttribute("Claimed") then
                            local mut, rar = getFishData(v)
                            if checkFilters(mut, rar, selectedMutationFilters, {}) then table.insert(fishes, v) end
                        end
                    end
                    if #fishes > 0 then Client.Network.Fire("TNTActivated", fishes) end
                end)
            end
        end
    end)

    -- [[ ELITE PROTECTION & SPEED ]]
    local ProtectionGroup = OceanTab:AddRightGroupbox('God Mode')
    local noclipEnabled = false

    ProtectionGroup:AddToggle('GhostMode', { Text = 'Ghost Mode (Noclip)', Default = false, Callback = function(v) noclipEnabled = v end })
    ProtectionGroup:AddToggle('InfOxygen', { Text = 'Infinite Oxygen', Default = true, Callback = function(v)
        task.spawn(function() while v do pcall(function() player.Character:SetAttribute("OxygenFill", 100) end); task.wait(1) end end)
    end })

    ProtectionGroup:AddSlider('SwimSpeed', { Text = 'Elite Swim Speed', Min = 1, Max = 100, Default = 1, Rounding = 1, Callback = function(v)
        pcall(function() workspace:SetAttribute("AdminSpeedMultiplier", v) end)
    end })

    -- Noclip Loop
    task.spawn(function()
        game:GetService("RunService").Stepped:Connect(function()
            if noclipEnabled and player.Character then
                for _, v in pairs(player.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
    end)

    -- [[ ELITE MISC ]]
    local MiscGroup = MiscTab:AddLeftGroupbox('Elite Utilities')
    MiscGroup:AddButton('Map-Wide Teleport Sell', function()
        pcall(function()
            local res = Client.Network.Invoke("SellInventory")
            Library:Notify("Sold everything for $" .. tostring(res or 0))
        end)
    end)

    local autoClaimAll = false
    MiscGroup:AddToggle('AutoClaimAll', { Text = 'Auto-Claim All Rewards', Default = false, Callback = function(v) autoClaimAll = v end })
    
    task.spawn(function()
        while true do
            task.wait(5)
            if autoClaimAll then
                pcall(function()
                    Client.Network.Fire("ClaimOfflineReward")
                    Client.Network.Invoke("ClaimDailyReward")
                    Client.Network.Fire("SpinWheel")
                end)
            end
        end
    end)

    -- [[ AUTO-UPGRADER ]]
    local autoUpgradeEverything = false
    MiscTab:AddRightGroupbox('Progression'):AddToggle('AutoUpgradeAll', { Text = 'Auto-Upgrade Everything', Default = false, Callback = function(v) autoUpgradeEverything = v end })
    
    task.spawn(function()
        local GearConfig = require(RS.Modules.GearConfig)
        while true do
            task.wait(2)
            if autoUpgradeEverything then
                pcall(function()
                    local save = Client.Network.Invoke("Get Save")
                    local cash = player:GetAttribute("Cash") or 0
                    for cat, items in pairs(GearConfig) do
                        for itemName, data in pairs(items) do
                            if data.price and data.price <= cash then Client.Network.Invoke("BuyItem", cat, itemName) end
                        end
                    end
                end)
            end
        end
    end)

    -- ESP & OTHER Visuals
    local FishEspGroup = VisualsTab:AddLeftGroupbox('Visuals')
    local fishEspEnabled = false
    FishEspGroup:AddToggle('FishEsp', { Text = 'Enable Fish ESP', Default = false, Callback = function(v) fishEspEnabled = v end })

    Library:Notify("ELITE VERSION LOADED. NO LIMITS.", 5)
end

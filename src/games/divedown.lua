return function(Window, ESP, Library)
    local player = game:GetService("Players").LocalPlayer
    local RS = game:GetService("ReplicatedStorage")
    local CollectionService = game:GetService("CollectionService")

    local OceanTab    = Window:AddTab('Ocean')
    local AutofarmTab = Window:AddTab('Autofarm')
    local VisualsTab  = Window:AddTab('Visuals')
    local MiscTab     = Window:AddTab('Misc')
    local AquariumTab = Window:AddTab('Aquarium')

    local game_folder = workspace:WaitForChild("Game")
    local Fish        = game_folder:WaitForChild("Fishes")
    local Markers     = game_folder:WaitForChild("OceanZoneMarkers")

    -- [[ DATA ]]
    local MutationTypes = {"Normal","Silver","Gold","Rainbow","Frozen","Shocked","Magma","Chocolate","Dry","Infected","Evil","YinYang","Hacker","Galaxy","Taco"}
    local ZoneOrder = {"SunlightZone","Area1","Area2","CoralReef","TwilightZone","Area3","DeepOcean","TheDeepDark","TheTrenches","Atlantis","AquaForest","ShellReef","KrakenWorld","MegalodonsLair","IceArea","JellyfishFields","SteampunkZone","DeadWaters","Prehistoric"}
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

    -- [[ HELPERS ]]
    local function getFishData(fish)
        local mut, rar = "normal", "normal"
        for _, mType in ipairs(MutationTypes) do
            if fish:GetAttribute(mType) then mut = mType:lower(); break end
        end
        local bp = fish:FindFirstChild(fish.Name.."BillboardPart")
        if bp then
            local frame = bp:FindFirstChildOfClass("BillboardGui") and bp:FindFirstChildOfClass("BillboardGui"):FindFirstChild("Frame")
            if frame then
                local rLab = frame:FindFirstChild("Rarity")
                if rLab then rar = rLab.Text:gsub("<[^>]+>",""):lower():match("^%s*(.-)%s*$") end
            end
        end
        return mut, rar
    end

    local function checkFilters(mut, rar, mFilters, rFilters)
        local mCount, rCount = 0, 0
        if mFilters then for _, v in pairs(mFilters) do if v then mCount=mCount+1 end end end
        if rFilters then for _, v in pairs(rFilters) do if v then rCount=rCount+1 end end end
        if mCount == 0 and rCount == 0 then return true end
        local mutMatch = mCount == 0
        if not mutMatch then for k,v in pairs(mFilters) do if v and (mut:find(k:lower()) or (k=="Normal" and mut=="normal")) then mutMatch=true; break end end end
        local rarMatch = rCount == 0
        if not rarMatch then for k,v in pairs(rFilters) do if v and (rar:find(k:lower()) or (k=="Normal" and rar=="normal")) then rarMatch=true; break end end end
        return mutMatch and rarMatch
    end

    -- [[ OCEAN TAB ]]
    local TeleportGroup = OceanTab:AddLeftGroupbox('Teleportation')
    local selectedAreaName = ZoneOrder[1]
    TeleportGroup:AddDropdown('AreaSelector', {
        Values = ZoneOrder,
        Default = ZoneOrder[1],
        Multi = false,
        Text = 'Target Area',
        Callback = function(v) selectedAreaName = v end
    })
    TeleportGroup:AddButton({ Text = 'Teleport', Func = function() if HardcodedZones[selectedAreaName] then player.Character:PivotTo(CFrame.new(HardcodedZones[selectedAreaName])) end end })
    TeleportGroup:AddButton({ Text = 'Teleport Back (Aquarium)', Func = function() pcall(function() workspace.Network["Teleport-RemoteEvent"]:FireServer("Aquarium") end) end })

    local autoTPRareEnabled, lastTPTime = false, 0
    TeleportGroup:AddToggle('AutoTPRare', { Text = 'Auto TP to Rare Spawns', Default = false, Callback = function(v) autoTPRareEnabled = v end })
    pcall(function()
        game:GetService("TextChatService").MessageReceived:Connect(function(msg)
            if not autoTPRareEnabled or tick()-lastTPTime < 5 then return end
            local m = msg.Text
            if m:find("has spawned in") and (m:find("Secret") or m:find("Divine") or m:find("Mythical") or m:find("Legendary")) then
                local zone = (m:match("has spawned in (%S+)") or ""):gsub("%p+$","")
                if HardcodedZones[zone] then lastTPTime = tick(); player.Character:PivotTo(CFrame.new(HardcodedZones[zone])); Library:Notify("Auto-TP to rare spawn!") end
            end
        end)
    end)

    -- [[ MODIFIERS TAB ]]
    local ProtectionGroup = OceanTab:AddRightGroupbox('Modifiers')
    local antiDrownEnabled, teleporting = false, false
    ProtectionGroup:AddToggle('AntiDrown', { Text = 'Anti Drown', Default = false, Callback = function(v)
        antiDrownEnabled = v
        if v then
            player.AttributeChanged:Connect(function(attr)
                if attr == "IsDrowning" and player:GetAttribute("IsDrowning") and not teleporting and antiDrownEnabled then
                    teleporting = true
                    local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local savedCF = char.HumanoidRootPart.CFrame
                        workspace.Network["Teleport-RemoteEvent"]:FireServer("Aquarium")
                        task.wait(0.5)
                        char:PivotTo(savedCF)
                    end
                    task.wait(1)
                    teleporting = false
                end
            end)
        end
    end })

    local ghostMode = false
    ProtectionGroup:AddToggle('GhostMode', { Text = 'Ghost Mode (Noclip)', Default = false, Callback = function(v) ghostMode = v end })
    task.spawn(function() game:GetService("RunService").Stepped:Connect(function() if ghostMode and player.Character then for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end end end) end)

    ProtectionGroup:AddSlider('SwimSpeed', {
        Text = 'Swim Speed',
        Min = 1,
        Max = 100,
        Default = 1,
        Rounding = 1,
        Compact = false,
        Callback = function(v) workspace:SetAttribute("AdminSpeedMultiplier", v) end
    })

    -- [[ AUTOFARM TAB ]]
    local FarmGroup = AutofarmTab:AddLeftGroupbox('Farming')
    local autofarmEnabled, mapVacuumEnabled, autoSellEnabled = false, false, false
    local mFilters, rFilters = {}, {}
    local selectedSpecificFish, targetFishInput = "Any", ""

    FarmGroup:AddToggle('MapVacuum', { Text = 'Map Vacuum', Default = false, Callback = function(v) mapVacuumEnabled = v end })
    FarmGroup:AddToggle('AutoFarm', { Text = 'Teleport Farm', Default = false, Callback = function(v) autofarmEnabled = v end })
    FarmGroup:AddToggle('AutoSell', { Text = 'Auto Sell', Default = false, Callback = function(v) autoSellEnabled = v end })

    local FishDrop = FarmGroup:AddDropdown('TargetFish', {
        Values = {"Any"},
        Default = "Any",
        Multi = false,
        Text = 'Specific Fish',
        Callback = function(v) selectedSpecificFish = v end
    })
    FarmGroup:AddButton({ Text = 'Refresh Fish List', Func = function()
        local list = {"Any"}
        for _, v in pairs(CollectionService:GetTagged("SpawnedFish")) do if not table.find(list, v.Name) then table.insert(list, v.Name) end end
        FishDrop:SetValues(list)
    end })
    FarmGroup:AddInput('ManualFish', { Text = 'Manual Name Filter', Default = '', Callback = function(v) targetFishInput = v end })

    local FilterGroup = AutofarmTab:AddRightGroupbox('Filters')
    FilterGroup:AddDropdown('MutF', { Values = MutationTypes, Default = MutationTypes[1], Multi = true, Text = 'Mutation Filter', Callback = function(v) mFilters = v end })
    FilterGroup:AddDropdown('RarF', { Values = {"Normal","Common","Rare","Epic","Legendary","Mythical","Secret","Divine"}, Default = "Normal", Multi = true, Text = 'Rarity Filter', Callback = function(v) rFilters = v end })

    -- LOOPS
    task.spawn(function()
        while true do
            task.wait(0.3)
            if mapVacuumEnabled then
                local fList = {}
                for _, v in pairs(CollectionService:GetTagged("SpawnedFish")) do
                    if v:IsA("Model") and v.Parent and not v:GetAttribute("Claimed") then
                        local m, r = getFishData(v)
                        if checkFilters(m, r, mFilters, rFilters) then table.insert(fList, v) end
                    end
                end
                if #fList > 0 then require(player.PlayerScripts.Client).Network.Fire("TNTActivated", fList) end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.1)
            if autofarmEnabled then
                for _, v in pairs(CollectionService:GetTagged("SpawnedFish")) do
                    if not autofarmEnabled then break end
                    if v:IsA("Model") and v.Parent and not v:GetAttribute("Claimed") then
                        local match = (selectedSpecificFish == "Any") or (v.Name == selectedSpecificFish) or (targetFishInput ~= "" and v.Name:lower():find(targetFishInput:lower()))
                        if match then
                            local m, r = getFishData(v)
                            if checkFilters(m, r, mFilters, rFilters) then
                                local p = v:FindFirstChildOfClass("ProximityPrompt", true)
                                if p and p.Enabled then
                                    player.Character:PivotTo(CFrame.new(v:GetPivot().Position) * CFrame.new(0,2,0))
                                    task.wait(0.1); if autofarmEnabled then fireproximityprompt(p) end; task.wait(0.3)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function() while true do task.wait(2.5); if autoSellEnabled then RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\003\001")) end end end)

    -- [[ MISC TAB ]]
    local MiscUtils = MiscTab:AddLeftGroupbox('Utilities')
    MiscUtils:AddButton({ Text = 'Spin Wheel', Func = function() RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\019\001")) end })
    MiscUtils:AddButton({ Text = 'Remote Sell All', Func = function() RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\003\001")) end })
    
    local autoUpgradeAll = false
    MiscTab:AddRightGroupbox('Progression'):AddToggle('AutoUpgrade', { Text = 'Auto-Upgrade Gear', Default = false, Callback = function(v) autoUpgradeAll = v end })
    task.spawn(function()
        local Gear = require(RS.Modules.GearConfig)
        while true do
            task.wait(5); if autoUpgradeAll then
                local cash = player:GetAttribute("Cash") or 0
                for cat, items in pairs(Gear) do
                    for itemName, data in pairs(items) do if data.price and data.price <= cash then require(player.PlayerScripts.Client).Network.Invoke("BuyItem", cat, itemName) end end
                end
            end
        end
    end)

    -- [[ VISUALS & AQUARIUM ]]
    local FishEspGroup = VisualsTab:AddLeftGroupbox('Fish ESP')
    local fishEspEnabled = false
    FishEspGroup:AddToggle('FishEsp', { Text = 'Enable Fish ESP', Default = false, Callback = function(v) fishEspEnabled = v; if not v then for _, f in pairs(Fish:GetChildren()) do pcall(function() ESP:Remove(f) end) end end end })
    
    local AqGroup = AquariumTab:AddLeftGroupbox('Aquarium')
    AqGroup:AddButton({ Text = 'Equip Best Fish', Func = function() require(player.PlayerScripts.Client).Network.Invoke("RequestEquipBestFish") end })

    Library:Notify("MASTER COMPLIANCE FIX LOADED.", 5)
end

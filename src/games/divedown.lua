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
    local ZoneOrder = {
        "SunlightZone","Area1","Area2","CoralReef","TwilightZone","Area3","DeepOcean",
        "TheDeepDark","TheTrenches","Atlantis","AquaForest","ShellReef","KrakenWorld",
        "MegalodonsLair","IceArea","JellyfishFields","SteampunkZone","DeadWaters","Prehistoric"
    }

    local MutationTypes = {"Normal","Silver","Gold","Rainbow","Frozen","Shocked","Magma","Chocolate","Dry","Infected","Evil","YinYang","Hacker","Galaxy","Taco"}
    local function getFishData(fish)
        local mut, rar = "none", "normal"
        for _, mType in ipairs(MutationTypes) do
            if fish:GetAttribute(mType) then
                if mType ~= "Normal" then mut = mType:lower() end
                break
            end
        end
        local bp = fish:FindFirstChild(fish.Name.."BillboardPart")
        if bp then
            local frame = bp:FindFirstChildOfClass("BillboardGui") and bp:FindFirstChildOfClass("BillboardGui"):FindFirstChild("Frame")
            if frame then
                if mut == "none" then
                    local mLab = frame:FindFirstChild("Mutations")
                    if mLab then 
                        local t = mLab.Text:gsub("<[^>]+>",""):lower():match("^%s*(.-)%s*$") 
                        if t~="" and t~="none" then mut=t end 
                    end
                end
                local rLab = frame:FindFirstChild("Rarity")
                if rLab then 
                    local t = rLab.Text:gsub("<[^>]+>",""):lower():match("^%s*(.-)%s*$") 
                    if t~="" and t~="normal" then rar=t end 
                end
            end
        end
        return mut, rar
    end

    local function checkFilters(mut, rar, mFilters, rFilters)
        local mCount, rCount = 0, 0
        if mFilters then for _, v in pairs(mFilters) do if v then mCount=mCount+1 end end end
        if rFilters then for _, v in pairs(rFilters) do if v then rCount=rCount+1 end end end
        local mutMatch = mCount == 0
        local rarMatch = rCount == 0
        if not mutMatch then
            if mFilters["None"] and (mut=="none" or mut=="normal") then mutMatch=true
            else for k,v in pairs(mFilters) do if v and string.find(mut,k:lower()) then mutMatch=true; break end end end
        end
        if not rarMatch then
            if rFilters["Normal"] and (rar=="normal" or rar=="") then rarMatch=true
            else for k,v in pairs(rFilters) do if v and string.find(rar,k:lower()) then rarMatch=true; break end end end
        end
        return mutMatch and rarMatch
    end

    local function teleportTo(pos)
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.zero; char:PivotTo(CFrame.new(pos) * CFrame.new(0,5,0)) end
    end

    local rarityColor = {
        legendary=Color3.fromRGB(255,170,0), mythical=Color3.fromRGB(170,0,255),
        secret=Color3.fromRGB(255,0,0),      divine=Color3.fromRGB(0,255,255),
        epic=Color3.fromRGB(255,0,150),      rare=Color3.fromRGB(0,150,255),
    }
    local MutationColors = {
        ["Normal"] = Color3.fromRGB(255, 255, 255), ["Dry"] = Color3.fromRGB(194, 164, 132), ["Frozen"] = Color3.fromRGB(120, 200, 255),
        ["Shocked"] = Color3.fromRGB(245, 0, 218), ["Chocolate"] = Color3.fromRGB(123, 63, 0), ["Silver"] = Color3.fromRGB(164, 166, 166),
        ["Gold"] = Color3.fromRGB(234, 181, 74), ["Rainbow"] = Color3.fromRGB(255, 125, 197), ["Infected"] = Color3.fromRGB(80, 255, 80),
        ["Evil"] = Color3.fromRGB(255, 0, 5), ["Magma"] = Color3.fromRGB(255, 98, 0), ["Wet"] = Color3.fromRGB(128, 255, 255),
        ["YinYang"] = Color3.fromRGB(200, 200, 200), ["Hacker"] = Color3.fromRGB(0, 255, 65), ["Galaxy"] = Color3.fromRGB(160, 64, 255),
        ["Taco"] = Color3.fromRGB(255, 180, 70)
    }
    local function fishColor(mut, rar)
        for k, c in pairs(rarityColor) do if string.find(rar, k) then return c end end
        for k, c in pairs(MutationColors) do if mut:lower() == k:lower() and k ~= "Normal" then return c end end
        return Color3.fromRGB(150,150,150)
    end

    local selectedAreaName = ZoneOrder[1]
    local TeleportGroup = OceanTab:AddLeftGroupbox('Teleportation')
    TeleportGroup:AddDropdown('AreaSelector', { Values = ZoneOrder, Default = 1, Multi = false, Text = 'Target Area', Callback = function(v) selectedAreaName = v end })
    TeleportGroup:AddButton({ Text = 'Teleport', Func = function()
        if HardcodedZones[selectedAreaName] then teleportTo(HardcodedZones[selectedAreaName]) end
    end })
    TeleportGroup:AddButton({ Text = 'Teleport Back (Aquarium)', Func = function()
        pcall(function() workspace.Network["Teleport-RemoteEvent"]:FireServer("Aquarium") end)
    end })

    local autoTPRareEnabled = false
    local lastTPTime = 0
    TeleportGroup:AddToggle('AutoTPRare', { Text = 'Auto TP to Rare Spawns', Default = false, Callback = function(v) autoTPRareEnabled = v end })
    pcall(function()
        game:GetService("TextChatService").MessageReceived:Connect(function(msg)
            if not autoTPRareEnabled or tick()-lastTPTime < 5 then return end
            local m = msg.Text
            if m:find("has spawned in") and (m:find("Secret") or m:find("Divine") or m:find("Mythical") or m:find("Legendary")) then
                local zone = (m:match("has spawned in (%S+)") or ""):gsub("%p+$","")
                if HardcodedZones[zone] then
                    lastTPTime = tick()
                    teleportTo(HardcodedZones[zone])
                    Library:Notify("Auto-TP → rare spawn in "..zone)
                end
            end
        end)
    end)

    local ProtectionGroup = OceanTab:AddRightGroupbox('Protection & Speed')
    local antiDrownEnabled = false
    local antiDrownConn = nil
    ProtectionGroup:AddToggle('AntiDrown', { Text = 'Anti Drown', Default = false, Callback = function(v)
        antiDrownEnabled = v
        if v then
            if not antiDrownConn then
                local teleporting = false
                antiDrownConn = player.AttributeChanged:Connect(function(attr)
                    if attr == "IsDrowning" and player:GetAttribute("IsDrowning") and not teleporting and antiDrownEnabled then
                        teleporting = true
                        local char = player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            local savedCF = char.HumanoidRootPart.CFrame
                            pcall(function() workspace.Network["Teleport-RemoteEvent"]:FireServer("Aquarium") end)
                            task.wait(0.5)
                            char:PivotTo(savedCF)
                        end
                        task.wait(1)
                        teleporting = false
                    end
                end)
            end
        elseif antiDrownConn then
            antiDrownConn:Disconnect()
            antiDrownConn = nil
        end
    end })

    local swimSpeedVal = 1
    ProtectionGroup:AddSlider('SwimSpeed', { Text = 'Swim Speed Multiplier', Min = 1, Max = 20, Default = 1, Rounding = 1, Callback = function(v)
        swimSpeedVal = v
        pcall(function() workspace:SetAttribute("AdminSpeedMultiplier", v) end)
    end })
    player.CharacterAdded:Connect(function()
        task.wait(1)
        pcall(function() workspace:SetAttribute("AdminSpeedMultiplier", swimSpeedVal) end)
    end)

    local reachEnabled = false
    local function applyReach(p)
        if reachEnabled and p:IsA("ProximityPrompt") then
            p.HoldDuration = 0
            p.MaxActivationDistance = 60
            p.RequiresLineOfSight = false
        end
    end
    workspace.DescendantAdded:Connect(applyReach)
    ProtectionGroup:AddToggle('Reach', { Text = 'Reach / Instant Interact', Default = false, Callback = function(v)
        reachEnabled = v
        if v then for _, p in pairs(workspace:GetDescendants()) do applyReach(p) end end
    end })

    local function getPredictedPosition(v)
        local sPos = v:GetAttribute("StartPos")
        local tPos = v:GetAttribute("TargetPos")
        local sTime = v:GetAttribute("StartTime")
        local speed = v:GetAttribute("Speed") or 5
        if sPos and tPos and sTime then
            local now = workspace:GetServerTimeNow()
            local elapsed = now - sTime
            local dist = (tPos - sPos).Magnitude
            local duration = dist / (speed > 0 and speed or 5)
            local alpha = math.clamp(elapsed / (duration > 0 and duration or 0.1), 0, 1)
            return sPos:Lerp(tPos, alpha)
        end
        return v:GetPivot().Position
    end

    local AutofarmGroup = AutofarmTab:AddLeftGroupbox('Automations')
    local autoFarmEnabled = false
    local tntSpoofEnabled = false
    local selectedMutationFilters, selectedRarityFilters = {}, {}
    local selectedSpecificFish = "Any"
    local targetFishInput = ""

    AutofarmGroup:AddToggle('TNTSpoof', { Text = 'Instant Catch (TNT Spoof)', Default = false, Callback = function(v) tntSpoofEnabled = v end })
    AutofarmGroup:AddToggle('AutoFarm', { Text = 'Teleport Autofarm', Default = false, Callback = function(v) autoFarmEnabled = v end })
    AutofarmGroup:AddDropdown('TargetFish', { Values = {"Any"}, Default = 1, Multi = false, Text = 'Target Fish', Callback = function(v) selectedSpecificFish = v end })
    AutofarmGroup:AddInput('ManualFish', { Text = 'Manual Name Filter', Default = '', Callback = function(v) targetFishInput = v end })

    local FiltersGroup = AutofarmTab:AddRightGroupbox('Filters')
    FiltersGroup:AddDropdown('MutationFilter', { Values = MutationTypes, Default = 1, Multi = true, Text = 'Mutation Filter', Callback = function(v) selectedMutationFilters = v end })
    FiltersGroup:AddDropdown('RarityFilter', { Values = {"Normal","Common","Rare","Epic","Legendary","Mythical","Secret","Divine"}, Default = 1, Multi = true, Text = 'Rarity Filter', Callback = function(v) selectedRarityFilters = v end })

    -- TNT Spoof Loop
    task.spawn(function()
        while true do
            task.wait(0.5)
            if tntSpoofEnabled then
                pcall(function()
                    local Client = require(player.PlayerScripts:WaitForChild("Client"))
                    local fishesToNuke = {}
                    local myPos = player.Character and player.Character:GetPivot().Position
                    if myPos then
                        for _, v in pairs(CollectionService:GetTagged("SpawnedFish")) do
                            if v:IsA("Model") and v.Parent and not v:GetAttribute("Claimed") then
                                if (v:GetPivot().Position - myPos).Magnitude <= 150 then
                                    local mut, rar = getFishData(v)
                                    if checkFilters(mut, rar, selectedMutationFilters, selectedRarityFilters) then
                                        table.insert(fishesToNuke, v)
                                    end
                                end
                            end
                        end
                    end
                    if #fishesToNuke > 0 then Client.Network.Fire("TNTActivated", fishesToNuke) end
                end)
            end
        end
    end)

    -- Teleport Loop
    task.spawn(function()
        while true do
            task.wait(0.1)
            if autoFarmEnabled then
                for _, v in pairs(CollectionService:GetTagged("SpawnedFish")) do
                    if not autoFarmEnabled then break end
                    if v:IsA("Model") and v.Parent and not v:GetAttribute("Claimed") then
                        local nameMatch = (selectedSpecificFish == "Any" and targetFishInput == "") or (selectedSpecificFish ~= "Any" and v.Name == selectedSpecificFish) or (targetFishInput ~= "" and string.find(v.Name:lower(), targetFishInput:lower()))
                        if nameMatch then
                            local mut, rar = getFishData(v)
                            if checkFilters(mut, rar, selectedMutationFilters, selectedRarityFilters) then
                                local prompt = v:FindFirstChildOfClass("ProximityPrompt", true)
                                if prompt and prompt.Enabled then
                                    local char = player.Character
                                    if char and char.PrimaryPart then
                                        local targetPos = getPredictedPosition(v)
                                        char.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
                                        char:PivotTo(CFrame.new(targetPos) * CFrame.new(0,3,0))
                                        task.wait(0.1)
                                        if autoFarmEnabled then pcall(function() fireproximityprompt(prompt) end) end
                                        task.wait(0.2)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    local autoSellEnabled = false
    AutofarmGroup:AddToggle('AutoSell', { Text = 'Auto Sell Fish', Default = false, Callback = function(v) autoSellEnabled = v end })
    task.spawn(function()
        while true do
            task.wait(2.5)
            if autoSellEnabled then
                pcall(function() RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\003\001")) end)
            end
        end
    end)

    local FishEspGroup = VisualsTab:AddLeftGroupbox('Fish ESP')
    local fishEspEnabled = false
    local espMFilters, espRFilters = {}, {}

    FishEspGroup:AddToggle('FishEsp', { Text = 'Enable Fish ESP', Default = false, Callback = function(v)
        fishEspEnabled = v
        if not v then for _, f in pairs(Fish:GetChildren()) do pcall(function() ESP:Remove(f) end) end end
    end })
    FishEspGroup:AddDropdown('EspMutFilter', { Values = MutationTypes, Default = 1, Multi = true, Text = 'Mutation Filter', Callback = function(v) espMFilters = v end })
    FishEspGroup:AddDropdown('EspRarFilter', { Values = {"Normal","Common","Rare","Epic","Legendary","Mythical","Secret","Divine"}, Default = 1, Multi = true, Text = 'Rarity Filter', Callback = function(v) espRFilters = v end })

    local function addFishEsp(f)
        if not fishEspEnabled or not f:IsA("Model") or ESP.Objects[f] then return end
        local mut, rar = getFishData(f)
        if not checkFilters(mut, rar, espMFilters, espRFilters) then return end
        local label = f.Name .. (mut~="none" and " ["..mut.."]" or "") .. (rar~="normal" and " ["..rar.."]" or "")
        task.spawn(function()
            local root = f:FindFirstChild("RootPart") or f:WaitForChild("RootPart", 5)
            if root and fishEspEnabled then
                ESP:Add(f, { Name=label, PrimaryPart=root, Color=fishColor(mut,rar), IsEnabled=function() return fishEspEnabled and f.Parent==Fish end })
            end
        end)
    end
    Fish.ChildAdded:Connect(function(f) task.wait(0.5); addFishEsp(f) end)
    Fish.ChildRemoved:Connect(function(f) pcall(function() ESP:Remove(f) end) end)
    FishEspGroup:AddButton({ Text = 'Refresh Filter', Func = function()
        for _, f in pairs(Fish:GetChildren()) do if fishEspEnabled then addFishEsp(f) else pcall(function() ESP:Remove(f) end) end end
    end })

    local AreaEspGroup = VisualsTab:AddRightGroupbox('Area ESP')
    local areaEspEnabled = false
    AreaEspGroup:AddToggle('AreaEsp', { Text = 'Enable Area ESP', Default = false, Callback = function(v)
        areaEspEnabled = v
        if not v then for _, m in pairs(Markers:GetChildren()) do pcall(function() ESP:Remove(m) end) end
        else for _, m in pairs(Markers:GetChildren()) do if not ESP.Objects[m] then pcall(function() ESP:Add(m, { Name="[Zone] "..m.Name, Color=Color3.fromRGB(0,150,255), TextOnly=true, IsEnabled=function() return areaEspEnabled end }) end) end end end
    end })

    local function firePacket(id, hasResponse)
        pcall(function() RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring(string.char(id)..(hasResponse and "\001" or ""))) end)
    end

    local MiscGroup = MiscTab:AddLeftGroupbox('Utilities')
    MiscGroup:AddButton({ Text = 'Spin Wheel',          Func = function() firePacket(19, true)  end })
    MiscGroup:AddButton({ Text = 'Claim Offline Reward', Func = function() firePacket(10, false) end })
    MiscGroup:AddButton({ Text = 'Cancel Death Screen',  Func = function() firePacket(11, false) end })
    MiscGroup:AddButton({ Text = 'Respawn',              Func = function() firePacket(7,  false) end })

    local autoSpin = false
    MiscGroup:AddToggle('AutoSpin', { Text = 'Auto Spin Wheel', Default = false, Callback = function(v) autoSpin = v end })
    task.spawn(function() while true do task.wait(10); if autoSpin then firePacket(19, true) end end end)

    MiscGroup:AddButton({ Text = 'Remote Sell All', Func = function()
        pcall(function()
            local Client = require(player.PlayerScripts:WaitForChild("Client"))
            local res = Client.Network.Invoke("SellInventory")
            Library:Notify("Sold inventory for $" .. tostring(res or 0))
        end)
    end })

    local autoClaimBloop = false
    MiscGroup:AddToggle('AutoClaimBloop', { Text = 'Auto-Claim Bloop Quest', Default = false, Callback = function(v) autoClaimBloop = v end })
    task.spawn(function()
        while true do
            task.wait(10)
            if autoClaimBloop then
                pcall(function()
                    local Client = require(player.PlayerScripts:WaitForChild("Client"))
                    local st = Client.Network.Invoke("GetBloopQuestState")
                    if st and st.AllCompleted and not st.SkinClaimed then
                        Client.Network.Invoke("ClaimBloopQuest")
                        Library:Notify("Bloop Aquarium Skin claimed!")
                    end
                end)
            end
        end
    end)

    local ScheduleGroup = MiscTab:AddRightGroupbox('Spawn Schedule')
    local MermaidLabel = ScheduleGroup:AddLabel('Next Mermaid: Loading...')
    local BloopLabel   = ScheduleGroup:AddLabel('Next Bloop: Loading...')
    task.spawn(function()
        local MM = require(RS.Modules.MermaidSpawnSchedule)
        local BM = require(RS.Modules.BloopSpawnSchedule)
        while true do
            local now = os.time()
            pcall(function()
                local nm = MM.NextMermaidSpawn(now)
                if nm then MermaidLabel:SetText(string.format("Next Mermaid: %02d:%02d:%02d", math.floor((nm-now)/3600), math.floor(((nm-now)%3600)/60), (nm-now)%60)) end
                local nb = BM.NextBloopSpawn(now)
                if nb then BloopLabel:SetText(string.format("Next Bloop: %02d:%02d:%02d", math.floor((nb-now)/3600), math.floor(((nb-now)%3600)/60), (nb-now)%60)) end
            end)
            task.wait(1)
        end
    end)

    -- [[ NEW FEATURES BASED ON DECOMPILED INFO ]]
    
    -- 1. Admin Join Notifier
    game:GetService("Players").PlayerAdded:Connect(function(p)
        if p:GetAttribute("IsAdmin") or p:GetAttribute("IsDev") then
            Library:Notify("⚠️ ADMIN JOINED: " .. p.Name, 15)
            if autoFarmEnabled then autoFarmEnabled = false; Library:Notify("Autofarm disabled for safety!") end
        end
    end)

    -- 2. Profit Predictor (Backpack Value)
    local FishEarnings = require(RS.Modules.FishEarnings)
    local BackpackLabel = MiscTab:AddLabel('Backpack Value: $0')
    task.spawn(function()
        while true do
            task.wait(2)
            local total = 0
            for _, tool in pairs(player.Backpack:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("Weight") then
                    local fakeFish = {
                        Name = tool.Name,
                        Weight = tool:GetAttribute("Weight"),
                        Mutations = tool:GetAttribute("Mutations") or {},
                        AgeYears = tool:GetAttribute("AgeYears") or 0,
                        Zone = tool:GetAttribute("Zone") or "SunlightZone"
                    }
                    total = total + FishEarnings.calculateCashPerSecond(nil, fakeFish)
                end
            end
            BackpackLabel:SetText("Backpack Value: $" .. tostring(total))
        end
    end)

    -- 3. Auto-Gear Upgrader
    local GearConfig = require(RS.Modules.GearConfig)
    local autoUpgradeGear = false
    ProtectionGroup:AddToggle('AutoUpgradeGear', { Text = 'Auto-Upgrade Gear', Default = false, Callback = function(v) autoUpgradeGear = v end })
    task.spawn(function()
        while true do
            task.wait(5)
            if autoUpgradeGear then
                pcall(function()
                    local save = require(player.PlayerScripts.Client).Network.Invoke("Get Save")
                    local cash = player:GetAttribute("Cash") or 0
                    for category, items in pairs(GearConfig) do
                        local owned = save.OwnedGear and save.OwnedGear[category] or {}
                        local nextItem = nil
                        for itemName, data in pairs(items) do
                            if not table.find(owned, itemName) and data.price then
                                if not nextItem or data.order < GearConfig[category][nextItem].order then
                                    nextItem = itemName
                                end
                            end
                        end
                        if nextItem and GearConfig[category][nextItem].price <= cash then
                            require(player.PlayerScripts.Client).Network.Invoke("BuyItem", category, nextItem)
                            Library:Notify("Auto-Upgraded " .. category .. " to " .. nextItem)
                        end
                    end
                end)
            end
        end
    end)

    local ShopGroup = MiscTab:AddLeftGroupbox('Auto Shop')
    local function fireBuy(store, item) pcall(function() RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring(string.char(4)..string.char(#store)..store..string.char(#item)..item)) end) end
    local autoBuyTreats, autoBuyTools = false, false
    ShopGroup:AddToggle('AutoBuyTreats', { Text = 'Auto Buy Treats', Default = false, Callback = function(v) autoBuyTreats = v end })
    ShopGroup:AddToggle('AutoBuyTools',  { Text = 'Auto Buy Tools',  Default = false, Callback = function(v) autoBuyTools  = v end })
    task.spawn(function()
        while true do
            task.wait(5)
            if not autoBuyTreats and not autoBuyTools then continue end
            pcall(function()
                local shops = player.PlayerGui:FindFirstChild("PersistentUI") and player.PlayerGui.PersistentUI:FindFirstChild("Shops")
                if not shops then return end
                local function buyFromShop(name, enabled)
                    if not enabled then return end
                    local sf = shops:FindFirstChild(name) and shops[name]:FindFirstChild("Content") and shops[name].Content:FindFirstChild("ScrollingFrame")
                    if not sf then return end
                    for _, item in pairs(sf:GetChildren()) do
                        if not item:IsA("Frame") or item.Name == "UIListLayout" then continue end
                        local stockLabel = item:FindFirstChild("SlotTemplate") and item.SlotTemplate:FindFirstChild("StockAmount")
                        if stockLabel then
                            local txt = stockLabel.Text:upper()
                            if not txt:find("NO STOCK") then
                                local stock = tonumber(txt:match("%d+")) or 0
                                for _ = 1, stock do if not enabled then break end; fireBuy(name, item.Name); task.wait(0.15) end
                            end
                        end
                    end
                end
                buyFromShop("Treat", autoBuyTreats)
                buyFromShop("Tool",  autoBuyTools)
            end)
        end
    end)

    local AqGroup = AquariumTab:AddLeftGroupbox('Aquarium')
    local function equipBest()
        pcall(function()
            local net = workspace:FindFirstChild("Network")
            local rem = net and (net:FindFirstChild("RequestEquipBestFish-RemoteFunction") or net:FindFirstChild("RequestEquipBestFish"))
            if rem then if rem:IsA("RemoteFunction") then rem:InvokeServer() else rem:FireServer() end end
        end)
    end
    AqGroup:AddButton({ Text = 'Equip Best Fish', Func = equipBest })
    local autoEquipBest = false
    AqGroup:AddToggle('AutoEquipBest', { Text = 'Auto Equip Best', Default = false, Callback = function(v) autoEquipBest = v end })
    task.spawn(function() while true do task.wait(5); if autoEquipBest then equipBest() end end end)

    local smartSellFilters = {}
    local smartSellEnabled = false
    AqGroup:AddDropdown('SmartSellFilter', { Values = {"Normal","Common","Rare","Epic","Legendary","Mythical","Secret","Divine"}, Default = 1, Multi = true, Text = 'Smart Sell Rarity', Callback = function(v) smartSellFilters = v end })
    AqGroup:AddToggle('SmartSell', { Text = 'Smart Sell Fish', Default = false, Callback = function(v) smartSellEnabled = v end })
    task.spawn(function()
        while true do
            task.wait(5)
            if not smartSellEnabled then continue end
            pcall(function()
                for _, tool in pairs(player.Backpack:GetChildren()) do
                    if not tool:IsA("Tool") then continue end
                    local rarity = "Normal"
                    for _, c in pairs(tool:GetChildren()) do
                        if c:IsA("BasePart") then
                            local bgui = c:FindFirstChild("BillboardGui")
                            if bgui and bgui:FindFirstChild("Frame") and bgui.Frame:FindFirstChild("Rarity") then rarity = bgui.Frame.Rarity.Text:gsub("<[^>]+>",""); break end
                        end
                    end
                    if rarity == "Normal" then rarity = tool.Name:match("%[(.-)%]") or "Normal" end
                    local sell = false
                    local count = 0; for _, v in pairs(smartSellFilters) do if v then count=count+1 end end
                    if count == 0 then sell = true else for k, v in pairs(smartSellFilters) do if v and rarity:lower():find(k:lower()) then sell=true; break end end end
                    if sell then
                        tool.Parent = player.Character; task.wait(0.1)
                        RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\002\001\r"), {player})
                        task.wait(0.2)
                    end
                end
            end)
        end
    end)
end

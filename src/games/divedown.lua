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

    local TeleportGroup = OceanTab:AddLeftGroupbox('Teleportation')
    local selectedAreaName = ZoneOrder[1]
    TeleportGroup:AddDropdown('AreaSelector', { Values = ZoneOrder, Default = ZoneOrder[1], Multi = false, Text = 'Target Area', Callback = function(v) selectedAreaName = v end })
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
    ProtectionGroup:AddSlider('SwimSpeed', { Text = 'Swim Speed', Min = 1, Max = 100, Default = 1, Rounding = 1, Compact = false, Callback = function(v) workspace:SetAttribute("AdminSpeedMultiplier", v) end })

    local FarmGroup = AutofarmTab:AddLeftGroupbox('Farming')
    local autofarmEnabled, mapVacuumEnabled, autoSellEnabled = false, false, false
    local mFilters, rFilters = {["Normal"]=true}, {["Normal"]=true}
    local selectedSpecificFish, targetFishInput = "Any", ""

    FarmGroup:AddToggle('MapVacuum', { Text = 'Map Vacuum', Default = false, Callback = function(v) mapVacuumEnabled = v end })
    FarmGroup:AddToggle('AutoFarm', { Text = 'Teleport Farm', Default = false, Callback = function(v) autofarmEnabled = v end })
    FarmGroup:AddToggle('AutoSell', { Text = 'Auto Sell', Default = false, Callback = function(v) autoSellEnabled = v end })

    local FishDrop = FarmGroup:AddDropdown('TargetFish', { Values = {"Any"}, Default = "Any", Multi = false, Text = 'Specific Fish', Callback = function(v) selectedSpecificFish = v end })
    FarmGroup:AddButton({ Text = 'Refresh Fish List', Func = function()
        local list = {"Any"}
        for _, v in pairs(Fish:GetChildren()) do if not table.find(list, v.Name) then table.insert(list, v.Name) end end
        FishDrop:SetValues(list)
    end })
    FarmGroup:AddInput('ManualFish', { Text = 'Manual Name Filter', Default = '', Callback = function(v) targetFishInput = v end })

    local FilterGroup = AutofarmTab:AddRightGroupbox('Filters')
    FilterGroup:AddDropdown('MutF', { Values = MutationTypes, Default = {["Normal"]=true}, Multi = true, Text = 'Mutation Filter', Callback = function(v) mFilters = v end })
    FilterGroup:AddDropdown('RarF', { Values = {"Normal","Common","Rare","Epic","Legendary","Mythical","Secret","Divine"}, Default = {["Normal"]=true}, Multi = true, Text = 'Rarity Filter', Callback = function(v) rFilters = v end })

    task.spawn(function()
        while true do
            task.wait(0.3)
            if mapVacuumEnabled then
                local fList = {}
                for _, v in pairs(Fish:GetChildren()) do
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
                for _, v in pairs(Fish:GetChildren()) do
                    if not autofarmEnabled then break end
                    if v:IsA("Model") and v.Parent and not v:GetAttribute("Claimed") then
                        local match = (selectedSpecificFish == "Any") or (v.Name == selectedSpecificFish) or (targetFishInput ~= "" and v.Name:lower():find(targetFishInput:lower()))
                        if match then
                            local m, r = getFishData(v)
                            if checkFilters(m, r, mFilters, rFilters) then
                                local root = v:FindFirstChild("RootPart") or v:FindFirstChildWhichIsA("BasePart", true)
                                local p = (root and root:FindFirstChildWhichIsA("ProximityPrompt", true)) or v:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if p and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                    p.HoldDuration = 0; p.MaxActivationDistance = 9e9; p.Enabled = true
                                    player.Character.HumanoidRootPart.CFrame = v:GetPivot() * CFrame.new(0, 3, 0)
                                    task.wait(0.2)
                                    if autofarmEnabled then fireproximityprompt(p) end
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    task.spawn(function() while true do task.wait(2.5); if autoSellEnabled then RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\003\001")) end end end)

    local fishEspEnabled, areaEspEnabled = false, false
    local espMFilters, espRFilters = {["Normal"]=true}, {["Normal"]=true}
    local EspMain = VisualsTab:AddLeftGroupbox('Fish ESP')
    EspMain:AddToggle('FishEsp', { Text = 'Enable Fish ESP', Default = false, Callback = function(v) fishEspEnabled = v end })
    EspMain:AddDropdown('EspMutF', { Values = MutationTypes, Default = {["Normal"]=true}, Multi = true, Text = 'ESP Mutation Filter', Callback = function(v) espMFilters = v end })
    EspMain:AddDropdown('EspRarF', { Values = {"Normal","Common","Rare","Epic","Legendary","Mythical","Secret","Divine"}, Default = {["Normal"]=true}, Multi = true, Text = 'ESP Rarity Filter', Callback = function(v) espRFilters = v end })
    VisualsTab:AddRightGroupbox('Area ESP'):AddToggle('AreaEsp', { Text = 'Enable Area ESP', Default = false, Callback = function(v) areaEspEnabled = v end })

    task.spawn(function()
        while true do
            task.wait(1)
            if fishEspEnabled then
                for _, f in pairs(Fish:GetChildren()) do
                    if f:IsA("Model") and f.Parent and not f:GetAttribute("Claimed") then
                        local m, r = getFishData(f)
                        if checkFilters(m, r, espMFilters, espRFilters) then
                            if not ESP.Objects[f] then ESP:Add(f, { Name = f.Name .. " [" .. m .. "]", Color = Color3.fromRGB(255, 255, 255), IsEnabled = function() return fishEspEnabled and f.Parent ~= nil end }) end
                        else pcall(function() ESP:Remove(f) end) end
                    end
                end
            else for _, f in pairs(Fish:GetChildren()) do pcall(function() ESP:Remove(f) end) end end
            if areaEspEnabled then
                for name, pos in pairs(HardcodedZones) do
                    local node = Markers:FindFirstChild(name) or Instance.new("Part", workspace); node.Name = name; node.Transparency = 1; node.Anchored = true; node.CFrame = CFrame.new(pos)
                    if not ESP.Objects[node] then ESP:Add(node, { Name = name, Color = Color3.fromRGB(0, 255, 255), TextOnly = true, IsEnabled = function() return areaEspEnabled end }) end
                end
            else for name, _ in pairs(HardcodedZones) do local node = Markers:FindFirstChild(name); if node then pcall(function() ESP:Remove(node) end) end end end
        end
    end)

    local MiscUtils = MiscTab:AddLeftGroupbox('Utilities')
    local TimerLabel = MiscUtils:AddLabel('Timers Loading...')
    task.spawn(function()
        local function getVal(m)
            if not m then return 0 end
            -- try schedule-style API first
            if type(m.NextBloopSpawn) == "function" then
                local ok, nextT = pcall(function() return m.NextBloopSpawn(os.time()) end)
                if ok and type(nextT) == "number" then return nextT end
            end
            if type(m.NextMermaidSpawn) == "function" then
                local ok, nextT = pcall(function() return m.NextMermaidSpawn(os.time()) end)
                if ok and type(nextT) == "number" then return nextT end
            end
            -- fallbacks
            return m.NextSpawn or m.SpawnTime or m.Time or m.time or 0
        end

        while true do
            task.wait(1)
            local bMod = RS.Modules:FindFirstChild("BloopSpawnSchedule")
            local mMod = RS.Modules:FindFirstChild("MermaidSpawnSchedule")
            if bMod and mMod then
                local okB, bS = pcall(function() return require(bMod) end)
                local okM, mS = pcall(function() return require(mMod) end)
                if okB and okM and bS and mS then
                    local bNext = getVal(bS)
                    local mNext = getVal(mS)
                    local now = os.time()
                    local function hhmmss(secs)
                        secs = math.max(0, math.floor(secs))
                        local h = math.floor(secs / 3600)
                        local m = math.floor((secs % 3600) / 60)
                        local s = secs % 60
                        return string.format("%02d:%02d:%02d", h, m, s)
                    end
                    local bRem = (type(bNext) == "number") and math.max(0, math.floor(bNext - now)) or 0
                    local mRem = (type(mNext) == "number") and math.max(0, math.floor(mNext - now)) or 0
                    local bRemStr = hhmmss(bRem)
                    local mRemStr = hhmmss(mRem)
                    local bTimeStr = (type(bNext) == "number") and os.date("%Y-%m-%d %H:%M:%S", bNext) or "N/A"
                    local mTimeStr = (type(mNext) == "number") and os.date("%Y-%m-%d %H:%M:%S", mNext) or "N/A"
                    TimerLabel:SetText(string.format("Bloop: %s (in %s)\nMermaid: %s (in %s)", bTimeStr, bRemStr, mTimeStr, mRemStr))
                else
                    TimerLabel:SetText("Searching for Schedule Modules...")
                end
            else
                TimerLabel:SetText("Searching for Schedule Modules...")
            end
        end
    end)

    local ValueLabel = MiscUtils:AddLabel('Backpack Value: $0')
    task.spawn(function()
        local Earnings = require(RS.Modules.FishEarnings)
        while true do
            task.wait(1)
            local total = 0
            local bf = player:FindFirstChild("BackpackFish")
            if bf then for _, f in pairs(bf:GetChildren()) do total = total + (Earnings[f.Name] or 0) end
            else for _, f in pairs(player:GetAttribute("BackpackFish") or {}) do total = total + (Earnings[f] or 0) end end
            ValueLabel:SetText("Backpack Value: $" .. total)
        end
    end)

    MiscUtils:AddButton({ Text = 'Spin Wheel', Func = function() RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\019\001")) end })
    MiscUtils:AddButton({ Text = 'Instant Respawn', Func = function() RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\007")) end })
    MiscUtils:AddButton({ Text = 'Weather Machine', Func = function() RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\024")) end })
    MiscUtils:AddButton({ Text = 'Rainbow Machine', Func = function() RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\025")) end })
    
    local autoShopTreats, autoShopTools = false, false
    local ShopGroup = MiscTab:AddRightGroupbox('Auto Shop')
    ShopGroup:AddToggle('AutoTreats', { Text = 'Auto Buy Treats', Default = false, Callback = function(v) autoShopTreats = v end })
    ShopGroup:AddToggle('AutoTools', { Text = 'Auto Buy Tools', Default = false, Callback = function(v) autoShopTools = v end })

    local buyCache = {}
    local knownEmpty = {}
    local function fireBuyItem(storeName, itemName)
        pcall(function()
            local str = string.char(4) .. string.char(#storeName) .. storeName .. string.char(#itemName) .. itemName
            RS:WaitForChild("Packets"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(buffer.fromstring(str))
        end)
    end
    
    task.spawn(function()
        while true do
            task.wait(3)
            pcall(function()
                local pgui = player:WaitForChild("PlayerGui")
                local ui = pgui:FindFirstChild("PersistentUI")
                if not ui then return end

                local function buyFromShop(shopKey, storeName)
                    local shops = ui:FindFirstChild("Shops")
                    if not shops then return end
                    local shop = shops:FindFirstChild(shopKey)
                    local content = shop and shop:FindFirstChild("Content")
                    local scroll = content and content:FindFirstChild("ScrollingFrame")
                    if not scroll then return end

                    for _, itemFrame in pairs(scroll:GetChildren()) do
                        if not (itemFrame:IsA("Frame") or itemFrame:IsA("ImageButton") or itemFrame:IsA("TextButton")) then continue end
                        local slot = itemFrame:FindFirstChild("SlotTemplate")
                        local stockLabel = slot and slot:FindFirstChild("StockAmount")
                        local key = storeName..":"..tostring(itemFrame.Name)

                        -- Skip if we've marked this item known-empty
                        if knownEmpty[key] then continue end

                        if stockLabel and stockLabel:IsA("TextLabel") then
                            local txt = tostring(stockLabel.Text or "")
                            local stockNum = tonumber(txt:match("%d+")) or 0

                            -- If no numeric stock found, mark as empty and skip
                            if stockNum <= 0 then
                                knownEmpty[key] = true
                                continue
                            end

                            -- Clear known-empty marker since numeric stock is present
                            knownEmpty[key] = nil

                            -- Respect toggles
                            if (storeName == "Treat" and not autoShopTreats) or (storeName == "Tool" and not autoShopTools) then continue end

                            -- Rate-limit per item key (30s)
                            local last = buyCache[key]
                            if last and tick() - last < 30 then continue end

                            -- Buy one unit (safer), record attempt
                            fireBuyItem(storeName, itemFrame.Name)
                            buyCache[key] = tick()
                        end
                    end
                end

                if autoShopTreats then buyFromShop("Treat", "Treat") end
                if autoShopTools then buyFromShop("Tool", "Tool") end
            end)
        end
    end)

    local autoUpgradeEnabled = false
    MiscTab:AddRightGroupbox('Progression'):AddToggle('AutoUpgrade', { Text = 'Auto-Upgrade Gear', Default = false, Callback = function(v) autoUpgradeEnabled = v end })
    task.spawn(function()
        local Gear = require(RS.Modules.GearConfig)
        local Client = player.PlayerScripts:WaitForChild("Client")
        local Net = require(Client).Network
        while true do
            task.wait(5)
            if autoUpgradeEnabled then
                local cash = player:GetAttribute("Cash") or 0
                for cat, items in pairs(Gear) do
                    for itemName, data in pairs(items) do
                        if data.price and data.price <= cash then pcall(function() Net.Invoke("BuyItem", cat, itemName) end) end
                    end
                end
            end
        end
    end)

    local AqGroup = AquariumTab:AddLeftGroupbox('Aquarium')

    local function equipBestFish()
        pcall(function()
            local netW = workspace:FindFirstChild("Network")
            if netW then
                local remote = netW:FindFirstChild("RequestEquipBestFish-RemoteFunction") or netW:FindFirstChild("RequestEquipBestFish")
                if remote then
                    if remote:IsA("RemoteFunction") then
                        remote:InvokeServer()
                    elseif remote:IsA("RemoteEvent") then
                        remote:FireServer()
                    end
                end
            end
        end)
        pcall(function()
            require(player.PlayerScripts.Client).Network.Invoke("RequestEquipBestFish")
        end)
    end

    local autoEquipBest = false
    AqGroup:AddButton({ Text = 'Equip Best Fish', Func = equipBestFish })
    AqGroup:AddToggle('AutoEquipBest', { Text = 'Always Equip Best Fish', Default = false, Callback = function(v) autoEquipBest = v end })

    task.spawn(function()
        while true do
            task.wait(3)
            if autoEquipBest then
                equipBestFish()
            end
        end
    end)

    local function getFishRarity(tool)
        for _, child in pairs(tool:GetChildren()) do
            if child:IsA("BasePart") then
                local bg = child:FindFirstChild("BillboardGui")
                local frame = bg and bg:FindFirstChild("Frame")
                local rarity = frame and frame:FindFirstChild("Rarity")
                if rarity and rarity:IsA("TextLabel") then
                    return rarity.Text:gsub("<[^>]+>", "")
                end
            end
        end
        local fromName = tool.Name:match("%[(.-)%]")
        return fromName or "Unknown"
    end

    local function selectedContains(filterTable, value)
        if type(filterTable) ~= "table" then return false end
        local needle = tostring(value):lower()
        for k, v in pairs(filterTable) do
            local current = type(k) == "number" and v or k
            if type(current) == "string" then
                local active = (type(k) == "number") or (v == true)
                if active and current:lower() == needle then
                    return true
                end
            end
        end
        return false
    end

    local function hasAnySelected(filterTable)
        if type(filterTable) ~= "table" then return false end
        for k, v in pairs(filterTable) do
            if type(k) == "number" then return true end
            if type(k) == "string" and v == true then return true end
        end
        return false
    end

    local function equipAndSell(tool)
        pcall(function()
            local char = player.Character
            if not char then return end
            tool.Parent = char
            task.wait(0.1)
            RS:WaitForChild("Packets"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(
                buffer.fromstring("\002\001\013"),
                {player}
            )
        end)
    end

    local smartSellEnabled = false
    local smartSellRarities = {}
    AqGroup:AddDropdown('SmartSellRarity', {
        Values = {"Normal", "Common", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Divine"},
        Default = {},
        Multi = true,
        Text = 'Smart Sell Rarity'
        ,Callback = function(v) smartSellRarities = v end
    })
    AqGroup:AddToggle('SmartSellToggle', { Text = 'Smart Sell Fish', Default = false, Callback = function(v) smartSellEnabled = v end })

    task.spawn(function()
        while true do
            task.wait(5)
            if smartSellEnabled and hasAnySelected(smartSellRarities) then
                for _, tool in pairs(player.Backpack:GetChildren()) do
                    if not smartSellEnabled then break end
                    if tool:IsA("Tool") then
                        local rarity = getFishRarity(tool)
                        if selectedContains(smartSellRarities, rarity) then
                            equipAndSell(tool)
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
    end)
end

return function(Window, ESP, Library)
    local player = game:GetService("Players").LocalPlayer
    local RS = game:GetService("ReplicatedStorage")

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

    local function getFishData(fish)
        local mut, rar = "none", "normal"
        local bp = fish:FindFirstChild(fish.Name.."BillboardPart") or fish:WaitForChild(fish.Name.."BillboardPart", 2)
        if bp then
            local frame = bp:FindFirstChildOfClass("BillboardGui") and bp:FindFirstChildOfClass("BillboardGui"):FindFirstChild("Frame")
            if frame then
                local mLab = frame:FindFirstChild("Mutations")
                local rLab = frame:FindFirstChild("Rarity")
                if mLab then local t = mLab.Text:gsub("<[^>]+>",""):lower():match("^%s*(.-)%s*$") if t~="" and t~="none" then mut=t end end
                if rLab then local t = rLab.Text:gsub("<[^>]+>",""):lower():match("^%s*(.-)%s*$") if t~="" and t~="normal" then rar=t end end
            end
        end
        return mut, rar
    end

    local function checkFilters(mut, rar, mFilters, rFilters)
        local mCount, rCount = 0, 0
        for _, v in pairs(mFilters) do if v then mCount=mCount+1 end end
        for _, v in pairs(rFilters) do if v then rCount=rCount+1 end end
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
    local function fishColor(mut, rar)
        for k, c in pairs(rarityColor) do if string.find(rar, k) then return c end end
        if mut ~= "none" then return Color3.fromRGB(255,255,0) end
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
    ProtectionGroup:AddToggle('Reach', { Text = 'Reach / Instant Interact', Default = false, Callback = function(v)
        reachEnabled = v
        if v then
            for _, p in pairs(workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") then p.HoldDuration=0; p.MaxActivationDistance=50; p.RequiresLineOfSight=false end
            end
        end
    end })

    local function getUniqueFishes()
        local list, map = {"Any"}, {}
        for _, v in ipairs(Fish:GetChildren()) do
            if v:IsA("Model") and not map[v.Name] then map[v.Name]=true; table.insert(list, v.Name) end
        end
        table.sort(list, function(a,b) if a=="Any" then return true end if b=="Any" then return false end return a<b end)
        return list
    end

    local AutofarmGroup = AutofarmTab:AddLeftGroupbox('Settings')
    local selectedSpecificFish = "Any"
    local targetFishInput = ""
    local FishDropdown = AutofarmGroup:AddDropdown('TargetFish', { Values = getUniqueFishes(), Default = 1, Text = 'Target Fish', Callback = function(v) selectedSpecificFish = v end })

    local isRefreshing = false
    local function refreshFishList()
        if isRefreshing then return end
        isRefreshing = true
        task.delay(0.5, function() pcall(function() FishDropdown:SetValues(getUniqueFishes()) end); isRefreshing = false end)
    end
    Fish.ChildAdded:Connect(refreshFishList)
    Fish.ChildRemoved:Connect(refreshFishList)

    AutofarmGroup:AddInput('ManualFish', { Text = 'Manual Name Filter', Default = '', Callback = function(v) targetFishInput = v end })
    local selectedMutationFilters = {}
    AutofarmGroup:AddDropdown('MutationFilter', { Values = {"None","Silver","Gold","Rainbow","Dry","Frozen","Shocked","Chocolate","Infected","Magma","Evil","Yinyang","Hacker","Taco","Galaxy"}, Default = 1, Multi = true, Text = 'Mutation Filter', Callback = function(v) selectedMutationFilters = v end })
    local selectedRarityFilters = {}
    AutofarmGroup:AddDropdown('RarityFilter', { Values = {"Normal","Common","Rare","Epic","Legendary","Mythical","Secret","Divine"}, Default = 1, Multi = true, Text = 'Rarity Filter', Callback = function(v) selectedRarityFilters = v end })

    local autoFarmEnabled = false
    AutofarmGroup:AddToggle('AutoFarm', { Text = 'Enable Autofarm', Default = false, Callback = function(v) autoFarmEnabled = v end })

    task.spawn(function()
        while true do
            task.wait(0.5)
            if autoFarmEnabled then
                for _, v in pairs(Fish:GetChildren()) do
                    if not autoFarmEnabled then break end
                    if v:IsA("Model") then
                        local nameMatch = (selectedSpecificFish == "Any" and targetFishInput == "") or
                            (selectedSpecificFish ~= "Any" and v.Name == selectedSpecificFish) or
                            (targetFishInput ~= "" and string.find(v.Name:lower(), targetFishInput:lower()))
                        if nameMatch then
                            local mut, rar = getFishData(v)
                            if checkFilters(mut, rar, selectedMutationFilters, selectedRarityFilters) then
                                local root = v:FindFirstChild("RootPart") or v:WaitForChild("RootPart", 2)
                                local prompt = root and root:FindFirstChildOfClass("ProximityPrompt")
                                if prompt and prompt.Enabled then
                                    local char = player.Character
                                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                    if hrp then
                                        hrp.AssemblyLinearVelocity = Vector3.zero
                                        char:PivotTo(root.CFrame * CFrame.new(0,3,0))
                                        task.wait(0.2)
                                        if autoFarmEnabled then pcall(function() fireproximityprompt(prompt) end) end
                                        task.wait(0.5)
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
    FishEspGroup:AddDropdown('EspMutFilter', { Values = {"None","Silver","Gold","Rainbow","Dry","Frozen","Shocked","Chocolate","Infected","Magma","Evil","Yinyang","Hacker","Taco","Galaxy"}, Default = 1, Multi = true, Text = 'Mutation Filter', Callback = function(v) espMFilters = v end })
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

    local function refreshFishEsp()
        for _, f in pairs(Fish:GetChildren()) do
            if fishEspEnabled then addFishEsp(f) else pcall(function() ESP:Remove(f) end) end
        end
    end
    FishEspGroup:AddButton({ Text = 'Refresh Filter', Func = refreshFishEsp })

    local AreaEspGroup = VisualsTab:AddRightGroupbox('Area ESP')
    local areaEspEnabled = false

    AreaEspGroup:AddToggle('AreaEsp', { Text = 'Enable Area ESP', Default = false, Callback = function(v)
        areaEspEnabled = v
        if not v then
            for _, m in pairs(Markers:GetChildren()) do pcall(function() ESP:Remove(m) end) end
        else
            for _, m in pairs(Markers:GetChildren()) do
                if not ESP.Objects[m] then
                    pcall(function() ESP:Add(m, { Name="[Zone] "..m.Name, Color=Color3.fromRGB(0,150,255), TextOnly=true, IsEnabled=function() return areaEspEnabled end }) end)
                end
            end
        end
    end })

    Markers.ChildAdded:Connect(function(m)
        task.wait(0.5)
        if areaEspEnabled and not ESP.Objects[m] then
            pcall(function() ESP:Add(m, { Name="[Zone] "..m.Name, Color=Color3.fromRGB(0,150,255), TextOnly=true, IsEnabled=function() return areaEspEnabled end }) end)
        end
    end)
    Markers.ChildRemoved:Connect(function(m) pcall(function() ESP:Remove(m) end) end)

    local function firePacket(id, hasResponse)
        pcall(function()
            RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring(string.char(id)..(hasResponse and "\001" or "")))
        end)
    end

    local MiscGroup = MiscTab:AddLeftGroupbox('Utilities')
    MiscGroup:AddButton({ Text = 'Spin Wheel',          Func = function() firePacket(19, true)  end })
    MiscGroup:AddButton({ Text = 'Claim Offline Reward', Func = function() firePacket(10, false) end })
    MiscGroup:AddButton({ Text = 'Cancel Death Screen',  Func = function() firePacket(11, false) end })
    MiscGroup:AddButton({ Text = 'Respawn',              Func = function() firePacket(7,  false) end })

    local autoSpin = false
    MiscGroup:AddToggle('AutoSpin', { Text = 'Auto Spin Wheel', Default = false, Callback = function(v) autoSpin = v end })
    task.spawn(function() while true do task.wait(10); if autoSpin then firePacket(19, true) end end end)

    local ExploitGroup = MiscTab:AddRightGroupbox('Exploits')

    ExploitGroup:AddButton({ Text = 'Recover Lost Items [TEST]', Func = function()
        local inv = player:FindFirstChild("Inventory")
        if not inv then Library:Notify("No Inventory found"); return end
        local count = 0
        for _, item in pairs(inv:GetChildren()) do
            pcall(function()
                RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring(string.char(13)..string.char(1)..item.Name))
                count = count + 1
            end)
            task.wait(0.1)
        end
        Library:Notify("Fired RecoverItem for "..count.." items")
    end })

    ExploitGroup:AddButton({ Text = 'Remove Weight (Better Swim)', Func = function()
        pcall(function()
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local wa = hrp:FindFirstChild("WeightAttachment")
                if wa then wa:Destroy() end
            end
        end)
    end })

    local autoRemoveWeight = false
    ExploitGroup:AddToggle('AutoRemoveWeight', { Text = 'Auto Remove Weight', Default = false, Callback = function(v)
        autoRemoveWeight = v
    end })
    task.spawn(function()
        while true do
            task.wait(1)
            if autoRemoveWeight then
                pcall(function()
                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local wa = hrp:FindFirstChild("WeightAttachment")
                        if wa then wa:Destroy() end
                    end
                end)
            end
        end
    end)

    local skinNameInput = ""
    ExploitGroup:AddInput('SkinName', { Text = 'Skin Name (exact)', Default = '', Callback = function(v) skinNameInput = v end })
    ExploitGroup:AddButton({ Text = 'Equip Aquarium Skin', Func = function()
        if skinNameInput == "" then Library:Notify("Enter a skin name first") return end
        pcall(function()
            RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\016" .. string.char(#skinNameInput) .. skinNameInput))
            Library:Notify("Tried to equip skin: " .. skinNameInput)
        end)
    end })

    ExploitGroup:AddButton({ Text = 'Open Weather Machine', Func = function() firePacket(8, false) end })
    ExploitGroup:AddButton({ Text = 'Request Rainbow Machine', Func = function() firePacket(18, true) end })

    local ShopGroup = MiscTab:AddLeftGroupbox('Auto Shop')
    local function fireBuy(store, item)
        pcall(function()
            RS.Packets.Packet.RemoteEvent:FireServer(buffer.fromstring(string.char(4)..string.char(#store)..store..string.char(#item)..item))
        end)
    end
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
                            if bgui and bgui:FindFirstChild("Frame") and bgui.Frame:FindFirstChild("Rarity") then
                                rarity = bgui.Frame.Rarity.Text:gsub("<[^>]+>",""); break
                            end
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

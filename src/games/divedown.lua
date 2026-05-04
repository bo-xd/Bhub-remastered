return function(Window, Tabs, ESP)
    local player = game:GetService("Players").LocalPlayer
    local camera = workspace.CurrentCamera
    local Fish = workspace:WaitForChild("Game"):WaitForChild("Fishes")

    local OceanTab = Window:AddTab('Ocean')
    local AutofarmTab = Window:AddTab('Autofarm')
    local VisualsTab = Window:AddTab('Visuals')
    local MiscTab = Window:AddTab('Misc')
    local AquariumTab = Window:AddTab('Aquarium')

    local HardcodedZones = {
        ["SunlightZone"] = Vector3.new(-1935.5, 2466.8, -1420.5),
        ["Area1"] = Vector3.new(-1934.9, 2447.1, -1429.0),
        ["Area2"] = Vector3.new(-1929.5, 2338.1, -1423.4),
        ["CoralReef"] = Vector3.new(-1934.0, 2336.6, -1418.3),
        ["TwilightZone"] = Vector3.new(-1928.1, 2106.0, -1421.2),
        ["Area3"] = Vector3.new(-1916.1, 2029.2, -1424.2),
        ["DeepOcean"] = Vector3.new(-1924.9, 1722.5, -1422.4),
        ["TheDeepDark"] = Vector3.new(-1938.6, 1004.3, -1422.2),
        ["TheTrenches"] = Vector3.new(-1938.6, 310.9, -1422.2),
        ["Atlantis"] = Vector3.new(-1932.6, -17.7, -1423.0),
        ["AquaForest"] = Vector3.new(-1932.6, -304.3, -1423.0),
        ["ShellReef"] = Vector3.new(-1932.6, -645.4, -1423.0),
        ["KrakenWorld"] = Vector3.new(-1932.6, -1107.9, -1423.0),
        ["MegalodonsLair"] = Vector3.new(-1927.7, -1591.8, -1418.6),
        ["IceArea"] = Vector3.new(-1927.7, -1961.3, -1418.6),
        ["JellyfishFields"] = Vector3.new(-1927.7, -2373.8, -1418.6),
        ["SteampunkZone"] = Vector3.new(-1927.7, -2885.3, -1418.6),
        ["DeadWaters"] = Vector3.new(-1927.7, -3361.3, -1418.6),
        ["Prehistoric"] = Vector3.new(-1927.7, -3820.8, -1418.6),
    }

    local HardcodedZonesOrder = {
        "SunlightZone", "Area1", "Area2", "CoralReef", "TwilightZone", "Area3", "DeepOcean",
        "TheDeepDark", "TheTrenches", "Atlantis", "AquaForest", "ShellReef", "KrakenWorld",
        "MegalodonsLair", "IceArea", "JellyfishFields", "SteampunkZone", "DeadWaters", "Prehistoric"
    }

    local selectedAreaName = HardcodedZonesOrder[1]
    local TeleportGroup = OceanTab:AddLeftGroupbox('Teleportation')

    TeleportGroup:AddDropdown('AreaSelector', { Values = HardcodedZonesOrder, Default = 1, Multi = false, Text = 'Target Area', Callback = function(v) selectedAreaName = v end })

    TeleportGroup:AddButton({
        Text = 'Teleport',
        Func = function()
            local targetPos = HardcodedZones[selectedAreaName]
            if not targetPos then return end
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Velocity = Vector3.new(0, 0, 0) end
                char:PivotTo(CFrame.new(targetPos) * CFrame.new(0, 5, 0))
            end
        end
    })

    TeleportGroup:AddButton({ Text = 'Teleport Back', Func = function()
        pcall(function() workspace:WaitForChild("Network"):WaitForChild("Teleport-RemoteEvent"):FireServer("Aquarium") end)
    end })

    local autoTPRareEnabled = false
    local lastTPTime = 0
    TeleportGroup:AddToggle('AutoTPRare', { Text = 'Auto TP to Rare Spawns', Default = false, Callback = function(v) autoTPRareEnabled = v end })

    pcall(function()
        game:GetService("TextChatService").MessageReceived:Connect(function(msg)
            if not autoTPRareEnabled or tick() - lastTPTime < 5 then return end
            local message = msg.Text
            if string.find(message, "has spawned in") then
                local isRare = string.find(message, "Secret") or string.find(message, "Divine") or string.find(message, "Mythical") or string.find(message, "Legendary")
                if isRare then
                    local zone = string.match(message, "has spawned in (%S+)")
                    if zone then
                        zone = string.gsub(zone, "%p+$", "")
                        if HardcodedZones[zone] then
                            lastTPTime = tick()
                            local char = player.Character
                            if char then
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                if hrp then hrp.Velocity = Vector3.new(0, 0, 0) end
                                char:PivotTo(CFrame.new(HardcodedZones[zone]) * CFrame.new(0, 5, 0))
                            end
                        end
                    end
                end
            end
        end)
    end)

    local ProtectionGroup = OceanTab:AddRightGroupbox('Protection')
    local antiDrownEnabled = false
    local antiDrownConnection = nil

    ProtectionGroup:AddToggle('AntiDrown', {
        Text = 'Anti Drown',
        Default = false,
        Callback = function(v)
            antiDrownEnabled = v
            if antiDrownEnabled then
                if not antiDrownConnection then
                    local teleporting = false
                    antiDrownConnection = player.AttributeChanged:Connect(function(attr)
                        if attr == "IsDrowning" and player:GetAttribute("IsDrowning") and not teleporting and antiDrownEnabled then
                            teleporting = true
                            local char = player.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                local savedCF = char.HumanoidRootPart.CFrame
                                pcall(function() workspace:WaitForChild("Network"):WaitForChild("Teleport-RemoteEvent"):FireServer("Aquarium") end)
                                task.wait(0.5)
                                char:PivotTo(savedCF)
                            end
                            task.wait(1)
                            teleporting = false
                        end
                    end)
                end
            elseif antiDrownConnection then
                antiDrownConnection:Disconnect()
                antiDrownConnection = nil
            end
        end
    })

    local function getUniqueFishes()
        local list = {"Any"}
        local map = {}
        for _, v in ipairs(Fish:GetChildren()) do
            if v:IsA("Model") and not map[v.Name] then
                map[v.Name] = true
                table.insert(list, v.Name)
            end
        end
        table.sort(list, function(a, b)
            if a == "Any" then return true end
            if b == "Any" then return false end
            return a < b
        end)
        return list
    end

    local function getFishData(fish)
        local mut = "none"
        local rar = "normal"
        local bp = fish:FindFirstChild(fish.Name .. "BillboardPart")
        if bp then
            local gui = bp:FindFirstChild("BillboardGui")
            local frame = gui and gui:FindFirstChild("Frame")
            if frame then
                local mLab = frame:FindFirstChild("Mutations")
                if mLab then
                    local t = mLab.Text:gsub("<[^>]+>", ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
                    if t ~= "" then mut = t end
                end
                local rLab = frame:FindFirstChild("Rarity")
                if rLab then
                    local t = rLab.Text:gsub("<[^>]+>", ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
                    if t ~= "" then rar = t end
                end
            end
        end
        return mut, rar
    end

    local function checkFilters(mut, rar, mFilters, rFilters)
        local mutMatch = false
        local mCount = 0
        for k, v in pairs(mFilters) do if v then mCount = mCount + 1 end end
        if mCount == 0 then
            mutMatch = true
        elseif mFilters["None"] and (mut == "none" or mut == "normal") then
            mutMatch = true
        else
            for k, v in pairs(mFilters) do
                if v and string.find(mut, k:lower()) then mutMatch = true break end
            end
        end

        local rarMatch = false
        local rCount = 0
        for k, v in pairs(rFilters) do if v then rCount = rCount + 1 end end
        if rCount == 0 then
            rarMatch = true
        elseif rFilters["Normal"] and rar == "normal" then
            rarMatch = true
        else
            for k, v in pairs(rFilters) do
                if v and string.find(rar, k:lower()) then rarMatch = true break end
            end
        end

        return mutMatch and rarMatch
    end

    local AutofarmGroup = AutofarmTab:AddLeftGroupbox('Settings')
    local selectedSpecificFish = "Any"
    local targetFishInput = ""

    local FishDropdown = AutofarmGroup:AddDropdown('TargetFish', { Values = getUniqueFishes(), Default = 1, Text = 'Target Fish', Callback = function(v) selectedSpecificFish = v end })

    local isRefreshing = false
    local function refreshFishDropdown()
        if isRefreshing then return end
        isRefreshing = true
        task.delay(0.5, function()
            pcall(function() FishDropdown:SetValues(getUniqueFishes()) end)
            isRefreshing = false
        end)
    end
    Fish.ChildAdded:Connect(refreshFishDropdown)
    Fish.ChildRemoved:Connect(refreshFishDropdown)

    AutofarmGroup:AddInput('ManualFish', { Text = 'Manual Name Filter', Default = '', Callback = function(v) targetFishInput = v end })

    local selectedMutationFilters = {}
    AutofarmGroup:AddDropdown('MutationFilter', { Values = {"None", "Silver", "Gold", "Rainbow", "Dry", "Frozen", "Shocked", "Chocolate", "Infected", "Magma", "Evil", "Yinyang", "Hacker", "Taco", "Galaxy"}, Multi = true, Text = 'Mutation Filter', Callback = function(v) selectedMutationFilters = v end })

    local selectedRarityFilters = {}
    AutofarmGroup:AddDropdown('RarityFilter', { Values = {"Normal", "Common", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Divine"}, Multi = true, Text = 'Rarity Filter', Callback = function(v) selectedRarityFilters = v end })

    local autoFarmEnabled = false
    AutofarmGroup:AddToggle('AutoFarm', { Text = 'Enable Autofarm', Default = false, Callback = function(v) autoFarmEnabled = v end })

    task.spawn(function()
        while true do
            if autoFarmEnabled then
                for _, v in pairs(Fish:GetChildren()) do
                    if not autoFarmEnabled then break end
                    if v:IsA("Model") then
                        local match = false
                        if selectedSpecificFish == "Any" and targetFishInput == "" then
                            match = true
                        elseif selectedSpecificFish ~= "Any" and v.Name == selectedSpecificFish then
                            match = true
                        elseif targetFishInput ~= "" and string.find(v.Name:lower(), targetFishInput:lower()) then
                            match = true
                        end
                        if match then
                            local mut, rar = getFishData(v)
                            if checkFilters(mut, rar, selectedMutationFilters, selectedRarityFilters) then
                                local root = v:FindFirstChild("RootPart")
                                local prompt = root and root:FindFirstChildOfClass("ProximityPrompt")
                                if prompt and prompt.Enabled then
                                    local char = player.Character
                                    if char and char:FindFirstChild("HumanoidRootPart") then
                                        char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                                        char:PivotTo(root.CFrame * CFrame.new(0, 3, 0))
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
            task.wait(0.5)
        end
    end)

    local autoSellEnabled = false
    AutofarmGroup:AddToggle('AutoSell', { Text = 'Auto Sell Fish', Default = false, Callback = function(v) autoSellEnabled = v end })
    task.spawn(function()
        while true do
            if autoSellEnabled then
                pcall(function()
                    game:GetService("ReplicatedStorage"):WaitForChild("Packets"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(buffer.fromstring("\003\001"))
                end)
            end
            task.wait(2.5)
        end
    end)

    local FishEspGroup = VisualsTab:AddLeftGroupbox('Fish ESP')
    local fishEspEnabled = false
    local espMFilters = {}
    local espRFilters = {}
    FishEspGroup:AddToggle('FishEsp', { Text = 'Fish ESP', Default = false, Callback = function(v)
        fishEspEnabled = v
        if not v then for _, f in pairs(Fish:GetChildren()) do ESP:Remove(f) end end
    end })
    FishEspGroup:AddDropdown('EspMutFilter', { Values = {"None", "Silver", "Gold", "Rainbow", "Dry", "Frozen", "Shocked", "Chocolate", "Infected", "Magma", "Evil", "Yinyang", "Hacker", "Taco", "Galaxy"}, Multi = true, Text = 'Mutation Filter', Callback = function(v) espMFilters = v end })
    FishEspGroup:AddDropdown('EspRarFilter', { Values = {"Normal", "Common", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Divine"}, Multi = true, Text = 'Rarity Filter', Callback = function(v) espRFilters = v end })

    task.spawn(function()
        while true do
            task.wait(1)
            if fishEspEnabled then
                for _, f in pairs(Fish:GetChildren()) do
                    if f:IsA("Model") then
                        local mut, rar = getFishData(f)
                        if checkFilters(mut, rar, espMFilters, espRFilters) then
                            if not ESP.Objects[f] then
                                local color = Color3.fromRGB(150, 150, 150)
                                if string.find(rar, "legendary") then color = Color3.fromRGB(255, 170, 0)
                                elseif string.find(rar, "mythical") then color = Color3.fromRGB(170, 0, 255)
                                elseif string.find(rar, "secret") then color = Color3.fromRGB(255, 0, 0)
                                elseif string.find(rar, "divine") then color = Color3.fromRGB(0, 255, 255)
                                elseif string.find(rar, "epic") then color = Color3.fromRGB(255, 0, 150)
                                elseif string.find(rar, "rare") then color = Color3.fromRGB(0, 150, 255)
                                elseif mut ~= "none" then color = Color3.fromRGB(255, 255, 0) end
                                local dispMut = mut ~= "none" and (" [" .. mut .. "]") or ""
                                local dispRar = rar ~= "normal" and (" [" .. rar .. "]") or ""
                                ESP:Add(f, {
                                    Name = f.Name .. dispMut .. dispRar,
                                    PrimaryPart = f:FindFirstChild("RootPart"),
                                    Color = color,
                                    IsEnabled = function() return fishEspEnabled and f.Parent == Fish end
                                })
                            end
                        else
                            if ESP.Objects and ESP.Objects[f] then ESP:Remove(f) end
                        end
                    end
                end
            end
        end
    end)

    local AreaEspGroup = VisualsTab:AddRightGroupbox('Area ESP')
    local areaEspEnabled = false
    AreaEspGroup:AddToggle('AreaEsp', { Text = 'Area ESP', Default = false, Callback = function(v)
        areaEspEnabled = v
        if not v then
            local markers = workspace.Game:FindFirstChild("OceanZoneMarkers")
            if markers then for _, m in pairs(markers:GetChildren()) do ESP:Remove(m) end end
        end
    end })
    task.spawn(function()
        while true do
            task.wait(2)
            if areaEspEnabled then
                local markers = workspace.Game:FindFirstChild("OceanZoneMarkers")
                if markers then
                    for _, m in pairs(markers:GetChildren()) do
                        if not (ESP.Objects and ESP.Objects[m]) then
                            ESP:Add(m, { Name = "[Zone] " .. m.Name, Color = Color3.fromRGB(0, 150, 255), IsEnabled = function() return areaEspEnabled end })
                        end
                    end
                end
            end
        end
    end)

    local function firePacket(id, hasResponse)
        pcall(function()
            local str = string.char(id) .. (hasResponse and "\001" or "")
            game:GetService("ReplicatedStorage").Packets.Packet.RemoteEvent:FireServer(buffer.fromstring(str))
        end)
    end

    local MiscGroup = MiscTab:AddLeftGroupbox('Utilities')
    MiscGroup:AddButton({ Text = 'Spin Wheel', Func = function() firePacket(19, true) end })
    local autoSpin = false
    MiscGroup:AddToggle('AutoSpin', { Text = 'Auto Spin Wheel', Default = false, Callback = function(v) autoSpin = v end })
    task.spawn(function() while true do if autoSpin then firePacket(19, true) end task.wait(10) end end)
    MiscGroup:AddButton({ Text = 'Claim Reward', Func = function() firePacket(10, false) end })
    MiscGroup:AddButton({ Text = 'Cancel Death Screen', Func = function() firePacket(11, false) end })
    MiscGroup:AddButton({ Text = 'Respawn', Func = function() firePacket(7, false) end })

    local ShopGroup = MiscTab:AddRightGroupbox('Auto Shop')
    local function fireBuy(store, item)
        pcall(function()
            local str = string.char(4) .. string.char(#store) .. store .. string.char(#item) .. item
            game:GetService("ReplicatedStorage").Packets.Packet.RemoteEvent:FireServer(buffer.fromstring(str))
        end)
    end
    local autoBuyTreats = false
    ShopGroup:AddToggle('AutoBuyTreats', { Text = 'Auto Buy Treats', Default = false, Callback = function(v) autoBuyTreats = v end })
    local autoBuyTools = false
    ShopGroup:AddToggle('AutoBuyTools', { Text = 'Auto Buy Tools', Default = false, Callback = function(v) autoBuyTools = v end })
    task.spawn(function()
        while true do
            task.wait(3)
            if autoBuyTreats or autoBuyTools then
                pcall(function()
                    local pUI = player:WaitForChild("PlayerGui"):FindFirstChild("PersistentUI")
                    if pUI and pUI:FindFirstChild("Shops") then
                        if autoBuyTreats and pUI.Shops:FindFirstChild("Treat") then
                            local content = pUI.Shops.Treat:FindFirstChild("Content") and pUI.Shops.Treat.Content:FindFirstChild("ScrollingFrame")
                            if content then
                                for _, item in pairs(content:GetChildren()) do
                                    local slot = item:FindFirstChild("SlotTemplate")
                                    local stockText = slot and slot:FindFirstChild("StockAmount") and slot.StockAmount.Text or ""
                                    local stock = tonumber(string.match(stockText, "%d+")) or 0
                                    for i = 1, stock do if not autoBuyTreats then break end fireBuy("Treat", item.Name) task.wait(0.1) end
                                end
                            end
                        end
                        if autoBuyTools and pUI.Shops:FindFirstChild("Tool") then
                            local content = pUI.Shops.Tool:FindFirstChild("Content") and pUI.Shops.Tool.Content:FindFirstChild("ScrollingFrame")
                            if content then
                                for _, item in pairs(content:GetChildren()) do
                                    local slot = item:FindFirstChild("SlotTemplate")
                                    local stockText = slot and slot:FindFirstChild("StockAmount") and slot.StockAmount.Text or ""
                                    local stock = tonumber(string.match(stockText, "%d+")) or 0
                                    for i = 1, stock do if not autoBuyTools then break end fireBuy("Tool", item.Name) task.wait(0.1) end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    local ModGroup = MiscTab:AddLeftGroupbox('Modifiers')
    local swimSpeedValue = 1
    ModGroup:AddSlider('SwimSpeed', { Text = 'Swim Speed', Min = 1, Max = 20, Default = 1, Rounding = 0, Callback = function(v)
        swimSpeedValue = v
        workspace:SetAttribute("AdminSpeedMultiplier", v)
        if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed = 16 * v end
    end })
    player.CharacterAdded:Connect(function(char)
        workspace:SetAttribute("AdminSpeedMultiplier", swimSpeedValue)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then hum.WalkSpeed = 16 * swimSpeedValue end
    end)
    local reachEnabled = false
    ModGroup:AddToggle('Reach', { Text = 'Reach / Instant Interact', Default = false, Callback = function(v)
        reachEnabled = v
        if v then
            for _, p in pairs(workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") then p.HoldDuration = 0 p.MaxActivationDistance = 50 p.RequiresLineOfSight = false end
            end
        end
    end })

    local AqGroup = AquariumTab:AddLeftGroupbox('Aquarium')
    local function equipBest()
        pcall(function()
            local net = workspace:FindFirstChild("Network")
            local rem = net and (net:FindFirstChild("RequestEquipBestFish-RemoteFunction") or net:FindFirstChild("RequestEquipBestFish"))
            if rem then if rem:IsA("RemoteFunction") then rem:InvokeServer() else rem:FireServer() end end
        end)
    end
    AqGroup:AddButton({ Text = 'Equip Best', Func = equipBest })
    local autoEquipBest = false
    AqGroup:AddToggle('AutoEquipBest', { Text = 'Auto Equip Best', Default = false, Callback = function(v) autoEquipBest = v end })
    task.spawn(function() while true do if autoEquipBest then equipBest() end task.wait(5) end end)

    local smartSellEnabled = false
    local smartSellFilters = {}
    AqGroup:AddDropdown('SmartSellFilter', { Values = {"Normal", "Common", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Divine"}, Multi = true, Text = 'Smart Sell Rarity', Callback = function(v) smartSellFilters = v end })
    AqGroup:AddToggle('SmartSell', { Text = 'Smart Sell Fish', Default = false, Callback = function(v) smartSellEnabled = v end })
    task.spawn(function()
        while true do
            task.wait(5)
            if smartSellEnabled then
                pcall(function()
                    for _, tool in pairs(player.Backpack:GetChildren()) do
                        if tool:IsA("Tool") then
                            local rarity = "Normal"
                            for _, c in pairs(tool:GetChildren()) do
                                if c:IsA("BasePart") then
                                    local bgui = c:FindFirstChild("BillboardGui")
                                    if bgui and bgui:FindFirstChild("Frame") and bgui.Frame:FindFirstChild("Rarity") then
                                        rarity = bgui.Frame.Rarity.Text:gsub("<[^>]+>", "")
                                        break
                                    end
                                end
                            end
                            if rarity == "Normal" then rarity = tool.Name:match("%[(.-)%]") or "Normal" end
                            local shouldSell = false
                            local count = 0
                            for k, v in pairs(smartSellFilters) do if v then count = count + 1 end end
                            if count == 0 then shouldSell = true
                            else for k, v in pairs(smartSellFilters) do if v and string.find(rarity:lower(), k:lower()) then shouldSell = true break end end end
                            if shouldSell then
                                tool.Parent = player.Character
                                task.wait(0.1)
                                game:GetService("ReplicatedStorage").Packets.Packet.RemoteEvent:FireServer(buffer.fromstring("\002\001\r"), {player})
                                task.wait(0.2)
                            end
                        end
                    end
                end)
            end
        end
    end)
end

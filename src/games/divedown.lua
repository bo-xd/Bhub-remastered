return function(Window, Tabs, ESP)
    local player = game:GetService("Players").LocalPlayer
    local Fish = workspace.Game.Fishes

    local OceanTab = Window:AddTab('Ocean')
    local AutofarmTab = Window:AddTab('Autofarm')
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

    TeleportGroup:AddDropdown('AreaSelector', {
        Values = HardcodedZonesOrder,
        Default = 1,
        Multi = false,
        Text = 'Target Area',
        Callback = function(Value)
            selectedAreaName = Value
        end
    })

    TeleportGroup:AddButton({
        Text = 'Teleport',
        Func = function()
            local targetPos = HardcodedZones[selectedAreaName]
            if not targetPos then return end
            local character = player.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Velocity = Vector3.new(0, 0, 0) end
                character:PivotTo(CFrame.new(targetPos) * CFrame.new(0, 5, 0))
            end
        end
    })

    TeleportGroup:AddButton({
        Text = 'Teleport Back',
        Func = function()
            local net = workspace:FindFirstChild("Network")
            local rem = net and net:FindFirstChild("Teleport-RemoteEvent")
            if rem then rem:FireServer("Aquarium") end
        end
    })

    local autoTPRareEnabled = false
    local lastTPTime = 0
    TeleportGroup:AddToggle('AutoTPRare', {
        Text = 'Auto TP to Rare Spawns',
        Default = false,
        Callback = function(Value)
            autoTPRareEnabled = Value
        end
    })

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
                            if hrp then hrp.Velocity = Vector3.new(0,0,0) end
                            char:PivotTo(CFrame.new(HardcodedZones[zone]) * CFrame.new(0, 5, 0))
                        end
                    end
                end
            end
        end
    end)

    local ProtectionGroup = OceanTab:AddRightGroupbox('Protection')
    local antiDrownEnabled = false
    local antiDrownConnection = nil

    ProtectionGroup:AddToggle('AntiDrown', {
        Text = 'Anti Drown',
        Default = false,
        Callback = function(Value)
            antiDrownEnabled = Value
            if antiDrownEnabled then
                if not antiDrownConnection then
                    local teleporting = false
                    antiDrownConnection = player.AttributeChanged:Connect(function(attr)
                        if attr == "IsDrowning" and player:GetAttribute("IsDrowning") and not teleporting and antiDrownEnabled then
                            teleporting = true
                            local character = player.Character
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                local savedCF = character.HumanoidRootPart.CFrame
                                local net = workspace:FindFirstChild("Network")
                                local rem = net and net:FindFirstChild("Teleport-RemoteEvent")
                                if rem then 
                                    rem:FireServer("Aquarium")
                                    task.wait(0.5)
                                    character:PivotTo(savedCF)
                                end
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

    local AutofarmGroup = AutofarmTab:AddLeftGroupbox('Settings')
    local selectedSpecificFish = "Any"
    local targetFishInput = ""

    local function getUniqueFishes()
        local list = {"Any"}
        local map = {}
        for _, v in ipairs(Fish:GetChildren()) do
            if v:IsA("Model") and not map[v.Name] then
                map[v.Name] = true
                table.insert(list, v.Name)
            end
        end
        return list
    end

    local FishDropdown = AutofarmGroup:AddDropdown('TargetFish', {
        Values = getUniqueFishes(),
        Default = 1,
        Text = 'Target Fish',
        Callback = function(Value) selectedSpecificFish = Value end
    })

    Fish.ChildAdded:Connect(function() FishDropdown:SetValues(getUniqueFishes()) end)
    Fish.ChildRemoved:Connect(function() FishDropdown:SetValues(getUniqueFishes()) end)

    AutofarmGroup:AddInput('ManualFish', {
        Text = 'Manual Name Filter',
        Default = '',
        Callback = function(Value) targetFishInput = Value end
    })

    local selectedMutationFilters = {}
    AutofarmGroup:AddDropdown('MutationFilter', {
        Values = {"None", "Silver", "Gold", "Rainbow", "Dry", "Frozen", "Shocked", "Chocolate", "Infected", "Magma", "Evil", "Yinyang", "Hacker", "Taco", "Galaxy"},
        Default = 0,
        Multi = true,
        Text = 'Mutation Filter',
        Callback = function(Value) selectedMutationFilters = Value end
    })

    local selectedRarityFilters = {}
    AutofarmGroup:AddDropdown('RarityFilter', {
        Values = {"Normal", "Common", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Divine"},
        Default = 0,
        Multi = true,
        Text = 'Rarity Filter',
        Callback = function(Value) selectedRarityFilters = Value end
    })

    local autoFarmEnabled = false
    AutofarmGroup:AddToggle('AutoFarm', {
        Text = 'Enable Autofarm',
        Default = false,
        Callback = function(Value) autoFarmEnabled = Value end
    })

    task.spawn(function()
        while true do
            if autoFarmEnabled then
                for _,v in pairs(Fish:GetChildren()) do
                    if not autoFarmEnabled then break end
                    if v:IsA("Model") then
                        local match = false
                        if selectedSpecificFish == "Any" and targetFishInput == "" then match = true
                        elseif selectedSpecificFish ~= "Any" and v.Name == selectedSpecificFish then match = true
                        elseif targetFishInput ~= "" and string.find(string.lower(v.Name), string.lower(targetFishInput)) then match = true end
                        
                        if match then
                            local root = v:FindFirstChild("RootPart")
                            local prompt = root and root:FindFirstChildOfClass("ProximityPrompt")
                            if prompt and prompt.Enabled then
                                local char = player.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                                    char:PivotTo(root.CFrame * CFrame.new(0, 3, 0))
                                    task.wait(0.2)
                                    if autoFarmEnabled then fireproximityprompt(prompt) end
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)

    local VisualsGroup = OceanTab:AddRightGroupbox('Visuals')
    local fishEspEnabled = false
    VisualsGroup:AddToggle('FishEsp', {
        Text = 'Fish ESP',
        Default = false,
        Callback = function(v) 
            fishEspEnabled = v 
            if not v then
                for _, f in pairs(Fish:GetChildren()) do ESP:Remove(f) end
            end
        end
    })

    task.spawn(function()
        while true do
            if fishEspEnabled then
                for _, f in pairs(Fish:GetChildren()) do
                    if f:IsA("Model") and not ESP.Objects[f] then
                        ESP:Add(f, {
                            Name = f.Name,
                            PrimaryPart = f:FindFirstChild("RootPart") or f.PrimaryPart,
                            IsEnabled = function() return fishEspEnabled and f.Parent == Fish end
                        })
                    end
                end
            end
            task.wait(1)
        end
    end)

    local MiscGroup = MiscTab:AddLeftGroupbox('Utilities')
    local function firePacket(id, hasResponse)
        pcall(function()
            local str = string.char(id) .. (hasResponse and "\001" or "")
            local net = game:GetService("ReplicatedStorage"):FindFirstChild("Packets")
            local p = net and net:FindFirstChild("Packet")
            local r = p and p:FindFirstChild("RemoteEvent")
            if r then r:FireServer(buffer.fromstring(str)) end
        end)
    end

    MiscGroup:AddButton({ Text = 'Spin Wheel', Func = function() firePacket(19, true) end })
    
    local autoSpin = false
    MiscGroup:AddToggle('AutoSpin', {
        Text = 'Auto Spin Wheel',
        Default = false,
        Callback = function(Value) autoSpin = Value end
    })
    task.spawn(function() while true do if autoSpin then firePacket(19, true) end task.wait(10) end end)

    MiscGroup:AddButton({ Text = 'Claim Reward', Func = function() firePacket(10, false) end })
    MiscGroup:AddButton({ Text = 'Respawn', Func = function() firePacket(7, false) end })

    local ShopGroup = MiscTab:AddRightGroupbox('Auto Shop')
    local function fireBuy(store, item)
        pcall(function()
            local str = string.char(4) .. string.char(#store) .. store .. string.char(#item) .. item
            local net = game:GetService("ReplicatedStorage"):FindFirstChild("Packets")
            local p = net and net:FindFirstChild("Packet")
            local r = p and p:FindFirstChild("RemoteEvent")
            if r then r:FireServer(buffer.fromstring(str)) end
        end)
    end

    local autoBuyTreats = false
    ShopGroup:AddToggle('AutoBuyTreats', { Text = 'Auto Buy Treats', Default = false, Callback = function(v) autoBuyTreats = v end })
    
    local autoBuyTools = false
    ShopGroup:AddToggle('AutoBuyTools', { Text = 'Auto Buy Tools', Default = false, Callback = function(v) autoBuyTools = v end })

    task.spawn(function()
        while true do
            if autoBuyTreats or autoBuyTools then
                local pUI = player:WaitForChild("PlayerGui"):FindFirstChild("PersistentUI")
                if pUI and pUI:FindFirstChild("Shops") then
                    if autoBuyTreats then
                        local treatShop = pUI.Shops:FindFirstChild("Treat") and pUI.Shops.Treat:FindFirstChild("Content") and pUI.Shops.Treat.Content:FindFirstChild("ScrollingFrame")
                        if treatShop then
                            for _, item in pairs(treatShop:GetChildren()) do
                                local slot = item:FindFirstChild("SlotTemplate")
                                local stockText = slot and slot:FindFirstChild("StockAmount") and slot.StockAmount.Text
                                local stock = stockText and tonumber(string.match(stockText, "%d+")) or 0
                                if stock > 0 then
                                    fireBuy("Treat", item.Name)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(3)
        end
    end)

    local ModGroup = MiscTab:AddLeftGroupbox('Modifiers')
    ModGroup:AddSlider('SwimSpeed', {
        Text = 'Swim Speed',
        Min = 1, Max = 20, Default = 1, Rounding = 0,
        Callback = function(v)
            workspace:SetAttribute("AdminSpeedMultiplier", v)
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.WalkSpeed = 16 * v
            end
        end
    })

    local instantInteract = false
    local originalPrompts = {}
    ModGroup:AddToggle('Reach', {
        Text = 'Instant Interact / Reach',
        Default = false,
        Callback = function(v)
            instantInteract = v
            if v then
                for _, p in pairs(workspace:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        originalPrompts[p] = {p.HoldDuration, p.MaxActivationDistance}
                        p.HoldDuration = 0
                        p.MaxActivationDistance = 50
                    end
                end
            else
                for p, data in pairs(originalPrompts) do
                    if p and p.Parent then p.HoldDuration = data[1] p.MaxActivationDistance = data[2] end
                end
                table.clear(originalPrompts)
            end
        end
    })

    local AqGroup = AquariumTab:AddLeftGroupbox('Aquarium')
    local function equipBest()
        local net = workspace:FindFirstChild("Network")
        local remote = net and (net:FindFirstChild("RequestEquipBestFish-RemoteFunction") or net:FindFirstChild("RequestEquipBestFish"))
        if remote then if remote:IsA("RemoteFunction") then remote:InvokeServer() else remote:FireServer() end end
    end
    AqGroup:AddButton({ Text = 'Equip Best', Func = equipBest })
    
    local smartSellEnabled = false
    local smartSellFilters = {}
    AqGroup:AddDropdown('SmartSellFilter', {
        Values = {"Normal", "Common", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Divine"},
        Multi = true, Text = 'Smart Sell Rarity',
        Callback = function(v) smartSellFilters = v end
    })
    AqGroup:AddToggle('SmartSell', { Text = 'Smart Sell Fish', Default = false, Callback = function(v) smartSellEnabled = v end })

    task.spawn(function()
        while true do
            if smartSellEnabled then
                for _, tool in pairs(player.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        local rarity = tool.Name:match("%[(.-)%]") or "Normal"
                        if smartSellFilters[rarity] then
                            tool.Parent = player.Character
                            task.wait(0.1)
                            local net = game:GetService("ReplicatedStorage"):FindFirstChild("Packets")
                            local p = net and net:FindFirstChild("Packet")
                            local r = p and p:FindFirstChild("RemoteEvent")
                            if r then r:FireServer(buffer.fromstring("\002\001\r"), {player}) end
                            task.wait(0.2)
                        end
                    end
                end
            end
            task.wait(5)
        end
    end)
end

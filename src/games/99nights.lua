return function(Window, ESP, Library)
    local player = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
    local RequestReplicateSound = Remotes:WaitForChild("RequestReplicateSound")
    local ToolDamageObject = Remotes:WaitForChild("ToolDamageObject")
    local PlayEnemyHitSound = Remotes:WaitForChild("PlayEnemyHitSound")
    local RequestBagStoreItem = Remotes:WaitForChild("RequestBagStoreItem")
    
    local MainTab = Window:AddTab('Survival')
    local FarmTab = Window:AddTab('Auto Farm')
    local VisualsTab = Window:AddTab('Visuals')
    local MiscTab = Window:AddTab('Misc')

    -- Survival Features
    local SurvivalGroup = MainTab:AddLeftGroupbox('Survival')
    
    local fullbrightEnabled = false
    local originalBrightness = Lighting.Brightness
    local originalAmbient = Lighting.Ambient
    local originalFog = Lighting.FogEnd

    SurvivalGroup:AddToggle('Fullbright', { Text = 'Fullbright', Default = false, Callback = function(v)
        fullbrightEnabled = v
        if v then
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.FogEnd = 100000
        else
            Lighting.Brightness = originalBrightness
            Lighting.Ambient = originalAmbient
            Lighting.FogEnd = originalFog
        end
    end })

    -- Farm Features
    local FarmGroup = FarmTab:AddLeftGroupbox('Automations')
    local autoWood = false
    local autoKill = false
    local autoCollect = false
    local autoStore = false

    FarmGroup:AddToggle('AutoWood', { Text = 'Auto Wood', Default = false, Callback = function(v) autoWood = v end })
    FarmGroup:AddToggle('AutoKill', { Text = 'Auto Kill Monsters', Default = false, Callback = function(v) autoKill = v end })
    FarmGroup:AddToggle('AutoCollect', { Text = 'Auto Collect Items', Default = false, Callback = function(v) autoCollect = v end })
    FarmGroup:AddToggle('AutoStore', { Text = 'Auto Store Logs', Default = false, Callback = function(v) autoStore = v end })

    local function getTool(name)
        local inv = player:FindFirstChild("Inventory")
        if not inv then return nil end
        if name then return inv:FindFirstChild(name) end
        return inv:FindFirstChild("Old Axe") or inv:FindFirstChildOfClass("Model") or inv:FindFirstChildOfClass("Tool")
    end

    task.spawn(function()
        while true do
            task.wait(0.3)
            
            -- Wood Cutting
            if autoWood then
                local tool = getTool("Old Axe") or getTool()
                local map = workspace:FindFirstChild("Map")
                local foliage = map and map:FindFirstChild("Foliage")
                if tool and foliage then
                    for _, obj in pairs(foliage:GetChildren()) do
                        if not autoWood then break end
                        if obj.Name:find("Tree") and (player.Character and player.Character:FindFirstChild("Head")) then
                            pcall(function()
                                RequestReplicateSound:FireServer("FireAllClients", "WoodChop", { Instance = player.Character.Head, Volume = 0.4 })
                                ToolDamageObject:InvokeServer(obj, tool, "12_4198471790", player.Character.Head.CFrame, false)
                                PlayEnemyHitSound:FireServer("FireAllClients", obj, tool)
                            end)
                        end
                    end
                end
            end
            
            -- Monster Killing
            if autoKill then
                local tool = getTool()
                local chars = workspace:FindFirstChild("Characters")
                if tool and chars then
                    for _, obj in pairs(chars:GetChildren()) do
                        if not autoKill then break end
                        if obj ~= player.Character and (player.Character and player.Character:FindFirstChild("Head")) then
                            pcall(function()
                                ToolDamageObject:InvokeServer(obj, tool, "12_4198471790", player.Character.Head.CFrame, false)
                                PlayEnemyHitSound:FireServer("FireAllClients", obj, tool)
                            end)
                        end
                    end
                end
            end

            -- Log Storing
            if autoStore then
                local sack = getTool("Old Sack")
                local itemBag = player:FindFirstChild("ItemBag")
                if sack and itemBag then
                    for _, item in pairs(itemBag:GetChildren()) do
                        if not autoStore then break end
                        if item.Name == "Log" then
                            pcall(function()
                                RequestReplicateSound:FireServer("FireAllClients", "BagGet", { Instance = player.Character.Head, Volume = 0.25 })
                                RequestBagStoreItem:InvokeServer(sack, item)
                            end)
                        end
                    end
                end
            end

            -- Item Collection
            if autoCollect then
                local items = workspace:FindFirstChild("Items")
                if items then
                    for _, obj in pairs(items:GetChildren()) do
                        if not autoCollect then break end
                        local prompt = obj:FindFirstChildOfClass("ProximityPrompt") or obj:FindFirstChild("Prompt", true)
                        if prompt then
                            fireproximityprompt(prompt)
                        end
                    end
                end
            end
        end
    end)

    -- ESP Features
    local EntityEspGroup = VisualsTab:AddLeftGroupbox('Entity ESP')
    local entityEspEnabled = false
    
    EntityEspGroup:AddToggle('EntityEsp', { Text = 'Enable Entity ESP', Default = false, Callback = function(v)
        entityEspEnabled = v
        if not v then 
            if ESP.Clear then ESP:Clear() end
        end
    end })

    task.spawn(function()
        while true do
            task.wait(2)
            if entityEspEnabled then
                local chars = workspace:FindFirstChild("Characters")
                if chars then
                    for _, obj in pairs(chars:GetChildren()) do
                        if obj ~= player.Character and not ESP.Objects[obj] then
                            ESP:Add(obj, { Name = "[Monster] " .. obj.Name, Color = Color3.fromRGB(255, 0, 0), IsEnabled = function() return entityEspEnabled and obj.Parent ~= nil end })
                        end
                    end
                end
                
                local items = workspace:FindFirstChild("Items")
                if items then
                    for _, obj in pairs(items:GetChildren()) do
                        if not ESP.Objects[obj] then
                            ESP:Add(obj, { Name = "[Item] " .. obj.Name, Color = Color3.fromRGB(0, 255, 0), IsEnabled = function() return entityEspEnabled and obj.Parent ~= nil end })
                        end
                    end
                end

                local map = workspace:FindFirstChild("Map")
                local foliage = map and map:FindFirstChild("Foliage")
                if foliage then
                    for _, obj in pairs(foliage:GetChildren()) do
                        if (obj.Name:find("Tree") or obj.Name:find("Chest")) and not ESP.Objects[obj] then
                             local label = obj.Name:find("Tree") and "[Tree]" or "[Chest]"
                             local color = obj.Name:find("Tree") and Color3.fromRGB(139, 69, 19) or Color3.fromRGB(255, 215, 0)
                             ESP:Add(obj, { Name = label, Color = color, IsEnabled = function() return entityEspEnabled and obj.Parent ~= nil end })
                        end
                    end
                end
            end
        end
    end)

    print("[BHub] 99 Nights in the Forest script loaded.")
end

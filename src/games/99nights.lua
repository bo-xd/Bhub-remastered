return function(Window, ESP, Library)
    local player = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")

    local MainTab = Window:AddTab('Survival')
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

    -- ESP Features
    local EntityEspGroup = VisualsTab:AddLeftGroupbox('Entity ESP')
    local entityEspEnabled = false
    
    EntityEspGroup:AddToggle('EntityEsp', { Text = 'Enable Entity ESP', Default = false, Callback = function(v)
        entityEspEnabled = v
        if not v then
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and ESP.Objects[obj] then
                    ESP:Remove(obj)
                end
            end
        end
    end })

    local function isMonster(model)
        local name = model.Name:lower()
        return name:find("deer") or name:find("monster") or name:find("cultist") or name:find("wolf") or name:find("bear") or name:find("alpha")
    end

    local function isItem(model)
        local name = model.Name:lower()
        return name:find("chest") or name:find("child") or name:find("sack") or name:find("box")
    end

    task.spawn(function()
        while true do
            task.wait(2)
            if entityEspEnabled then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if not entityEspEnabled then break end
                    if obj:IsA("Model") and not ESP.Objects[obj] then
                        local color = nil
                        local label = nil
                        
                        if isMonster(obj) then
                            color = Color3.fromRGB(255, 0, 0)
                            label = "[Monster] " .. obj.Name
                        elseif isItem(obj) then
                            color = Color3.fromRGB(0, 255, 0)
                            label = "[Item] " .. obj.Name
                        elseif obj.Name:lower():find("campfire") then
                            color = Color3.fromRGB(255, 165, 0)
                            label = "[Campfire]"
                        end
                        
                        if color and label then
                            ESP:Add(obj, { 
                                Name = label, 
                                Color = color, 
                                IsEnabled = function() return entityEspEnabled and obj.Parent ~= nil end 
                            })
                        end
                    end
                end
            end
        end
    end)

    -- Misc Features
    local MiscGroup = MiscTab:AddLeftGroupbox('Utilities')
    
    MiscGroup:AddButton({ Text = 'Kill All Monsters (Client-Side)', Func = function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and isMonster(obj) then
                pcall(function() obj:Destroy() end)
            end
        end
    end })

    print("[BHub] 99 Nights in the Forest script loaded.")
end

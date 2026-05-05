local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESP = {
    Enabled = false,
    ShowBoxes = true,
    ShowNames = true,
    ShowDistance = true,
    ShowHealth = true,
    ShowTracers = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    TextSize = 13,
    TextFont = 2,
    MaxDistance = 400,
    Objects = {},
    _conn = nil
}

local Camera = workspace.CurrentCamera

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function hideAll(components)
    for _, c in pairs(components) do
        c.Visible = false
    end
end

function ESP:Add(object, options)
    -- Prevent duplicate tracking for the same object[cite: 1]
    if self.Objects[object] then self:Remove(object) end

    local primaryPart =
        (options and options.PrimaryPart) or
        (object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true))) or
        (object:IsA("BasePart") and object)

    if not primaryPart then return end

    local color = (options and options.Color) or self.BoxColor
    local name  = (options and options.Name)  or object.Name

    -- Initialize drawing objects[cite: 1]
    local c = {
        BoxOut  = newDrawing("Square", { Thickness=3, Color=Color3.new(0,0,0), Transparency=1, Filled=false, Visible=false }),
        Box     = newDrawing("Square", { Thickness=1, Color=color, Transparency=1, Filled=false, Visible=false }),
        HpOut   = newDrawing("Square", { Thickness=1, Color=Color3.new(0,0,0), Transparency=1, Filled=true,  Visible=false }),
        Hp      = newDrawing("Square", { Thickness=1, Color=Color3.fromRGB(0,200,0), Transparency=1, Filled=true,  Visible=false }),
        Name    = newDrawing("Text",   { Text=name,  Color=color, Center=true, Outline=true, Size=self.TextSize, Font=self.TextFont, Visible=false }),
        Dist    = newDrawing("Text",   { Text="",    Color=color, Center=true, Outline=true, Size=self.TextSize, Font=self.TextFont, Visible=false }),
        Tracer  = newDrawing("Line",   { From=Vector2.new(0,0), To=Vector2.new(0,0), Color=color, Thickness=1, Transparency=1, Visible=false }),
    }

    self.Objects[object] = {
        PrimaryPart = primaryPart,
        Object      = object,
        Name        = name,
        Color       = color,
        TextOnly    = options and options.TextOnly or false,
        IsEnabled   = options and options.IsEnabled,
        Components  = c,
    }
end

function ESP:Remove(object)
    local data = self.Objects[object]
    if not data then return end
    
    -- Properly remove drawings from memory[cite: 1]
    for _, c in pairs(data.Components) do
        c.Visible = false
        c:Remove()
    end
    self.Objects[object] = nil
end

function ESP:Clear()
    for obj in pairs(self.Objects) do
        self:Remove(obj)
    end
end

function ESP:Update()
    local cam = workspace.CurrentCamera
    if not cam then return end

    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for obj, data in pairs(self.Objects) do
        -- CRITICAL PERFORMANCE FIX: 
        -- If the object is deleted or removed from workspace, kill its ESP immediately[cite: 1]
        if not obj or not obj.Parent or not data.PrimaryPart or not data.PrimaryPart.Parent then
            self:Remove(obj)
            continue
        end

        local part = data.PrimaryPart
        local globalOk = data.IsEnabled ~= nil or self.Enabled
        local c = data.Components

        -- Check if custom enabled callback or global flag is false
        if not globalOk or (data.IsEnabled and not data.IsEnabled()) then
            hideAll(c)
            continue
        end

        -- Distance Cull: Stop processing if too far away[cite: 1]
        local rootPos = part.Position
        local dist    = localRoot and (localRoot.Position - rootPos).Magnitude or 0
        if dist > self.MaxDistance then
            hideAll(c)
            continue
        end

        -- Screen position check
        local topVP, onTop       = cam:WorldToViewportPoint(rootPos + Vector3.new(0, 3, 0))
        local bottomVP, onBottom = cam:WorldToViewportPoint(rootPos - Vector3.new(0, 3, 0))

        if not (onTop or onBottom) or topVP.Z < 0 then
            hideAll(c)
            continue
        end

        local color     = data.Color or self.BoxColor
        local textColor = data.Color or self.TextColor
        local height    = math.max(1, math.abs(topVP.Y - bottomVP.Y))
        local width     = height * 0.6
        local x         = topVP.X - width * 0.5
        local y         = topVP.Y

        if data.TextOnly then
            hideAll({c.BoxOut, c.Box, c.HpOut, c.Hp})

            c.Name.Visible  = self.ShowNames
            c.Name.Text     = data.Name
            c.Name.Color    = textColor
            c.Name.Position = Vector2.new(topVP.X, y)

            c.Dist.Visible  = self.ShowDistance and localRoot ~= nil
            if c.Dist.Visible then
                c.Dist.Text     = string.format("[%d]", math.floor(dist))
                c.Dist.Color    = textColor
                c.Dist.Position = Vector2.new(topVP.X, y + self.TextSize + 2)
            end
        else
            -- Box Logic
            local showBox = self.ShowBoxes
            c.BoxOut.Visible = showBox
            c.Box.Visible    = showBox
            if showBox then
                c.BoxOut.Size     = Vector2.new(width, height)
                c.BoxOut.Position = Vector2.new(x, y)
                c.Box.Size        = Vector2.new(width, height)
                c.Box.Position    = Vector2.new(x, y)
                c.Box.Color       = color
            end

            -- Health Logic[cite: 1]
            local hum = obj:FindFirstChildWhichIsA("Humanoid")
            local showHp = self.ShowHealth and hum ~= nil
            c.HpOut.Visible = showHp
            c.Hp.Visible    = showHp
            if showHp then
                local pct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
                local barH = height * pct
                c.HpOut.Size     = Vector2.new(3, height)
                c.HpOut.Position = Vector2.new(x - 6, y)
                c.Hp.Size        = Vector2.new(3, barH)
                c.Hp.Position    = Vector2.new(x - 6, y + (height - barH))
                c.Hp.Color       = Color3.fromHSV(pct * 0.33, 1, 1)
            end

            -- Name Logic
            c.Name.Visible = self.ShowNames
            if c.Name.Visible then
                c.Name.Text     = data.Name
                c.Name.Color    = textColor
                c.Name.Position = Vector2.new(x + width * 0.5, y - self.TextSize - 2)
            end

            -- Distance Logic
            c.Dist.Visible = self.ShowDistance and localRoot ~= nil
            if c.Dist.Visible then
                c.Dist.Text     = string.format("[%d]", math.floor(dist))
                c.Dist.Color    = textColor
                c.Dist.Position = Vector2.new(x + width * 0.5, y + height + 2)
            end
        end

        -- Tracer Logic
        if self.ShowTracers then
            local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
            c.Tracer.Visible = true
            c.Tracer.Color = color
            c.Tracer.From = center
            c.Tracer.To = Vector2.new(topVP.X, topVP.Y)
        else
            c.Tracer.Visible = false
        end
    end
end

function ESP:Init()
    if self._conn then self._conn:Disconnect() end
    -- Optimized render loop[cite: 1]
    self._conn = RunService.RenderStepped:Connect(function() self:Update() end)
end

function ESP:Unload()
    self:Clear()
    if self._conn then self._conn:Disconnect(); self._conn = nil end
end

ESP:Init()
return ESP
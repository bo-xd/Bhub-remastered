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
	-- seconds between visual updates (throttle to save FPS)
	UpdateRate = 0.06,
	-- when many objects present, only render the closest N
	MaxRendered = 150,
	Objects = {},
	_conn = nil,
	_lastUpdate = 0,
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
	if self.Objects[object] then self:Remove(object) end

	local primaryPart =
		(options and options.PrimaryPart) or
		(object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true))) or
		(object:IsA("BasePart") and object)

	if not primaryPart then return end

	local color = (options and options.Color) or self.BoxColor
	local name  = (options and options.Name)  or object.Name

	local c = {
		BoxOut  = newDrawing("Square", { Thickness=3, Color=Color3.new(0,0,0), Transparency=0.6, Filled=false, Visible=false }),
		Box     = newDrawing("Square", { Thickness=1, Color=color, Transparency=0, Filled=false, Visible=false }),
		HpOut   = newDrawing("Square", { Thickness=1, Color=Color3.new(0,0,0), Transparency=0.6, Filled=true,  Visible=false }),
		Hp      = newDrawing("Square", { Thickness=1, Color=Color3.fromRGB(0,200,0), Transparency=0, Filled=true,  Visible=false }),
		TextBg  = newDrawing("Square", { Filled=true, Color=Color3.new(0,0,0), Transparency=0.6, Visible=false }),
		Name    = newDrawing("Text",   { Text=name,  Color=color, Center=true, Outline=true, Size=self.TextSize, Font=self.TextFont, Visible=false }),
		Dist    = newDrawing("Text",   { Text="",    Color=color, Center=true, Outline=true, Size=self.TextSize, Font=self.TextFont, Visible=false }),
		Tracer  = newDrawing("Line",   { From=Vector2.new(0,0), To=Vector2.new(0,0), Color=color, Thickness=1, Transparency=0, Visible=false }),
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

	-- Auto-remove when destroyed
	object.AncestryChanged:Connect(function(_, parent)
		if not parent then self:Remove(object) end
	end)
end

function ESP:Remove(object)
	local data = self.Objects[object]
	if not data then return end
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
	local now = tick()
	if now - (self._lastUpdate or 0) < (self.UpdateRate or 0.06) then return end
	self._lastUpdate = now

	local cam = workspace.CurrentCamera
	if not cam then return end

	local localChar = LocalPlayer.Character
	local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
	local viewportSize = cam.ViewportSize

	-- gather visible candidates
	local candidates = {}
	for _, data in pairs(self.Objects) do
		local part = data.PrimaryPart
		local globalOk = data.IsEnabled ~= nil or self.Enabled
		local c = data.Components

		if not globalOk or not part or not part.Parent or (data.IsEnabled and not data.IsEnabled()) then
			hideAll(c)
			continue
		end

		local rootPos = part.Position
		local dist = localRoot and (localRoot.Position - rootPos).Magnitude or 0
		if dist > self.MaxDistance then
			hideAll(c)
			continue
		end

		local topVP, onTop = cam:WorldToViewportPoint(rootPos + Vector3.new(0, 3, 0))
		local bottomVP, onBottom = cam:WorldToViewportPoint(rootPos - Vector3.new(0, 3, 0))
		if not (onTop or onBottom) or topVP.Z < 0 then
			hideAll(c)
			continue
		end

		table.insert(candidates, { dist = dist, data = data, top = topVP, bottom = bottomVP })
	end

	-- limit rendered objects to closest N
	local maxR = math.max(1, self.MaxRendered or 150)
	if #candidates > maxR then
		table.sort(candidates, function(a,b) return a.dist < b.dist end)
		for i = maxR + 1, #candidates do
			hideAll(candidates[i].data.Components)
			candidates[i] = nil
		end
	end

	-- render candidates
	for _, entry in ipairs(candidates) do
		local data = entry.data
		local c = data.Components
		local color = data.Color or self.BoxColor
		local textColor = data.Color or self.TextColor
		local topVP = entry.top
		local bottomVP = entry.bottom
		local height = math.max(1, math.abs(topVP.Y - bottomVP.Y))
		local width = height * 0.6
		local x = topVP.X - width * 0.5
		local y = topVP.Y

		if data.TextOnly then
			c.BoxOut.Visible = false; c.Box.Visible = false
			c.HpOut.Visible = false; c.Hp.Visible = false

			c.Name.Visible = self.ShowNames
			if c.Name.Visible then
				c.Name.Text = data.Name
				c.Name.Color = textColor
				local namePos = Vector2.new(topVP.X, y)
				c.Name.Position = namePos
				local bgW = math.max(40, (#tostring(data.Name)) * (self.TextSize * 0.6) + 8)
				c.TextBg.Size = Vector2.new(bgW, self.TextSize + 6)
				c.TextBg.Position = namePos - Vector2.new(c.TextBg.Size.X/2, (self.TextSize/2) + 3)
				c.TextBg.Visible = true
			else
				c.TextBg.Visible = false
			end

			c.Dist.Visible = self.ShowDistance and localRoot ~= nil
			if c.Dist.Visible then
				c.Dist.Text = string.format("[%d]", math.floor(entry.dist))
				c.Dist.Color = textColor
				c.Dist.Position = Vector2.new(topVP.X, y + self.TextSize + 2)
			end
		else
			-- Box
			local showBox = self.ShowBoxes
			c.BoxOut.Visible = showBox
			c.Box.Visible = showBox
			if showBox then
				c.BoxOut.Size = Vector2.new(width, height)
				c.BoxOut.Position = Vector2.new(x, y)
				c.Box.Size = Vector2.new(width, height)
				c.Box.Position = Vector2.new(x, y)
				c.Box.Color = color
			end

			-- Health bar
			local hum = data.Object and data.Object:FindFirstChildWhichIsA("Humanoid") or nil
			local showHp = self.ShowHealth and hum ~= nil
			c.HpOut.Visible = showHp; c.Hp.Visible = showHp
			if showHp then
				local pct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
				local barH = height * pct
				c.HpOut.Size = Vector2.new(3, height)
				c.HpOut.Position = Vector2.new(x - 6, y)
				c.Hp.Size = Vector2.new(3, barH)
				c.Hp.Position = Vector2.new(x - 6, y + (height - barH))
				c.Hp.Color = Color3.fromHSV(pct * 0.33, 1, 1)
			end

			-- Name + background
			c.Name.Visible = self.ShowNames
			if c.Name.Visible then
				c.Name.Text = data.Name
				c.Name.Color = textColor
				c.Name.Position = Vector2.new(x + width * 0.5, y - self.TextSize - 2)
				c.TextBg.Size = Vector2.new(width, self.TextSize + 6)
				c.TextBg.Position = c.Name.Position - Vector2.new(c.TextBg.Size.X/2, (self.TextSize/2) + 3)
				c.TextBg.Visible = true
			else
				c.TextBg.Visible = false
			end

			-- Distance
			c.Dist.Visible = self.ShowDistance and localRoot ~= nil
			if c.Dist.Visible then
				c.Dist.Text = string.format("[%d]", math.floor(entry.dist))
				c.Dist.Color = textColor
				c.Dist.Position = Vector2.new(x + width * 0.5, y + height + 2)
			end
		end

		-- Tracer (line from screen center to top of target)
		if self.ShowTracers then
			local center = Vector2.new(viewportSize.X/2, viewportSize.Y/2)
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
	-- use Heartbeat and internal throttling to reduce render overhead
	self._conn = RunService.Heartbeat:Connect(function() self:Update() end)
end

function ESP:Unload()
	self:Clear()
	if self._conn then self._conn:Disconnect(); self._conn = nil end
end

ESP:Init()
return ESP

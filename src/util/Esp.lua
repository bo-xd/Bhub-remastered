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
	_conn = nil,
	_overlay = nil,
	_usingDrawing = false,
}

local canUseDrawing
do
	local ok, compat = pcall(function()
		return (type(getgenv) == "function" and getgenv().BHub_Compat) or _G.BHub_Compat
	end)
	if ok and compat and type(compat.CanUseDrawing) == "function" then
		canUseDrawing = compat.CanUseDrawing
	else
		canUseDrawing = function()
			if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then
				return false
			end
			local ok = pcall(function()
				local probe = Drawing.new("Square")
				if probe and probe.Remove then
					probe:Remove()
				end
			end)
			return ok
		end
	end
end

ESP._usingDrawing = canUseDrawing()

local getGuiParent
do
	local ok, compat = pcall(function()
		return (type(getgenv) == "function" and getgenv().BHub_Compat) or _G.BHub_Compat
	end)
	if ok and compat and type(compat.GetGuiParent) == "function" then
		getGuiParent = compat.GetGuiParent
	else
		getGuiParent = function()
			local ok, hui = pcall(function()
				if type(gethui) == "function" then
					return gethui()
				end
			end)
			if ok and hui then
				return hui
			end
			local lp = Players.LocalPlayer
			if lp then
				return lp:WaitForChild("PlayerGui")
			end
			return game:GetService("CoreGui")
		end
	end
end

local function ensureOverlay()
	if ESP._overlay and ESP._overlay.Parent then
		return ESP._overlay
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "BHubESPOverlay"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 300
	gui.Parent = getGuiParent()
	ESP._overlay = gui
	return gui
end

local function hideAll(components)
	for key, c in pairs(components) do
		if not (type(key) == "string" and string.sub(key, 1, 1) == "_") then
			if c then
				pcall(function()
					c.Visible = false
				end)
			end
		end
	end
end

local function makeStrokeFrame(parent, color, thickness)
	local frame = Instance.new("Frame")
	frame.Parent = parent
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Visible = false

	local stroke = Instance.new("UIStroke")
	stroke.Parent = frame
	stroke.Thickness = thickness or 1
	stroke.Color = color

	return frame, stroke
end

local function makeText(parent)
	local label = Instance.new("TextLabel")
	label.Parent = parent
	label.Size = UDim2.new(0, 200, 0, 16)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Font = Enum.Font.SourceSans
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Visible = false
	return label
end

local function makeTracer(parent)
	local line = Instance.new("Frame")
	line.Parent = parent
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.BorderSizePixel = 0
	line.BackgroundColor3 = Color3.new(1, 1, 1)
	line.Size = UDim2.fromOffset(0, 1)
	line.Visible = false
	return line
end

local function newDrawing(class, props)
	local success, result = pcall(function()
		local d = Drawing.new(class)
		for k, v in pairs(props) do
			d[k] = v
		end
		return d
	end)

	if success then
		return result
	else
		return nil
	end
end

local function createDrawingComponents(dataColor, dataName)
	return {
		BoxOut = newDrawing(
			"Square",
			{ Thickness = 3, Color = Color3.new(0, 0, 0), Transparency = 1, Filled = false, Visible = false }
		),
		Box = newDrawing(
			"Square",
			{ Thickness = 1, Color = dataColor, Transparency = 1, Filled = false, Visible = false }
		),
		HpOut = newDrawing(
			"Square",
			{ Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 1, Filled = true, Visible = false }
		),
		Hp = newDrawing(
			"Square",
			{ Thickness = 1, Color = Color3.fromRGB(0, 200, 0), Transparency = 1, Filled = true, Visible = false }
		),
		Name = newDrawing(
			"Text",
			{
				Text = dataName,
				Color = dataColor,
				Center = true,
				Outline = true,
				Size = ESP.TextSize,
				Font = ESP.TextFont,
				Visible = false,
			}
		),
		Dist = newDrawing(
			"Text",
			{
				Text = "",
				Color = dataColor,
				Center = true,
				Outline = true,
				Size = ESP.TextSize,
				Font = ESP.TextFont,
				Visible = false,
			}
		),
		Tracer = newDrawing(
			"Line",
			{
				From = Vector2.new(0, 0),
				To = Vector2.new(0, 0),
				Color = dataColor,
				Thickness = 1,
				Transparency = 1,
				Visible = false,
			}
		),
	}
end

local function createInstanceComponents(dataColor)
	local overlay = ensureOverlay()

	local root = Instance.new("Folder")
	root.Name = "ESPItem"
	root.Parent = overlay

	local boxOut, boxOutStroke = makeStrokeFrame(root, Color3.new(0, 0, 0), 2)
	local box, boxStroke = makeStrokeFrame(root, dataColor, 1)

	local hpOut = Instance.new("Frame")
	hpOut.Parent = root
	hpOut.BackgroundColor3 = Color3.new(0, 0, 0)
	hpOut.BorderSizePixel = 0
	hpOut.Visible = false

	local hp = Instance.new("Frame")
	hp.Parent = root
	hp.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	hp.BorderSizePixel = 0
	hp.Visible = false

	local name = makeText(root)
	local dist = makeText(root)
	local tracer = makeTracer(root)

	return {
		Root = root,
		BoxOut = boxOut,
		Box = box,
		HpOut = hpOut,
		Hp = hp,
		Name = name,
		Dist = dist,
		Tracer = tracer,
		_BoxStroke = boxStroke,
		_BoxOutStroke = boxOutStroke,
	}
end

function ESP:Add(object, options)
	if self.Objects[object] then
		self:Remove(object)
	end

	local primaryPart = (options and options.PrimaryPart)
		or (object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)))
		or (object:IsA("BasePart") and object)

	if not primaryPart then
		return
	end

	local color = (options and options.Color) or self.BoxColor
	local name = (options and options.Name) or object.Name

	local components
	if self._usingDrawing then
		components = createDrawingComponents(color, name)
	else
		components = createInstanceComponents(color)
	end

	self.Objects[object] = {
		PrimaryPart = primaryPart,
		Object = object,
		Name = name,
		Color = color,
		TextOnly = options and options.TextOnly or false,
		IsEnabled = options and options.IsEnabled,
		Components = components,
	}
end

function ESP:Remove(object)
	local data = self.Objects[object]
	if not data then
		return
	end

	for key, c in pairs(data.Components) do
		if not (type(key) == "string" and string.sub(key, 1, 1) == "_") then
			if typeof(c) == "table" then
			elseif self._usingDrawing then
				pcall(function()
					c.Visible = false
				end)
				pcall(function()
					c:Remove()
				end)
			elseif typeof(c) == "Instance" and c ~= data.Components.Root then
				c:Destroy()
			end
		end
	end

	if not self._usingDrawing and data.Components.Root and data.Components.Root.Parent then
		data.Components.Root:Destroy()
	end

	self.Objects[object] = nil
end

function ESP:Clear()
	for obj in pairs(self.Objects) do
		self:Remove(obj)
	end
end

local function updateDrawingObject(self, data, localRoot, cam, topVP, bottomVP, dist)
	local c = data.Components
	local color = data.Color or self.BoxColor
	local textColor = data.Color or self.TextColor
	local height = math.max(1, math.abs(topVP.Y - bottomVP.Y))
	local width = height * 0.6
	local x = topVP.X - width * 0.5
	local y = topVP.Y

	if data.TextOnly then
		hideAll({ c.BoxOut, c.Box, c.HpOut, c.Hp })

		c.Name.Visible = self.ShowNames
		c.Name.Text = data.Name
		c.Name.Color = textColor
		c.Name.Position = Vector2.new(topVP.X, y)

		c.Dist.Visible = self.ShowDistance and localRoot ~= nil
		if c.Dist.Visible then
			c.Dist.Text = string.format("[%d]", math.floor(dist))
			c.Dist.Color = textColor
			c.Dist.Position = Vector2.new(topVP.X, y + self.TextSize + 2)
		end
	else
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

		local hum = data.Object:FindFirstChildWhichIsA("Humanoid")
		local showHp = self.ShowHealth and hum ~= nil
		c.HpOut.Visible = showHp
		c.Hp.Visible = showHp
		if showHp then
			local pct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
			local barH = height * pct
			c.HpOut.Size = Vector2.new(3, height)
			c.HpOut.Position = Vector2.new(x - 6, y)
			c.Hp.Size = Vector2.new(3, barH)
			c.Hp.Position = Vector2.new(x - 6, y + (height - barH))
			c.Hp.Color = Color3.fromHSV(pct * 0.33, 1, 1)
		end

		c.Name.Visible = self.ShowNames
		if c.Name.Visible then
			c.Name.Text = data.Name
			c.Name.Color = textColor
			c.Name.Position = Vector2.new(x + width * 0.5, y - self.TextSize - 2)
		end

		c.Dist.Visible = self.ShowDistance and localRoot ~= nil
		if c.Dist.Visible then
			c.Dist.Text = string.format("[%d]", math.floor(dist))
			c.Dist.Color = textColor
			c.Dist.Position = Vector2.new(x + width * 0.5, y + height + 2)
		end
	end

	if self.ShowTracers then
		local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
		c.Tracer.Visible = true
		c.Tracer.Color = color
		c.Tracer.From = center
		c.Tracer.To = Vector2.new(topVP.X, topVP.Y)
	else
		c.Tracer.Visible = false
	end
end

local function updateInstanceObject(self, data, localRoot, cam, topVP, bottomVP, dist)
	local c = data.Components
	local color = data.Color or self.BoxColor
	local textColor = data.Color or self.TextColor
	local height = math.max(1, math.abs(topVP.Y - bottomVP.Y))
	local width = height * 0.6
	local x = topVP.X - width * 0.5
	local y = topVP.Y

	if data.TextOnly then
		c.BoxOut.Visible = false
		c.Box.Visible = false
		c.HpOut.Visible = false
		c.Hp.Visible = false

		c.Name.Visible = self.ShowNames
		c.Name.Text = data.Name
		c.Name.TextColor3 = textColor
		c.Name.TextSize = self.TextSize
		c.Name.Position = UDim2.fromOffset(topVP.X - 100, y - 8)

		c.Dist.Visible = self.ShowDistance and localRoot ~= nil
		if c.Dist.Visible then
			c.Dist.Text = string.format("[%d]", math.floor(dist))
			c.Dist.TextColor3 = textColor
			c.Dist.TextSize = self.TextSize
			c.Dist.Position = UDim2.fromOffset(topVP.X - 100, y + self.TextSize)
		end
	else
		local showBox = self.ShowBoxes
		c.BoxOut.Visible = showBox
		c.Box.Visible = showBox
		if showBox then
			c.BoxOut.Position = UDim2.fromOffset(x, y)
			c.BoxOut.Size = UDim2.fromOffset(width, height)
			c.Box.Position = UDim2.fromOffset(x, y)
			c.Box.Size = UDim2.fromOffset(width, height)
			c._BoxStroke.Color = color
		end

		local hum = data.Object:FindFirstChildWhichIsA("Humanoid")
		local showHp = self.ShowHealth and hum ~= nil
		c.HpOut.Visible = showHp
		c.Hp.Visible = showHp
		if showHp then
			local pct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
			local barH = height * pct
			c.HpOut.Position = UDim2.fromOffset(x - 6, y)
			c.HpOut.Size = UDim2.fromOffset(3, height)
			c.Hp.Position = UDim2.fromOffset(x - 6, y + (height - barH))
			c.Hp.Size = UDim2.fromOffset(3, barH)
			c.Hp.BackgroundColor3 = Color3.fromHSV(pct * 0.33, 1, 1)
		end

		c.Name.Visible = self.ShowNames
		if c.Name.Visible then
			c.Name.Text = data.Name
			c.Name.TextColor3 = textColor
			c.Name.TextSize = self.TextSize
			c.Name.Position = UDim2.fromOffset((x + width * 0.5) - 100, y - self.TextSize - 2)
		end

		c.Dist.Visible = self.ShowDistance and localRoot ~= nil
		if c.Dist.Visible then
			c.Dist.Text = string.format("[%d]", math.floor(dist))
			c.Dist.TextColor3 = textColor
			c.Dist.TextSize = self.TextSize
			c.Dist.Position = UDim2.fromOffset((x + width * 0.5) - 100, y + height + 2)
		end
	end

	if self.ShowTracers then
		local centerX = cam.ViewportSize.X / 2
		local centerY = cam.ViewportSize.Y / 2
		local dx = topVP.X - centerX
		local dy = topVP.Y - centerY
		local length = math.sqrt(dx * dx + dy * dy)

		c.Tracer.Visible = true
		c.Tracer.BackgroundColor3 = color
		c.Tracer.Size = UDim2.fromOffset(length, 1)
		c.Tracer.Position = UDim2.fromOffset(centerX, centerY)
		c.Tracer.Rotation = math.deg(math.atan2(dy, dx))
	else
		c.Tracer.Visible = false
	end
end

function ESP:Update()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end

	local localChar = LocalPlayer and LocalPlayer.Character
	local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

	for obj, data in pairs(self.Objects) do
		if not obj or not obj.Parent or not data.PrimaryPart or not data.PrimaryPart.Parent then
			self:Remove(obj)
		else
			local part = data.PrimaryPart
			local globalOk = data.IsEnabled ~= nil or self.Enabled
			local c = data.Components

			if not globalOk or (data.IsEnabled and not data.IsEnabled()) then
				hideAll(c)
			else
				local rootPos = part.Position
				local dist = localRoot and (localRoot.Position - rootPos).Magnitude or 0
				if dist > self.MaxDistance then
					hideAll(c)
				else
					local topVP, onTop = cam:WorldToViewportPoint(rootPos + Vector3.new(0, 3, 0))
					local bottomVP, onBottom = cam:WorldToViewportPoint(rootPos - Vector3.new(0, 3, 0))

					if not (onTop or onBottom) or topVP.Z < 0 then
						hideAll(c)
					else
						if self._usingDrawing then
							updateDrawingObject(self, data, localRoot, cam, topVP, bottomVP, dist)
						else
							updateInstanceObject(self, data, localRoot, cam, topVP, bottomVP, dist)
						end
					end
				end
			end
		end
	end
end

function ESP:Init()
	if self._conn then
		self._conn:Disconnect()
	end
	if not self._usingDrawing then
		ensureOverlay()
	end
	self._conn = RunService.RenderStepped:Connect(function()
		self:Update()
	end)
end

function ESP:Unload()
	self:Clear()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	if self._overlay and self._overlay.Parent then
		self._overlay:Destroy()
	end
	self._overlay = nil
end

-- Toggle between Drawing API and Instance-based overlay at runtime.
function ESP:SwitchDrawing(useDrawing)
	if useDrawing == nil then
		return
	end
	if self._usingDrawing == useDrawing then
		return
	end
	self._usingDrawing = useDrawing

	-- Snapshot existing objects
	local snapshot = {}
	for obj, data in pairs(self.Objects) do
		snapshot[obj] = {
			Name = data.Name,
			Color = data.Color,
			TextOnly = data.TextOnly,
			IsEnabled = data.IsEnabled,
			PrimaryPart = data.PrimaryPart,
		}
	end

	-- Clear current components and recreate according to the new mode
	self:Clear()

	for obj, d in pairs(snapshot) do
		pcall(function()
			self:Add(obj, {
				PrimaryPart = d.PrimaryPart,
				Name = d.Name,
				Color = d.Color,
				TextOnly = d.TextOnly,
				IsEnabled = d.IsEnabled,
			})
		end)
	end

	-- Ensure overlay exists for instance-based rendering
	if not self._usingDrawing then
		ensureOverlay()
	else
		-- if using drawing, remove overlay if present
		if self._overlay and self._overlay.Parent then
			self._overlay:Destroy()
		end
		self._overlay = nil
	end
end

ESP:Init()

-- Register with compatibility checker if available to switch drawing mode automatically
pcall(function()
	local compat = (type(getgenv) == "function" and getgenv().BHub_Compat) or _G.BHub_Compat
	if compat and type(compat.RegisterFeatureHandler) == "function" then
		compat.RegisterFeatureHandler("Drawing.new", function(disabled)
			pcall(function()
				ESP:SwitchDrawing(not disabled)
			end)
		end)
	end
end)

return ESP

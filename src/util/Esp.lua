local ESP = {
	Enabled = false,
	ShowBoxes = true,
	ShowNames = true,
	ShowDistance = true,
	ShowHealth = true,
	ShowTracers = false,
    
	BoxColor = Color3.fromRGB(255, 255, 255),
	TextColor = Color3.fromRGB(255, 255, 255),
	TracerColor = Color3.fromRGB(255, 255, 255),
    
	Thickness = 1,
	TextSize = 13,
	TextFont = 2,
    TracerOrigin = "Bottom",
    
	Objects = {},
	Connections = {}
}

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local function CreateDrawing(class, properties)
	local drawing = Drawing.new(class)
	for i, v in pairs(properties) do
		drawing[i] = v
	end
	return drawing
end

function ESP:Add(object, options)
	options = options or {}
	
	if self.Objects[object] then
		self:Remove(object)
	end
	
	local primaryPart = options.PrimaryPart or (object:IsA("Model") and (object.PrimaryPart or object:FindFirstChild("HumanoidRootPart"))) or (object:IsA("BasePart") and object)
	
	if not primaryPart then
		return nil
	end

	local espData = {
		Object = object,
		PrimaryPart = primaryPart,
		Name = options.Name or object.Name,
		Color = options.Color,
		TextOnly = options.TextOnly or false,
		Size = options.Size or (object:IsA("Model") and select(2, object:GetBoundingBox())) or (object:IsA("BasePart") and object.Size) or Vector3.new(4, 5, 0),
		IsEnabled = options.IsEnabled,
        
		Components = {
			BoxOutline = CreateDrawing("Square", { Thickness = 3, Color = Color3.new(0,0,0), Transparency = 1, Filled = false, Visible = false }),
			Box = CreateDrawing("Square", { Thickness = 1, Color = options.Color or self.BoxColor, Transparency = 1, Filled = false, Visible = false }),
			
			HealthBarOutline = CreateDrawing("Square", { Thickness = 1, Color = Color3.new(0,0,0), Transparency = 1, Filled = true, Visible = false }),
			HealthBar = CreateDrawing("Square", { Thickness = 1, Color = Color3.new(0,1,0), Transparency = 1, Filled = true, Visible = false }),

			Name = CreateDrawing("Text", { Text = options.Name or object.Name, Color = options.Color or self.TextColor, Center = true, Outline = true, Size = self.TextSize, Font = self.TextFont, Visible = false }),
			Distance = CreateDrawing("Text", { Text = "", Color = options.Color or self.TextColor, Center = true, Outline = true, Size = self.TextSize, Font = self.TextFont, Visible = false }),
			Tracer = CreateDrawing("Line", { Thickness = 1, Color = options.Color or self.TracerColor, Transparency = 1, Visible = false })
		}
	}
	
	self.Objects[object] = espData
	
	local connection
	connection = object.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:Remove(object)
			if connection then connection:Disconnect() end
		end
	end)
	
	return espData
end

function ESP:Remove(object)
	local espData = self.Objects[object]
	if espData then
		for _, component in pairs(espData.Components) do
			component.Visible = false
			component:Remove()
		end
		self.Objects[object] = nil
	end
end

function ESP:Clear()
	for object, _ in pairs(self.Objects) do
		self:Remove(object)
	end
end

function ESP:Update()
	local localChar = LocalPlayer.Character
	local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

	for object, espData in pairs(self.Objects) do
		local shouldRender = true
		if espData.IsEnabled and not espData.IsEnabled() then
			shouldRender = false
		end

		if not shouldRender or not espData.PrimaryPart or not espData.PrimaryPart.Parent then
			for _, component in pairs(espData.Components) do
				component.Visible = false
			end
			continue
		end

		local cf = espData.PrimaryPart.CFrame
		local size = espData.Size
		
		local rootPos = espData.PrimaryPart.Position
		
		local topPos, onScreenTop = Camera:WorldToViewportPoint(rootPos + Vector3.new(0, 3, 0))
		local bottomPos, onScreenBottom = Camera:WorldToViewportPoint(rootPos - Vector3.new(0, 3, 0))
		
		if onScreenTop or onScreenBottom then
			local height = math.abs(topPos.Y - bottomPos.Y)
			local width = height * 0.7 
			local x = topPos.X - width/2
			local y = topPos.Y
			
			local color = espData.Color or self.BoxColor
			local textColor = espData.Color or self.TextColor
			
			if espData.TextOnly then
				espData.Components.BoxOutline.Visible = false
				espData.Components.Box.Visible = false
				espData.Components.HealthBarOutline.Visible = false
				espData.Components.HealthBar.Visible = false
				espData.Components.Tracer.Visible = false
				
				espData.Components.Name.Visible = true
				espData.Components.Name.Text = espData.Name
				espData.Components.Name.Position = Vector2.new(topPos.X, topPos.Y)
				espData.Components.Name.Color = textColor
				
				if localRoot then
					local dist = math.floor((localRoot.Position - espData.PrimaryPart.Position).Magnitude)
					espData.Components.Distance.Visible = true
					espData.Components.Distance.Text = string.format("%d studs", dist)
					espData.Components.Distance.Position = Vector2.new(topPos.X, topPos.Y + self.TextSize + 2)
					espData.Components.Distance.Color = textColor
				else
					espData.Components.Distance.Visible = false
				end
			else
				if self.ShowBoxes then
					espData.Components.BoxOutline.Visible = true
					espData.Components.BoxOutline.Size = Vector2.new(width, height)
					espData.Components.BoxOutline.Position = Vector2.new(x, y)
					
					espData.Components.Box.Visible = true
					espData.Components.Box.Size = Vector2.new(width, height)
					espData.Components.Box.Position = Vector2.new(x, y)
					espData.Components.Box.Color = color
				else
					espData.Components.BoxOutline.Visible = false
					espData.Components.Box.Visible = false
				end
				
				local humanoid = object:FindFirstChildOfClass("Humanoid")
				if self.ShowHealth and humanoid then
					local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
					local barHeight = height * healthPercent
					local barColor = Color3.fromHSV(healthPercent * 0.3, 1, 1) 
					
					espData.Components.HealthBarOutline.Visible = true
					espData.Components.HealthBarOutline.Size = Vector2.new(2, height)
					espData.Components.HealthBarOutline.Position = Vector2.new(x - 5, y)
					
					espData.Components.HealthBar.Visible = true
					espData.Components.HealthBar.Size = Vector2.new(2, barHeight)
					espData.Components.HealthBar.Position = Vector2.new(x - 5, y + (height - barHeight))
					espData.Components.HealthBar.Color = barColor
				else
					espData.Components.HealthBarOutline.Visible = false
					espData.Components.HealthBar.Visible = false
				end
				
				if self.ShowNames then
					espData.Components.Name.Visible = true
					espData.Components.Name.Text = espData.Name
					espData.Components.Name.Position = Vector2.new(x + width/2, y - self.TextSize - 2)
					espData.Components.Name.Color = textColor
				else
					espData.Components.Name.Visible = false
				end
				
				if self.ShowDistance and localRoot then
					local dist = (localRoot.Position - espData.PrimaryPart.Position).Magnitude
					espData.Components.Distance.Visible = true
					espData.Components.Distance.Text = string.format("%d studs", dist)
					espData.Components.Distance.Position = Vector2.new(x + width/2, y + height + 2)
					espData.Components.Distance.Color = textColor
				else
					espData.Components.Distance.Visible = false
				end
				
				if self.ShowTracers then
					local origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
					
					if self.TracerOrigin == "Top" then
						origin = Vector2.new(Camera.ViewportSize.X / 2, 0)
					elseif self.TracerOrigin == "Middle" then
						origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
					elseif self.TracerOrigin == "Mouse" then
						origin = game:GetService("UserInputService"):GetMouseLocation()
					end
	
					espData.Components.Tracer.Visible = true
					espData.Components.Tracer.From = origin
					espData.Components.Tracer.To = Vector2.new(x + width/2, y + height)
					espData.Components.Tracer.Color = self.TracerColor
				else
					espData.Components.Tracer.Visible = false
				end
			end
		else
			for _, component in pairs(espData.Components) do
				component.Visible = false
			end
		end
	end
end

function ESP:Init()
	if self.Connections["RenderStepped"] then
		self.Connections["RenderStepped"]:Disconnect()
	end
	
	self.Connections["RenderStepped"] = RunService.RenderStepped:Connect(function()
		self:Update()
	end)
end

function ESP:Unload()
	self:Clear()
	for _, conn in pairs(self.Connections) do
		conn:Disconnect()
	end
	self.Connections = {}
end

ESP:Init()
return ESP

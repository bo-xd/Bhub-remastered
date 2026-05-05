return function(Window, ESP, Library)
	local gameFolder = workspace:WaitForChild("Game")
	local playersFolder = gameFolder:WaitForChild("Players")

	local EvadeTab = Window:AddTab("Evade")
	local Visuals = EvadeTab:AddLeftGroupbox("Player ESP")

	local hitboxEspEnabled = false
	Visuals:AddToggle("EvadeHitboxESP", {
		Text = "Enable Hitbox ESP",
		Default = false,
		Callback = function(v)
			hitboxEspEnabled = v
		end,
	})

	task.spawn(function()
		while true do
			task.wait(0.5)

			if hitboxEspEnabled then
				for _, playerModel in pairs(playersFolder:GetChildren()) do
					local hitbox = playerModel:FindFirstChild("Hitbox")
					if hitbox and hitbox:IsA("Part") then
						if not ESP.Objects[playerModel] then
							ESP:Add(playerModel, {
								Name = playerModel.Name,
								PrimaryPart = hitbox,
								Color = Color3.fromRGB(255, 255, 255),
								IsEnabled = function()
									return hitboxEspEnabled and playerModel.Parent ~= nil and hitbox.Parent ~= nil
								end,
							})
						end
					else
						pcall(function()
							ESP:Remove(playerModel)
						end)
					end
				end
			else
				for _, playerModel in pairs(playersFolder:GetChildren()) do
					pcall(function()
						ESP:Remove(playerModel)
					end)
				end
			end
		end
	end)
end
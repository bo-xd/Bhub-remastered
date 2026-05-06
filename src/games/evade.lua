return function(Window, ESP, Library)
	local gameFolder = workspace:WaitForChild("Game")
	local playersFolder = gameFolder:WaitForChild("Players")
	local ChangePlayerMode = game:GetService("ReplicatedStorage").Events.Player.ChangePlayerMode:FireServer(true)
	local State = workspace.Game.Players[game.Players.LocalPlayer.Name]:GetAttribute("State")

	local EvadeTab = Window:AddTab("Evade")
	local Misc = EvadeTab:AddLeftGroupbox("Misc")
	local Visuals = EvadeTab:AddLeftGroupbox("Player ESP")

	local hitboxEspEnabled = false
	Visuals:AddToggle("EvadeHitboxESP", {
		Text = "NextBots ESP",
		Default = false,
		Callback = function(v)
			hitboxEspEnabled = v
		end,
	})

	task.spawn(function()
		while task.wait(0.5) do
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

	local AutoRevive = false;
	Misc:AddToggle("EvadeAutoRevive", {
		Text = "Auto Revive",
		Default = false,
		Callback = function(v)
			AutoRevive = v
		end,
	})

	task.spawn(function()
		while task.wait() do
			if AutoRevive and State == "Downed" then
				ChangePlayerMode:FireServer(true)
			end
		end
	end)
end
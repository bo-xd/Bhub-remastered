local ctween = {}

local player = game:GetService("Players").LocalPlayer
local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

function ctween:go(endPosition, duration)
    local startPosition = humanoidRootPart.CFrame
    local startTime = os.clock()
    local connection

    local updatePosition = function()
        local elapsedTime = os.clock() - startTime
        if elapsedTime >= duration then
            humanoidRootPart.CFrame = endPosition
            connection:Disconnect()
            player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        else
            local t = elapsedTime / duration
            humanoidRootPart.CFrame = startPosition:Lerp(endPosition, t)
        end
    end

    connection = game:GetService("RunService").Heartbeat:Connect(updatePosition)

    return function()
        connection:Disconnect()
    end
end

return ctween

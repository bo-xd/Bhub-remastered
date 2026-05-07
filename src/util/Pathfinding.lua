local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local Pathfinding = {}

local function resolvePosition(x)
    if typeof(x) == "Vector3" then
        return x
    end
    if typeof(x) == "Instance" then
        if x:IsA("BasePart") then
            return x.Position
        end
        if x:IsA("Model") then
            local hrp = x:FindFirstChild("HumanoidRootPart") or x.PrimaryPart
            if hrp and hrp:IsA("BasePart") then
                return hrp.Position
            end
        end
        if x.Position and typeof(x.Position) == "Vector3" then
            return x.Position
        end
    end
    error("resolvePosition: unsupported value, expected Vector3 or Instance with position")
end

function Pathfinding:FindPath(startObj, goalObj, opts)
    opts = opts or {}
    local startPos = resolvePosition(startObj)
    local goalPos = resolvePosition(goalObj)

    local success, result
    local ok, err = pcall(function()
        local params = {}

        if opts.AgentRadius ~= nil then params.AgentRadius = opts.AgentRadius end
        if opts.AgentHeight ~= nil then params.AgentHeight = opts.AgentHeight end
        if opts.AgentCanJump ~= nil then params.AgentCanJump = opts.AgentCanJump end
        if opts.AgentJumpHeight ~= nil then params.AgentJumpHeight = opts.AgentJumpHeight end
        if opts.AgentMaxSlope ~= nil then params.AgentMaxSlope = opts.AgentMaxSlope end

        local path = PathfindingService:CreatePath(params)
        path:ComputeAsync(startPos, goalPos)
        success = true
        result = path
    end)

    if not ok then
        return {
            Status = "Error",
            Error = tostring(err),
            Waypoints = {},
            Path = nil,
        }
    end

    if not result then
        return {
            Status = "Unknown",
            Error = "CreatePath returned nil",
            Waypoints = {},
            Path = nil,
        }
    end

    local status = result.Status
    local wps = {}
    for i, wp in ipairs(result:GetWaypoints()) do
        table.insert(wps, {
            Position = wp.Position,
            Action = wp.Action,
        })
    end

    return {
        Status = tostring(status),
        Waypoints = wps,
        Path = result,
    }
end

function Pathfinding:FollowPath(character, waypoints, options)
    options = options or {}
    local arrival = options.ArrivalTolerance or 4
    local timeoutPer = options.Timeout or 6
    local teleport = options.TeleportIfStuck or false

    if not character or not character.Parent then
        return false, "invalid_character"
    end

    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then
        return false, "missing_humanoid_or_hrp"
    end

    -- allow passing the whole result from FindPath
    if waypoints and waypoints.Waypoints and type(waypoints.Waypoints) == "table" then
        waypoints = waypoints.Waypoints
    end

    if type(waypoints) ~= "table" or #waypoints == 0 then
        return false, "no_waypoints"
    end

    for i, wp in ipairs(waypoints) do
        local pos = wp.Position
        local action = wp.Action
        if action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        local finished = false
        local timedOut = false

        local conn
        conn = humanoid.MoveToFinished:Connect(function(reached)
            finished = reached
        end)

        humanoid:MoveTo(pos)

        local startT = tick()
        while true do
            if not character or not character.Parent then
                conn:Disconnect()
                return false, "character_gone"
            end

            local dist = (hrp.Position - pos).Magnitude
            if dist <= arrival then
                conn:Disconnect()
                break
            end

            if finished then
                conn:Disconnect()
                break
            end

            if tick() - startT > timeoutPer then
                timedOut = true
                conn:Disconnect()
                break
            end

            RunService.Heartbeat:Wait()
        end

        if timedOut then
            if teleport then
                pcall(function()
                    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                end)
            else
                return false, string.format("timeout_at_waypoint_%d", i)
            end
        end
    end

    return true
end

return Pathfinding

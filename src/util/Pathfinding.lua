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

function Pathfinding:ShowPath(waypoints, duration, options)
    duration = duration or 10
    options = options or {}
    
    local drawingAvailable = pcall(function() 
        return Drawing ~= nil
    end)
    
    if drawingAvailable and Drawing then
        return self:_showPathDrawing(waypoints, duration, options)
    else
        return self:_showPathParts(waypoints, duration, options)
    end
end

function Pathfinding:_showPathDrawing(waypoints, duration, options)
    local drawings = {}
    
    local lineColor = options.LineColor or Color3.fromRGB(0, 255, 0)
    local startColor = options.StartColor or Color3.fromRGB(0, 255, 0)
    local endColor = options.EndColor or Color3.fromRGB(255, 0, 0)
    local waypointColor = options.WaypointColor or Color3.fromRGB(100, 149, 237)
    local lineThickness = options.LineThickness or 2
    
    local camera = workspace.CurrentCamera

    for i = 1, #waypoints - 1 do
        local wp1 = waypoints[i].Position
        local wp2 = waypoints[i + 1].Position
        
        local line = Drawing.new("Line")
        line.Visible = true
        line.Color = lineColor
        line.Thickness = lineThickness

        line.From = camera:WorldToScreenPoint(wp1)
        line.To = camera:WorldToScreenPoint(wp2)
        
        table.insert(drawings, {obj = line, type = "line", wp1 = wp1, wp2 = wp2})
    end

    for i, wp in ipairs(waypoints) do
        local color = i == 1 and startColor or (i == #waypoints and endColor or waypointColor)
        
        local circle = Drawing.new("Circle")
        circle.Visible = true
        circle.Color = color
        circle.Filled = true
        circle.Radius = 8
        
        local screenPos = camera:WorldToScreenPoint(wp.Position)
        circle.Position = Vector2.new(screenPos.X, screenPos.Y)
        
        table.insert(drawings, {obj = circle, type = "circle", pos = wp.Position})
    end
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        for _, drawing in ipairs(drawings) do
            if drawing.type == "line" then
                local from = camera:WorldToScreenPoint(drawing.wp1)
                local to = camera:WorldToScreenPoint(drawing.wp2)
                drawing.obj.From = Vector2.new(from.X, from.Y)
                drawing.obj.To = Vector2.new(to.X, to.Y)
            elseif drawing.type == "circle" then
                local screenPos = camera:WorldToScreenPoint(drawing.pos)
                drawing.obj.Position = Vector2.new(screenPos.X, screenPos.Y)
            end
        end
    end)

    task.delay(duration, function()
        connection:Disconnect()
        for _, drawing in ipairs(drawings) do
            pcall(function()
                drawing.obj:Remove()
            end)
        end
    end)
    
    return {Type = "Drawing", Count = #drawings}
end

function Pathfinding:_showPathParts(waypoints, duration, options)
    local lineColor = options.LineColor or Color3.fromRGB(0, 255, 0)
    local startColor = options.StartColor or Color3.fromRGB(0, 255, 0)
    local endColor = options.EndColor or Color3.fromRGB(255, 0, 0)
    local waypointColor = options.WaypointColor or Color3.fromRGB(100, 149, 237)
    
    local folder = Instance.new("Folder")
    folder.Name = "PathVisualization"
    folder.Parent = workspace
    
    -- Draw lines between consecutive waypoints
    for i = 1, #waypoints - 1 do
        local wp1 = waypoints[i].Position
        local wp2 = waypoints[i + 1].Position
        
        local direction = (wp2 - wp1)
        local distance = direction.Magnitude
        local midpoint = (wp1 + wp2) / 2
        
        local line = Instance.new("Part")
        line.Name = "PathLine_" .. i
        line.Shape = Enum.PartType.Cylinder
        line.Material = Enum.Material.Neon
        line.Color = lineColor
        line.CanCollide = false
        line.CFrame = CFrame.new(midpoint, wp2)
        line.Size = Vector3.new(0.2, distance, 0.2)
        line.Parent = folder
    end
    
    -- Mark waypoints with small spheres
    for i, wp in ipairs(waypoints) do
        local color = i == 1 and startColor or (i == #waypoints and endColor or waypointColor)
        
        local marker = Instance.new("Part")
        marker.Name = "Waypoint_" .. i
        marker.Shape = Enum.PartType.Ball
        marker.Material = Enum.Material.Neon
        marker.Color = color
        marker.CanCollide = false
        marker.Size = Vector3.new(0.6, 0.6, 0.6)
        marker.Position = wp.Position + Vector3.new(0, 2, 0)
        marker.Parent = folder
    end
    
    -- Clean up after duration
    task.delay(duration, function()
        if folder and folder.Parent then
            folder:Destroy()
        end
    end)
    
    return {Type = "Parts", Count = #waypoints}
end

return Pathfinding

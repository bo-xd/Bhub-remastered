local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Compat = {}
Compat.__index = Compat

Compat.Supports = {}
Compat.DisabledFeatures = {}
Compat._prevDisabled = {}

local _handlers = {}

local function resolveGlobal(name)
    local parts = {}
    for part in string.gmatch(name, "[^%.]+") do table.insert(parts, part) end

    local function lookup(env)
        local val = env
        for i, part in ipairs(parts) do
            if type(val) == "table" and val[part] ~= nil then
                val = val[part]
            else
                if i == 1 and type(env) == "table" and rawget(env, part) ~= nil then
                    val = rawget(env, part)
                else
                    return nil
                end
            end
        end
        return val
    end

    local envs = { _G }
    if type(getgenv) == "function" then
        local ok, genv = pcall(getgenv)
        if ok and type(genv) == "table" and genv ~= _G then
            table.insert(envs, 1, genv)
        end
    end

    for _, env in ipairs(envs) do
        local val = lookup(env)
        if val ~= nil then
            return val
        end
    end

    return nil
end

local names = {
    "Drawing.new", "Drawing.Fonts",
    "isfile", "readfile", "writefile", "isfolder", "makefolder", "listfiles", "appendfile", "delfile", "delfolder",
    "request", "http_request", "WebSocket.connect",
    "setclipboard",
    "queue_on_teleport",
    "getrawmetatable", "hookmetamethod", "hookfunction", "restorefunction",
    "getgc", "getconnections", "getinstances", "getloadedmodules",
    "loadstring", "loadfile",
    "cache.iscached", "cache.invalidate", "cache.replace",
    "getgenv", "getrenv",
    "gethui",
}

local expectedType = {
    ["Drawing.new"] = "function",
    ["Drawing.Fonts"] = "table",
    ["isfile"] = "function",
    ["readfile"] = "function",
    ["writefile"] = "function",
    ["isfolder"] = "function",
    ["makefolder"] = "function",
    ["request"] = "function",
    ["http_request"] = "function",
    ["WebSocket.connect"] = "function",
    ["setclipboard"] = "function",
    ["queue_on_teleport"] = "function",
    ["getrawmetatable"] = "function",
    ["hookmetamethod"] = "function",
    ["hookfunction"] = "function",
    ["loadstring"] = "function",
    ["loadfile"] = "function",
    ["cache.iscached"] = "function",
}

local function dedupeOrder(t)
    local seen = {}
    local out = {}
    for _, v in ipairs(t) do
        if not seen[v] then seen[v] = true; table.insert(out, v) end
    end
    return out
end
names = dedupeOrder(names)

local _checks = {}
for _, nm in ipairs(names) do
    table.insert(_checks, {
        id = nm,
        label = nm,
        expected = expectedType[nm],
        test = function()
            return resolveGlobal(nm)
        end,
        features = { nm },
    })
end

local function getGuiParent()

    local ok, hui = pcall(function()
        if type(gethui) == "function" then return gethui() end
    end)
    if ok and hui then return hui end
    local lp = Players.LocalPlayer
    if lp then
        local ok2, pg = pcall(function() return lp:FindFirstChild("PlayerGui") end)
        if ok2 and pg then return pg end
    end
    return game:GetService("CoreGui")
end

local function createSummaryGui()
    if Compat._summaryGui and Compat._summaryGui.Parent then return Compat._summaryGui end
    local parent = getGuiParent()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BHubCompatSummary"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000
    gui.Parent = parent

    local frame = Instance.new("Frame")
    frame.Name = "CompatFrame"
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.Position = UDim2.new(1, -12, 0, 12)
    frame.Size = UDim2.new(0, 360, 0, 28)
    frame.BackgroundTransparency = 0.18
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local label = Instance.new("TextLabel")
    label.Name = "CompatLabel"
    label.Size = UDim2.new(1, -12, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Right
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 200, 80)
    label.Text = ""
    label.Parent = frame

    Compat._summaryGui = gui
    Compat._summaryLabel = label
    return gui
end

local function updateSummaryGui(aggregateDisabled)
    if not aggregateDisabled or #aggregateDisabled == 0 then
        if Compat._summaryGui and Compat._summaryGui.Parent then
            pcall(function() Compat._summaryGui:Destroy() end)
        end
        Compat._summaryGui = nil
        Compat._summaryLabel = nil
        return
    end

    local gui = createSummaryGui()
    if not Compat._summaryLabel then return end
    Compat._summaryLabel.Text = "Limited: " .. table.concat(aggregateDisabled, ", ")
end

local function safeNotify(title, text, duration)
    duration = duration or 6
    pcall(function()
        if type(_G) == "table" and _G.Library and type(_G.Library.Notify) == "function" then
            _G.Library:Notify(text, duration)
            return
        end
    end)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title or "BHub", Text = text or "", Duration = duration })
    end)
    print(("[BHub-Compat] %s: %s"):format(title or "BHub", text or ""))
end

function Compat.RegisterFeatureHandler(featureName, handler)
    if type(featureName) ~= "string" or type(handler) ~= "function" then return false end
    _handlers[featureName] = _handlers[featureName] or {}
    table.insert(_handlers[featureName], handler)

    local disabled = Compat.DisabledFeatures[featureName]
    if disabled then pcall(handler, true) end
    return true
end

function Compat.RunChecks(options)
    options = options or {}
    local showUI = options.ShowUI == true
    local notify = (options.Notify ~= false) or showUI
    local notifyAll = options.NotifyAll == true

    local unsupported = {}
    local newSupports = {}
    local disabledFeatures = {}

    for _, check in ipairs(_checks) do
        local ok, val = pcall(check.test)
        local passed = false
        if ok and val ~= nil then
            if check.expected then
                if check.expected == "function" then passed = (type(val) == "function")
                elseif check.expected == "table" then passed = (type(val) == "table")
                else passed = true end
            else
                passed = true
            end
        end
        Compat.Supports[check.id] = passed
        if not passed then
            disabledFeatures[check.id] = true
            table.insert(unsupported, check)
        end
    end

    for k, _ in pairs(disabledFeatures) do Compat.DisabledFeatures[k] = true end

    local groups = {
        ConfigSaveLoad = { 'isfile', 'readfile', 'writefile', 'isfolder', 'makefolder' },
        DrawingAPI = { 'Drawing.new', 'Drawing.Fonts' },
        Hooking = { 'getrawmetatable', 'hookmetamethod', 'hookfunction', 'restorefunction' },
        HTTP = { 'request', 'http_request', 'WebSocket.connect' },
        ClipboardCopy = { 'setclipboard' },
        QueueOnTeleport = { 'queue_on_teleport' },
        Cache = { 'cache.iscached', 'cache.invalidate', 'cache.replace' },
        DebugHelpers = { 'getgc', 'debug.getupvalues', 'debug.getprotos', 'debug.getinfo' },
    }

    for gname, deps in pairs(groups) do
        local ok = true
        for _, dep in ipairs(deps) do
            if not Compat.Supports[dep] then ok = false; break end
        end
        if not ok then Compat.DisabledFeatures[gname] = true end
    end

    local prev = Compat._prevDisabled or {}
    local now = {}
    for k, _ in pairs(Compat.DisabledFeatures) do now[k] = true end

    for k, _ in pairs(now) do
        if not prev[k] then
            local hs = _handlers[k]
            if hs then for _, h in ipairs(hs) do pcall(h, true) end end
        end
    end

    for k, _ in pairs(prev) do
        if not now[k] then
            local hs = _handlers[k]
            if hs then for _, h in ipairs(hs) do pcall(h, false) end end
        end
    end

    Compat._prevDisabled = {}
    for k, _ in pairs(now) do Compat._prevDisabled[k] = true end

    if notify and #unsupported > 0 then
        if notifyAll and not showUI then
            for _, c in ipairs(unsupported) do
                local m = ("Your executor doesn't support %s; some features may be limited or disabled."):format(c.label or c.id)
                safeNotify("Executor incompatibility", m, 6)
            end
        else
            local namesList = {}
            for _, c in ipairs(unsupported) do table.insert(namesList, c.label or c.id) end
            local msg = "Your executor may be missing: " .. table.concat(namesList, ", ") .. ". Some features may be limited or disabled."
            safeNotify("Executor incompatibility", msg, 8)
        end
    end

    if notify then
        local ag = {}
        for k, _ in pairs(groups) do
            if Compat.DisabledFeatures[k] then table.insert(ag, k) end
        end
        updateSummaryGui(ag)
    end

    return Compat.Supports, Compat.DisabledFeatures
end

pcall(function() Compat.RunChecks({ Notify = true, NotifyAll = false }) end)

Compat.GetGuiParent = getGuiParent
Compat.CanUseDrawing = function()
    local ok, val = pcall(function()
        if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then return false end
        local probe = Drawing.new("Square")
        if probe and probe.Remove then probe:Remove() end
        return true
    end)
    return ok and val
end
Compat.SafeNotify = safeNotify

pcall(function()
    if type(getgenv) == "function" then
        local g = getgenv()
        g.BHub_Compat = Compat
    else
        _G = _G or {}
        _G.BHub_Compat = Compat
    end
end)

return Compat

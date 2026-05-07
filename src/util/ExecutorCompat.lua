local Compat = {}
Compat.Supports = {}
Compat.DisabledFeatures = {}

local function resolve(path)
    local parts = string.split(path, ".")
    local current = getgenv and getgenv() or _G
    
    for _, part in ipairs(parts) do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end
    return current
end

local FeatureRequirements = {
    ["DrawingAPI"]    = { "Drawing.new" },
    ["FileIO"]        = { "readfile", "writefile", "isfile", "makefolder" },
    ["HTTP"]          = { "request" },
    ["Clipboard"]     = { "setclipboard" },
    ["TeleportSave"]  = { "queue_on_teleport" },
    ["Proximity"]     = { "fireproximityprompt" }
}

local Fallbacks = {
    ["request"] = { "http_request", "http.request" }
}

function Compat:RunChecks()
    self.Supports = {}
    self.DisabledFeatures = {}

    for feature, reqs in pairs(FeatureRequirements) do
        local featureDisabled = false
        for _, funcPath in ipairs(reqs) do
            if self.Supports[funcPath] == nil then
                local found = resolve(funcPath)
                if not found and Fallbacks[funcPath] then
                    for _, alt in ipairs(Fallbacks[funcPath]) do
                        found = resolve(alt)
                        if found then break end
                    end
                end
                self.Supports[funcPath] = (found ~= nil)
            end
            if not self.Supports[funcPath] then
                featureDisabled = true
            end
        end
        self.DisabledFeatures[feature] = featureDisabled
    end

    return self.DisabledFeatures
end

function Compat:CanUse(featureName)
    if self.DisabledFeatures[featureName] == nil then
        return true
    end
    return not self.DisabledFeatures[featureName]
end

Compat:RunChecks()

if getgenv then getgenv().BHub_Compat = Compat end
return Compat
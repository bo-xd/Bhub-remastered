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

    local allFunctions = {
        "Drawing.new", "readfile", "writefile", "isfile", "makefolder", 
        "request", "setclipboard", "queue_on_teleport", "fireproximityprompt",
        "gethui", "getgenv"
    }

    for _, funcPath in ipairs(allFunctions) do
        local found = resolve(funcPath)

        if not found and Fallbacks[funcPath] then
            for _, alt in ipairs(Fallbacks[funcPath]) do
                found = resolve(alt)
                if found then break end
            end
        end
        
        self.Supports[funcPath] = (found ~= nil)
    end

    for feature, reqs in pairs(FeatureRequirements) do
        local isDisabled = false
        for _, req in ipairs(reqs) do
            if not self.Supports[req] then
                isDisabled = true
                break
            end
        end
        self.DisabledFeatures[feature] = isDisabled
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
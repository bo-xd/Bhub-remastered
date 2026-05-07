-- Test script for ExecutorCompat.lua
-- This script tests the executor compatibility layer

local Compat = loadstring(game:HttpGet("https://raw.githubusercontent.com/bo-xd/Bhub-remastered/refs/heads/main/src/util/ExecutorCompat.lua"))()

-- Test 1: Run compatibility checks
Compat:RunChecks({
    ShowUI = true,  -- Show the compatibility summary UI
    Silent = false, -- Print results to console
})

-- Test 2: Check specific features
print("Drawing.new supported:", Compat.Supports["Drawing.new"])
print("File IO supported:", Compat.Supports["isfile"])
print("HTTP requests supported:", Compat.Supports["request"])
print("WebSocket supported:", Compat.Supports["WebSocket.connect"])
print("Clipboard supported:", Compat.Supports["setclipboard"])

-- Test 3: Register a custom feature handler
Compat:RegisterFeatureHandler("CustomFeature", function()
    return true, "Custom feature is available"
end)

-- Test 4: Check disabled features
print("Disabled features:", table.concat((function()
    local disabled = {}
    for k, v in pairs(Compat.DisabledFeatures) do
        if v then table.insert(disabled, k) end
    end
    return disabled
end)(), ", "))

-- Test 5: Test GetGuiParent function (if available)
local ok, guiParent = pcall(function() return Compat:GetGuiParent() end)
if ok then
    print("GUI Parent retrieved successfully")
else
    print("GUI Parent not available:", guiParent)
end

print("ExecutorCompat test completed!")
-- Test script for ExecutorCompat.lua - Testing feature disabling when functions are missing
-- This script simulates missing functions and verifies that features are properly disabled

local Compat = loadstring(game:HttpGet("https://raw.githubusercontent.com/bo-xd/Bhub-remastered/refs/heads/main/src/util/ExecutorCompat.lua"))()

print("=== Testing Feature Disabling ===")

-- Backup original functions
local originalDrawing = Drawing
local originalIsfile = isfile
local originalRequest = request
local originalSetclipboard = setclipboard

-- Simulate missing functions by temporarily removing them
Drawing = nil
isfile = nil
request = nil
setclipboard = nil

print("Simulated missing functions: Drawing, isfile, request, setclipboard")

-- Run compatibility checks
Compat:RunChecks({
    ShowUI = false,  -- Don't show UI for test
    Silent = false,  -- Print results
})

-- Check individual function support
print("\n=== Individual Function Support ===")
print("Drawing.new supported:", Compat.Supports["Drawing.new"])
print("Drawing.Fonts supported:", Compat.Supports["Drawing.Fonts"])
print("isfile supported:", Compat.Supports["isfile"])
print("request supported:", Compat.Supports["request"])
print("setclipboard supported:", Compat.Supports["setclipboard"])

-- Check feature group disabling
print("\n=== Feature Group Disabling ===")
print("DrawingAPI disabled:", Compat.DisabledFeatures["DrawingAPI"] or false)
print("ConfigSaveLoad disabled:", Compat.DisabledFeatures["ConfigSaveLoad"] or false)
print("HTTP disabled:", Compat.DisabledFeatures["HTTP"] or false)
print("ClipboardCopy disabled:", Compat.DisabledFeatures["ClipboardCopy"] or false)

-- Test CanUseDrawing function
print("\n=== CanUseDrawing Test ===")
local canUseDrawing = Compat.CanUseDrawing()
print("CanUseDrawing result:", canUseDrawing)

-- Restore original functions
Drawing = originalDrawing
isfile = originalIsfile
request = originalRequest
setclipboard = originalSetclipboard

print("\n=== Restored Functions ===")
print("Restored original functions")

-- Run checks again to verify restoration
Compat:RunChecks({
    ShowUI = false,
    Silent = true,  -- Don't print again
})

print("After restoration:")
print("DrawingAPI disabled:", Compat.DisabledFeatures["DrawingAPI"] or false)
print("ConfigSaveLoad disabled:", Compat.DisabledFeatures["ConfigSaveLoad"] or false)
print("HTTP disabled:", Compat.DisabledFeatures["HTTP"] or false)
print("ClipboardCopy disabled:", Compat.DisabledFeatures["ClipboardCopy"] or false)

print("\n=== Feature Dependencies Test ===")
if Compat.FeatureDependencies then
    print("FeatureDependencies available")
    for group, deps in pairs(Compat.FeatureDependencies) do
        print(group .. " requires:", table.concat(deps, ", "))
    end
else
    print("FeatureDependencies not available")
end

print("\n=== UI Element Disabling Test ===")
print("Note: This test simulates missing functions but cannot test actual UI creation")
print("In a real scenario, UI elements would be automatically disabled based on Compat.DisabledFeatures")

-- Test the helper function logic
local function isFeatureDisabled(featureName)
    if not Compat or not Compat.DisabledFeatures then return false end
    return Compat.DisabledFeatures[featureName] == true
end

print("ESP features should be disabled:", isFeatureDisabled('DrawingAPI'))
print("Config features should be disabled:", isFeatureDisabled('ConfigSaveLoad'))
print("Discord button should be disabled:", (isFeatureDisabled('HTTP') and isFeatureDisabled('ClipboardCopy')))

print("\n=== Expected UI Behavior ===")
print("- ESP toggles should appear dimmed and show '(disabled)' in their text")
print("- Config save/load buttons should appear dimmed")
print("- Discord button should appear dimmed if both HTTP and clipboard are unavailable")
print("- Clicking disabled buttons should show 'This feature is disabled by your executor'")

print("\nExecutorCompat feature disabling test completed!")
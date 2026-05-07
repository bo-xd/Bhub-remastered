-- Test script for NormalUILib.lua
-- This script tests the basic functionality of the Normal UI Library

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bo-xd/Bhub-remastered/refs/heads/main/src/util/ui/NormalUILib.lua"))()

-- Test 1: Create a window
local Window = Library:CreateWindow({
    Title = "Test Window",
    Center = true,
    AutoShow = true,
})

-- Test 2: Add a tab
local Tab = Window:AddTab("Test Tab")

-- Test 3: Add a group
local Group = Tab:AddLeftGroupbox("Test Group")

-- Test 4: Add various elements
Group:AddLabel("This is a label")
Group:AddButton("Test Button", function()
    print("Button clicked!")
end)
Group:AddToggle("Test Toggle", {Text = "Toggle me", Default = false, Callback = function(v)
    print("Toggle changed to:", v)
end})
Group:AddSlider("Test Slider", {Text = "Slide me", Min = 0, Max = 100, Default = 50, Rounding = 0, Callback = function(v)
    print("Slider value:", v)
end})
Group:AddDropdown("Test Dropdown", {Values = {"Option 1", "Option 2", "Option 3"}, Default = 1, Multi = false, Text = "Select option", Callback = function(v)
    print("Dropdown selected:", v)
end})

-- Test 5: Test themes
print("Available themes:", table.concat(Library:GetThemeNames(), ", "))
Library:SetTheme("Neon")

-- Test 6: Test notifications
Library:Notify("Test notification!", 3)

-- Test 7: Test config save/load (if file IO is supported)
if pcall(function() return isfile end) then
    Library:SaveConfig("test_config")
    wait(1)
    Library:LoadConfig("test_config")
    print("Config test passed")
else
    print("File IO not supported, skipping config test")
end

print("NormalUILib test completed!")
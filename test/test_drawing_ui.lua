local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bo-xd/Bhub-remastered/refs/heads/main/src/util/ui/DrawingUILib.lua"))()

-- Test 1: Create a window
local Window = Library:CreateWindow({
    Title = "Test Drawing Window",
    Center = true,
    AutoShow = true,
})

-- Test 2: Add a tab
local Tab = Window:AddTab("Test Tab")

-- Test 3: Add a group
local Group = Tab:AddLeftGroupbox("Test Group")

-- Test 4: Add various elements
Group:AddLabel("This is a drawing label")
Group:AddButton("Test Button", function()
    print("Drawing button clicked!")
end)
Group:AddToggle("Test Toggle", {Text = "Toggle me", Default = false, Callback = function(v)
    print("Drawing toggle changed to:", v)
end})
Group:AddSlider("Test Slider", {Text = "Slide me", Min = 0, Max = 100, Default = 50, Rounding = 0, Callback = function(v)
    print("Drawing slider value:", v)
end})
Group:AddDropdown("Test Dropdown", {Values = {"Option 1", "Option 2", "Option 3"}, Default = 1, Multi = false, Text = "Select option", Callback = function(v)
    print("Drawing dropdown selected:", v)
end})

-- Test 5: Test themes
print("Available themes:", table.concat(Library:GetThemeNames(), ", "))
Library:SetTheme("Ocean")

-- Test 6: Test notifications
Library:Notify("Test drawing notification!", 3)

-- Test 7: Test loader
local Loader = Library:CreateLoader({
    Title = "Test Loader",
    Theme = "Default",
})
Loader:SetStage("Loading...", 0.5)
wait(2)
Loader:Close()

print("DrawingUILib test completed!")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Library = {}
Library.Drawings = {}
Library.Connections = {}

local function create(class, props)
    local obj = Drawing.new(class)
    for i, v in pairs(props) do obj[i] = v end
    table.insert(Library.Drawings, obj)
    return obj
end

local function connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Library.Connections, conn)
    return conn
end

local function isMouseOver(pos, size)
    local mLoc = UserInputService:GetMouseLocation()
    return mLoc.X >= pos.X and mLoc.X <= (pos.X + size.X) and mLoc.Y >= pos.Y and mLoc.Y <= (pos.Y + size.Y)
end

function Library:CreateWindow(options)
    local title = options.Title or "Custom Hub"
    local Window = {
        Position = Vector2.new(100, 100),
        Size = Vector2.new(350, 30),
        Tabs = {},
        ActiveTab = nil,
        Dragging = false,
        DragOffset = Vector2.new(0,0),
        Items = {}
    }
    
    local MainFrame = create("Square", { Position = Window.Position, Size = Window.Size, Color = Color3.fromRGB(25, 25, 25), Filled = true, Visible = true, ZIndex = 1 })
    local TopBar = create("Square", { Position = Window.Position, Size = Vector2.new(Window.Size.X, 30), Color = Color3.fromRGB(35, 35, 35), Filled = true, Visible = true, ZIndex = 2 })
    local AccentLine = create("Square", { Position = Window.Position + Vector2.new(0, 30), Size = Vector2.new(Window.Size.X, 2), Color = Color3.fromRGB(0, 150, 255), Filled = true, Visible = true, ZIndex = 3 })
    local Title = create("Text", { Position = Window.Position + Vector2.new(10, 6), Text = title, Size = 16, Color = Color3.fromRGB(255, 255, 255), Outline = true, Visible = true, ZIndex = 3, Font = 2 })
    
    local function UpdateLayout()
        local y = 32
        local tabX = 10
        for _, tabBtn in ipairs(Window.Items) do
            tabBtn:UpdatePosition(Window.Position + Vector2.new(tabX, y))
            tabX = tabX + tabBtn.Width + 10
        end
        if #Window.Items > 0 then y = y + 25 end
        
        if Window.ActiveTab then
            for _, item in ipairs(Window.ActiveTab.Items) do
                item:UpdatePosition(Window.Position + Vector2.new(0, y))
                y = y + item.Height
            end
        end
        MainFrame.Size = Vector2.new(Window.Size.X, math.max(y + 10, 80))
    end
    
    connect(UserInputService.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if isMouseOver(TopBar.Position, TopBar.Size) then
                Window.Dragging = true
                Window.DragOffset = UserInputService:GetMouseLocation() - Window.Position
            end
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Window.Dragging = false end
    end)
    connect(RunService.RenderStepped, function()
        if Window.Dragging then
            Window.Position = UserInputService:GetMouseLocation() - Window.DragOffset
            TopBar.Position = Window.Position
            AccentLine.Position = Window.Position + Vector2.new(0, 30)
            MainFrame.Position = Window.Position
            Title.Position = Window.Position + Vector2.new(10, 6)
            UpdateLayout()
        end
    end)
    
    function Window:AddTab(name)
        local Tab = { Name = name, Items = {} }
        table.insert(self.Tabs, Tab)
        
        local tabBtn = { Width = string.len(name) * 7 + 10 }
        local Label = create("Text", { Text = name, Size = 14, Color = Color3.fromRGB(150, 150, 150), Outline = true, Visible = true, ZIndex = 3, Font = 2 })
        local currentPos = Vector2.new(0,0)
        
        function tabBtn:UpdatePosition(pos)
            currentPos = pos
            Label.Position = pos + Vector2.new(5, 4)
            Label.Color = (Window.ActiveTab == Tab) and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(150, 150, 150)
        end
        
        connect(UserInputService.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and isMouseOver(currentPos, Vector2.new(tabBtn.Width, 25)) then
                if Window.ActiveTab then
                    for _, item in ipairs(Window.ActiveTab.Items) do item:SetVisible(false) end
                end
                Window.ActiveTab = Tab
                for _, item in ipairs(Window.ActiveTab.Items) do item:SetVisible(true) end
                UpdateLayout()
            end
        end)
        
        table.insert(self.Items, tabBtn)
        if not Window.ActiveTab then Window.ActiveTab = Tab end
        
        function Tab:AddLeftGroupbox(gbName) return self end
        function Tab:AddRightGroupbox(gbName) return self end
        
        function Tab:AddToggle(id, options)
            local Toggle = { Height = 25, State = options.Default or false }
            local text = options.Text or id
            local Label = create("Text", { Text = text, Size = 13, Color = Color3.fromRGB(220, 220, 220), Outline = true, Visible = Window.ActiveTab == Tab, ZIndex = 3, Font = 2 })
            local Box = create("Square", { Size = Vector2.new(14, 14), Color = Toggle.State and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 50), Filled = true, Visible = Window.ActiveTab == Tab, ZIndex = 3 })
            local currentPos = Vector2.new(0,0)
            
            function Toggle:SetVisible(v) Label.Visible = v; Box.Visible = v end
            function Toggle:UpdatePosition(pos)
                currentPos = pos
                Label.Position = pos + Vector2.new(15, 4)
                Box.Position = pos + Vector2.new(Window.Size.X - 25, 5)
            end
            
            connect(UserInputService.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and Window.ActiveTab == Tab then
                    if isMouseOver(currentPos, Vector2.new(Window.Size.X, Toggle.Height)) then
                        Toggle.State = not Toggle.State
                        Box.Color = Toggle.State and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 50)
                        if options.Callback then options.Callback(Toggle.State) end
                    end
                end
            end)
            
            function Toggle:AddColorPicker(...) return { OnChanged = function() end } end
            
            table.insert(Tab.Items, Toggle)
            if options.Callback then task.spawn(options.Callback, Toggle.State) end
            return Toggle
        end
        
        function Tab:AddButton(options)
            local text = type(options) == "table" and options.Text or options
            local callback = type(options) == "table" and options.Func or function() end
            local Button = { Height = 30 }
            
            local BtnBg = create("Square", { Size = Vector2.new(Window.Size.X - 30, 22), Color = Color3.fromRGB(50, 50, 50), Filled = true, Visible = Window.ActiveTab == Tab, ZIndex = 3 })
            local Label = create("Text", { Text = text, Size = 13, Color = Color3.fromRGB(255, 255, 255), Outline = true, Center = true, Visible = Window.ActiveTab == Tab, ZIndex = 4, Font = 2 })
            
            function Button:SetVisible(v) BtnBg.Visible = v; Label.Visible = v end
            function Button:UpdatePosition(pos)
                BtnBg.Position = pos + Vector2.new(15, 4)
                Label.Position = pos + Vector2.new(Window.Size.X / 2, 7)
            end
            
            connect(UserInputService.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and Window.ActiveTab == Tab then
                    if isMouseOver(BtnBg.Position, BtnBg.Size) then
                        BtnBg.Color = Color3.fromRGB(0, 150, 255)
                        if callback then callback() end
                        task.delay(0.1, function() BtnBg.Color = Color3.fromRGB(50, 50, 50) end)
                    end
                end
            end)
            
            table.insert(Tab.Items, Button)
            return Button
        end
        
        function Tab:AddSlider(id, options)
            local text = options.Text or id
            local min = options.Min or 0
            local max = options.Max or 100
            local Slider = { Height = 40, Value = options.Default or min }
            
            local Label = create("Text", { Text = text .. ": " .. tostring(Slider.Value), Size = 13, Color = Color3.fromRGB(220, 220, 220), Outline = true, Visible = Window.ActiveTab == Tab, ZIndex = 3, Font = 2 })
            local SliderBg = create("Square", { Size = Vector2.new(Window.Size.X - 30, 8), Color = Color3.fromRGB(40, 40, 40), Filled = true, Visible = Window.ActiveTab == Tab, ZIndex = 3 })
            local SliderFill = create("Square", { Size = Vector2.new(((Slider.Value - min) / (max - min)) * (Window.Size.X - 30), 8), Color = Color3.fromRGB(0, 150, 255), Filled = true, Visible = Window.ActiveTab == Tab, ZIndex = 4 })
            
            function Slider:SetVisible(v) Label.Visible = v; SliderBg.Visible = v; SliderFill.Visible = v end
            function Slider:UpdatePosition(pos)
                Label.Position = pos + Vector2.new(15, 2)
                SliderBg.Position = pos + Vector2.new(15, 20)
                SliderFill.Position = pos + Vector2.new(15, 20)
            end
            
            local Dragging = false
            local function updateVal()
                if Dragging and Window.ActiveTab == Tab then
                    local pct = math.clamp((UserInputService:GetMouseLocation().X - SliderBg.Position.X) / SliderBg.Size.X, 0, 1)
                    Slider.Value = min + ((max - min) * pct)
                    if options.Rounding and options.Rounding == 0 then Slider.Value = math.floor(Slider.Value) end
                    SliderFill.Size = Vector2.new(pct * SliderBg.Size.X, 8)
                    Label.Text = text .. ": " .. tostring(math.floor(Slider.Value*10)/10)
                    if options.Callback then options.Callback(Slider.Value) end
                end
            end
            
            connect(UserInputService.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and Window.ActiveTab == Tab then
                    if isMouseOver(SliderBg.Position, SliderBg.Size) then Dragging = true; updateVal() end
                end
            end)
            connect(UserInputService.InputEnded, function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end end)
            connect(RunService.RenderStepped, updateVal)
            
            table.insert(Tab.Items, Slider)
            if options.Callback then task.spawn(options.Callback, Slider.Value) end
            return Slider
        end
        
        function Tab:AddLabel(text)
            local LabelItem = { Height = 25 }
            local Label = create("Text", { Text = text, Size = 13, Color = Color3.fromRGB(200, 200, 200), Outline = true, Visible = Window.ActiveTab == Tab, ZIndex = 3, Font = 2 })
            
            function LabelItem:SetVisible(v) Label.Visible = v end
            function LabelItem:UpdatePosition(pos) Label.Position = pos + Vector2.new(15, 4) end
            function LabelItem:SetText(t) Label.Text = t end
            function LabelItem:AddKeyPicker(...) return { OnChanged = function() end } end
            
            table.insert(Tab.Items, LabelItem)
            return LabelItem
        end
        
        function Tab:AddDropdown(id, options)
            local Dropdown = { Height = 45, Values = options.Values or {}, Value = options.Default, Multi = options.Multi }
            local text = options.Text or id
            
            local Label = create("Text", { Text = text, Size = 13, Color = Color3.fromRGB(220, 220, 220), Outline = true, Visible = Window.ActiveTab == Tab, ZIndex = 3, Font = 2 })
            local BtnBg = create("Square", { Size = Vector2.new(Window.Size.X - 30, 22), Color = Color3.fromRGB(50, 50, 50), Filled = true, Visible = Window.ActiveTab == Tab, ZIndex = 3 })
            
            local function getDisplay()
                if Dropdown.Multi then
                    local s = ""
                    for k,v in pairs(Dropdown.Value or {}) do if v then s = s .. tostring(k) .. ", " end end
                    return s == "" and "None" or s:sub(1, -3)
                else
                    return tostring(Dropdown.Value)
                end
            end
            
            local ValLabel = create("Text", { Text = getDisplay(), Size = 12, Color = Color3.fromRGB(255, 255, 255), Outline = true, Center = true, Visible = Window.ActiveTab == Tab, ZIndex = 4, Font = 2 })
            
            function Dropdown:SetVisible(v) Label.Visible = v; BtnBg.Visible = v; ValLabel.Visible = v end
            function Dropdown:UpdatePosition(pos)
                Label.Position = pos + Vector2.new(15, 2)
                BtnBg.Position = pos + Vector2.new(15, 20)
                ValLabel.Position = pos + Vector2.new(Window.Size.X / 2, 23)
            end
            
            function Dropdown:SetValues(vals) 
                Dropdown.Values = vals 
                if not Dropdown.Multi then Dropdown.Value = vals[1] end
                ValLabel.Text = getDisplay()
            end
            
            connect(UserInputService.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and Window.ActiveTab == Tab then
                    if isMouseOver(BtnBg.Position, BtnBg.Size) then
                        if not Dropdown.Multi then
                            local idx = table.find(Dropdown.Values, Dropdown.Value) or 0
                            idx = (idx % #Dropdown.Values) + 1
                            Dropdown.Value = Dropdown.Values[idx]
                        else
                            local keys = Dropdown.Values
                            -- Find first enabled key to toggle to the next
                            local currentKey = nil
                            for k,v in pairs(Dropdown.Value or {}) do if v then currentKey = k; break end end
                            local idx = table.find(keys, currentKey) or 0
                            idx = (idx % #keys) + 1
                            Dropdown.Value = { [keys[idx]] = true }
                        end
                        ValLabel.Text = getDisplay()
                        if options.Callback then options.Callback(Dropdown.Value) end
                    end
                end
            end)
            
            table.insert(Tab.Items, Dropdown)
            if options.Callback then task.spawn(options.Callback, Dropdown.Value) end
            return Dropdown
        end
        
        UpdateLayout()
        return Tab
    end
    
    return Window
end

function Library:Notify(text) print("[BHub Notify]", text) end
function Library:Unload()
    for _, conn in ipairs(Library.Connections) do conn:Disconnect() end
    for _, obj in ipairs(Library.Drawings) do if obj and obj.Remove then obj:Remove() end end
    Library.Connections = {}
    Library.Drawings = {}
end

return Library

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.ConfigData = {}
Library.ThemeUpdaters = {}
Library.CurrentThemeName = "Default"
Library.AccentOverride = nil
Library.RootGui = nil
Library._windows = {}
Library._notifyHolder = nil

Library.Themes = {
    Default = {
        Bg=Color3.fromRGB(14,14,21), Bar=Color3.fromRGB(20,20,32), Accent=Color3.fromRGB(98,62,255),
        GroupBg=Color3.fromRGB(19,19,29), GroupBorder=Color3.fromRGB(38,38,58), GroupHead=Color3.fromRGB(25,25,38),
        TabOn=Color3.fromRGB(98,62,255), TabOff=Color3.fromRGB(125,125,155), Text=Color3.fromRGB(232,232,245),
        Dim=Color3.fromRGB(148,148,175), TogOn=Color3.fromRGB(98,62,255), TogOff=Color3.fromRGB(38,38,58),
        Thumb=Color3.fromRGB(230,230,248), Btn=Color3.fromRGB(30,30,46), Sep=Color3.fromRGB(32,32,50),
        SlidBg=Color3.fromRGB(26,26,42), DropBg=Color3.fromRGB(18,18,28), DropItem=Color3.fromRGB(26,26,40),
        DropHover=Color3.fromRGB(42,42,65), DropSel=Color3.fromRGB(72,44,200)
    },
    Neon = {
        Bg=Color3.fromRGB(8,10,18), Bar=Color3.fromRGB(12,16,28), Accent=Color3.fromRGB(0,255,209),
        GroupBg=Color3.fromRGB(12,16,28), GroupBorder=Color3.fromRGB(26,38,56), GroupHead=Color3.fromRGB(15,22,38),
        TabOn=Color3.fromRGB(0,255,209), TabOff=Color3.fromRGB(118,142,170), Text=Color3.fromRGB(232,245,255),
        Dim=Color3.fromRGB(141,172,196), TogOn=Color3.fromRGB(0,255,209), TogOff=Color3.fromRGB(20,34,44),
        Thumb=Color3.fromRGB(245,250,255), Btn=Color3.fromRGB(18,28,42), Sep=Color3.fromRGB(22,34,52),
        SlidBg=Color3.fromRGB(14,22,34), DropBg=Color3.fromRGB(9,12,20), DropItem=Color3.fromRGB(14,22,34),
        DropHover=Color3.fromRGB(24,40,62), DropSel=Color3.fromRGB(0,170,255)
    },
    Sunset = {
        Bg=Color3.fromRGB(22,12,16), Bar=Color3.fromRGB(34,18,22), Accent=Color3.fromRGB(255,128,72),
        GroupBg=Color3.fromRGB(30,16,20), GroupBorder=Color3.fromRGB(62,32,38), GroupHead=Color3.fromRGB(42,22,28),
        TabOn=Color3.fromRGB(255,128,72), TabOff=Color3.fromRGB(180,140,144), Text=Color3.fromRGB(255,239,232),
        Dim=Color3.fromRGB(194,160,154), TogOn=Color3.fromRGB(255,128,72), TogOff=Color3.fromRGB(58,30,34),
        Thumb=Color3.fromRGB(255,246,240), Btn=Color3.fromRGB(46,24,28), Sep=Color3.fromRGB(56,30,34),
        SlidBg=Color3.fromRGB(32,18,22), DropBg=Color3.fromRGB(18,10,14), DropItem=Color3.fromRGB(30,16,20),
        DropHover=Color3.fromRGB(66,34,40), DropSel=Color3.fromRGB(255,94,58)
    },
    Ocean = {
        Bg=Color3.fromRGB(9,16,22), Bar=Color3.fromRGB(14,24,34), Accent=Color3.fromRGB(64,196,255),
        GroupBg=Color3.fromRGB(14,24,34), GroupBorder=Color3.fromRGB(28,44,58), GroupHead=Color3.fromRGB(18,30,42),
        TabOn=Color3.fromRGB(64,196,255), TabOff=Color3.fromRGB(120,154,176), Text=Color3.fromRGB(232,248,255),
        Dim=Color3.fromRGB(148,182,198), TogOn=Color3.fromRGB(64,196,255), TogOff=Color3.fromRGB(22,40,52),
        Thumb=Color3.fromRGB(245,252,255), Btn=Color3.fromRGB(20,34,46), Sep=Color3.fromRGB(24,40,54),
        SlidBg=Color3.fromRGB(14,26,36), DropBg=Color3.fromRGB(10,18,26), DropItem=Color3.fromRGB(16,28,40),
        DropHover=Color3.fromRGB(28,52,72), DropSel=Color3.fromRGB(32,150,220)
    },
    Voltage = {
        Bg=Color3.fromRGB(11,11,13), Bar=Color3.fromRGB(18,18,22), Accent=Color3.fromRGB(255,220,60),
        GroupBg=Color3.fromRGB(16,16,20), GroupBorder=Color3.fromRGB(40,40,48), GroupHead=Color3.fromRGB(22,22,28),
        TabOn=Color3.fromRGB(255,220,60), TabOff=Color3.fromRGB(150,150,160), Text=Color3.fromRGB(246,246,240),
        Dim=Color3.fromRGB(168,168,156), TogOn=Color3.fromRGB(255,220,60), TogOff=Color3.fromRGB(30,30,36),
        Thumb=Color3.fromRGB(255,255,255), Btn=Color3.fromRGB(28,28,34), Sep=Color3.fromRGB(34,34,42),
        SlidBg=Color3.fromRGB(22,22,28), DropBg=Color3.fromRGB(14,14,18), DropItem=Color3.fromRGB(22,22,28),
        DropHover=Color3.fromRGB(48,48,58), DropSel=Color3.fromRGB(200,170,42)
    },
    Dark = {
        Bg=Color3.fromRGB(12,12,16), Bar=Color3.fromRGB(17,17,24), Accent=Color3.fromRGB(0,140,255),
        GroupBg=Color3.fromRGB(17,17,23), GroupBorder=Color3.fromRGB(28,28,44), GroupHead=Color3.fromRGB(21,21,30),
        TabOn=Color3.fromRGB(0,140,255), TabOff=Color3.fromRGB(115,115,148), Text=Color3.fromRGB(228,228,242),
        Dim=Color3.fromRGB(140,140,168), TogOn=Color3.fromRGB(0,140,255), TogOff=Color3.fromRGB(28,28,46),
        Thumb=Color3.fromRGB(220,220,240), Btn=Color3.fromRGB(24,24,38), Sep=Color3.fromRGB(25,25,40),
        SlidBg=Color3.fromRGB(20,20,34), DropBg=Color3.fromRGB(14,14,22), DropItem=Color3.fromRGB(20,20,34),
        DropHover=Color3.fromRGB(34,34,54), DropSel=Color3.fromRGB(0,100,210)
    },
    Midnight = {
        Bg=Color3.fromRGB(10,10,18), Bar=Color3.fromRGB(15,14,26), Accent=Color3.fromRGB(210,45,115),
        GroupBg=Color3.fromRGB(15,14,26), GroupBorder=Color3.fromRGB(30,26,50), GroupHead=Color3.fromRGB(19,17,32),
        TabOn=Color3.fromRGB(210,45,115), TabOff=Color3.fromRGB(122,118,155), Text=Color3.fromRGB(235,234,248),
        Dim=Color3.fromRGB(150,144,180), TogOn=Color3.fromRGB(210,45,115), TogOff=Color3.fromRGB(30,26,50),
        Thumb=Color3.fromRGB(232,228,248), Btn=Color3.fromRGB(26,22,44), Sep=Color3.fromRGB(28,24,48),
        SlidBg=Color3.fromRGB(22,18,40), DropBg=Color3.fromRGB(14,12,22), DropItem=Color3.fromRGB(22,18,38),
        DropHover=Color3.fromRGB(40,30,60), DropSel=Color3.fromRGB(160,30,85)
    },
    Forest = {
        Bg=Color3.fromRGB(10,15,12), Bar=Color3.fromRGB(14,21,16), Accent=Color3.fromRGB(45,195,82),
        GroupBg=Color3.fromRGB(14,21,16), GroupBorder=Color3.fromRGB(22,36,26), GroupHead=Color3.fromRGB(17,27,20),
        TabOn=Color3.fromRGB(45,195,82), TabOff=Color3.fromRGB(112,140,118), Text=Color3.fromRGB(228,240,230),
        Dim=Color3.fromRGB(138,164,142), TogOn=Color3.fromRGB(45,195,82), TogOff=Color3.fromRGB(20,34,24),
        Thumb=Color3.fromRGB(220,236,224), Btn=Color3.fromRGB(16,28,20), Sep=Color3.fromRGB(18,30,22),
        SlidBg=Color3.fromRGB(12,24,16), DropBg=Color3.fromRGB(10,16,12), DropItem=Color3.fromRGB(14,24,18),
        DropHover=Color3.fromRGB(24,42,28), DropSel=Color3.fromRGB(28,140,55)
    }
}

local function T()
    local base = Library.Themes[Library.CurrentThemeName] or Library.Themes.Default
    if Library.AccentOverride then
        return setmetatable({ Accent = Library.AccentOverride }, { __index = base })
    end
    return base
end

local function th(fn)
    table.insert(Library.ThemeUpdaters, fn)
end

local function applyTheme()
    for _, fn in ipairs(Library.ThemeUpdaters) do
        pcall(fn)
    end
end

local getGuiParent
do
    local ok, compat = pcall(function() return (type(getgenv) == "function" and getgenv().BHub_Compat) or _G.BHub_Compat end)
    if ok and compat and type(compat.GetGuiParent) == "function" then
        getGuiParent = compat.GetGuiParent
    else
        getGuiParent = function()
            local ok, hui = pcall(function()
                if type(gethui) == "function" then
                    return gethui()
                end
            end)
            if ok and hui then
                return hui
            end
            if LocalPlayer then
                return LocalPlayer:WaitForChild("PlayerGui")
            end
            return game:GetService("CoreGui")
        end
    end
end

local function ensureRootGui()
    if Library.RootGui and Library.RootGui.Parent then
        return Library.RootGui
    end
    local parent = getGuiParent()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BHubRemasteredUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 500
    gui.Parent = parent
    Library.RootGui = gui

    local notifyHolder = Instance.new("Frame")
    notifyHolder.Name = "NotifyHolder"
    notifyHolder.Size = UDim2.new(0, 360, 1, -24)
    notifyHolder.Position = UDim2.new(1, -372, 0, 12)
    notifyHolder.BackgroundTransparency = 1
    notifyHolder.Parent = gui

    local notifyList = Instance.new("UIListLayout")
    notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifyList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifyList.SortOrder = Enum.SortOrder.LayoutOrder
    notifyList.Padding = UDim.new(0, 8)
    notifyList.Parent = notifyHolder

    Library._notifyHolder = notifyHolder
    return gui
end

local function showTip(anchor, text)
    ensureRootGui()
    if not Library._tooltip then
        local f = Instance.new("Frame", Library.RootGui)
        f.BackgroundColor3 = T().GroupBg
        f.BorderSizePixel = 0
        f.ZIndex = 999
        f.AutomaticSize = Enum.AutomaticSize.X
        f.Size = UDim2.new(0, 0, 0, 22)
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
        local stroke = Instance.new("UIStroke", f)
        stroke.Color = T().GroupBorder
        local pad = Instance.new("UIPadding", f)
        pad.PaddingLeft = UDim.new(0, 6)
        pad.PaddingRight = UDim.new(0, 6)
        local lbl = Instance.new("TextLabel", f)
        lbl.Name = "_tipLabel"
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.Size = UDim2.new(0, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextColor3 = T().Dim
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        Library._tooltip = f
        th(function()
            if f.Parent then
                f.BackgroundColor3 = T().GroupBg
                stroke.Color = T().GroupBorder
                lbl.TextColor3 = T().Dim
            end
        end)
    end
    Library._tooltip._tipLabel.Text = text
    local abs = anchor.AbsolutePosition
    Library._tooltip.Position = UDim2.fromOffset(math.max(abs.X, 0), math.max(abs.Y - 26, 0))
    Library._tooltip.Visible = true
end

local function hideTip()
    if Library._tooltip then Library._tooltip.Visible = false end
end

function Library:GetThemeNames()
    local names = {}
    for n in pairs(Library.Themes) do
        names[#names + 1] = n
    end
    table.sort(names)
    return names
end

function Library:SetTheme(name)
    if not Library.Themes[name] then
        return
    end
    Library.CurrentThemeName = name
    applyTheme()
end

function Library:SetAccentColor(color)
    Library.AccentOverride = color
    applyTheme()
end

function Library:ClearAccentColor()
    Library.AccentOverride = nil
    applyTheme()
end

function Library:_regCfg(id, getFn, setFn)
    if id and id ~= "" then
        Library.ConfigData[id] = { get = getFn, set = setFn }
    end
end

function Library:SaveConfig(name)
    name = name or "default"
    local data = {}
    for id, cfg in pairs(Library.ConfigData) do
        local ok, value = pcall(cfg.get)
        if ok then
            data[id] = value
        end
    end
    local okJson, json = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if not okJson then
        return false
    end
    pcall(function()
        if not isfolder then
            return
        end
        if not isfolder("BHub-remastered") then
            makefolder("BHub-remastered")
        end
        if not isfolder("BHub-remastered/configs") then
            makefolder("BHub-remastered/configs")
        end
        writefile("BHub-remastered/configs/" .. name .. ".json", json)
    end)
    return true
end

function Library:LoadConfig(name)
    name = name or "default"
    if not (isfile and readfile) then
        return false
    end
    local path = "BHub-remastered/configs/" .. name .. ".json"
    if not isfile(path) then
        return false
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(decoded) ~= "table" then
        return false
    end
    for id, value in pairs(decoded) do
        local cfg = Library.ConfigData[id]
        if cfg and cfg.set then
            pcall(cfg.set, value)
        end
    end
    return true
end

function Library:CreateLoader(opts)
    ensureRootGui()
    opts = opts or {}

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, math.clamp(opts.Width or 360, 300, 460), 0, 150)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = T().Bg
    frame.Parent = Library.RootGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = T().GroupBorder
    stroke.Parent = frame

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 2)
    accent.BackgroundColor3 = T().Accent
    accent.BorderSizePixel = 0
    accent.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 24)
    title.Position = UDim2.new(0, 12, 0, 12)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 18
    title.TextColor3 = T().Text
    title.Text = opts.Title or "BHub Remastered"
    title.Parent = frame

    local stage = Instance.new("TextLabel")
    stage.Size = UDim2.new(1, -24, 0, 20)
    stage.Position = UDim2.new(0, 12, 0, 42)
    stage.BackgroundTransparency = 1
    stage.TextXAlignment = Enum.TextXAlignment.Left
    stage.Font = Enum.Font.Gotham
    stage.TextSize = 13
    stage.TextColor3 = T().Dim
    stage.Text = opts.Subtitle or "Initializing"
    stage.Parent = frame

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -24, 0, 8)
    barBg.Position = UDim2.new(0, 12, 0, 100)
    barBg.BackgroundColor3 = T().SlidBg
    barBg.BorderSizePixel = 0
    barBg.Parent = frame

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 4)
    bgCorner.Parent = barBg

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 1, 1, 0)
    barFill.BackgroundColor3 = T().Accent
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = barFill

    local pct = Instance.new("TextLabel")
    pct.Size = UDim2.new(0, 48, 0, 18)
    pct.Position = UDim2.new(1, -58, 0, 74)
    pct.BackgroundTransparency = 1
    pct.TextXAlignment = Enum.TextXAlignment.Right
    pct.Font = Enum.Font.Gotham
    pct.TextSize = 12
    pct.TextColor3 = T().Dim
    pct.Text = "0%"
    pct.Parent = frame

    th(function()
        frame.BackgroundColor3 = T().Bg
        stroke.Color = T().GroupBorder
        accent.BackgroundColor3 = T().Accent
        title.TextColor3 = T().Text
        stage.TextColor3 = T().Dim
        barBg.BackgroundColor3 = T().SlidBg
        barFill.BackgroundColor3 = T().Accent
        pct.TextColor3 = T().Dim
    end)

    local loader = { Progress = 0, Stage = stage.Text }

    function loader:SetStage(text, progress)
        if text ~= nil then
            self.Stage = text
            stage.Text = text
        end
        if progress ~= nil then
            self.Progress = math.clamp(progress, 0, 1)
            barFill.Size = UDim2.new(self.Progress, 0, 1, 0)
            pct.Text = tostring(math.floor(self.Progress * 100)) .. "%"
        end
    end

    function loader:SetProgress(progress)
        self:SetStage(nil, progress)
    end

    function loader:Close()
        if frame and frame.Parent then
            frame:Destroy()
        end
    end

    return loader
end

function Library:Notify(text, duration, opts)
    ensureRootGui()
    duration = duration or 3
    opts = opts or {}

    local item = Instance.new("Frame")
    item.Size = UDim2.new(1, 0, 0, 34)
    item.BackgroundColor3 = T().GroupBg
    item.BorderSizePixel = 0
    item.Parent = Library._notifyHolder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = item

    local stroke = Instance.new("UIStroke")
    stroke.Color = T().GroupBorder
    stroke.Parent = item

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 2, 1, 0)
    accent.BackgroundColor3 = T().Accent
    accent.BorderSizePixel = 0
    accent.Parent = item

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 18, 1, 0)
    icon.Position = UDim2.new(0, 8, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = opts.Icon or "•"
    icon.Font = Enum.Font.GothamSemibold
    icon.TextSize = 14
    icon.TextColor3 = T().Accent
    icon.Parent = item

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -34, 1, 0)
    label.Position = UDim2.new(0, 26, 0, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = T().Text
    label.Text = tostring(text)
    label.Parent = item

    th(function()
        if item.Parent then
            item.BackgroundColor3 = T().GroupBg
            stroke.Color = T().GroupBorder
            accent.BackgroundColor3 = T().Accent
            icon.TextColor3 = T().Accent
            label.TextColor3 = T().Text
        end
    end)

    task.delay(duration, function()
        if item and item.Parent then
            item:Destroy()
        end
    end)
end

function Library:CreateCommandPalette(opts)
    ensureRootGui()
    opts = opts or {}

    local modal = Instance.new("Frame")
    modal.Size = UDim2.fromScale(1, 1)
    modal.BackgroundColor3 = Color3.new(0, 0, 0)
    modal.BackgroundTransparency = 0.45
    modal.Visible = false
    modal.Parent = Library.RootGui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, math.clamp(opts.Width or 420, 340, 540), 0, 240)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = T().Bg
    panel.Parent = modal

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 8)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = T().GroupBorder
    panelStroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 22)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 15
    title.TextColor3 = T().Text
    title.Text = opts.Title or "Command Palette"
    title.Parent = panel

    local query = Instance.new("TextBox")
    query.Size = UDim2.new(1, -20, 0, 30)
    query.Position = UDim2.new(0, 10, 0, 38)
    query.BackgroundColor3 = T().DropBg
    query.TextColor3 = T().Text
    query.PlaceholderText = "Type to search"
    query.PlaceholderColor3 = T().Dim
    query.Font = Enum.Font.Gotham
    query.TextSize = 13
    query.ClearTextOnFocus = false
    query.TextXAlignment = Enum.TextXAlignment.Left
    query.Parent = panel

    local queryCorner = Instance.new("UICorner")
    queryCorner.CornerRadius = UDim.new(0, 6)
    queryCorner.Parent = query

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -20, 1, -78)
    list.Position = UDim2.new(0, 10, 0, 72)
    list.BackgroundColor3 = T().GroupBg
    list.BorderSizePixel = 0
    list.CanvasSize = UDim2.new()
    list.ScrollBarThickness = 5
    list.Parent = panel

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = list

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = list

    local items = {}

    local function renderRows()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local q = string.lower(query.Text or "")
        local count = 0
        for _, item in ipairs(items) do
            local label = tostring(item.Text or "")
            if q == "" or string.find(string.lower(label), q, 1, true) then
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, -10, 0, 28)
                row.BackgroundColor3 = T().DropItem
                row.TextColor3 = T().Text
                row.Font = Enum.Font.Gotham
                row.TextSize = 13
                row.TextXAlignment = Enum.TextXAlignment.Left
                row.Text = "  " .. label
                row.AutoButtonColor = false
                row.Parent = list

                local rowCorner = Instance.new("UICorner")
                rowCorner.CornerRadius = UDim.new(0, 4)
                rowCorner.Parent = row

                row.MouseEnter:Connect(function()
                    row.BackgroundColor3 = T().DropHover
                end)
                row.MouseLeave:Connect(function()
                    row.BackgroundColor3 = T().DropItem
                end)
                row.Activated:Connect(function()
                    modal.Visible = false
                    if item.Callback then
                        pcall(item.Callback)
                    end
                end)

                count = count + 1
            end
        end

        list.CanvasSize = UDim2.new(0, 0, 0, count * 34)
    end

    query:GetPropertyChangedSignal("Text"):Connect(renderRows)

    modal.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
            modal.Visible = false
        end
    end)

    th(function()
        panel.BackgroundColor3 = T().Bg
        panelStroke.Color = T().GroupBorder
        title.TextColor3 = T().Text
        query.BackgroundColor3 = T().DropBg
        query.TextColor3 = T().Text
        query.PlaceholderColor3 = T().Dim
        list.BackgroundColor3 = T().GroupBg
    end)

    local api = {}

    function api:Open(newItems)
        items = newItems or {}
        query.Text = ""
        modal.Visible = true
        renderRows()
        query:CaptureFocus()
    end

    function api:Close()
        modal.Visible = false
    end

    function api:IsOpen()
        return modal.Visible
    end

    return api
end

local function keyNameFromCode(code)
    if not code then
        return "None"
    end
    local s = tostring(code)
    return s:match("KeyCode%.(.+)") or s:match("UserInputType%.(.+)") or s
end

function Library:CreateWindow(opts)
    ensureRootGui()
    opts = opts or {}

    local window = {
        Tabs = {},
        Active = nil,
        Visible = true,
        ShadowEnabled = true,
        ShadowTransparency = 0.35,
    }

    local shell = Instance.new("Frame")
    shell.Size = UDim2.new(0, 700, 0, 460)
    shell.Position = UDim2.fromScale(0.5, 0.5)
    shell.AnchorPoint = Vector2.new(0.5, 0.5)
    shell.BackgroundColor3 = T().Bg
    shell.Parent = Library.RootGui

    local shellCorner = Instance.new("UICorner")
    shellCorner.CornerRadius = UDim.new(0, 10)
    shellCorner.Parent = shell

    local shellStroke = Instance.new("UIStroke")
    shellStroke.Color = T().GroupBorder
    shellStroke.Parent = shell

    local topbar = Instance.new("Frame")
    topbar.Size = UDim2.new(1, 0, 0, 34)
    topbar.BackgroundColor3 = T().Bar
    topbar.BorderSizePixel = 0
    topbar.Parent = shell

    local topAccent = Instance.new("Frame")
    topAccent.Size = UDim2.new(1, 0, 0, 2)
    topAccent.Position = UDim2.new(0, 0, 0, 34)
    topAccent.BackgroundColor3 = T().Accent
    topAccent.BorderSizePixel = 0
    topAccent.Parent = shell

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 14
    title.TextColor3 = T().Text
    title.Text = opts.Title or "BHub"
    title.Parent = topbar

    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Size = UDim2.new(1, 0, 0, 28)
    tabBar.Position = UDim2.new(0, 0, 0, 36)
    tabBar.BackgroundColor3 = T().Bar
    tabBar.BorderSizePixel = 0
    tabBar.ScrollBarThickness = 0
    tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabBar.Parent = shell

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, -14, 1, -74)
    body.Position = UDim2.new(0, 7, 0, 67)
    body.BackgroundTransparency = 1
    body.Parent = shell

    local function makeGroupbox(tabObj, side, name)
        local widthScale = 0.5
        local colPadding = 6

        local parentCol = side == "left" and tabObj.LeftColumn or tabObj.RightColumn

        local box = Instance.new("Frame")
        box.Size = UDim2.new(1, 0, 0, 40)
        box.BackgroundColor3 = T().GroupBg
        box.BorderSizePixel = 0
        box.Parent = parentCol

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 7)
        boxCorner.Parent = box

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = T().GroupBorder
        boxStroke.Parent = box

        local head = Instance.new("Frame")
        head.Size = UDim2.new(1, 0, 0, 26)
        head.BackgroundColor3 = T().GroupHead
        head.BorderSizePixel = 0
        head.Parent = box

        local headCorner = Instance.new("UICorner")
        headCorner.CornerRadius = UDim.new(0, 7)
        headCorner.Parent = head

        local headFix = Instance.new("Frame")
        headFix.Size = UDim2.new(1, 0, 0, 8)
        headFix.Position = UDim2.new(0, 0, 1, -8)
        headFix.BackgroundColor3 = T().GroupHead
        headFix.BorderSizePixel = 0
        headFix.Parent = head

        local headLabel = Instance.new("TextLabel")
        headLabel.Size = UDim2.new(1, -16, 1, 0)
        headLabel.Position = UDim2.new(0, 10, 0, 0)
        headLabel.BackgroundTransparency = 1
        headLabel.TextXAlignment = Enum.TextXAlignment.Left
        headLabel.Font = Enum.Font.GothamSemibold
        headLabel.TextSize = 13
        headLabel.TextColor3 = T().Dim
        headLabel.Text = name
        headLabel.Parent = head

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, -12, 0, 1)
        content.Position = UDim2.new(0, 6, 0, 32)
        content.BackgroundTransparency = 1
        content.Parent = box

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Padding = UDim.new(0, 4)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Parent = content

        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.Size = UDim2.new(1, -12, 0, contentLayout.AbsoluteContentSize.Y)
            box.Size = UDim2.new(1, 0, 0, math.max(40, contentLayout.AbsoluteContentSize.Y + 40))
        end)

        th(function()
            box.BackgroundColor3 = T().GroupBg
            boxStroke.Color = T().GroupBorder
            head.BackgroundColor3 = T().GroupHead
            headFix.BackgroundColor3 = T().GroupHead
            headLabel.TextColor3 = T().Dim
        end)

        local Obj = {}

        local function mkRow(height)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, height)
            row.BackgroundTransparency = 1
            row.Parent = content
            return row
        end

        function Obj:AddToggle(id, o)
            o = o or {}
            local txt = o.Text or id
            local state = o.Default or false

            local row = mkRow(30)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = T().Text
            label.Text = txt
            label.Parent = row

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0, 38, 0, 20)
            button.Position = UDim2.new(1, -40, 0.5, -10)
            button.Text = ""
            button.BorderSizePixel = 0
            button.BackgroundColor3 = state and T().TogOn or T().TogOff
            button.Parent = row

            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 10)
            buttonCorner.Parent = button

            local thumb = Instance.new("Frame")
            thumb.Size = UDim2.new(0, 14, 0, 14)
            thumb.Position = state and UDim2.new(1, -16, 0, 3) or UDim2.new(0, 2, 0, 3)
            thumb.BackgroundColor3 = T().Thumb
            thumb.BorderSizePixel = 0
            thumb.Parent = button

            local thumbCorner = Instance.new("UICorner")
            thumbCorner.CornerRadius = UDim.new(0, 7)
            thumbCorner.Parent = thumb

            local Tog = { State = state }

            local function applyState(v, fire)
                state = not not v
                Tog.State = state
                button.BackgroundColor3 = state and T().TogOn or T().TogOff
                thumb.Position = state and UDim2.new(1, -16, 0, 3) or UDim2.new(0, 2, 0, 3)
                if fire and o.Callback then
                    o.Callback(state)
                end
            end

            button.Activated:Connect(function()
                applyState(not state, true)
            end)

            th(function()
                label.TextColor3 = T().Text
                button.BackgroundColor3 = state and T().TogOn or T().TogOff
                thumb.BackgroundColor3 = T().Thumb
            end)

            Library:_regCfg(id, function() return state end, function(v) applyState(v, true) end)
            if o.Callback then
                task.spawn(o.Callback, state)
            end

            function Tog:AddColorPicker(cpId, co)
                co = co or {}
                local pickerColor = co.Default or Color3.new(1, 1, 1)

                local swatch = Instance.new("TextButton")
                swatch.Size = UDim2.new(0, 18, 0, 18)
                swatch.Position = UDim2.new(1, -64, 0.5, -9)
                swatch.Text = ""
                swatch.AutoButtonColor = false
                swatch.BorderSizePixel = 0
                swatch.BackgroundColor3 = pickerColor
                swatch.Parent = row

                local swCorner = Instance.new("UICorner")
                swCorner.CornerRadius = UDim.new(0, 4)
                swCorner.Parent = swatch

                local popup = Instance.new("Frame")
                popup.Size = UDim2.new(0, 176, 0, 84)
                popup.Position = UDim2.new(1, -178, 1, 2)
                popup.BackgroundColor3 = T().DropBg
                popup.BorderSizePixel = 0
                popup.Visible = false
                popup.Parent = row

                local popCorner = Instance.new("UICorner")
                popCorner.CornerRadius = UDim.new(0, 6)
                popCorner.Parent = popup

                local popStroke = Instance.new("UIStroke")
                popStroke.Color = T().GroupBorder
                popStroke.Parent = popup

                local presets = {
                    Color3.fromRGB(255,255,255), Color3.fromRGB(255,80,80), Color3.fromRGB(255,170,60),
                    Color3.fromRGB(255,220,60), Color3.fromRGB(80,220,120), Color3.fromRGB(80,180,255),
                    Color3.fromRGB(170,100,255), Color3.fromRGB(255,90,180), Color3.fromRGB(0,255,209),
                    Color3.fromRGB(255,120,72)
                }

                for idx, c in ipairs(presets) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(0, 28, 0, 28)
                    local col = (idx - 1) % 5
                    local rowIdx = math.floor((idx - 1) / 5)
                    b.Position = UDim2.new(0, 8 + col * 32, 0, 8 + rowIdx * 32)
                    b.Text = ""
                    b.BorderSizePixel = 0
                    b.BackgroundColor3 = c
                    b.Parent = popup

                    local bCorner = Instance.new("UICorner")
                    bCorner.CornerRadius = UDim.new(0, 5)
                    bCorner.Parent = b

                    b.Activated:Connect(function()
                        pickerColor = c
                        swatch.BackgroundColor3 = pickerColor
                        popup.Visible = false
                        if co.Callback then
                            co.Callback(pickerColor)
                        end
                    end)
                end

                swatch.Activated:Connect(function()
                    popup.Visible = not popup.Visible
                end)

                Library:_regCfg(cpId or (id .. "Color"), function() return pickerColor end, function(v)
                    if typeof(v) == "Color3" then
                        pickerColor = v
                        swatch.BackgroundColor3 = v
                        if co.Callback then
                            co.Callback(v)
                        end
                    end
                end)

                if co.Callback then
                    task.spawn(co.Callback, pickerColor)
                end

                th(function()
                    popup.BackgroundColor3 = T().DropBg
                    popStroke.Color = T().GroupBorder
                end)

                return {
                    Value = pickerColor,
                    SetValue = function(v)
                        if typeof(v) == "Color3" then
                            pickerColor = v
                            swatch.BackgroundColor3 = v
                            if co.Callback then
                                co.Callback(v)
                            end
                        end
                    end,
                    OnChanged = function() end,
                }
            end

            function Tog:AddKeyPicker(kid, ko)
                ko = ko or {}
                local key = ko.Default and Enum.KeyCode[ko.Default] or Enum.KeyCode.Delete

                local bindBtn = Instance.new("TextButton")
                bindBtn.Size = UDim2.new(0, 62, 0, 18)
                bindBtn.Position = UDim2.new(1, -132, 0.5, -9)
                bindBtn.Text = keyNameFromCode(key)
                bindBtn.Font = Enum.Font.Gotham
                bindBtn.TextSize = 12
                bindBtn.TextColor3 = T().Text
                bindBtn.BackgroundColor3 = T().Btn
                bindBtn.BorderSizePixel = 0
                bindBtn.Parent = row

                local kbCorner = Instance.new("UICorner")
                kbCorner.CornerRadius = UDim.new(0, 4)
                kbCorner.Parent = bindBtn

                local listening = false
                bindBtn.Activated:Connect(function()
                    listening = true
                    bindBtn.Text = "..."
                    bindBtn.BackgroundColor3 = T().Accent
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then
                        return
                    end
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode ~= Enum.KeyCode.Escape then
                            key = input.KeyCode
                            if ko.Callback then
                                ko.Callback(key)
                            end
                        end
                        listening = false
                        bindBtn.Text = keyNameFromCode(key)
                        bindBtn.BackgroundColor3 = T().Btn
                        return
                    end
                    if input.KeyCode == key and ko.OnKey then
                        ko.OnKey()
                    end
                end)

                Library:_regCfg(kid, function() return tostring(key) end, function(v)
                    local parsed = Enum.KeyCode[v]
                    if parsed then
                        key = parsed
                        bindBtn.Text = keyNameFromCode(key)
                    end
                end)

                return { OnChanged = function() end }
            end

            return Tog
        end

        function Obj:AddButton(o)
            local txt = type(o) == "table" and o.Text or tostring(o)
            local fn = type(o) == "table" and o.Func or function() end
            local disabled = type(o) == "table" and o.Disabled or false
            local row = mkRow(32)

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 24)
            btn.Position = UDim2.new(0, 4, 0, 4)
            btn.Text = txt
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.TextColor3 = disabled and T().Dim or T().Text
            btn.BackgroundColor3 = disabled and T().GroupBg or T().Btn
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = not disabled
            btn.Parent = row

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = btn

            if disabled then
                btn.MouseEnter:Connect(function() showTip(btn, "Incompatible") end)
                btn.MouseLeave:Connect(hideTip)
            end

            btn.Activated:Connect(function()
                if disabled then return end
                btn.BackgroundColor3 = T().Accent
                pcall(fn)
                task.delay(0.1, function()
                    if btn.Parent then
                        btn.BackgroundColor3 = T().Btn
                    end
                end)
            end)

            th(function()
                if disabled then
                    btn.TextColor3 = T().Dim
                    btn.BackgroundColor3 = T().GroupBg
                else
                    btn.TextColor3 = T().Text
                    btn.BackgroundColor3 = T().Btn
                end
            end)

            return {}
        end

        function Obj:AddSlider(id, o)
            o = o or {}
            local txt = o.Text or id
            local mn = o.Min or 0
            local mx = o.Max or 100
            local value = o.Default or mn

            local row = mkRow(50)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -8, 0, 18)
            label.Position = UDim2.new(0, 4, 0, 2)
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = T().Text
            label.Parent = row

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, -8, 0, 8)
            bar.Position = UDim2.new(0, 4, 0, 30)
            bar.BackgroundColor3 = T().SlidBg
            bar.BorderSizePixel = 0
            bar.Parent = row

            local barCorner = Instance.new("UICorner")
            barCorner.CornerRadius = UDim.new(0, 4)
            barCorner.Parent = bar

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(0, 1, 1, 0)
            fill.BackgroundColor3 = T().Accent
            fill.BorderSizePixel = 0
            fill.Parent = bar

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 4)
            fillCorner.Parent = fill

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 12, 0, 12)
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new(0, 0, 0.5, 0)
            knob.BackgroundColor3 = T().Thumb
            knob.BorderSizePixel = 0
            knob.Parent = bar

            local knobCorner = Instance.new("UICorner")
            knobCorner.CornerRadius = UDim.new(0, 6)
            knobCorner.Parent = knob

            local dragging = false

            local function refresh(fire)
                local pct = math.clamp((value - mn) / math.max(1e-6, (mx - mn)), 0, 1)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                knob.Position = UDim2.new(pct, 0, 0.5, 0)
                label.Text = txt .. ": " .. tostring(math.floor(value * 100) / 100)
                if fire and o.Callback then
                    o.Callback(value)
                end
            end

            local function setFromMouse()
                local mouseX = UserInputService:GetMouseLocation().X
                local pct = math.clamp((mouseX - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
                value = mn + (mx - mn) * pct
                if o.Rounding == 0 then
                    value = math.floor(value)
                end
                refresh(true)
            end

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    setFromMouse()
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromMouse()
                end
            end)

            th(function()
                label.TextColor3 = T().Text
                bar.BackgroundColor3 = T().SlidBg
                fill.BackgroundColor3 = T().Accent
                knob.BackgroundColor3 = T().Thumb
            end)

            local api = { Value = value }
            function api:SetValue(v)
                value = math.clamp(tonumber(v) or value, mn, mx)
                api.Value = value
                refresh(true)
            end

            Library:_regCfg(id, function() return value end, function(v) api:SetValue(v) end)
            refresh(false)
            if o.Callback then
                task.spawn(o.Callback, value)
            end
            return api
        end

        function Obj:AddDropdown(id, o)
            o = o or {}
            local txt = o.Text or id
            local vals = o.Values or {}
            local multi = o.Multi
            local value = o.Default
            if not multi and value == nil then
                value = vals[1]
            end

            local row = mkRow(54)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -8, 0, 18)
            label.Position = UDim2.new(0, 4, 0, 2)
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = T().Text
            label.Text = txt
            label.Parent = row

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 24)
            btn.Position = UDim2.new(0, 4, 0, 24)
            btn.Text = ""
            btn.BackgroundColor3 = T().Btn
            btn.BorderSizePixel = 0
            btn.Parent = row

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn

            local valText = Instance.new("TextLabel")
            valText.Size = UDim2.new(1, -26, 1, 0)
            valText.Position = UDim2.new(0, 8, 0, 0)
            valText.BackgroundTransparency = 1
            valText.TextXAlignment = Enum.TextXAlignment.Left
            valText.Font = Enum.Font.Gotham
            valText.TextSize = 13
            valText.TextColor3 = T().Text
            valText.Parent = btn

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Position = UDim2.new(1, -20, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▾"
            arrow.Font = Enum.Font.Gotham
            arrow.TextSize = 13
            arrow.TextColor3 = T().Dim
            arrow.Parent = btn

            local list = Instance.new("ScrollingFrame")
            list.Size = UDim2.new(1, -8, 0, 0)
            list.Position = UDim2.new(0, 4, 1, 2)
            list.BackgroundColor3 = T().DropBg
            list.BorderSizePixel = 0
            list.Visible = false
            list.ScrollBarThickness = 4
            list.Parent = row

            local listCorner = Instance.new("UICorner")
            listCorner.CornerRadius = UDim.new(0, 4)
            listCorner.Parent = list

            local listStroke = Instance.new("UIStroke")
            listStroke.Color = T().GroupBorder
            listStroke.Parent = list

            local listLayout = Instance.new("UIListLayout")
            listLayout.Padding = UDim.new(0, 2)
            listLayout.Parent = list

            local open = false

            local function display()
                if multi then
                    local picked = {}
                    for k, v in pairs(value or {}) do
                        if v then
                            picked[#picked + 1] = tostring(k)
                        end
                    end
                    table.sort(picked)
                    if #picked == 0 then
                        return "None"
                    end
                    if #picked <= 2 then
                        return table.concat(picked, ", ")
                    end
                    return picked[1] .. ", " .. picked[2] .. " +" .. tostring(#picked - 2)
                end
                return tostring(value or "None")
            end

            local function rebuildList()
                for _, c in ipairs(list:GetChildren()) do
                    if c:IsA("TextButton") then
                        c:Destroy()
                    end
                end

                for _, item in ipairs(vals) do
                    local isSel = multi and (type(value) == "table" and value[item] == true) or (value == item)
                    local rowBtn = Instance.new("TextButton")
                    rowBtn.Size = UDim2.new(1, -6, 0, 22)
                    rowBtn.Position = UDim2.new(0, 3, 0, 0)
                    rowBtn.Text = (isSel and "✓ " or "  ") .. tostring(item)
                    rowBtn.TextXAlignment = Enum.TextXAlignment.Left
                    rowBtn.Font = Enum.Font.Gotham
                    rowBtn.TextSize = 12
                    rowBtn.TextColor3 = T().Text
                    rowBtn.BackgroundColor3 = isSel and T().DropSel or T().DropItem
                    rowBtn.BorderSizePixel = 0
                    rowBtn.Parent = list

                    local rowCorner = Instance.new("UICorner")
                    rowCorner.CornerRadius = UDim.new(0, 3)
                    rowCorner.Parent = rowBtn

                    rowBtn.Activated:Connect(function()
                        if multi then
                            if type(value) ~= "table" then
                                value = {}
                            end
                            value[item] = not value[item] or nil
                            if value[item] == false then
                                value[item] = nil
                            end
                        else
                            value = item
                            open = false
                            list.Visible = false
                            list.Size = UDim2.new(1, -8, 0, 0)
                        end
                        valText.Text = display()
                        rebuildList()
                        if o.Callback then
                            o.Callback(value)
                        end
                    end)
                end

                local h = math.min(#vals, 8) * 24 + 4
                list.Size = open and UDim2.new(1, -8, 0, h) or UDim2.new(1, -8, 0, 0)
                list.CanvasSize = UDim2.new(0, 0, 0, #vals * 24)
                row.Size = UDim2.new(1, 0, 0, open and (56 + h) or 54)
            end

            btn.Activated:Connect(function()
                open = not open
                list.Visible = open
                arrow.Text = open and "▴" or "▾"
                rebuildList()
            end)

            local api = {}
            function api:SetValues(v)
                vals = v or {}
                if not multi then
                    value = vals[1]
                end
                valText.Text = display()
                rebuildList()
            end
            function api:SetValue(v)
                value = v
                valText.Text = display()
                rebuildList()
            end

            th(function()
                label.TextColor3 = T().Text
                btn.BackgroundColor3 = T().Btn
                valText.TextColor3 = T().Text
                arrow.TextColor3 = T().Dim
                list.BackgroundColor3 = T().DropBg
                listStroke.Color = T().GroupBorder
            end)

            Library:_regCfg(id, function() return value end, function(v)
                value = v
                valText.Text = display()
                rebuildList()
                if o.Callback then
                    o.Callback(value)
                end
            end)

            valText.Text = display()
            rebuildList()
            if o.Callback then
                task.spawn(o.Callback, value)
            end
            return api
        end

        function Obj:AddKeybind(id, o)
            o = o or {}
            local txt = o.Text or id
            local key = Enum.KeyCode[o.Default or "Unknown"] or Enum.KeyCode.Unknown
            local listening = false

            local row = mkRow(30)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -80, 1, 0)
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = T().Text
            label.Text = txt
            label.Parent = row

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 68, 0, 20)
            btn.Position = UDim2.new(1, -70, 0.5, -10)
            btn.Text = keyNameFromCode(key)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.TextColor3 = T().Text
            btn.BackgroundColor3 = T().Btn
            btn.BorderSizePixel = 0
            btn.Parent = row

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = btn

            btn.Activated:Connect(function()
                listening = true
                btn.Text = "..."
                btn.BackgroundColor3 = T().Accent
            end)

            UserInputService.InputBegan:Connect(function(input, gp)
                if gp then
                    return
                end
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode ~= Enum.KeyCode.Escape then
                        key = input.KeyCode
                        if o.Callback then
                            o.Callback(key)
                        end
                    end
                    listening = false
                    btn.Text = keyNameFromCode(key)
                    btn.BackgroundColor3 = T().Btn
                    return
                end
                if not listening and input.KeyCode == key and o.OnKey then
                    o.OnKey()
                end
            end)

            th(function()
                label.TextColor3 = T().Text
                btn.BackgroundColor3 = T().Btn
                btn.TextColor3 = T().Text
            end)

            Library:_regCfg(id, function() return tostring(key) end, function(v)
                local parsed = Enum.KeyCode[v]
                if parsed then
                    key = parsed
                    btn.Text = keyNameFromCode(key)
                end
            end)

            return { Value = key }
        end

        function Obj:AddLabel(txt)
            local row = mkRow(24)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -8, 1, 0)
            label.Position = UDim2.new(0, 4, 0, 0)
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = T().Dim
            label.Text = tostring(txt)
            label.Parent = row

            th(function()
                label.TextColor3 = T().Dim
            end)

            local api = {}
            function api:SetText(t)
                label.Text = tostring(t)
            end
            function api:AddKeyPicker(kid, ko)
                ko = ko or {}
                local key = Enum.KeyCode[ko.Default or "Delete"] or Enum.KeyCode.Delete
                local listening = false

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 62, 0, 18)
                btn.Position = UDim2.new(1, -66, 0.5, -9)
                btn.Text = keyNameFromCode(key)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 12
                btn.TextColor3 = T().Text
                btn.BackgroundColor3 = T().Btn
                btn.BorderSizePixel = 0
                btn.Parent = row

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 4)
                corner.Parent = btn

                btn.Activated:Connect(function()
                    listening = true
                    btn.Text = "..."
                    btn.BackgroundColor3 = T().Accent
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then
                        return
                    end
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode ~= Enum.KeyCode.Escape then
                            key = input.KeyCode
                            if ko.Callback then
                                ko.Callback(key)
                            end
                        end
                        listening = false
                        btn.Text = keyNameFromCode(key)
                        btn.BackgroundColor3 = T().Btn
                        return
                    end
                    if input.KeyCode == key and ko.OnKey then
                        ko.OnKey()
                    end
                end)

                Library:_regCfg(kid, function() return tostring(key) end, function(v)
                    local parsed = Enum.KeyCode[v]
                    if parsed then
                        key = parsed
                        btn.Text = keyNameFromCode(key)
                    end
                end)

                return { OnChanged = function() end }
            end

            return api
        end

        function Obj:AddInput(id, o)
            o = o or {}
            local txt = o.Text or id
            local cur = o.Default or ""

            local row = mkRow(54)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -8, 0, 18)
            label.Position = UDim2.new(0, 4, 0, 2)
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = T().Text
            label.Text = txt
            label.Parent = row

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -8, 0, 26)
            box.Position = UDim2.new(0, 4, 0, 24)
            box.BackgroundColor3 = T().Btn
            box.TextColor3 = T().Text
            box.PlaceholderText = "Type..."
            box.PlaceholderColor3 = T().Dim
            box.Font = Enum.Font.Gotham
            box.TextSize = 13
            box.ClearTextOnFocus = false
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.Text = tostring(cur)
            box.BorderSizePixel = 0
            box.Parent = row

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = box

            box.FocusLost:Connect(function(enterPressed)
                cur = box.Text
                if o.Callback then
                    o.Callback(cur)
                end
            end)

            th(function()
                label.TextColor3 = T().Text
                box.BackgroundColor3 = T().Btn
                box.TextColor3 = T().Text
                box.PlaceholderColor3 = T().Dim
            end)

            local api = {}
            function api:SetValue(v)
                cur = tostring(v)
                box.Text = cur
                if o.Callback then
                    o.Callback(cur)
                end
            end

            Library:_regCfg(id, function() return cur end, function(v) api:SetValue(v) end)
            if o.Callback then
                task.spawn(o.Callback, cur)
            end
            return api
        end

        return Obj
    end

    local function setActiveTab(tab)
        for _, t in ipairs(window.Tabs) do
            local isActive = t == tab
            t.Content.Visible = isActive
            t.Button.TextColor3 = isActive and T().TabOn or T().TabOff
        end
        window.Active = tab
    end

    function window:AddTab(name)
        local tab = { Name = name }

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, math.max(72, #name * 7 + 14), 0, 22)
        btn.Text = name
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.TextColor3 = T().TabOff
        btn.BackgroundTransparency = 1
        btn.Parent = tabBar

        tabBar.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + 20, 0, 0)
        tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabBar.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + 20, 0, 0)
        end)

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, 0, 1, 0)
        content.BackgroundTransparency = 1
        content.Visible = false
        content.Parent = body

        local left = Instance.new("ScrollingFrame")
        left.Size = UDim2.new(0.5, -4, 1, 0)
        left.Position = UDim2.new(0, 0, 0, 0)
        left.BackgroundTransparency = 1
        left.BorderSizePixel = 0
        left.ScrollBarThickness = 5
        left.CanvasSize = UDim2.new(0, 0, 0, 0)
        left.Parent = content

        local right = Instance.new("ScrollingFrame")
        right.Size = UDim2.new(0.5, -4, 1, 0)
        right.Position = UDim2.new(0.5, 4, 0, 0)
        right.BackgroundTransparency = 1
        right.BorderSizePixel = 0
        right.ScrollBarThickness = 5
        right.CanvasSize = UDim2.new(0, 0, 0, 0)
        right.Parent = content

        local leftList = Instance.new("UIListLayout")
        leftList.Padding = UDim.new(0, 8)
        leftList.Parent = left

        local rightList = Instance.new("UIListLayout")
        rightList.Padding = UDim.new(0, 8)
        rightList.Parent = right

        leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            left.CanvasSize = UDim2.new(0, 0, 0, leftList.AbsoluteContentSize.Y + 8)
        end)
        rightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            right.CanvasSize = UDim2.new(0, 0, 0, rightList.AbsoluteContentSize.Y + 8)
        end)

        tab.Button = btn
        tab.Content = content
        tab.LeftColumn = left
        tab.RightColumn = right

        function tab:AddLeftGroupbox(groupName)
            return makeGroupbox(tab, "left", groupName)
        end

        function tab:AddRightGroupbox(groupName)
            return makeGroupbox(tab, "right", groupName)
        end

        btn.Activated:Connect(function()
            setActiveTab(tab)
        end)

        table.insert(window.Tabs, tab)
        if not window.Active then
            setActiveTab(tab)
        end

        th(function()
            btn.TextColor3 = (window.Active == tab) and T().TabOn or T().TabOff
        end)

        return tab
    end

    local dragging = false
    local dragOffset = Vector2.new(0, 0)

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragOffset = UserInputService:GetMouseLocation() - Vector2.new(shell.AbsolutePosition.X, shell.AbsolutePosition.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local m = UserInputService:GetMouseLocation()
            shell.Position = UDim2.fromOffset(m.X - dragOffset.X + shell.AbsoluteSize.X * 0.5, m.Y - dragOffset.Y + shell.AbsoluteSize.Y * 0.5)
        end
    end)

    function window:SetVisible(v)
        window.Visible = not not v
        shell.Visible = window.Visible
    end

    function window:SetShadowEnabled(v)
        window.ShadowEnabled = not not v
    end

    function window:SetShadowTransparency(v)
        window.ShadowTransparency = math.clamp(tonumber(v) or window.ShadowTransparency, 0, 1)
    end

    th(function()
        shell.BackgroundColor3 = T().Bg
        shellStroke.Color = T().GroupBorder
        topbar.BackgroundColor3 = T().Bar
        topAccent.BackgroundColor3 = T().Accent
        title.TextColor3 = T().Text
        tabBar.BackgroundColor3 = T().Bar
    end)

    table.insert(Library._windows, shell)
    return window
end

function Library:Unload()
    for _, w in ipairs(Library._windows) do
        if w and w.Parent then
            w:Destroy()
        end
    end
    Library._windows = {}
    if Library.RootGui and Library.RootGui.Parent then
        Library.RootGui:Destroy()
    end
    Library.RootGui = nil
    Library._notifyHolder = nil
    Library.ThemeUpdaters = {}
    Library.ConfigData = {}
end

return Library

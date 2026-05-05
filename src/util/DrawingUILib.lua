local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Library = {}
Library.Drawings = {}
Library.Connections = {}
Library.ThemeUpdaters = {}
Library.CurrentThemeName = "Default"

-- ── Themes ────────────────────────────────────────────────────────────────────
Library.Themes = {
    Default = {
        Bg          = Color3.fromRGB(14, 14, 20),
        Bar         = Color3.fromRGB(20, 20, 30),
        Accent      = Color3.fromRGB(98, 62, 255),
        GroupBg     = Color3.fromRGB(20, 20, 30),
        GroupBorder = Color3.fromRGB(38, 38, 55),
        GroupHead   = Color3.fromRGB(26, 26, 38),
        TabOn       = Color3.fromRGB(98, 62, 255),
        TabOff      = Color3.fromRGB(130, 130, 158),
        Text        = Color3.fromRGB(235, 235, 242),
        Dim         = Color3.fromRGB(148, 148, 172),
        TogOn       = Color3.fromRGB(98, 62, 255),
        TogOff      = Color3.fromRGB(36, 36, 52),
        Thumb       = Color3.fromRGB(230, 230, 242),
        Btn         = Color3.fromRGB(32, 32, 48),
        Sep         = Color3.fromRGB(30, 30, 46),
        SlidBg      = Color3.fromRGB(26, 26, 40),
    },
    Dark = {
        Bg          = Color3.fromRGB(12, 12, 16),
        Bar         = Color3.fromRGB(18, 18, 24),
        Accent      = Color3.fromRGB(0, 140, 255),
        GroupBg     = Color3.fromRGB(18, 18, 24),
        GroupBorder = Color3.fromRGB(30, 30, 44),
        GroupHead   = Color3.fromRGB(22, 22, 32),
        TabOn       = Color3.fromRGB(0, 140, 255),
        TabOff      = Color3.fromRGB(118, 118, 148),
        Text        = Color3.fromRGB(232, 232, 240),
        Dim         = Color3.fromRGB(140, 140, 168),
        TogOn       = Color3.fromRGB(0, 140, 255),
        TogOff      = Color3.fromRGB(30, 30, 46),
        Thumb       = Color3.fromRGB(224, 224, 238),
        Btn         = Color3.fromRGB(26, 26, 40),
        Sep         = Color3.fromRGB(24, 24, 38),
        SlidBg      = Color3.fromRGB(22, 22, 34),
    },
    Midnight = {
        Bg          = Color3.fromRGB(10, 10, 18),
        Bar         = Color3.fromRGB(16, 14, 26),
        Accent      = Color3.fromRGB(220, 50, 120),
        GroupBg     = Color3.fromRGB(16, 14, 26),
        GroupBorder = Color3.fromRGB(32, 28, 48),
        GroupHead   = Color3.fromRGB(20, 18, 32),
        TabOn       = Color3.fromRGB(220, 50, 120),
        TabOff      = Color3.fromRGB(126, 120, 154),
        Text        = Color3.fromRGB(238, 236, 248),
        Dim         = Color3.fromRGB(150, 144, 178),
        TogOn       = Color3.fromRGB(220, 50, 120),
        TogOff      = Color3.fromRGB(32, 28, 50),
        Thumb       = Color3.fromRGB(232, 228, 246),
        Btn         = Color3.fromRGB(28, 24, 44),
        Sep         = Color3.fromRGB(28, 24, 46),
        SlidBg      = Color3.fromRGB(24, 20, 40),
    },
    Forest = {
        Bg          = Color3.fromRGB(10, 16, 12),
        Bar         = Color3.fromRGB(14, 22, 16),
        Accent      = Color3.fromRGB(50, 200, 90),
        GroupBg     = Color3.fromRGB(14, 22, 16),
        GroupBorder = Color3.fromRGB(24, 38, 28),
        GroupHead   = Color3.fromRGB(18, 28, 22),
        TabOn       = Color3.fromRGB(50, 200, 90),
        TabOff      = Color3.fromRGB(115, 142, 122),
        Text        = Color3.fromRGB(232, 242, 234),
        Dim         = Color3.fromRGB(138, 164, 144),
        TogOn       = Color3.fromRGB(50, 200, 90),
        TogOff      = Color3.fromRGB(22, 36, 26),
        Thumb       = Color3.fromRGB(224, 238, 228),
        Btn         = Color3.fromRGB(18, 30, 22),
        Sep         = Color3.fromRGB(20, 32, 24),
        SlidBg      = Color3.fromRGB(14, 26, 18),
    },
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function T() return Library.Themes[Library.CurrentThemeName] end
local function th(fn) table.insert(Library.ThemeUpdaters, fn) end

local function d(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do pcall(function() obj[k] = v end) end
    table.insert(Library.Drawings, obj)
    return obj
end

local function on(sig, fn)
    local c = sig:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end

local function over(pos, sz)
    local m = UserInputService:GetMouseLocation()
    return m.X >= pos.X and m.X <= pos.X + sz.X and m.Y >= pos.Y and m.Y <= pos.Y + sz.Y
end

local function fv(v) return Vector2.new(math.floor(v.X), math.floor(v.Y)) end

-- ── Theme API ─────────────────────────────────────────────────────────────────
function Library:SetTheme(name)
    if not Library.Themes[name] then return end
    Library.CurrentThemeName = name
    for _, fn in ipairs(Library.ThemeUpdaters) do pcall(fn) end
end

-- ── CreateWindow ──────────────────────────────────────────────────────────────
function Library:CreateWindow(opts)
    local title = opts.Title or "BHub"

    local W      = 490   -- window width
    local BAR    = 32    -- title bar height
    local TABH   = 28    -- tab strip height
    local HDR    = BAR + 2 + TABH + 1   -- total header block
    local PAD    = 8
    local GAP    = 6
    local COL    = math.floor((W - PAD * 2 - GAP) / 2)   -- ≈ 233

    local Win = {
        Pos      = Vector2.new(100, 100),
        Tabs     = {},
        Active   = nil,
        Dragging = false,
        DragOff  = Vector2.new(),
        Btns     = {},
        Visible  = true,
    }

    -- Chrome
    local wBg     = d("Square", { Filled=true,  ZIndex=10, Rounding=6, Color=T().Bg,     Visible=true, Position=Win.Pos, Size=Vector2.new(W,BAR) })
    local wBar    = d("Square", { Filled=true,  ZIndex=11, Rounding=6, Color=T().Bar,    Visible=true, Position=Win.Pos, Size=Vector2.new(W,BAR) })
    local wBarBot = d("Square", { Filled=true,  ZIndex=11, Rounding=0, Color=T().Bar,    Visible=true, Position=Win.Pos+Vector2.new(0,BAR-5), Size=Vector2.new(W,5) })
    local wAccent = d("Square", { Filled=true,  ZIndex=12,             Color=T().Accent, Visible=true, Position=Win.Pos+Vector2.new(0,BAR), Size=Vector2.new(W,2) })
    local wTabBg  = d("Square", { Filled=true,  ZIndex=11, Rounding=0, Color=T().Bar,    Visible=true, Position=Win.Pos+Vector2.new(0,BAR+2), Size=Vector2.new(W,TABH) })
    local wTabSep = d("Square", { Filled=true,  ZIndex=12,             Color=T().Sep,    Visible=true, Position=Win.Pos+Vector2.new(0,HDR), Size=Vector2.new(W,1) })
    local wTitle  = d("Text",   { Text=title, Size=15, Font=2, Outline=false, Color=T().Text, Visible=true, ZIndex=13, Position=Win.Pos+Vector2.new(12,9) })

    th(function()
        wBg.Color=T().Bg; wBar.Color=T().Bar; wBarBot.Color=T().Bar
        wAccent.Color=T().Accent; wTabBg.Color=T().Bar; wTabSep.Color=T().Sep; wTitle.Color=T().Text
    end)

    local CONTY = HDR + 1 + PAD   -- content area Y offset from Win.Pos

    -- ── Layout ────────────────────────────────────────────────────────────────
    local function layout()
        wBg.Position    = fv(Win.Pos)
        wBar.Position   = fv(Win.Pos)
        wBarBot.Position= fv(Win.Pos + Vector2.new(0, BAR-5))
        wAccent.Position= fv(Win.Pos + Vector2.new(0, BAR))
        wTabBg.Position = fv(Win.Pos + Vector2.new(0, BAR+2))
        wTabSep.Position= fv(Win.Pos + Vector2.new(0, HDR))
        wTitle.Position = fv(Win.Pos + Vector2.new(12, 9))

        local tx = 12
        for _, btn in ipairs(Win.Btns) do
            btn.setPos(fv(Win.Pos + Vector2.new(tx, BAR+2+6)))
            tx = tx + btn.w + 20
        end

        if not Win.Active then return end
        local lH, rH = 0, 0
        for _, gb in ipairs(Win.Active.L) do
            gb.setPos(fv(Win.Pos + Vector2.new(PAD, CONTY + lH)))
            lH = lH + gb.height() + PAD
        end
        for _, gb in ipairs(Win.Active.R) do
            gb.setPos(fv(Win.Pos + Vector2.new(PAD + COL + GAP, CONTY + rH)))
            rH = rH + gb.height() + PAD
        end
        local totH = math.max(lH, rH, 40)
        wBg.Size = fv(Vector2.new(W, CONTY + totH + PAD))
    end

    -- ── Drag ──────────────────────────────────────────────────────────────────
    on(UserInputService.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            if over(Win.Pos, Vector2.new(W, BAR)) then
                Win.Dragging = true
                Win.DragOff  = UserInputService:GetMouseLocation() - Win.Pos
            end
        end
    end)
    on(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then Win.Dragging = false end
    end)
    on(RunService.RenderStepped, function()
        if Win.Dragging then
            Win.Pos = fv(UserInputService:GetMouseLocation() - Win.DragOff)
            layout()
        end
    end)

    -- Insert = toggle visibility
    on(UserInputService.InputBegan, function(i)
        if i.KeyCode == Enum.KeyCode.Insert then
            Win.Visible = not Win.Visible
            -- hide everything except the bare chrome so we can re-show
            local keep = { [wBg]=true, [wBar]=true, [wBarBot]=true, [wAccent]=true, [wTabBg]=true, [wTabSep]=true, [wTitle]=true }
            for _, obj in ipairs(Library.Drawings) do
                if not keep[obj] then pcall(function() obj.Visible = Win.Visible end) end
            end
        end
    end)

    -- ── Groupbox factory ──────────────────────────────────────────────────────
    local function makeGB(parentTab, side, name)
        local GH = 26    -- header row height
        local GP = 6     -- inner vertical padding

        local GB = { items = {}, pos = Vector2.new() }

        local gBg    = d("Square", { Filled=true,  ZIndex=14, Rounding=5, Color=T().GroupBg,     Visible=false, Size=Vector2.new(COL,GH) })
        local gOut   = d("Square", { Filled=false, ZIndex=14, Rounding=5, Thickness=1, Color=T().GroupBorder, Visible=false, Size=Vector2.new(COL,GH) })
        local gHead  = d("Square", { Filled=true,  ZIndex=15, Rounding=5, Color=T().GroupHead,   Visible=false, Size=Vector2.new(COL,GH) })
        local gHBot  = d("Square", { Filled=true,  ZIndex=15, Rounding=0, Color=T().GroupHead,   Visible=false, Size=Vector2.new(COL,6) })
        local gHLine = d("Square", { Filled=true,  ZIndex=16,             Color=T().Sep,          Visible=false, Size=Vector2.new(COL,1) })
        local gTitle = d("Text",   { Text=name, Size=12, Font=2, Outline=false, Color=T().Dim,   Visible=false, ZIndex=16 })

        th(function()
            gBg.Color=T().GroupBg; gOut.Color=T().GroupBorder; gHead.Color=T().GroupHead
            gHBot.Color=T().GroupHead; gHLine.Color=T().Sep; gTitle.Color=T().Dim
        end)

        function GB.height()
            local h = GH + GP
            for _, it in ipairs(GB.items) do h = h + it.h end
            return h + GP
        end

        function GB.setVis(v)
            gBg.Visible=v; gOut.Visible=v; gHead.Visible=v
            gHBot.Visible=v; gHLine.Visible=v; gTitle.Visible=v
            for _, it in ipairs(GB.items) do it.setVis(v) end
        end

        function GB.setPos(p)
            GB.pos = p
            local h = GB.height()
            gBg.Position=p;   gBg.Size=fv(Vector2.new(COL,h))
            gOut.Position=p;  gOut.Size=fv(Vector2.new(COL,h))
            gHead.Position=p; gHead.Size=fv(Vector2.new(COL,GH))
            gHBot.Position=fv(p+Vector2.new(0,GH-4)); gHBot.Size=Vector2.new(COL,4)
            gHLine.Position=fv(p+Vector2.new(0,GH));  gHLine.Size=Vector2.new(COL,1)
            gTitle.Position=fv(p+Vector2.new(10,7))
            local iy = GH + GP
            for _, it in ipairs(GB.items) do
                it.setPos(fv(p + Vector2.new(0, iy)))
                iy = iy + it.h
            end
        end

        local function addIt(it)
            table.insert(GB.items, it)
            if Win.Active == parentTab then it.setVis(true) end
            layout()
        end

        -- ── Groupbox public API ───────────────────────────────────────────────
        local Obj = {}

        function Obj:AddToggle(id, o)
            local txt = o.Text or id
            local st  = o.Default or false
            local iP  = Vector2.new()
            local IH  = 26

            local lbl = d("Text",   { Text=txt, Size=13, Font=2, Outline=false, Color=T().Text,   Visible=false, ZIndex=20 })
            local trk = d("Square", { Size=Vector2.new(30,16), Filled=true, ZIndex=20, Rounding=8, Color=st and T().TogOn or T().TogOff, Visible=false })
            local thb = d("Square", { Size=Vector2.new(12,12), Filled=true, ZIndex=21, Rounding=6, Color=T().Thumb, Visible=false })

            th(function() lbl.Color=T().Text; trk.Color=st and T().TogOn or T().TogOff; thb.Color=T().Thumb end)

            local function refreshThumb()
                trk.Color = st and T().TogOn or T().TogOff
                thb.Position = fv(iP + Vector2.new(COL - 42 + (st and 15 or 3), 7))
            end

            local it = { h=IH }
            function it.setVis(v) lbl.Visible=v; trk.Visible=v; thb.Visible=v end
            function it.setPos(p)
                iP = p
                lbl.Position = fv(p + Vector2.new(GP+2, 6))
                trk.Position = fv(p + Vector2.new(COL-42, 5))
                thb.Position = fv(p + Vector2.new(COL-42+(st and 15 or 3), 7))
            end

            local Tog = { State=st }
            on(UserInputService.InputBegan, function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Win.Active ~= parentTab then return end
                if over(iP, Vector2.new(COL, IH)) then
                    st = not st; Tog.State = st
                    refreshThumb()
                    if o.Callback then o.Callback(st) end
                end
            end)
            function Tog:AddColorPicker() return { OnChanged=function()end } end
            function Tog:AddKeyPicker()   return { OnChanged=function()end } end

            addIt(it)
            if o.Callback then task.spawn(o.Callback, st) end
            return Tog
        end

        function Obj:AddButton(o)
            local txt = type(o)=="table" and o.Text or tostring(o)
            local fn  = type(o)=="table" and o.Func or function() end
            local IH  = 30
            local iP  = Vector2.new()
            local bW  = COL - GP*2

            local bg2 = d("Square", { Size=Vector2.new(bW,22), Filled=true, ZIndex=20, Rounding=4, Color=T().Btn,  Visible=false })
            local lt  = d("Text",   { Text=txt, Size=13, Font=2, Outline=false, Center=true, Color=T().Text, ZIndex=21, Visible=false })

            th(function() bg2.Color=T().Btn; lt.Color=T().Text end)

            local it = { h=IH }
            function it.setVis(v) bg2.Visible=v; lt.Visible=v end
            function it.setPos(p)
                iP = p
                bg2.Position = fv(p + Vector2.new(GP, 4))
                lt.Position  = fv(p + Vector2.new(GP + bW/2, 7))
            end

            on(UserInputService.InputBegan, function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Win.Active ~= parentTab then return end
                if over(bg2.Position, bg2.Size) then
                    bg2.Color = T().Accent
                    if fn then fn() end
                    task.delay(0.12, function() pcall(function() bg2.Color = T().Btn end) end)
                end
            end)

            addIt(it)
            return { }
        end

        function Obj:AddSlider(id, o)
            local txt  = o.Text or id
            local mn   = o.Min or 0
            local mx   = o.Max or 100
            local val  = o.Default or mn
            local sW   = COL - GP*2
            local IH   = 44
            local iP   = Vector2.new()
            local dragging = false

            local lbl  = d("Text",   { Text=txt..": "..tostring(val), Size=13, Font=2, Outline=false, Color=T().Text,   Visible=false, ZIndex=20 })
            local sBg  = d("Square", { Size=Vector2.new(sW,6), Filled=true, ZIndex=20, Rounding=3, Color=T().SlidBg, Visible=false })
            local sFill= d("Square", { Size=Vector2.new(((val-mn)/(mx-mn))*sW,6), Filled=true, ZIndex=21, Rounding=3, Color=T().Accent, Visible=false })
            local sThb = d("Square", { Size=Vector2.new(10,10), Filled=true, ZIndex=22, Rounding=5, Color=T().Thumb, Visible=false })

            th(function() lbl.Color=T().Text; sBg.Color=T().SlidBg; sFill.Color=T().Accent; sThb.Color=T().Thumb end)

            local function refreshSlider(pct)
                pct = math.clamp(pct, 0, 1)
                val = mn + (mx - mn) * pct
                if o.Rounding == 0 then val = math.floor(val) end
                local fw = math.max(pct * sW, 0)
                sFill.Size = Vector2.new(fw, 6)
                sThb.Position = fv(sBg.Position + Vector2.new(fw - 5, -2))
                lbl.Text = txt..": "..tostring(math.floor(val*10)/10)
                if o.Callback then o.Callback(val) end
            end

            local Sld = { Value=val }
            local it = { h=IH }
            function it.setVis(v) lbl.Visible=v; sBg.Visible=v; sFill.Visible=v; sThb.Visible=v end
            function it.setPos(p)
                iP = p
                lbl.Position  = fv(p + Vector2.new(GP+2, 4))
                sBg.Position  = fv(p + Vector2.new(GP, 26))
                local pct2 = (val - mn) / (mx - mn)
                sFill.Position = fv(p + Vector2.new(GP, 26))
                sFill.Size     = Vector2.new(math.max(pct2*sW, 0), 6)
                sThb.Position  = fv(p + Vector2.new(GP + pct2*sW - 5, 24))
            end

            on(UserInputService.InputBegan, function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Win.Active ~= parentTab then return end
                if over(sBg.Position, Vector2.new(sW, 14)) then
                    dragging = true
                    refreshSlider((UserInputService:GetMouseLocation().X - sBg.Position.X) / sW)
                end
            end)
            on(UserInputService.InputEnded, function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            on(RunService.RenderStepped, function()
                if dragging and Win.Active == parentTab then
                    refreshSlider((UserInputService:GetMouseLocation().X - sBg.Position.X) / sW)
                    Sld.Value = val
                end
            end)

            addIt(it)
            if o.Callback then task.spawn(o.Callback, val) end
            return Sld
        end

        function Obj:AddLabel(txt)
            local IH = 22
            local lbl = d("Text", { Text=txt, Size=13, Font=2, Outline=false, Color=T().Dim, Visible=false, ZIndex=20 })
            th(function() lbl.Color=T().Dim end)

            local it = { h=IH }
            function it.setVis(v) lbl.Visible=v end
            function it.setPos(p) lbl.Position = fv(p + Vector2.new(GP+2, 4)) end

            local Lbl = {}
            function Lbl:SetText(t) lbl.Text = t end
            function Lbl:AddKeyPicker() return { OnChanged=function()end } end

            addIt(it)
            return Lbl
        end

        function Obj:AddDropdown(id, o)
            local txt   = o.Text or id
            local vals  = o.Values or {}
            local multi = o.Multi
            local val   = o.Default
            local dW    = COL - GP*2
            local IH    = 48
            local iP    = Vector2.new()

            local lbl  = d("Text",   { Text=txt, Size=13, Font=2, Outline=false, Color=T().Text, Visible=false, ZIndex=20 })
            local dBg  = d("Square", { Size=Vector2.new(dW,22), Filled=true, ZIndex=20, Rounding=4, Color=T().Btn, Visible=false })
            local dVal = d("Text",   { Size=12, Font=2, Outline=false, Center=true, Color=T().Text, Visible=false, ZIndex=21 })
            local dArr = d("Text",   { Text="▾", Size=11, Font=2, Outline=false, Color=T().Dim, Visible=false, ZIndex=21 })

            th(function() lbl.Color=T().Text; dBg.Color=T().Btn; dVal.Color=T().Text; dArr.Color=T().Dim end)

            local function display()
                if multi then
                    local parts = {}
                    for k, v in pairs(val or {}) do if v then table.insert(parts, tostring(k)) end end
                    return #parts==0 and "None" or table.concat(parts, ", ")
                end
                return tostring(val or "None")
            end
            dVal.Text = display()

            local it = { h=IH }
            function it.setVis(v) lbl.Visible=v; dBg.Visible=v; dVal.Visible=v; dArr.Visible=v end
            function it.setPos(p)
                iP = p
                lbl.Position  = fv(p + Vector2.new(GP+2, 4))
                dBg.Position  = fv(p + Vector2.new(GP, 22))
                dVal.Position = fv(p + Vector2.new(GP + dW/2, 26))
                dArr.Position = fv(p + Vector2.new(GP + dW - 14, 26))
            end

            local Drop = {}
            function Drop:SetValues(v)
                vals = v
                if not multi then val = v[1] end
                dVal.Text = display()
            end

            on(UserInputService.InputBegan, function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Win.Active ~= parentTab then return end
                if over(dBg.Position, dBg.Size) then
                    dBg.Color = T().Accent
                    if not multi then
                        local idx = table.find(vals, val) or 0
                        idx = (idx % #vals) + 1
                        val = vals[idx]
                    else
                        local cur = nil
                        for k, v in pairs(val or {}) do if v then cur = k; break end end
                        local idx = table.find(vals, cur) or 0
                        idx = (idx % #vals) + 1
                        val = { [vals[idx]] = true }
                    end
                    dVal.Text = display()
                    if o.Callback then o.Callback(val) end
                    task.delay(0.12, function() pcall(function() dBg.Color = T().Btn end) end)
                end
            end)

            addIt(it)
            if o.Callback then task.spawn(o.Callback, val) end
            return Drop
        end

        function Obj:AddInput(id, o)
            -- Drawing API has no text input; shows label stub
            local txt = (o and o.Text or id)
            local cur = (o and o.Default or "")
            local IH  = 22
            local lbl = d("Text", { Text=txt..": ["..cur.."]", Size=13, Font=2, Outline=false, Color=T().Dim, Visible=false, ZIndex=20 })
            th(function() lbl.Color=T().Dim end)

            local it = { h=IH }
            function it.setVis(v) lbl.Visible=v end
            function it.setPos(p) lbl.Position = fv(p + Vector2.new(GP+2, 4)) end

            local Inp = {}
            function Inp:SetValue(v)
                cur = v
                lbl.Text = txt..": ["..cur.."]"
                if o and o.Callback then o.Callback(v) end
            end

            addIt(it)
            return Inp
        end

        -- register with tab
        if side == "left" then
            table.insert(parentTab.L, GB)
        else
            table.insert(parentTab.R, GB)
        end
        layout()
        return Obj
    end

    -- ── AddTab ────────────────────────────────────────────────────────────────
    function Win:AddTab(name)
        local Tab = { L={}, R={} }
        table.insert(Win.Tabs, Tab)

        local tw  = #name * 7 + 14
        local btn = { w=tw, Tab=Tab }
        local bPos = Vector2.new()

        local bLbl = d("Text",   { Text=name, Size=13, Font=2, Outline=false, Color=Win.Active==Tab and T().TabOn or T().TabOff, Visible=true, ZIndex=18 })
        local bInd = d("Square", { Size=Vector2.new(tw-4,2), Filled=true, ZIndex=18, Color=T().Accent, Visible=Win.Active==Tab })

        th(function()
            bLbl.Color = (Win.Active==Tab) and T().TabOn or T().TabOff
            bInd.Color = T().Accent
        end)

        function btn.setPos(p)
            bPos = p
            bLbl.Position = p
            bInd.Position = fv(p + Vector2.new(2, 17))
        end

        local function activate()
            for _, ob in ipairs(Win.Btns) do
                if ob.Tab then
                    for _, gb in ipairs(ob.Tab.L) do gb.setVis(false) end
                    for _, gb in ipairs(ob.Tab.R) do gb.setVis(false) end
                    ob.bLbl.Color = T().TabOff
                    ob.bInd.Visible = false
                end
            end
            Win.Active = Tab
            for _, gb in ipairs(Tab.L) do gb.setVis(true) end
            for _, gb in ipairs(Tab.R) do gb.setVis(true) end
            bLbl.Color = T().TabOn
            bInd.Visible = true
            layout()
        end

        btn.bLbl = bLbl
        btn.bInd = bInd

        on(UserInputService.InputBegan, function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if over(bPos, Vector2.new(tw, TABH)) then activate() end
        end)

        table.insert(Win.Btns, btn)
        if not Win.Active then
            Win.Active = Tab
            bLbl.Color = T().TabOn
            bInd.Visible = true
        end

        function Tab:AddLeftGroupbox(n)  return makeGB(Tab, "left",  n) end
        function Tab:AddRightGroupbox(n) return makeGB(Tab, "right", n) end

        layout()
        return Tab
    end

    -- ── Built-in Settings tab (deferred so it appears last) ───────────────────
    task.defer(function()
        local stab   = Win:AddTab("Settings")
        local tGroup = stab:AddLeftGroupbox("Theme")
        local names  = {}
        for k in pairs(Library.Themes) do table.insert(names, k) end
        table.sort(names)
        tGroup:AddDropdown("_theme", {
            Values = names, Default = Library.CurrentThemeName, Text = "Color Theme",
            Callback = function(v) Library:SetTheme(v) end
        })
        tGroup:AddLabel("Insert = toggle visibility")

        local kGroup = stab:AddRightGroupbox("Keybind")
        kGroup:AddLabel("Menu bind: Insert")
        kGroup:AddButton({ Text = "Unload UI", Func = function() Library:Unload() end })
    end)

    layout()
    return Win
end

-- ── Notify & Unload ───────────────────────────────────────────────────────────
function Library:Notify(text, _duration)
    print("[BHub]", text)
end

function Library:Unload()
    for _, c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
    for _, o in ipairs(Library.Drawings)    do pcall(function() o:Remove()     end) end
    Library.Connections   = {}
    Library.Drawings      = {}
    Library.ThemeUpdaters = {}
end

return Library

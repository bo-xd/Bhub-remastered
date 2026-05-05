local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local Library = {}
Library.Drawings      = {}
Library.Connections   = {}
Library.ThemeUpdaters = {}
Library.ConfigData    = {}
Library.CurrentThemeName = "Default"

local FONT = 0  -- Drawing.Fonts.UI — anti-aliased Gotham/sans-serif

-- ── Themes ────────────────────────────────────────────────────────────────────
Library.Themes = {
    Default = {
        Bg=Color3.fromRGB(14,14,21),      Bar=Color3.fromRGB(20,20,32),
        Accent=Color3.fromRGB(98,62,255), GroupBg=Color3.fromRGB(19,19,29),
        GroupBorder=Color3.fromRGB(38,38,58), GroupHead=Color3.fromRGB(25,25,38),
        TabOn=Color3.fromRGB(98,62,255),  TabOff=Color3.fromRGB(125,125,155),
        Text=Color3.fromRGB(232,232,245), Dim=Color3.fromRGB(148,148,175),
        TogOn=Color3.fromRGB(98,62,255),  TogOff=Color3.fromRGB(38,38,58),
        Thumb=Color3.fromRGB(230,230,248),Btn=Color3.fromRGB(30,30,46),
        Sep=Color3.fromRGB(32,32,50),     SlidBg=Color3.fromRGB(26,26,42),
        DropBg=Color3.fromRGB(18,18,28),  DropItem=Color3.fromRGB(26,26,40),
        DropHover=Color3.fromRGB(42,42,65),DropSel=Color3.fromRGB(72,44,200),
    },
    Dark = {
        Bg=Color3.fromRGB(12,12,16),      Bar=Color3.fromRGB(17,17,24),
        Accent=Color3.fromRGB(0,140,255), GroupBg=Color3.fromRGB(17,17,23),
        GroupBorder=Color3.fromRGB(28,28,44), GroupHead=Color3.fromRGB(21,21,30),
        TabOn=Color3.fromRGB(0,140,255),  TabOff=Color3.fromRGB(115,115,148),
        Text=Color3.fromRGB(228,228,242), Dim=Color3.fromRGB(140,140,168),
        TogOn=Color3.fromRGB(0,140,255),  TogOff=Color3.fromRGB(28,28,46),
        Thumb=Color3.fromRGB(220,220,240),Btn=Color3.fromRGB(24,24,38),
        Sep=Color3.fromRGB(25,25,40),     SlidBg=Color3.fromRGB(20,20,34),
        DropBg=Color3.fromRGB(14,14,22),  DropItem=Color3.fromRGB(20,20,34),
        DropHover=Color3.fromRGB(34,34,54),DropSel=Color3.fromRGB(0,100,210),
    },
    Midnight = {
        Bg=Color3.fromRGB(10,10,18),       Bar=Color3.fromRGB(15,14,26),
        Accent=Color3.fromRGB(210,45,115), GroupBg=Color3.fromRGB(15,14,26),
        GroupBorder=Color3.fromRGB(30,26,50),GroupHead=Color3.fromRGB(19,17,32),
        TabOn=Color3.fromRGB(210,45,115),  TabOff=Color3.fromRGB(122,118,155),
        Text=Color3.fromRGB(235,234,248),  Dim=Color3.fromRGB(150,144,180),
        TogOn=Color3.fromRGB(210,45,115),  TogOff=Color3.fromRGB(30,26,50),
        Thumb=Color3.fromRGB(232,228,248), Btn=Color3.fromRGB(26,22,44),
        Sep=Color3.fromRGB(28,24,48),      SlidBg=Color3.fromRGB(22,18,40),
        DropBg=Color3.fromRGB(14,12,22),   DropItem=Color3.fromRGB(22,18,38),
        DropHover=Color3.fromRGB(40,30,60),DropSel=Color3.fromRGB(160,30,85),
    },
    Forest = {
        Bg=Color3.fromRGB(10,15,12),      Bar=Color3.fromRGB(14,21,16),
        Accent=Color3.fromRGB(45,195,82), GroupBg=Color3.fromRGB(14,21,16),
        GroupBorder=Color3.fromRGB(22,36,26), GroupHead=Color3.fromRGB(17,27,20),
        TabOn=Color3.fromRGB(45,195,82),  TabOff=Color3.fromRGB(112,140,118),
        Text=Color3.fromRGB(228,240,230), Dim=Color3.fromRGB(138,164,142),
        TogOn=Color3.fromRGB(45,195,82),  TogOff=Color3.fromRGB(20,34,24),
        Thumb=Color3.fromRGB(220,236,224),Btn=Color3.fromRGB(16,28,20),
        Sep=Color3.fromRGB(18,30,22),     SlidBg=Color3.fromRGB(12,24,16),
        DropBg=Color3.fromRGB(10,16,12),  DropItem=Color3.fromRGB(14,24,18),
        DropHover=Color3.fromRGB(24,42,28),DropSel=Color3.fromRGB(28,140,55),
    },
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function T()   return Library.Themes[Library.CurrentThemeName] end
local function th(f) table.insert(Library.ThemeUpdaters, f) end

local function d(class, props)
    local obj = Drawing.new(class)
    for k,v in pairs(props) do pcall(function() obj[k]=v end) end
    table.insert(Library.Drawings, obj)
    return obj
end
local function on(sig, fn)
    local c = sig:Connect(fn); table.insert(Library.Connections, c); return c
end
local function over(pos, sz)
    local m = UserInputService:GetMouseLocation()
    return m.X>=pos.X and m.X<=pos.X+sz.X and m.Y>=pos.Y and m.Y<=pos.Y+sz.Y
end
local function fv(v) return Vector2.new(math.floor(v.X), math.floor(v.Y)) end
local function keyName(kc)
    if not kc then return "None" end
    local s = tostring(kc)
    return s:match("KeyCode%.(.+)") or s:match("UserInputType%.(.+)") or s
end

-- ── Theme API ─────────────────────────────────────────────────────────────────
function Library:SetTheme(name)
    if not Library.Themes[name] then return end
    Library.CurrentThemeName = name
    for _,fn in ipairs(Library.ThemeUpdaters) do pcall(fn) end
end

-- ── Config API ────────────────────────────────────────────────────────────────
function Library:_regCfg(id, getFn, setFn)
    if id and id ~= "" then Library.ConfigData[id] = {get=getFn, set=setFn} end
end
function Library:SaveConfig(name)
    name = name or "default"
    local data = {}
    for id,c in pairs(Library.ConfigData) do pcall(function() data[id]=c.get() end) end
    local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end
    pcall(function()
        if not isfolder then return end
        if not isfolder("BHub-remastered") then makefolder("BHub-remastered") end
        if not isfolder("BHub-remastered/configs") then makefolder("BHub-remastered/configs") end
        writefile("BHub-remastered/configs/"..name..".json", json)
    end)
    return true
end
function Library:LoadConfig(name)
    name = name or "default"
    if not (isfile and readfile) then return false end
    local path = "BHub-remastered/configs/"..name..".json"
    if not isfile(path) then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if ok and type(data)=="table" then
        for id,val in pairs(data) do
            if Library.ConfigData[id] then pcall(function() Library.ConfigData[id].set(val) end) end
        end
        return true
    end
    return false
end

-- ── Global overlay state ──────────────────────────────────────────────────────
local activeDD   = nil  -- { close=fn, pos=V2, sz=V2 }
local activeBind = nil  -- { cancel=fn }

-- ── CreateWindow ──────────────────────────────────────────────────────────────
function Library:CreateWindow(opts)
    local title   = opts.Title or "BHub"
    local BASE_W  = 520
    local W       = BASE_W         -- window width
    local BAR     = 32            -- title bar height
    local TAB_RH  = 26            -- height per tab row
    local PAD     = 8
    local GAP     = 6
    local COL     = math.floor((W - PAD*2 - GAP) / 2)  -- ~248
    local IP      = 8             -- item inner padding
    local MAXDD   = 14            -- max dropdown rows
    local DD_H    = 22            -- dropdown row height
    local MIN_W   = BASE_W
    local MAX_W   = 900
    local MIN_H   = 300
    local userMinH = 0

    local Win = {
        Pos=Vector2.new(100,100), Tabs={}, Active=nil,
        Dragging=false, Resizing=false, DragOff=Vector2.new(), ResizeStartMouse=Vector2.new(), ResizeStartSize=Vector2.new(), Btns={}, DropBtns={}, Visible=true,
        ShadowEnabled = true,
    }

    -- Chrome (title bar + tab strip)
    local wShd  = d("Square",{Filled=true, ZIndex=9, Rounding=10, Color=Color3.new(0,0,0), Transparency=0.35, Visible=true,Position=Win.Pos+Vector2.new(4,4),Size=Vector2.new(W,BAR)})
    Win.ShadowTransparency = 0.35
    local wBg   = d("Square",{Filled=true, ZIndex=10,Rounding=10,Color=T().Bg,    Visible=true,Position=Win.Pos,Size=Vector2.new(W,BAR)})
    local wOut  = d("Square",{Filled=false,ZIndex=10,Rounding=10,Thickness=1,Color=T().GroupBorder,Visible=true,Position=Win.Pos,Size=Vector2.new(W,BAR)})
    local wBar  = d("Square",{Filled=true, ZIndex=11,Rounding=10,Color=T().Bar,   Visible=true,Position=Win.Pos,Size=Vector2.new(W,BAR)})
    local wBBt  = d("Square",{Filled=true, ZIndex=11,Rounding=0,Color=T().Bar,   Visible=true,Position=Win.Pos+Vector2.new(0,BAR-4),Size=Vector2.new(W,4)})
    local wAcc  = d("Square",{Filled=true, ZIndex=12,            Color=T().Accent,Visible=true,Position=Win.Pos+Vector2.new(0,BAR),Size=Vector2.new(W,2)})
    local wTBg  = d("Square",{Filled=true, ZIndex=11,Rounding=0,Color=T().Bar,   Visible=true,Position=Win.Pos+Vector2.new(0,BAR+2),Size=Vector2.new(W,TAB_RH)})
    local wTSep = d("Square",{Filled=true, ZIndex=12,            Color=T().Sep,   Visible=true,Position=Win.Pos+Vector2.new(0,BAR+2+TAB_RH),Size=Vector2.new(W,1)})
    local wTit  = d("Text",  {Text=title,Size=16,Font=FONT,Outline=false,Color=T().Text,Visible=true,ZIndex=13,Position=Win.Pos+Vector2.new(13,8)})
    local wGrip = d("Square",{Filled=true, ZIndex=19,Rounding=3,Color=T().Dim,   Visible=true,Position=Win.Pos+Vector2.new(W-14,BAR-14),Size=Vector2.new(10,10)})
    local wGrip2= d("Square",{Filled=true, ZIndex=20,Rounding=2,Color=T().Accent,Visible=true,Position=Win.Pos+Vector2.new(W-10,BAR-10),Size=Vector2.new(6,6)})

    th(function()
        wBg.Color=T().Bg; wBar.Color=T().Bar; wBBt.Color=T().Bar; wAcc.Color=T().Accent
        wOut.Color=T().GroupBorder; wTBg.Color=T().Bar; wTSep.Color=T().Sep; wTit.Color=T().Text; wGrip.Color=T().Dim; wGrip2.Color=T().Accent
    end)

    -- All chrome objects for proper visibility restore
    local chromeObjs = {wShd, wBg, wOut, wBar, wBBt, wAcc, wTBg, wTSep, wTit, wGrip, wGrip2}

    -- ── Visibility toggle (correct hide/restore) ───────────────────────────────
    local function setVisible(v)
        Win.Visible = v
        if not v then
            -- Hide everything with no exceptions
            for _, obj in ipairs(Library.Drawings) do
                pcall(function() obj.Visible = false end)
            end
        else
            -- Restore chrome
            for _, obj in ipairs(chromeObjs) do pcall(function() obj.Visible = true end) end
            -- Restore tab buttons
            for _, btn in ipairs(Win.Btns) do
                btn.bLbl.Visible = true
                btn.bInd.Visible = (Win.Active == btn.Tab)
            end
            -- Restore active tab groupbox items only
            if Win.Active then
                for _, gb in ipairs(Win.Active.L) do gb.setVis(true) end
                for _, gb in ipairs(Win.Active.R) do gb.setVis(true) end
            end
        end
    end

    -- ── Layout (handles dynamic multi-row tab strip) ───────────────────────────
    local function layout()
        -- Recalculate column width based on current window width so children reflow on resize
        COL = math.floor((W - PAD*2 - GAP) / 2)
        -- Calculate tab rows
        local tabRows, tx = 1, 10
        for _, btn in ipairs(Win.Btns) do
            if #Win.Btns > 1 and tx + btn.w > W - 10 then tx = 10; tabRows = tabRows + 1 end
            tx = tx + btn.w + 10
        end
        local dynTH   = TAB_RH * tabRows
        local dynHDR  = BAR + 2 + dynTH + 1
        local dynCONTY = dynHDR + 1 + PAD

        -- Chrome positions
        wShd.Position = fv(Win.Pos + Vector2.new(4, 4))
        wShd.Size     = fv(Vector2.new(W, dynTH + BAR + 3))
        wBg.Position  = fv(Win.Pos)
        wBar.Position = fv(Win.Pos)
        wBar.Size     = fv(Vector2.new(W, BAR))
        wOut.Position = fv(Win.Pos)
        wBBt.Position = fv(Win.Pos + Vector2.new(0, BAR-4))
        wBBt.Size     = fv(Vector2.new(W, 4))
        wAcc.Position = fv(Win.Pos + Vector2.new(0, BAR))
        wAcc.Size     = fv(Vector2.new(W, 2))
        wTBg.Position = fv(Win.Pos + Vector2.new(0, BAR+2))
        wTBg.Size     = fv(Vector2.new(W, dynTH))
        wTSep.Position= fv(Win.Pos + Vector2.new(0, dynHDR))
        wTSep.Size    = fv(Vector2.new(W, 1))
        wTit.Position = fv(Win.Pos + Vector2.new(13, 8))

        -- Tab button positions (wrap to next row when overflow)
        local bx, row = 10, 1
        for _, btn in ipairs(Win.Btns) do
            if bx + btn.w > W - 10 then bx = 10; row = row + 1 end
            local by = BAR + 2 + (row-1)*TAB_RH + math.floor((TAB_RH-14)/2)
            btn.setPos(fv(Win.Pos + Vector2.new(bx, by)))
            bx = bx + btn.w + 10
        end

        -- Content
        if not Win.Active then
            local targetH = math.max(dynCONTY + 50, userMinH)
            wBg.Size = fv(Vector2.new(W, targetH))
            wOut.Size = wBg.Size
            wShd.Size = fv(wBg.Size + Vector2.new(0, 2))
            wGrip.Position = fv(wBg.Position + wBg.Size - Vector2.new(14,14))
            wGrip2.Position = fv(wBg.Position + wBg.Size - Vector2.new(10,10))
            return
        end
        local lH, rH = 0, 0
        for _, gb in ipairs(Win.Active.L) do
            gb.setPos(fv(Win.Pos + Vector2.new(PAD, dynCONTY + lH)))
            lH = lH + gb.height() + PAD
        end
        for _, gb in ipairs(Win.Active.R) do
            gb.setPos(fv(Win.Pos + Vector2.new(PAD+COL+GAP, dynCONTY + rH)))
            rH = rH + gb.height() + PAD
        end
        local contentH = dynCONTY + math.max(lH, rH, 40) + PAD
        wBg.Size = fv(Vector2.new(W, math.max(contentH, userMinH)))
        wOut.Size = wBg.Size
        wShd.Size = fv(wBg.Size + Vector2.new(0, 2))
        -- Shadow visibility controlled by window setting (user can toggle)
        pcall(function() wShd.Visible = Win.ShadowEnabled end)
        wGrip.Position = fv(wBg.Position + wBg.Size - Vector2.new(14,14))
        wGrip2.Position = fv(wBg.Position + wBg.Size - Vector2.new(10,10))
    end

    -- Drag
    on(UserInputService.InputBegan, function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if over(wGrip.Position - Vector2.new(4,4), wGrip.Size + Vector2.new(8,8)) then
            Win.Resizing = true
            Win.ResizeStartMouse = UserInputService:GetMouseLocation()
            Win.ResizeStartSize = wBg.Size
            return
        end
        if over(Win.Pos, Vector2.new(W, BAR)) then
            Win.Dragging = true
            Win.DragOff = UserInputService:GetMouseLocation() - Win.Pos
        end
    end)
    on(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            Win.Dragging = false
            Win.Resizing = false
        end
    end)
    on(RunService.RenderStepped, function()
        if Win.Resizing then
            local delta = UserInputService:GetMouseLocation() - Win.ResizeStartMouse
            W = math.clamp(math.floor(Win.ResizeStartSize.X + delta.X), MIN_W, MAX_W)
            userMinH = math.max(MIN_H, math.floor(Win.ResizeStartSize.Y + delta.Y))
            layout()
        elseif Win.Dragging then
            Win.Pos = fv(UserInputService:GetMouseLocation() - Win.DragOff)
            layout()
        end
    end)

    -- Close dropdown when clicking outside it
    on(UserInputService.InputBegan, function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local clickOnAnyDropHeader = false
        for _, ref in ipairs(Win.DropBtns) do
            if ref.pos and ref.sz and (not ref.active or ref.active()) and over(ref.pos, ref.sz) then
                clickOnAnyDropHeader = true
                break
            end
        end
        if activeDD then
            if clickOnAnyDropHeader then return end
            local inList = activeDD.pos and activeDD.sz and over(activeDD.pos, activeDD.sz)
            local inBtn = activeDD.btnPos and activeDD.btnSz and over(activeDD.btnPos, activeDD.btnSz)
            if not inList and not inBtn then
                activeDD.close(); activeDD = nil
            end
        end
    end)

    -- ── Groupbox factory ──────────────────────────────────────────────────────
    local function makeGB(parentTab, side, name)
        local GH = 26  -- header row height
        local GP = 7   -- inner vertical padding
        local GB = {items={}, pos=Vector2.new()}

        local gBg  = d("Square",{Filled=true, ZIndex=14,Rounding=5,Color=T().GroupBg,     Visible=false,Size=Vector2.new(COL,GH)})
        local gOut = d("Square",{Filled=false,ZIndex=14,Rounding=5,Thickness=1,Color=T().GroupBorder,Visible=false,Size=Vector2.new(COL,GH)})
        local gHd  = d("Square",{Filled=true, ZIndex=15,Rounding=5,Color=T().GroupHead,   Visible=false,Size=Vector2.new(COL,GH)})
        local gHF  = d("Square",{Filled=true, ZIndex=15,Rounding=0,Color=T().GroupHead,   Visible=false,Size=Vector2.new(COL,5)})
        local gHL  = d("Square",{Filled=true, ZIndex=16,            Color=T().Sep,          Visible=false,Size=Vector2.new(COL,1)})
        local gTit = d("Text",  {Text=name,Size=13,Font=FONT,Outline=false,Color=T().Dim, Visible=false,ZIndex=16})
        th(function()
            gBg.Color=T().GroupBg; gOut.Color=T().GroupBorder; gHd.Color=T().GroupHead
            gHF.Color=T().GroupHead; gHL.Color=T().Sep; gTit.Color=T().Dim
        end)

        function GB.height()
            local h = GH + GP
            for _, it in ipairs(GB.items) do h = h + it.h end
            return h + GP
        end
        function GB.setVis(v)
            gBg.Visible=v; gOut.Visible=v; gHd.Visible=v; gHF.Visible=v; gHL.Visible=v; gTit.Visible=v
            for _, it in ipairs(GB.items) do it.setVis(v) end
        end
        function GB.setPos(p)
            GB.pos = p
            local h = GB.height()
            gBg.Position=p;  gBg.Size=fv(Vector2.new(COL,h))
            gOut.Position=p; gOut.Size=fv(Vector2.new(COL,h))
            gHd.Position=p;  gHd.Size=fv(Vector2.new(COL,GH))
            gHF.Position=fv(p+Vector2.new(0,GH-4)); gHF.Size=Vector2.new(COL,4)
            gHL.Position=fv(p+Vector2.new(0,GH));   gHL.Size=Vector2.new(COL,1)
            gTit.Position=fv(p+Vector2.new(10,7))
            local iy = GH + GP
            for _, it in ipairs(GB.items) do it.setPos(fv(p+Vector2.new(0,iy))); iy = iy + it.h end
        end

        local function addIt(it)
            table.insert(GB.items, it)
            if Win.Active == parentTab then it.setVis(true) end
            layout()
        end

        local Obj = {}

        -- Toggle ---------------------------------------------------------------
        function Obj:AddToggle(id, o)
            local txt = o.Text or id
            local st  = o.Default or false
            local iP  = Vector2.new()
            local isActive = false
            local lbl = d("Text",  {Text=txt,Size=14,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=20})
            local trk = d("Square",{Size=Vector2.new(32,17),Filled=true,ZIndex=20,Rounding=8,Color=st and T().TogOn or T().TogOff,Visible=false})
            local thb = d("Square",{Size=Vector2.new(13,13),Filled=true,ZIndex=21,Rounding=6,Color=T().Thumb,Visible=false})
            th(function() lbl.Color=T().Text; trk.Color=st and T().TogOn or T().TogOff; thb.Color=T().Thumb end)
            local function refresh()
                trk.Color = st and T().TogOn or T().TogOff
                thb.Position = fv(iP + Vector2.new(COL-44+(st and 16 or 2), 6))
            end
            local it = {h=28}
            function it.setVis(v) lbl.Visible=v; trk.Visible=v; thb.Visible=v; isActive=v end
            function it.setPos(p)
                iP=p; lbl.Position=fv(p+Vector2.new(IP,7))
                trk.Position=fv(p+Vector2.new(COL-44,5))
                thb.Position=fv(p+Vector2.new(COL-44+(st and 16 or 2),6))
            end
            local Tog = {State=st}
            on(UserInputService.InputBegan, function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Win.Active ~= parentTab or not isActive then return end
                if over(iP, Vector2.new(COL, 28)) then
                    st = not st; Tog.State = st; refresh()
                    if o.Callback then o.Callback(st) end
                end
            end)
            function Tog:AddColorPicker() return {OnChanged=function()end} end
            function Tog:AddKeyPicker()   return {OnChanged=function()end} end
            Library:_regCfg(id, function() return st end, function(v)
                st=v; Tog.State=v; refresh(); if o.Callback then o.Callback(v) end
            end)
            addIt(it)
            if o.Callback then task.spawn(o.Callback, st) end
            return Tog
        end

        -- Button ---------------------------------------------------------------
        function Obj:AddButton(o)
            local txt = type(o)=="table" and o.Text or tostring(o)
            local fn  = type(o)=="table" and o.Func or function() end
            local bW  = COL - IP*2
            local iP  = Vector2.new()
            local isActive = false
            local bg2 = d("Square",{Size=Vector2.new(bW,24),Filled=true,ZIndex=20,Rounding=4,Color=T().Btn,Visible=false})
            local lt  = d("Text",  {Text=txt,Size=14,Font=FONT,Outline=false,Center=true,Color=T().Text,ZIndex=21,Visible=false})
            th(function() bg2.Color=T().Btn; lt.Color=T().Text end)
            local it = {h=32}
            function it.setVis(v) bg2.Visible=v; lt.Visible=v; isActive=v end
            function it.setPos(p)
                iP=p; bg2.Position=fv(p+Vector2.new(IP,4))
                lt.Position=fv(p+Vector2.new(IP+bW/2, 8))
            end
            on(UserInputService.InputBegan, function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Win.Active ~= parentTab or not isActive then return end
                if over(bg2.Position, bg2.Size) then
                    bg2.Color = T().Accent; if fn then fn() end
                    task.delay(0.13, function() pcall(function() bg2.Color = T().Btn end) end)
                end
            end)
            addIt(it); return {}
        end

        -- Slider ---------------------------------------------------------------
        function Obj:AddSlider(id, o)
            local txt     = o.Text or id
            local mn, mx  = o.Min or 0, o.Max or 100
            local val     = o.Default or mn
            local sW      = COL - IP*2
            local iP      = Vector2.new()
            local drag    = false
            local isActive = false
            local lbl  = d("Text",  {Text=txt..": "..tostring(val),Size=14,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=20})
            local sBg  = d("Square",{Size=Vector2.new(sW,6),Filled=true,ZIndex=20,Rounding=3,Color=T().SlidBg,Visible=false})
            local sFll = d("Square",{Size=Vector2.new(((val-mn)/(mx-mn))*sW,6),Filled=true,ZIndex=21,Rounding=3,Color=T().Accent,Visible=false})
            local sThb = d("Square",{Size=Vector2.new(12,12),Filled=true,ZIndex=22,Rounding=6,Color=T().Thumb,Visible=false})
            th(function() lbl.Color=T().Text; sBg.Color=T().SlidBg; sFll.Color=T().Accent; sThb.Color=T().Thumb end)
            local function apply(pct)
                pct = math.clamp(pct, 0, 1)
                val = mn + (mx-mn)*pct
                if o.Rounding == 0 then val = math.floor(val) end
                local fw = math.max(pct*sW, 0)
                sFll.Size = Vector2.new(fw, 6)
                sThb.Position = fv(sBg.Position + Vector2.new(fw-6, -3))
                lbl.Text = txt..": "..tostring(math.floor(val*10)/10)
                if o.Callback then o.Callback(val) end
            end
            local Sld = {Value=val}
            local it = {h=48}
            function it.setVis(v) lbl.Visible=v; sBg.Visible=v; sFll.Visible=v; sThb.Visible=v; isActive=v end
            function it.setPos(p)
                iP=p; lbl.Position=fv(p+Vector2.new(IP,5))
                sBg.Position=fv(p+Vector2.new(IP,28))
                local pct2 = (val-mn)/(mx-mn)
                sFll.Position=sBg.Position; sFll.Size=Vector2.new(math.max(pct2*sW,0),6)
                sThb.Position=fv(p+Vector2.new(IP+pct2*sW-6,25))
            end
            on(UserInputService.InputBegan, function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Win.Active ~= parentTab or not isActive then return end
                if over(sBg.Position, Vector2.new(sW, 16)) then
                    drag=true; apply((UserInputService:GetMouseLocation().X-sBg.Position.X)/sW)
                end
            end)
            on(UserInputService.InputEnded, function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
            on(RunService.RenderStepped, function()
                if drag and Win.Active==parentTab and isActive then apply((UserInputService:GetMouseLocation().X-sBg.Position.X)/sW); Sld.Value=val end
            end)
            Library:_regCfg(id, function() return val end, function(v) val=v; Sld.Value=v; apply((v-mn)/(mx-mn)) end)
            addIt(it)
            if o.Callback then task.spawn(o.Callback, val) end
            return Sld
        end

        -- Label ----------------------------------------------------------------
        function Obj:AddLabel(txt)
            local lbl = d("Text",{Text=txt,Size=14,Font=FONT,Outline=false,Color=T().Dim,Visible=false,ZIndex=20})
            th(function() lbl.Color=T().Dim end)
            local isActive = false
            local it = {h=24}
            function it.setVis(v) lbl.Visible=v; isActive=v end
            function it.setPos(p) lbl.Position=fv(p+Vector2.new(IP,5)) end
            local Lbl = {}
            function Lbl:SetText(t) lbl.Text=t end
            function Lbl:AddKeyPicker(kid, ko)
                local defKey = ko and ko.Default or "Delete"
                local ok2, kc2 = pcall(function() return Enum.KeyCode[defKey] end)
                local kc = (ok2 and kc2) or Enum.KeyCode.Delete
                local listening = false; local kbW = 62
                local kbBg  = d("Square",{Size=Vector2.new(kbW,18),Filled=true,ZIndex=22,Rounding=3,Color=T().Btn,Visible=false})
                local kbTxt = d("Text",  {Text=keyName(kc),Size=12,Font=FONT,Outline=false,Center=true,Color=T().Text,Visible=false,ZIndex=23})
                th(function() kbBg.Color=listening and T().Accent or T().Btn; kbTxt.Color=T().Text end)
                local origP, origV = it.setPos, it.setVis
                function it.setPos(p)
                    origP(p)
                    kbBg.Position  = fv(p+Vector2.new(COL-kbW-IP, 3))
                    kbTxt.Position = fv(p+Vector2.new(COL-kbW/2-IP, 7))
                end
                function it.setVis(v) origV(v); kbBg.Visible=v; kbTxt.Visible=v end
                on(UserInputService.InputBegan, function(i)
                    if not isActive or Win.Active ~= parentTab then return end
                    if i.UserInputType==Enum.UserInputType.MouseButton1 and over(kbBg.Position, kbBg.Size) then
                        if activeBind then activeBind.cancel() end
                        listening=true; kbBg.Color=T().Accent; kbTxt.Text="..."
                        activeBind={cancel=function() listening=false; kbBg.Color=T().Btn; kbTxt.Text=keyName(kc); activeBind=nil end}
                        return
                    end
                    if listening and i.UserInputType==Enum.UserInputType.Keyboard then
                        if i.KeyCode==Enum.KeyCode.Escape then
                            listening=false; kbBg.Color=T().Btn; kbTxt.Text=keyName(kc); activeBind=nil
                        else
                            kc=i.KeyCode; listening=false; kbBg.Color=T().Btn; kbTxt.Text=keyName(kc); activeBind=nil
                            if ko and ko.Callback then ko.Callback(kc) end
                        end
                    end
                    if not listening and i.KeyCode==kc then if ko and ko.OnKey then ko.OnKey() end end
                end)
                Library:_regCfg(kid,
                    function() return tostring(kc) end,
                    function(v) local ok3,k3=pcall(function() return Enum.KeyCode[v] end); if ok3 and k3 then kc=k3; kbTxt.Text=keyName(kc) end end
                )
                return {OnChanged=function()end}
            end
            addIt(it); return Lbl
        end

        -- Dropdown (real overlay list) -----------------------------------------
        function Obj:AddDropdown(id, o)
            local txt   = o.Text or id
            local vals  = o.Values or {}
            local multi = o.Multi
            local val   = o.Default
            local dW    = COL - IP*2
            local iP    = Vector2.new()
            local isOpen = false
            local isActive = false
            local ddBtnRef = {
                pos=nil,
                sz=nil,
                active=function() return isActive and Win.Active == parentTab end,
            }
            table.insert(Win.DropBtns, ddBtnRef)
            -- Default to first value for single-select
            if not multi and val==nil and vals[1] then val=vals[1] end

            local lbl  = d("Text",  {Text=txt,Size=14,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=20})
            local dBg  = d("Square",{Size=Vector2.new(dW,24),Filled=true,ZIndex=20,Rounding=4,Color=T().Btn,Visible=false,Position=Vector2.new(0,0)})
            local dVal = d("Text",  {Size=13,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=21})
            local dArr = d("Text",  {Text="▾",Size=12,Font=FONT,Outline=false,Color=T().Dim,Visible=false,ZIndex=21})
            th(function() lbl.Color=T().Text; dBg.Color=isOpen and T().Accent or T().Btn; dVal.Color=T().Text; dArr.Color=T().Dim end)

            local function display()
                if multi then
                    local p={}; for k,v in pairs(val or {}) do if v then table.insert(p,tostring(k)) end end
                    table.sort(p)
                    if #p==0 then return "None" end
                    return #p<=2 and table.concat(p,", ") or (p[1]..", "..p[2].." +"..#p-2)
                end
                local s = tostring(val or "None")
                return #s>22 and s:sub(1,20).."…" or s
            end
            dVal.Text = display()

            -- Overlay pool (MAXDD rows, created once, shown/hidden)
            local pool = {}
            for _=1,MAXDD do
                local row = {
                    bg  = d("Square",{Filled=true, ZIndex=92,Rounding=0,Color=T().DropItem,Visible=false,Position=Vector2.new(0,0),Size=Vector2.new(1,DD_H)}),
                    chk = d("Square",{Filled=true, ZIndex=94,Rounding=2,Color=T().Accent,  Visible=false,Size=Vector2.new(10,10)}),
                    box = d("Square",{Filled=false,ZIndex=94,Rounding=2,Thickness=1,Color=T().Dim,Visible=false,Size=Vector2.new(10,10)}),
                    txt = d("Text",  {Size=13,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=93,Position=Vector2.new(0,0)}),
                }
                th(function() row.bg.Color=T().DropItem; row.chk.Color=T().Accent; row.box.Color=T().Dim; row.txt.Color=T().Text end)
                table.insert(pool, row)
            end
            local lBg  = d("Square",{Filled=true, ZIndex=90,Rounding=5,Color=T().DropBg,      Visible=false,Position=Vector2.new(0,0),Size=Vector2.new(1,1)})
            local lOut = d("Square",{Filled=false,ZIndex=91,Rounding=5,Thickness=1,Color=T().GroupBorder,Visible=false,Position=Vector2.new(0,0),Size=Vector2.new(1,1)})
            th(function() lBg.Color=T().DropBg; lOut.Color=T().GroupBorder end)

            local function closeDD()
                isOpen=false; dBg.Color=T().Btn; dArr.Text="▾"
                lBg.Visible=false; lOut.Visible=false
                for _,row in ipairs(pool) do
                    row.bg.Visible=false; row.chk.Visible=false; row.box.Visible=false; row.txt.Visible=false
                end
                -- clear active reference so other dropdowns can respond
                pcall(function() Win._activeDropRef = nil end)
            end

            local function openDD()
                if not dBg or not dBg.Position or dBg.Position == Vector2.new(0,0) then return end
                if activeDD then activeDD.close(); activeDD=nil end
                isOpen=true; pcall(function() dBg.Color=T().Accent end); dArr.Text="▴"
                local count  = math.min(#vals, MAXDD)
                local scrollIndex = 1
                if count == 0 then return end  -- No items to show
                local listH  = count * DD_H + 6
                local vp     = pcall(function() return workspace.CurrentCamera.ViewportSize end) and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
                local baseY  = dBg.Position.Y + dBg.Size.Y + 3
                if baseY + listH > vp.Y - 10 then baseY = dBg.Position.Y - listH - 3 end
                local lx, lw = dBg.Position.X, dBg.Size.X
                lBg.Position =fv(Vector2.new(lx,baseY)); lBg.Size =fv(Vector2.new(lw,listH))
                lOut.Position=fv(Vector2.new(lx,baseY)); lOut.Size=fv(Vector2.new(lw,listH))
                lBg.Visible=true; lOut.Visible=true
                -- show the first `count` rows; scrolling will offset this window over `vals`
                for i=1, count do
                    local row = pool[i]
                    local v = vals[i]
                    if v then
                        local ry  = baseY + 3 + (i-1)*DD_H
                        local sel = multi and (type(val)=="table" and val[v]==true) or (val==v)
                        row.bg.Position=fv(Vector2.new(lx,ry)); row.bg.Size=Vector2.new(lw,DD_H)
                        row.bg.Color   = sel and T().DropSel or T().DropItem
                        row.bg.Visible = true
                        if multi then
                            local cx,cy = lx+6, ry+(DD_H-10)/2
                            if sel then
                                row.chk.Position=fv(Vector2.new(cx,cy)); row.chk.Visible=true; row.box.Visible=false
                            else
                                row.box.Position=fv(Vector2.new(cx,cy)); row.box.Visible=true; row.chk.Visible=false
                            end
                            row.txt.Position = fv(Vector2.new(lx+22, ry+(DD_H-13)/2))
                        else
                            row.chk.Visible=false; row.box.Visible=false
                            row.txt.Position = fv(Vector2.new(lx+10, ry+(DD_H-13)/2))
                        end
                        row.txt.Text=tostring(v); row.txt.Visible=true
                    end
                end
                -- scrolling state (1-based start index into vals)
                local scrollState = {index = 1, visible = count}
                activeDD = {
                    close=closeDD,
                    pos=fv(Vector2.new(lx,baseY)),
                    sz=fv(Vector2.new(lw,listH)),
                    btnPos=dBg.Position,
                    btnSz=dBg.Size,
                    scroll=scrollState,
                }
                -- mark this dropdown's button ref as the current active dropdown
                pcall(function() Win._activeDropRef = ddBtnRef end)
            end

            local it = {h=52}
            function it.setVis(v)
                lbl.Visible=v; dBg.Visible=v; dVal.Visible=v; dArr.Visible=v
                isActive=v
                if not v and isOpen then closeDD(); activeDD=nil end
            end
            function it.setPos(p)
                iP=p; lbl.Position=fv(p+Vector2.new(IP,5))
                -- compute current dropdown width based on current column width so it reflows on resize
                local curDW = math.max(48, COL - IP*2)
                dBg.Position=fv(p+Vector2.new(IP,24))
                dBg.Size = fv(Vector2.new(curDW,24))
                dVal.Position=fv(p+Vector2.new(IP+7,28))
                dArr.Position=fv(p+Vector2.new(IP+curDW-14,28))
                ddBtnRef.pos = dBg.Position
                ddBtnRef.sz  = dBg.Size
            end

            on(UserInputService.InputBegan, function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Win.Active ~= parentTab or not isActive then return end
                -- Toggle the header button
                if dBg and dBg.Position and dBg.Size and over(dBg.Position, dBg.Size) then
                    -- if another dropdown is currently open, ignore header clicks on this one
                    if activeDD and Win._activeDropRef and Win._activeDropRef ~= ddBtnRef then return end
                    if isOpen then closeDD(); activeDD=nil else openDD() end
                    return
                end
                -- Click a list item
                if isOpen then
                    local scrollIdx = activeDD and activeDD.scroll and activeDD.scroll.index or 1
                    for idx, row in ipairs(pool) do
                        local actualIdx = scrollIdx + idx - 1
                        if vals[actualIdx] and over(row.bg.Position, row.bg.Size) then
                            local v = vals[actualIdx]
                            if multi then
                                if type(val) ~= "table" then val={} end
                                -- Toggle: set to true if not set, remove if true
                                if val[v] then val[v]=nil else val[v]=true end
                                dVal.Text = display()
                                openDD()  -- refresh list in place (will re-evaluate visible window)
                            else
                                val=v; dVal.Text=display(); closeDD(); activeDD=nil
                            end
                            if o.Callback then o.Callback(val) end
                            break
                        end
                    end
                end
            end)

            -- Hover highlight on RenderStepped
            on(RunService.RenderStepped, function()
                if not isOpen then return end
                local scrollIdx = activeDD and activeDD.scroll and activeDD.scroll.index or 1
                for idx, row in ipairs(pool) do
                    local actualIdx = scrollIdx + idx - 1
                    local v = vals[actualIdx]
                    if v and row.bg.Visible then
                        local sel = multi and (type(val)=="table" and val[v]==true) or (val==v)
                        row.bg.Color = over(row.bg.Position, row.bg.Size) and T().DropHover or (sel and T().DropSel or T().DropItem)
                        row.txt.Text = tostring(v)
                    end
                end
            end)

            -- Mouse wheel to scroll dropdown when open
            on(UserInputService.InputChanged, function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseWheel then return end
                if not activeDD or not isOpen then return end
                -- only scroll when mouse is over the list area or the dropdown button
                local overList = activeDD.pos and activeDD.sz and over(activeDD.pos, activeDD.sz)
                local overBtn = activeDD.btnPos and activeDD.btnSz and over(activeDD.btnPos, activeDD.btnSz)
                if not overList and not overBtn then return end
                local s = activeDD.scroll
                if not s then return end
                local delta = 0
                if i.Position and i.Position.Z then
                    if i.Position.Z > 0 then delta = -1 elseif i.Position.Z < 0 then delta = 1 end
                end
                if delta == 0 then return end
                local maxStart = math.max(1, #vals - s.visible + 1)
                s.index = math.clamp(s.index + delta, 1, maxStart)
                -- refresh visible rows according to new s.index
                local lx, lw = dBg.Position.X, dBg.Size.X
                local baseY = activeDD.pos.Y
                for i=1, s.visible do
                    local row = pool[i]
                    local actual = s.index + i - 1
                    local v = vals[actual]
                    if v then
                        local ry = baseY + 3 + (i-1)*DD_H
                        row.bg.Position = fv(Vector2.new(lx, ry)); row.bg.Size = Vector2.new(lw, DD_H)
                        local sel = multi and (type(val)=="table" and val[v]==true) or (val==v)
                        row.bg.Color = sel and T().DropSel or T().DropItem
                        row.bg.Visible = true
                        if multi then
                            local cx,cy = lx+6, ry+(DD_H-10)/2
                            if sel then row.chk.Position=fv(Vector2.new(cx,cy)); row.chk.Visible=true; row.box.Visible=false
                            else row.box.Position=fv(Vector2.new(cx,cy)); row.box.Visible=true; row.chk.Visible=false end
                            row.txt.Position = fv(Vector2.new(lx+22, ry+(DD_H-13)/2))
                        else
                            row.chk.Visible=false; row.box.Visible=false
                            row.txt.Position = fv(Vector2.new(lx+10, ry+(DD_H-13)/2))
                        end
                        row.txt.Text = tostring(v); row.txt.Visible=true
                    else
                        row.bg.Visible = false; row.chk.Visible=false; row.box.Visible=false; row.txt.Visible=false
                    end
                end
                -- update activeDD scroll state
                activeDD.scroll = s
            end)

            local Drop = {}
            function Drop:SetValues(v)
                vals=v; if not multi then val=v[1] end; dVal.Text=display()
                if isOpen then openDD() end
            end
            Library:_regCfg(id,
                function() return val end,
                function(v) val=v; dVal.Text=display(); if o.Callback then o.Callback(val) end end
            )
            addIt(it)
            if o.Callback then task.spawn(o.Callback, val) end
            return Drop
        end

        -- Keybind --------------------------------------------------------------
        function Obj:AddKeybind(id, o)
            local txt = o.Text or id
            local ok2, kc2 = pcall(function() return Enum.KeyCode[o.Default or "Unknown"] end)
            local kc = (ok2 and kc2) or Enum.KeyCode.Unknown
            local listening = false; local kbW = 64
            local isActive = false
            local lbl   = d("Text",  {Text=txt,Size=14,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=20})
            local kbBg  = d("Square",{Size=Vector2.new(kbW,20),Filled=true,ZIndex=20,Rounding=3,Color=T().Btn,Visible=false})
            local kbTxt = d("Text",  {Text=keyName(kc),Size=12,Font=FONT,Outline=false,Center=true,Color=T().Text,Visible=false,ZIndex=21})
            th(function() lbl.Color=T().Text; kbBg.Color=listening and T().Accent or T().Btn; kbTxt.Color=T().Text end)
            local it = {h=28}
            function it.setVis(v) lbl.Visible=v; kbBg.Visible=v; kbTxt.Visible=v; isActive=v end
            function it.setPos(p)
                lbl.Position  = fv(p+Vector2.new(IP,7))
                kbBg.Position = fv(p+Vector2.new(COL-kbW-IP,4))
                kbTxt.Position= fv(p+Vector2.new(COL-kbW/2-IP,8))
            end
            local Bind = {Value=kc}
            on(UserInputService.InputBegan, function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 and over(kbBg.Position, kbBg.Size) and Win.Active==parentTab and isActive then
                    if activeBind then activeBind.cancel() end
                    listening=true; kbBg.Color=T().Accent; kbTxt.Text="..."
                    activeBind={cancel=function() listening=false; kbBg.Color=T().Btn; kbTxt.Text=keyName(kc); activeBind=nil end}
                    return
                end
                if listening and i.UserInputType==Enum.UserInputType.Keyboard then
                    if i.KeyCode==Enum.KeyCode.Escape then
                        listening=false; kbBg.Color=T().Btn; kbTxt.Text=keyName(kc); activeBind=nil
                    else
                        kc=i.KeyCode; Bind.Value=kc; listening=false; kbBg.Color=T().Btn; kbTxt.Text=keyName(kc); activeBind=nil
                        if o.Callback then o.Callback(kc) end
                    end
                end
                if not listening and i.KeyCode==kc then if o.OnKey then o.OnKey() end end
            end)
            Library:_regCfg(id,
                function() return tostring(kc) end,
                function(v) local ok3,k3=pcall(function() return Enum.KeyCode[v] end); if ok3 and k3 then kc=k3; Bind.Value=kc; kbTxt.Text=keyName(kc) end end
            )
            addIt(it); return Bind
        end

        -- Input stub -----------------------------------------------------------
        function Obj:AddInput(id, o)
            local txt = o and o.Text or id; local cur = o and o.Default or ""
            local lbl = d("Text",{Text=txt..": ["..cur.."]",Size=14,Font=FONT,Outline=false,Color=T().Dim,Visible=false,ZIndex=20})
            th(function() lbl.Color=T().Dim end)
            local it={h=24}
            function it.setVis(v) lbl.Visible=v end
            function it.setPos(p) lbl.Position=fv(p+Vector2.new(IP,5)) end
            local Inp={}
            function Inp:SetValue(v) cur=v; lbl.Text=txt..": ["..cur.."]"; if o and o.Callback then o.Callback(v) end end
            addIt(it); return Inp
        end

        if side=="left" then table.insert(parentTab.L,GB) else table.insert(parentTab.R,GB) end
        layout(); return Obj
    end

    -- ── AddTab ────────────────────────────────────────────────────────────────
    function Win:AddTab(name)
        local Tab = {L={}, R={}, Name=name}
        table.insert(Win.Tabs, Tab)
        local tw   = math.floor(#name * 6.5) + 12
        local btn  = {w=tw, Tab=Tab}
        local bP   = Vector2.new()
        local bLbl = d("Text",  {Text=name,Size=12,Font=FONT,Outline=false,Color=Win.Active==Tab and T().TabOn or T().TabOff,Visible=true,ZIndex=18})
        local bInd = d("Square",{Size=Vector2.new(tw,2),Filled=true,ZIndex=18,Color=T().Accent,Visible=Win.Active==Tab})
        th(function() bLbl.Color=(Win.Active==Tab) and T().TabOn or T().TabOff; bInd.Color=T().Accent end)

        function btn.setPos(p)
            bP=p; bLbl.Position=p; bInd.Position=fv(p+Vector2.new(0,16))
        end

        local function activate()
                -- Close any active dropdown and binding listener
                if activeDD then activeDD.close(); activeDD=nil end
                if activeBind then activeBind.cancel(); activeBind=nil end
                
                -- Hide old tab completely
                for _, ob in ipairs(Win.Btns) do
                    if ob.Tab then
                        for _,gb in ipairs(ob.Tab.L) do gb.setVis(false) end
                        for _,gb in ipairs(ob.Tab.R) do gb.setVis(false) end
                        ob.bLbl.Color=T().TabOff; ob.bInd.Visible=false
                    end
                end
                
                -- Set active tab
                Win.Active=Tab
                
                -- Force layout to recalculate positions
                layout()
                
                -- Explicitly re-position all items in new tab before making visible
                for _,gb in ipairs(Tab.L) do gb.setPos(gb.pos) end
                for _,gb in ipairs(Tab.R) do gb.setPos(gb.pos) end
                
                -- Now show new tab
                for _,gb in ipairs(Tab.L) do gb.setVis(true) end
                for _,gb in ipairs(Tab.R) do gb.setVis(true) end
                bLbl.Color=T().TabOn; bInd.Visible=true
        end

        btn.bLbl=bLbl; btn.bInd=bInd
        on(UserInputService.InputBegan, function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if over(bP, Vector2.new(tw, TAB_RH)) then activate() end
        end)
        table.insert(Win.Btns, btn)
        if not Win.Active then Win.Active=Tab; bLbl.Color=T().TabOn; bInd.Visible=true end
        function Tab:AddLeftGroupbox(n)  return makeGB(Tab,"left", n) end
        function Tab:AddRightGroupbox(n) return makeGB(Tab,"right",n) end
        layout(); return Tab
    end

    -- Expose visibility toggle on window
    function Win:SetVisible(v)
        setVisible(v)
    end

    -- Allow toggling the backdrop shadow (user preference)
    function Win:SetShadowEnabled(v)
        Win.ShadowEnabled = not not v
        pcall(function() wShd.Visible = Win.ShadowEnabled end)
        layout()
    end

    function Win:SetShadowTransparency(v)
        local n = tonumber(v) or 0
        n = math.clamp(n, 0, 1)
        Win.ShadowTransparency = n
        pcall(function() wShd.Transparency = n end)
    end

    -- Persist shadow settings through the library config API
    pcall(function()
        Library:_regCfg('WindowShadow', function() return Win.ShadowEnabled end, function(v) Win:SetShadowEnabled(v) end)
        Library:_regCfg('WindowShadowAlpha', function() return Win.ShadowTransparency end, function(v) Win:SetShadowTransparency(v) end)
    end)

    layout(); return Win
end

-- ── Notify & Unload ───────────────────────────────────────────────────────────
function Library:Notify(text, _duration)
    print("[BHub]", text)
end

function Library:Unload()
    for _,c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
    for _,o in ipairs(Library.Drawings)   do pcall(function() o:Remove() end) end
    Library.Connections={}; Library.Drawings={}; Library.ThemeUpdaters={}; Library.ConfigData={}
    activeDD=nil; activeBind=nil
end

return Library

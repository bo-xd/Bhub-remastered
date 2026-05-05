-- BHub Library Cache Setup (Real Libraries)
-- Run this once to cache the REAL DrawingUILib and Esp for any BHub game
-- This uses the actual full-featured libraries from src/util/

local function writeLib(filename, content)
    if writefile then
        pcall(function()
            if not isfolder("bhub_cache") then
                makefolder("bhub_cache")
            end
            writefile("bhub_cache/" .. filename, content)
            print("[BHub Cache] Wrote " .. filename .. " (" .. #content .. " bytes)")
        end)
    else
        print("[BHub Cache] writefile not available - skipping")
    end
end

-- REAL DrawingUILib - Full featured (from src/util/DrawingUILib.lua)
local DrawingUILibCode = [[local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local Library = {}
Library.Drawings      = {}
Library.Connections   = {}
Library.ThemeUpdaters = {}
Library.ConfigData    = {}
Library.CurrentThemeName = "Default"

local FONT = 0  

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

local baseTransMap = {}
local notifyList = {}

local function T()   return Library.Themes[Library.CurrentThemeName] end
local function th(f) table.insert(Library.ThemeUpdaters, f) end

local function d(class, props)
    local obj = Drawing.new(class)
    baseTransMap[obj] = props.Transparency or 1
    for k,v in pairs(props) do pcall(function() obj[k]=v end) end
    table.insert(Library.Drawings, obj)
    return obj
end

local function removeDrawing(obj)
    pcall(function() obj.Visible = false end)
    pcall(function() obj:Remove() end)
    for i = #Library.Drawings, 1, -1 do
        if Library.Drawings[i] == obj then
            table.remove(Library.Drawings, i)
            break
        end
    end
    baseTransMap[obj] = nil
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

on(RunService.RenderStepped, function(dt)
    local vp = workspace.CurrentCamera.ViewportSize
    local currentY = vp.Y - 20 
    
    for i = #notifyList, 1, -1 do
        local notif = notifyList[i]
        currentY = currentY - notif.h - 10 
        notif.targetY = currentY
        
        notif.currentY = notif.currentY + (notif.targetY - notif.currentY) * 12 * dt
        
        local x = vp.X - notif.w - 20
        local y = notif.currentY
        
        pcall(function()
            notif.objs.bg.Position = Vector2.new(x, y)
            notif.objs.out.Position = Vector2.new(x, y)
            notif.objs.acc.Position = Vector2.new(x, y)
            notif.objs.txt.Position = Vector2.new(x + 12, y + (notif.h - notif.objs.txt.TextBounds.Y)/2)
            
            notif.objs.bg.Color = T().GroupBg
            notif.objs.out.Color = T().GroupBorder
            notif.objs.acc.Color = T().Accent
            notif.objs.txt.Color = T().Text
        end)
        
        if tick() - notif.createdAt >= notif.duration and not notif.fadingOut then
            notif.fadingOut = true
            task.spawn(function()
                for j = 1, 10 do
                    local a = 1 - (j/10)
                    pcall(function()
                        notif.objs.bg.Transparency = a; notif.objs.out.Transparency = a
                        notif.objs.acc.Transparency = a; notif.objs.txt.Transparency = a
                    end)
                    task.wait(0.015)
                end
                removeDrawing(notif.objs.bg); removeDrawing(notif.objs.out)
                removeDrawing(notif.objs.acc); removeDrawing(notif.objs.txt)
            end)
        end
    end
    
    for i = #notifyList, 1, -1 do
        if notifyList[i].fadingOut and tick() - notifyList[i].createdAt > notifyList[i].duration + 0.5 then
            table.remove(notifyList, i)
        end
    end
end)

function Library:Notify(text, duration)
    duration = duration or 3
    
    local txt = d("Text", {Text=text, Size=14, Font=FONT, Outline=false, Color=T().Text, Visible=true, ZIndex=102})
    local bounds = txt.TextBounds
    local w = bounds.X + 26
    local h = 30
    
    local bg = d("Square", {Filled=true, ZIndex=100, Rounding=4, Color=T().GroupBg, Visible=true})
    local out = d("Square", {Filled=false, ZIndex=100, Rounding=4, Thickness=1, Color=T().GroupBorder, Visible=true})
    local acc = d("Square", {Filled=true, ZIndex=101, Rounding=0, Color=T().Accent, Visible=true})
    
    baseTransMap[bg] = 1; baseTransMap[out] = 1; baseTransMap[acc] = 1; baseTransMap[txt] = 1
    bg.Transparency = 0; out.Transparency = 0; acc.Transparency = 0; txt.Transparency = 0
    
    local vp = workspace.CurrentCamera.ViewportSize
    local startY = vp.Y + h 
    
    bg.Size = Vector2.new(w, h); out.Size = Vector2.new(w, h); acc.Size = Vector2.new(2, h)
    
    local notif = {
        targetY = startY, currentY = startY, createdAt = tick(),
        duration = duration, fadingOut = false, w = w, h = h,
        objs = {bg=bg, out=out, acc=acc, txt=txt}
    }
    
    table.insert(notifyList, notif)
    
    task.spawn(function()
        for i = 1, 10 do
            local a = i/10
            pcall(function() bg.Transparency=a; out.Transparency=a; acc.Transparency=a; txt.Transparency=a end)
            task.wait(0.015)
        end
    end)
end

function Library:SetTheme(name)
    if not Library.Themes[name] then return end
    Library.CurrentThemeName = name
    for _,fn in ipairs(Library.ThemeUpdaters) do pcall(fn) end
end

function Library:_regCfg(id, getFn, setFn)
    if id and id ~= "" then Library.ConfigData[id] = {get=getFn, set=setFn} end
end

function Library:CreateWindow(opts)
    local title   = opts.Title or "BHub"
    local BASE_W  = 520
    local W       = BASE_W         
    local BAR     = 32            
    local TAB_RH  = 26            
    local PAD     = 8
    local GAP     = 6
    local COL     = math.floor((W - PAD*2 - GAP) / 2)
    local IP      = 8             
    local MAXDD   = 14            
    local DD_H    = 22            
    local MIN_W   = BASE_W
    local MAX_W   = 900
    local MIN_H   = 300
    local userMinH = 0

    local Win = {
        Pos=Vector2.new(100,100), Tabs={}, Active=nil,
        Dragging=false, Resizing=false, DragOff=Vector2.new(), ResizeStartMouse=Vector2.new(), ResizeStartSize=Vector2.new(), Btns={}, DropBtns={}, Visible=true,
        ShadowEnabled = true,
    }

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

    local chromeObjs = {wShd, wBg, wOut, wBar, wBBt, wAcc, wTBg, wTSep, wTit, wGrip, wGrip2}

    local isAnimating = false
    local function setVisible(v)
        if isAnimating or Win.Visible == v then return end
        isAnimating = true
        Win.Visible = v

        if not v then
            local activeObjs = {}
            for _, obj in ipairs(Library.Drawings) do
                if obj.Visible then table.insert(activeObjs, obj) end
            end
            
            for i = 1, 10 do
                local a = 1 - (i/10)
                for _, obj in ipairs(activeObjs) do
                    pcall(function() obj.Transparency = (baseTransMap[obj] or 1) * a end)
                end
                task.wait(0.015)
            end
            
            for _, obj in ipairs(Library.Drawings) do
                pcall(function() obj.Visible = false end)
                pcall(function() obj.Transparency = (baseTransMap[obj] or 1) end)
            end
        else
            for _, obj in ipairs(chromeObjs) do pcall(function() obj.Visible = true end) end
            for _, btn in ipairs(Win.Btns) do
                btn.bLbl.Visible = true; btn.bInd.Visible = (Win.Active == btn.Tab)
            end
            if Win.Active then
                for _, gb in ipairs(Win.Active.L) do gb.setVis(true) end
                for _, gb in ipairs(Win.Active.R) do gb.setVis(true) end
            end
            
            local activeObjs = {}
            for _, obj in ipairs(Library.Drawings) do
                if obj.Visible then 
                    pcall(function() obj.Transparency = 0 end)
                    table.insert(activeObjs, obj) 
                end
            end
            
            for i = 1, 10 do
                local a = (i/10)
                for _, obj in ipairs(activeObjs) do
                    pcall(function() obj.Transparency = (baseTransMap[obj] or 1) * a end)
                end
                task.wait(0.015)
            end
            
            for _, obj in ipairs(activeObjs) do
                pcall(function() obj.Transparency = (baseTransMap[obj] or 1) end)
            end
        end
        isAnimating = false
    end

    local function layout()
        COL = math.floor((W - PAD*2 - GAP) / 2)
        local tabRows, tx = 1, 10
        for _, btn in ipairs(Win.Btns) do
            if #Win.Btns > 1 and tx + btn.w > W - 10 then tx = 10; tabRows = tabRows + 1 end
            tx = tx + btn.w + 10
        end
        local dynTH   = TAB_RH * tabRows
        local dynHDR  = BAR + 2 + dynTH + 1
        local dynCONTY = dynHDR + 1 + PAD

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

        local bx, row = 10, 1
        for _, btn in ipairs(Win.Btns) do
            if bx + btn.w > W - 10 then bx = 10; row = row + 1 end
            local by = BAR + 2 + (row-1)*TAB_RH + math.floor((TAB_RH-14)/2)
            btn.setPos(fv(Win.Pos + Vector2.new(bx, by)))
            bx = bx + btn.w + 10
        end

        if not Win.Active then
            local targetH = math.max(dynCONTY + 50, userMinH)
            wBg.Size = fv(Vector2.new(W, targetH)); wOut.Size = wBg.Size
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
        pcall(function() wShd.Visible = Win.ShadowEnabled end)
        wGrip.Position = fv(wBg.Position + wBg.Size - Vector2.new(14,14))
        wGrip2.Position = fv(wBg.Position + wBg.Size - Vector2.new(10,10))
    end

    on(UserInputService.InputBegan, function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if over(wGrip.Position - Vector2.new(4,4), wGrip.Size + Vector2.new(8,8)) then
            Win.Resizing = true; Win.ResizeStartMouse = UserInputService:GetMouseLocation()
            Win.ResizeStartSize = wBg.Size; return
        end
        if over(Win.Pos, Vector2.new(W, BAR)) then
            Win.Dragging = true; Win.DragOff = UserInputService:GetMouseLocation() - Win.Pos
        end
    end)
    on(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then Win.Dragging = false; Win.Resizing = false end
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

    on(UserInputService.InputBegan, function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local clickOnAnyDropHeader = false
        for _, ref in ipairs(Win.DropBtns) do
            if ref.pos and ref.sz and (not ref.active or ref.active()) and over(ref.pos, ref.sz) then
                clickOnAnyDropHeader = true; break
            end
        end
    end)

    local activeDD   = nil  
    local activeBind = nil 

    local function makeGB(parentTab, side, name)
        local GH = 26
        local GP = 7
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
            Library:_regCfg(id, function() return st end, function(v)
                st=v; Tog.State=v; refresh(); if o.Callback then o.Callback(v) end
            end)
            addIt(it)
            if o.Callback then task.spawn(o.Callback, st) end
            return Tog
        end

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

        function Obj:AddLabel(txt)
            local lbl = d("Text",{Text=txt,Size=14,Font=FONT,Outline=false,Color=T().Dim,Visible=false,ZIndex=20})
            th(function() lbl.Color=T().Dim end)
            local isActive = false
            local it = {h=24}
            function it.setVis(v) lbl.Visible=v; isActive=v end
            function it.setPos(p) lbl.Position=fv(p+Vector2.new(IP,5)) end
            local Lbl = {}
            function Lbl:SetText(t) lbl.Text=t end
            addIt(it); return Lbl
        end

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

        function Obj:AddDropdown(id, o)
            local txt   = o.Text or id
            local vals  = o.Values or {}
            local val   = o.Default
            local dW    = COL - IP*2
            local iP    = Vector2.new()
            local isOpen = false
            local isActive = false
            if val==nil and vals[1] then val=vals[1] end

            local lbl  = d("Text",  {Text=txt,Size=14,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=20})
            local dBg  = d("Square",{Size=Vector2.new(dW,24),Filled=true,ZIndex=20,Rounding=4,Color=T().Btn,Visible=false})
            local dVal = d("Text",  {Size=13,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=21})
            th(function() lbl.Color=T().Text; dBg.Color=isOpen and T().Accent or T().Btn; dVal.Color=T().Text end)

            local function display()
                local s = tostring(val or "None")
                return #s>22 and s:sub(1,20).."…" or s
            end
            dVal.Text = display()

            local it = {h=52}
            function it.setVis(v) lbl.Visible=v; dBg.Visible=v; dVal.Visible=v; isActive=v end
            function it.setPos(p)
                iP=p; lbl.Position=fv(p+Vector2.new(IP,5))
                local curDW = math.max(48, COL - IP*2)
                dBg.Position=fv(p+Vector2.new(IP,24))
                dBg.Size = fv(Vector2.new(curDW,24))
                dVal.Position=fv(p+Vector2.new(IP+7,28))
            end

            on(UserInputService.InputBegan, function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Win.Active ~= parentTab or not isActive then return end
                if dBg and dBg.Position and dBg.Size and over(dBg.Position, dBg.Size) then
                    if vals[1] then
                        val = vals[1]; dVal.Text = display()
                        if o.Callback then o.Callback(val) end
                    end
                end
            end)

            local Drop = {}
            function Drop:SetValues(v) vals=v; val=v[1]; dVal.Text=display() end
            Library:_regCfg(id, function() return val end, function(v) val=v; dVal.Text=display(); if o.Callback then o.Callback(val) end end)
            addIt(it); if o.Callback then task.spawn(o.Callback, val) end
            return Drop
        end

        if side=="left" then table.insert(parentTab.L,GB) else table.insert(parentTab.R,GB) end
        layout(); return Obj
    end

    function Win:AddTab(name)
        local Tab = {L={}, R={}, Name=name}
        table.insert(Win.Tabs, Tab)
        local tw   = math.floor(#name * 6.5) + 12
        local btn  = {w=tw, Tab=Tab}
        local bP   = Vector2.new()
        local bLbl = d("Text",  {Text=name,Size=12,Font=FONT,Outline=false,Color=Win.Active==Tab and T().TabOn or T().TabOff,Visible=true,ZIndex=18})
        local bInd = d("Square",{Size=Vector2.new(tw,2),Filled=true,ZIndex=18,Color=T().Accent,Visible=Win.Active==Tab})
        th(function() bLbl.Color=(Win.Active==Tab) and T().TabOn or T().TabOff; bInd.Color=T().Accent end)

        function btn.setPos(p) bP=p; bLbl.Position=p; bInd.Position=fv(p+Vector2.new(0,16)) end

        local function activate()
            for _, ob in ipairs(Win.Btns) do
                if ob.Tab then
                    for _,gb in ipairs(ob.Tab.L) do gb.setVis(false) end
                    for _,gb in ipairs(ob.Tab.R) do gb.setVis(false) end
                    ob.bLbl.Color=T().TabOff; ob.bInd.Visible=false
                end
            end
            Win.Active=Tab
            layout()
            for _,gb in ipairs(Tab.L) do gb.setPos(gb.pos) end
            for _,gb in ipairs(Tab.R) do gb.setPos(gb.pos) end
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

    function Win:SetVisible(v) setVisible(v) end
    function Win:SetShadowEnabled(v) Win.ShadowEnabled = not not v; pcall(function() wShd.Visible = Win.ShadowEnabled end); layout() end
    function Win:SetShadowTransparency(v) local n = tonumber(v) or 0; n = math.clamp(n, 0, 1); Win.ShadowTransparency = n; baseTransMap[wShd] = n; pcall(function() wShd.Transparency = n end) end

    layout(); return Win
end

function Library:Unload()
    for _,c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
    for _,o in ipairs(Library.Drawings)   do pcall(function() o:Remove() end) end
    Library.Connections={}; Library.Drawings={}; Library.ThemeUpdaters={}; Library.ConfigData={}
    notifyList={}
end

return Library
]]

-- REAL ESP Module (from src/util/Esp.lua)
local EspCode = [[local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESP = {
    Enabled = false,
    ShowBoxes = true,
    ShowNames = true,
    ShowDistance = true,
    ShowHealth = true,
    ShowTracers = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(255, 255, 255),
    TextSize = 13,
    TextFont = 2,
    MaxDistance = 400,
    Objects = {},
    _conn = nil
}

local Camera = workspace.CurrentCamera

local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function hideAll(components)
    for _, c in pairs(components) do
        c.Visible = false
    end
end

function ESP:Add(object, options)
    if self.Objects[object] then self:Remove(object) end

    local primaryPart =
        (options and options.PrimaryPart) or
        (object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true))) or
        (object:IsA("BasePart") and object)

    if not primaryPart then return end

    local color = (options and options.Color) or self.BoxColor
    local name  = (options and options.Name)  or object.Name

    local c = {
        BoxOut  = newDrawing("Square", { Thickness=3, Color=Color3.new(0,0,0), Transparency=1, Filled=false, Visible=false }),
        Box     = newDrawing("Square", { Thickness=1, Color=color, Transparency=1, Filled=false, Visible=false }),
        HpOut   = newDrawing("Square", { Thickness=1, Color=Color3.new(0,0,0), Transparency=1, Filled=true,  Visible=false }),
        Hp      = newDrawing("Square", { Thickness=1, Color=Color3.fromRGB(0,200,0), Transparency=1, Filled=true,  Visible=false }),
        Name    = newDrawing("Text",   { Text=name,  Color=color, Center=true, Outline=true, Size=self.TextSize, Font=self.TextFont, Visible=false }),
        Dist    = newDrawing("Text",   { Text="",    Color=color, Center=true, Outline=true, Size=self.TextSize, Font=self.TextFont, Visible=false }),
        Tracer  = newDrawing("Line",   { From=Vector2.new(0,0), To=Vector2.new(0,0), Color=color, Thickness=1, Transparency=1, Visible=false }),
    }

    self.Objects[object] = {
        PrimaryPart = primaryPart,
        Object      = object,
        Name        = name,
        Color       = color,
        TextOnly    = options and options.TextOnly or false,
        IsEnabled   = options and options.IsEnabled,
        Components  = c,
    }
end

function ESP:Remove(object)
    local data = self.Objects[object]
    if not data then return end
    
    for _, c in pairs(data.Components) do
        c.Visible = false
        c:Remove()
    end
    self.Objects[object] = nil
end

function ESP:Clear()
    for obj in pairs(self.Objects) do
        self:Remove(obj)
    end
end

function ESP:Update()
    local cam = workspace.CurrentCamera
    if not cam then return end

    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for obj, data in pairs(self.Objects) do
        if not obj or not obj.Parent or not data.PrimaryPart or not data.PrimaryPart.Parent then
            self:Remove(obj)
            continue
        end

        local part = data.PrimaryPart
        local globalOk = data.IsEnabled ~= nil or self.Enabled
        local c = data.Components

        if not globalOk or (data.IsEnabled and not data.IsEnabled()) then
            hideAll(c)
            continue
        end

        local rootPos = part.Position
        local dist    = localRoot and (localRoot.Position - rootPos).Magnitude or 0
        if dist > self.MaxDistance then
            hideAll(c)
            continue
        end

        local topVP, onTop       = cam:WorldToViewportPoint(rootPos + Vector3.new(0, 3, 0))
        local bottomVP, onBottom = cam:WorldToViewportPoint(rootPos - Vector3.new(0, 3, 0))

        if not (onTop or onBottom) or topVP.Z < 0 then
            hideAll(c)
            continue
        end

        local color     = data.Color or self.BoxColor
        local textColor = data.Color or self.TextColor
        local height    = math.max(1, math.abs(topVP.Y - bottomVP.Y))
        local width     = height * 0.6
        local x         = topVP.X - width * 0.5
        local y         = topVP.Y

        if data.TextOnly then
            hideAll({c.BoxOut, c.Box, c.HpOut, c.Hp})

            c.Name.Visible  = self.ShowNames
            c.Name.Text     = data.Name
            c.Name.Color    = textColor
            c.Name.Position = Vector2.new(topVP.X, y)

            c.Dist.Visible  = self.ShowDistance and localRoot ~= nil
            if c.Dist.Visible then
                c.Dist.Text     = string.format("[%d]", math.floor(dist))
                c.Dist.Color    = textColor
                c.Dist.Position = Vector2.new(topVP.X, y + self.TextSize + 2)
            end
        else
            local showBox = self.ShowBoxes
            c.BoxOut.Visible = showBox
            c.Box.Visible    = showBox
            if showBox then
                c.BoxOut.Size     = Vector2.new(width, height)
                c.BoxOut.Position = Vector2.new(x, y)
                c.Box.Size        = Vector2.new(width, height)
                c.Box.Position    = Vector2.new(x, y)
                c.Box.Color       = color
            end

            local hum = obj:FindFirstChildWhichIsA("Humanoid")
            local showHp = self.ShowHealth and hum ~= nil
            c.HpOut.Visible = showHp
            c.Hp.Visible    = showHp
            if showHp then
                local pct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
                local barH = height * pct
                c.HpOut.Size     = Vector2.new(3, height)
                c.HpOut.Position = Vector2.new(x - 6, y)
                c.Hp.Size        = Vector2.new(3, barH)
                c.Hp.Position    = Vector2.new(x - 6, y + (height - barH))
                c.Hp.Color       = Color3.fromHSV(pct * 0.33, 1, 1)
            end

            c.Name.Visible = self.ShowNames
            if c.Name.Visible then
                c.Name.Text     = data.Name
                c.Name.Color    = textColor
                c.Name.Position = Vector2.new(x + width * 0.5, y - self.TextSize - 2)
            end

            c.Dist.Visible = self.ShowDistance and localRoot ~= nil
            if c.Dist.Visible then
                c.Dist.Text     = string.format("[%d]", math.floor(dist))
                c.Dist.Color    = textColor
                c.Dist.Position = Vector2.new(x + width * 0.5, y + height + 2)
            end
        end

        if self.ShowTracers then
            local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
            c.Tracer.Visible = true
            c.Tracer.Color = color
            c.Tracer.From = center
            c.Tracer.To = Vector2.new(topVP.X, topVP.Y)
        else
            c.Tracer.Visible = false
        end
    end
end

function ESP:Init()
    if self._conn then self._conn:Disconnect() end
    self._conn = RunService.RenderStepped:Connect(function() self:Update() end)
end

function ESP:Unload()
    self:Clear()
    if self._conn then self._conn:Disconnect(); self._conn = nil end
end

ESP:Init()
return ESP
]]

-- Write the libs to executor filesystem
print("[BHub Cache] Writing REAL libraries to executor filesystem...")
writeLib("DrawingUILib.lua", DrawingUILibCode)
writeLib("Esp.lua", EspCode)
print("[BHub Cache] Setup complete! Now paste evade_executor.lua")

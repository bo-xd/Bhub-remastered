local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local Library = {}
Library.Drawings      = {}
Library.Connections   = {}
Library.ThemeUpdaters = {}
Library.ConfigData    = {}
Library.CurrentThemeName = "Default"

local FONT = 0  -- Drawing.Fonts.UI (Gotham/sans-serif, anti-aliased)

-- ── Themes ────────────────────────────────────────────────────────────────────
Library.Themes = {
    Default = {
        Bg=Color3.fromRGB(14,14,21),     Bar=Color3.fromRGB(20,20,32),
        Accent=Color3.fromRGB(98,62,255), GroupBg=Color3.fromRGB(19,19,29),
        GroupBorder=Color3.fromRGB(38,38,58), GroupHead=Color3.fromRGB(25,25,38),
        TabOn=Color3.fromRGB(98,62,255),  TabOff=Color3.fromRGB(125,125,155),
        Text=Color3.fromRGB(232,232,245), Dim=Color3.fromRGB(145,145,172),
        TogOn=Color3.fromRGB(98,62,255),  TogOff=Color3.fromRGB(36,36,55),
        Thumb=Color3.fromRGB(228,228,245),Btn=Color3.fromRGB(30,30,46),
        Sep=Color3.fromRGB(32,32,50),     SlidBg=Color3.fromRGB(26,26,42),
        DropBg=Color3.fromRGB(18,18,28),  DropItem=Color3.fromRGB(26,26,40),
        DropHover=Color3.fromRGB(40,40,62),DropSel=Color3.fromRGB(72,44,200),
    },
    Dark = {
        Bg=Color3.fromRGB(12,12,16),     Bar=Color3.fromRGB(17,17,24),
        Accent=Color3.fromRGB(0,140,255), GroupBg=Color3.fromRGB(17,17,23),
        GroupBorder=Color3.fromRGB(28,28,42), GroupHead=Color3.fromRGB(21,21,30),
        TabOn=Color3.fromRGB(0,140,255),  TabOff=Color3.fromRGB(115,115,145),
        Text=Color3.fromRGB(228,228,240), Dim=Color3.fromRGB(138,138,165),
        TogOn=Color3.fromRGB(0,140,255),  TogOff=Color3.fromRGB(28,28,44),
        Thumb=Color3.fromRGB(220,220,238),Btn=Color3.fromRGB(24,24,36),
        Sep=Color3.fromRGB(25,25,38),     SlidBg=Color3.fromRGB(20,20,32),
        DropBg=Color3.fromRGB(14,14,22),  DropItem=Color3.fromRGB(20,20,32),
        DropHover=Color3.fromRGB(32,32,52),DropSel=Color3.fromRGB(0,100,200),
    },
    Midnight = {
        Bg=Color3.fromRGB(10,10,18),      Bar=Color3.fromRGB(15,14,25),
        Accent=Color3.fromRGB(210,45,115),GroupBg=Color3.fromRGB(15,14,25),
        GroupBorder=Color3.fromRGB(30,26,48),GroupHead=Color3.fromRGB(19,17,31),
        TabOn=Color3.fromRGB(210,45,115), TabOff=Color3.fromRGB(122,118,152),
        Text=Color3.fromRGB(235,234,248), Dim=Color3.fromRGB(148,142,178),
        TogOn=Color3.fromRGB(210,45,115), TogOff=Color3.fromRGB(30,26,48),
        Thumb=Color3.fromRGB(230,226,246),Btn=Color3.fromRGB(26,22,42),
        Sep=Color3.fromRGB(28,24,46),     SlidBg=Color3.fromRGB(22,18,38),
        DropBg=Color3.fromRGB(14,12,22),  DropItem=Color3.fromRGB(22,18,36),
        DropHover=Color3.fromRGB(38,28,58),DropSel=Color3.fromRGB(160,30,85),
    },
    Forest = {
        Bg=Color3.fromRGB(10,15,12),      Bar=Color3.fromRGB(14,21,16),
        Accent=Color3.fromRGB(45,195,82), GroupBg=Color3.fromRGB(14,21,16),
        GroupBorder=Color3.fromRGB(22,36,26),GroupHead=Color3.fromRGB(17,27,20),
        TabOn=Color3.fromRGB(45,195,82),  TabOff=Color3.fromRGB(112,140,118),
        Text=Color3.fromRGB(228,240,230), Dim=Color3.fromRGB(135,162,140),
        TogOn=Color3.fromRGB(45,195,82),  TogOff=Color3.fromRGB(20,34,24),
        Thumb=Color3.fromRGB(220,236,224),Btn=Color3.fromRGB(16,28,20),
        Sep=Color3.fromRGB(18,30,22),     SlidBg=Color3.fromRGB(12,24,16),
        DropBg=Color3.fromRGB(10,16,12),  DropItem=Color3.fromRGB(14,24,17),
        DropHover=Color3.fromRGB(24,40,28),DropSel=Color3.fromRGB(28,140,55),
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
    local c = sig:Connect(fn)
    table.insert(Library.Connections, c)
    return c
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

function Library:ListConfigs()
    local out = {}
    pcall(function()
        if not (listfiles and isfolder) then return end
        if not isfolder("BHub-remastered/configs") then return end
        for _,f in ipairs(listfiles("BHub-remastered/configs")) do
            local n = f:match("([^/\\]+)%.json$")
            if n then table.insert(out,n) end
        end
    end)
    if #out == 0 then table.insert(out,"default") end
    return out
end

-- ── Global overlay state ──────────────────────────────────────────────────────
local activeDD   = nil   -- { close=fn, pos=V2, sz=V2 }
local activeBind = nil   -- { cancel=fn }

-- ── CreateWindow ──────────────────────────────────────────────────────────────
function Library:CreateWindow(opts)
    local title = opts.Title or "BHub"
    local W     = 494
    local BAR   = 32
    local TABH  = 28
    local HDR   = BAR + 2 + TABH + 1
    local PAD   = 8
    local GAP   = 6
    local COL   = math.floor((W - PAD*2 - GAP) / 2)  -- ~235
    local IP    = 7    -- item inner padding
    local MAXDD = 14   -- max visible dropdown rows
    local DD_H  = 20   -- height per dropdown row

    local Win = {
        Pos=Vector2.new(100,100), Tabs={}, Active=nil,
        Dragging=false, DragOff=Vector2.new(), Btns={}, Visible=true,
    }

    local wBg   = d("Square",{Filled=true, ZIndex=10,Rounding=6,Color=T().Bg,   Visible=true,Position=Win.Pos,Size=Vector2.new(W,BAR)})
    local wBar  = d("Square",{Filled=true, ZIndex=11,Rounding=6,Color=T().Bar,  Visible=true,Position=Win.Pos,Size=Vector2.new(W,BAR)})
    local wBBt  = d("Square",{Filled=true, ZIndex=11,Rounding=0,Color=T().Bar,  Visible=true,Position=Win.Pos+Vector2.new(0,BAR-4),Size=Vector2.new(W,4)})
    local wAcc  = d("Square",{Filled=true, ZIndex=12,            Color=T().Accent,Visible=true,Position=Win.Pos+Vector2.new(0,BAR),Size=Vector2.new(W,2)})
    local wTBg  = d("Square",{Filled=true, ZIndex=11,Rounding=0,Color=T().Bar,  Visible=true,Position=Win.Pos+Vector2.new(0,BAR+2),Size=Vector2.new(W,TABH)})
    local wTSep = d("Square",{Filled=true, ZIndex=12,            Color=T().Sep,  Visible=true,Position=Win.Pos+Vector2.new(0,HDR),Size=Vector2.new(W,1)})
    local wTit  = d("Text",  {Text=title,Size=15,Font=FONT,Outline=false,Color=T().Text,Visible=true,ZIndex=13,Position=Win.Pos+Vector2.new(12,9)})

    th(function()
        wBg.Color=T().Bg; wBar.Color=T().Bar; wBBt.Color=T().Bar; wAcc.Color=T().Accent
        wTBg.Color=T().Bar; wTSep.Color=T().Sep; wTit.Color=T().Text
    end)

    local CONTY = HDR + 1 + PAD

    local function layout()
        wBg.Position=fv(Win.Pos); wBar.Position=fv(Win.Pos)
        wBBt.Position=fv(Win.Pos+Vector2.new(0,BAR-4))
        wAcc.Position=fv(Win.Pos+Vector2.new(0,BAR))
        wTBg.Position=fv(Win.Pos+Vector2.new(0,BAR+2))
        wTSep.Position=fv(Win.Pos+Vector2.new(0,HDR))
        wTit.Position=fv(Win.Pos+Vector2.new(12,9))
        local tx = 12
        for _,btn in ipairs(Win.Btns) do
            btn.setPos(fv(Win.Pos+Vector2.new(tx,BAR+2+6))); tx=tx+btn.w+20
        end
        if not Win.Active then return end
        local lH,rH = 0,0
        for _,gb in ipairs(Win.Active.L) do
            gb.setPos(fv(Win.Pos+Vector2.new(PAD,CONTY+lH))); lH=lH+gb.height()+PAD
        end
        for _,gb in ipairs(Win.Active.R) do
            gb.setPos(fv(Win.Pos+Vector2.new(PAD+COL+GAP,CONTY+rH))); rH=rH+gb.height()+PAD
        end
        wBg.Size=fv(Vector2.new(W, CONTY+math.max(lH,rH,40)+PAD))
    end

    -- drag
    on(UserInputService.InputBegan,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 and over(Win.Pos,Vector2.new(W,BAR)) then
            Win.Dragging=true; Win.DragOff=UserInputService:GetMouseLocation()-Win.Pos
        end
    end)
    on(UserInputService.InputEnded,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then Win.Dragging=false end
    end)
    on(RunService.RenderStepped,function()
        if Win.Dragging then Win.Pos=fv(UserInputService:GetMouseLocation()-Win.DragOff); layout() end
    end)

    -- close dropdown on outside click
    on(UserInputService.InputBegan,function(i)
        if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if activeDD and not over(activeDD.pos,activeDD.sz) then activeDD.close(); activeDD=nil end
    end)

    -- ── Groupbox factory ──────────────────────────────────────────────────────
    local function makeGB(parentTab, side, name)
        local GH = 26
        local GP = 6
        local GB = {items={}, pos=Vector2.new()}

        local gBg  = d("Square",{Filled=true, ZIndex=14,Rounding=5,Color=T().GroupBg,    Visible=false,Size=Vector2.new(COL,GH)})
        local gOut = d("Square",{Filled=false,ZIndex=14,Rounding=5,Thickness=1,Color=T().GroupBorder,Visible=false,Size=Vector2.new(COL,GH)})
        local gHd  = d("Square",{Filled=true, ZIndex=15,Rounding=5,Color=T().GroupHead,  Visible=false,Size=Vector2.new(COL,GH)})
        local gHF  = d("Square",{Filled=true, ZIndex=15,Rounding=0,Color=T().GroupHead,  Visible=false,Size=Vector2.new(COL,5)})
        local gHL  = d("Square",{Filled=true, ZIndex=16,            Color=T().Sep,        Visible=false,Size=Vector2.new(COL,1)})
        local gTit = d("Text",  {Text=name,Size=12,Font=FONT,Outline=false,Color=T().Dim,Visible=false,ZIndex=16})
        th(function()
            gBg.Color=T().GroupBg; gOut.Color=T().GroupBorder; gHd.Color=T().GroupHead
            gHF.Color=T().GroupHead; gHL.Color=T().Sep; gTit.Color=T().Dim
        end)

        function GB.height()
            local h=GH+GP
            for _,it in ipairs(GB.items) do h=h+it.h end
            return h+GP
        end
        function GB.setVis(v)
            gBg.Visible=v;gOut.Visible=v;gHd.Visible=v;gHF.Visible=v;gHL.Visible=v;gTit.Visible=v
            for _,it in ipairs(GB.items) do it.setVis(v) end
        end
        function GB.setPos(p)
            GB.pos=p
            local h=GB.height()
            gBg.Position=p;  gBg.Size=fv(Vector2.new(COL,h))
            gOut.Position=p; gOut.Size=fv(Vector2.new(COL,h))
            gHd.Position=p;  gHd.Size=fv(Vector2.new(COL,GH))
            gHF.Position=fv(p+Vector2.new(0,GH-4)); gHF.Size=Vector2.new(COL,4)
            gHL.Position=fv(p+Vector2.new(0,GH));   gHL.Size=Vector2.new(COL,1)
            gTit.Position=fv(p+Vector2.new(10,7))
            local iy=GH+GP
            for _,it in ipairs(GB.items) do it.setPos(fv(p+Vector2.new(0,iy))); iy=iy+it.h end
        end

        local function addIt(it)
            table.insert(GB.items,it)
            if Win.Active==parentTab then it.setVis(true) end
            layout()
        end

        local Obj={}

        -- Toggle ---------------------------------------------------------------
        function Obj:AddToggle(id, o)
            local txt=o.Text or id; local st=o.Default or false; local iP=Vector2.new()
            local lbl=d("Text",  {Text=txt,Size=13,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=20})
            local trk=d("Square",{Size=Vector2.new(30,16),Filled=true,ZIndex=20,Rounding=8,Color=st and T().TogOn or T().TogOff,Visible=false})
            local thb=d("Square",{Size=Vector2.new(12,12),Filled=true,ZIndex=21,Rounding=6,Color=T().Thumb,Visible=false})
            th(function() lbl.Color=T().Text; trk.Color=st and T().TogOn or T().TogOff; thb.Color=T().Thumb end)
            local function refresh()
                trk.Color=st and T().TogOn or T().TogOff
                thb.Position=fv(iP+Vector2.new(COL-42+(st and 15 or 3),7))
            end
            local it={h=26}
            function it.setVis(v) lbl.Visible=v;trk.Visible=v;thb.Visible=v end
            function it.setPos(p)
                iP=p; lbl.Position=fv(p+Vector2.new(IP+1,6))
                trk.Position=fv(p+Vector2.new(COL-42,5))
                thb.Position=fv(p+Vector2.new(COL-42+(st and 15 or 3),7))
            end
            local Tog={State=st}
            on(UserInputService.InputBegan,function(i)
                if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
                if Win.Active~=parentTab then return end
                if over(iP,Vector2.new(COL,26)) then st=not st;Tog.State=st;refresh();if o.Callback then o.Callback(st) end end
            end)
            function Tog:AddColorPicker() return {OnChanged=function()end} end
            function Tog:AddKeyPicker()   return {OnChanged=function()end} end
            Library:_regCfg(id,function() return st end,function(v) st=v;Tog.State=v;refresh();if o.Callback then o.Callback(v) end end)
            addIt(it); if o.Callback then task.spawn(o.Callback,st) end
            return Tog
        end

        -- Button ---------------------------------------------------------------
        function Obj:AddButton(o)
            local txt=type(o)=="table" and o.Text or tostring(o)
            local fn =type(o)=="table" and o.Func or function() end
            local bW=COL-IP*2
            local bg2=d("Square",{Size=Vector2.new(bW,22),Filled=true,ZIndex=20,Rounding=4,Color=T().Btn,Visible=false})
            local lt =d("Text",  {Text=txt,Size=13,Font=FONT,Outline=false,Center=true,Color=T().Text,ZIndex=21,Visible=false})
            th(function() bg2.Color=T().Btn; lt.Color=T().Text end)
            local it={h=30}
            function it.setVis(v) bg2.Visible=v;lt.Visible=v end
            function it.setPos(p) bg2.Position=fv(p+Vector2.new(IP,4)); lt.Position=fv(p+Vector2.new(IP+bW/2,7)) end
            on(UserInputService.InputBegan,function(i)
                if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
                if Win.Active~=parentTab then return end
                if over(bg2.Position,bg2.Size) then
                    bg2.Color=T().Accent; if fn then fn() end
                    task.delay(0.13,function() pcall(function() bg2.Color=T().Btn end) end)
                end
            end)
            addIt(it); return {}
        end

        -- Slider ---------------------------------------------------------------
        function Obj:AddSlider(id, o)
            local txt=o.Text or id; local mn,mx=o.Min or 0,o.Max or 100
            local val=o.Default or mn; local sW=COL-IP*2; local iP=Vector2.new(); local drag=false
            local lbl =d("Text",  {Text=txt..": "..tostring(val),Size=13,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=20})
            local sBg =d("Square",{Size=Vector2.new(sW,6),Filled=true,ZIndex=20,Rounding=3,Color=T().SlidBg,Visible=false})
            local sFll=d("Square",{Size=Vector2.new(((val-mn)/(mx-mn))*sW,6),Filled=true,ZIndex=21,Rounding=3,Color=T().Accent,Visible=false})
            local sThb=d("Square",{Size=Vector2.new(10,10),Filled=true,ZIndex=22,Rounding=5,Color=T().Thumb,Visible=false})
            th(function() lbl.Color=T().Text;sBg.Color=T().SlidBg;sFll.Color=T().Accent;sThb.Color=T().Thumb end)
            local function apply(pct)
                pct=math.clamp(pct,0,1); val=mn+(mx-mn)*pct
                if o.Rounding==0 then val=math.floor(val) end
                local fw=math.max(pct*sW,0)
                sFll.Size=Vector2.new(fw,6); sThb.Position=fv(sBg.Position+Vector2.new(fw-5,-2))
                lbl.Text=txt..": "..tostring(math.floor(val*10)/10)
                if o.Callback then o.Callback(val) end
            end
            local Sld={Value=val}
            local it={h=44}
            function it.setVis(v) lbl.Visible=v;sBg.Visible=v;sFll.Visible=v;sThb.Visible=v end
            function it.setPos(p)
                iP=p; lbl.Position=fv(p+Vector2.new(IP+1,4)); sBg.Position=fv(p+Vector2.new(IP,26))
                local pct2=(val-mn)/(mx-mn)
                sFll.Position=sBg.Position; sFll.Size=Vector2.new(math.max(pct2*sW,0),6)
                sThb.Position=fv(p+Vector2.new(IP+pct2*sW-5,24))
            end
            on(UserInputService.InputBegan,function(i)
                if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
                if Win.Active~=parentTab then return end
                if over(sBg.Position,Vector2.new(sW,14)) then drag=true;apply((UserInputService:GetMouseLocation().X-sBg.Position.X)/sW) end
            end)
            on(UserInputService.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
            on(RunService.RenderStepped,function() if drag and Win.Active==parentTab then apply((UserInputService:GetMouseLocation().X-sBg.Position.X)/sW);Sld.Value=val end end)
            Library:_regCfg(id,function() return val end,function(v) val=v;Sld.Value=v;apply((v-mn)/(mx-mn)) end)
            addIt(it); if o.Callback then task.spawn(o.Callback,val) end
            return Sld
        end

        -- Label ----------------------------------------------------------------
        function Obj:AddLabel(txt)
            local lbl=d("Text",{Text=txt,Size=13,Font=FONT,Outline=false,Color=T().Dim,Visible=false,ZIndex=20})
            th(function() lbl.Color=T().Dim end)
            local it={h=22}
            function it.setVis(v) lbl.Visible=v end
            function it.setPos(p) lbl.Position=fv(p+Vector2.new(IP+1,4)) end
            local Lbl={}
            function Lbl:SetText(t) lbl.Text=t end
            function Lbl:AddKeyPicker(kid,ko)
                local kc=(ko and ko.Default) and (pcall(function() return Enum.KeyCode[ko.Default] end) and Enum.KeyCode[ko.Default]) or Enum.KeyCode.Delete
                local listening=false; local kbW=58
                local kbBg =d("Square",{Size=Vector2.new(kbW,16),Filled=true,ZIndex=22,Rounding=3,Color=T().Btn,Visible=false})
                local kbTxt=d("Text",  {Text=keyName(kc),Size=11,Font=FONT,Outline=false,Center=true,Color=T().Text,Visible=false,ZIndex=23})
                th(function() kbBg.Color=listening and T().Accent or T().Btn; kbTxt.Color=T().Text end)
                local origPos,origVis=it.setPos,it.setVis
                function it.setPos(p) origPos(p); kbBg.Position=fv(p+Vector2.new(COL-kbW-IP,3)); kbTxt.Position=fv(p+Vector2.new(COL-kbW/2-IP,5)) end
                function it.setVis(v) origVis(v); kbBg.Visible=v; kbTxt.Visible=v end
                on(UserInputService.InputBegan,function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 and over(kbBg.Position,kbBg.Size) then
                        if activeBind then activeBind.cancel() end
                        listening=true; kbBg.Color=T().Accent; kbTxt.Text="..."
                        activeBind={cancel=function() listening=false;kbBg.Color=T().Btn;kbTxt.Text=keyName(kc);activeBind=nil end}
                        return
                    end
                    if listening and i.UserInputType==Enum.UserInputType.Keyboard then
                        if i.KeyCode==Enum.KeyCode.Escape then
                            listening=false;kbBg.Color=T().Btn;kbTxt.Text=keyName(kc);activeBind=nil
                        else
                            kc=i.KeyCode;listening=false;kbBg.Color=T().Btn;kbTxt.Text=keyName(kc);activeBind=nil
                            if ko and ko.Callback then ko.Callback(kc) end
                        end
                    end
                    if not listening and i.KeyCode==kc then if ko and ko.OnKey then ko.OnKey() end end
                end)
                Library:_regCfg(kid,function() return tostring(kc) end,function(v) local ok,k=pcall(function() return Enum.KeyCode[v] end);if ok and k then kc=k;kbTxt.Text=keyName(kc) end end)
                return {OnChanged=function()end}
            end
            addIt(it); return Lbl
        end

        -- Dropdown (real overlay) ----------------------------------------------
        function Obj:AddDropdown(id, o)
            local txt=o.Text or id; local vals=o.Values or {}; local multi=o.Multi
            local val=o.Default; local dW=COL-IP*2; local iP=Vector2.new(); local isOpen=false
            if not multi and val==nil and vals[1] then val=vals[1] end

            local lbl =d("Text",  {Text=txt,Size=13,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=20})
            local dBg =d("Square",{Size=Vector2.new(dW,22),Filled=true,ZIndex=20,Rounding=4,Color=T().Btn,Visible=false})
            local dVal=d("Text",  {Size=12,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=21})
            local dArr=d("Text",  {Text="▾",Size=11,Font=FONT,Outline=false,Color=T().Dim,Visible=false,ZIndex=21})
            th(function() lbl.Color=T().Text;dBg.Color=isOpen and T().Accent or T().Btn;dVal.Color=T().Text;dArr.Color=T().Dim end)

            local function display()
                if multi then
                    local p={}; for k,v in pairs(val or {}) do if v then table.insert(p,tostring(k)) end end
                    return #p==0 and "None" or (#p<=3 and table.concat(p,", ") or p[1].." +"..#p-1)
                end
                return tostring(val or "None")
            end
            dVal.Text=display()

            -- overlay pool
            local pool={}
            for _=1,MAXDD do
                local row={
                    bg  =d("Square",{Filled=true, ZIndex=92,Rounding=0,Color=T().DropItem, Visible=false}),
                    chk =d("Square",{Filled=true, ZIndex=94,Rounding=2,Color=T().Accent,   Visible=false,Size=Vector2.new(10,10)}),
                    box =d("Square",{Filled=false,ZIndex=94,Rounding=2,Thickness=1,Color=T().Dim,Visible=false,Size=Vector2.new(10,10)}),
                    txt =d("Text",  {Size=12,Font=FONT,Outline=false,Color=T().Text,        Visible=false,ZIndex=93}),
                }
                th(function() row.bg.Color=T().DropItem;row.chk.Color=T().Accent;row.box.Color=T().Dim;row.txt.Color=T().Text end)
                table.insert(pool,row)
            end
            local lBg =d("Square",{Filled=true, ZIndex=90,Rounding=4,Color=T().DropBg,     Visible=false})
            local lOut=d("Square",{Filled=false,ZIndex=91,Rounding=4,Thickness=1,Color=T().GroupBorder,Visible=false})
            th(function() lBg.Color=T().DropBg;lOut.Color=T().GroupBorder end)

            local function closeDD()
                isOpen=false; dBg.Color=T().Btn; dArr.Text="▾"
                lBg.Visible=false; lOut.Visible=false
                for _,row in ipairs(pool) do row.bg.Visible=false;row.chk.Visible=false;row.box.Visible=false;row.txt.Visible=false end
            end

            local function openDD()
                if activeDD then activeDD.close();activeDD=nil end
                isOpen=true; dBg.Color=T().Accent; dArr.Text="▴"
                local count=math.min(#vals,MAXDD)
                local listH=count*DD_H+4
                local vp=pcall(function() return workspace.CurrentCamera.ViewportSize end) and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
                local baseY=dBg.Position.Y+dBg.Size.Y+2
                if baseY+listH>vp.Y-10 then baseY=dBg.Position.Y-listH-2 end
                local lx,lw=dBg.Position.X,dW
                lBg.Position=fv(Vector2.new(lx,baseY));  lBg.Size=fv(Vector2.new(lw,listH))
                lOut.Position=fv(Vector2.new(lx,baseY)); lOut.Size=fv(Vector2.new(lw,listH))
                lBg.Visible=true; lOut.Visible=true
                for i,row in ipairs(pool) do
                    local v=vals[i]
                    if v then
                        local ry=baseY+(i-1)*DD_H+2
                        local sel=multi and (type(val)=="table" and val[v]) or (val==v)
                        row.bg.Position=fv(Vector2.new(lx,ry)); row.bg.Size=Vector2.new(lw,DD_H)
                        row.bg.Color=sel and T().DropSel or T().DropItem; row.bg.Visible=true
                        if multi then
                            local cx,cy=lx+5,ry+(DD_H-10)/2
                            if sel then row.chk.Position=fv(Vector2.new(cx,cy));row.chk.Visible=true;row.box.Visible=false
                            else        row.box.Position=fv(Vector2.new(cx,cy));row.box.Visible=true;row.chk.Visible=false end
                            row.txt.Position=fv(Vector2.new(lx+20,ry+(DD_H-12)/2))
                        else
                            row.chk.Visible=false;row.box.Visible=false
                            row.txt.Position=fv(Vector2.new(lx+8,ry+(DD_H-12)/2))
                        end
                        row.txt.Text=tostring(v); row.txt.Visible=true
                    else
                        row.bg.Visible=false;row.chk.Visible=false;row.box.Visible=false;row.txt.Visible=false
                    end
                end
                activeDD={close=closeDD,pos=fv(Vector2.new(lx,baseY)),sz=fv(Vector2.new(lw,listH))}
            end

            local it={h=50}
            function it.setVis(v)
                lbl.Visible=v;dBg.Visible=v;dVal.Visible=v;dArr.Visible=v
                if not v and isOpen then closeDD() end
            end
            function it.setPos(p)
                iP=p; lbl.Position=fv(p+Vector2.new(IP+1,4))
                dBg.Position=fv(p+Vector2.new(IP,22))
                dVal.Position=fv(p+Vector2.new(IP+6,26))
                dArr.Position=fv(p+Vector2.new(IP+dW-13,26))
            end

            on(UserInputService.InputBegan,function(i)
                if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
                if Win.Active~=parentTab then return end
                if over(dBg.Position,dBg.Size) then
                    if isOpen then closeDD();activeDD=nil else openDD() end
                    return
                end
                if isOpen then
                    for idx,row in ipairs(pool) do
                        if vals[idx] and over(row.bg.Position,row.bg.Size) then
                            local v=vals[idx]
                            if multi then
                                if type(val)~="table" then val={} end
                                val[v]=not val[v] or nil; dVal.Text=display(); openDD()
                            else
                                val=v; dVal.Text=display(); closeDD(); activeDD=nil
                            end
                            if o.Callback then o.Callback(val) end; break
                        end
                    end
                end
            end)

            on(RunService.RenderStepped,function()
                if not isOpen then return end
                for idx,row in ipairs(pool) do
                    local v=vals[idx]
                    if v and row.bg.Visible then
                        local sel=multi and (type(val)=="table" and val[v]) or (val==v)
                        row.bg.Color=over(row.bg.Position,row.bg.Size) and T().DropHover or (sel and T().DropSel or T().DropItem)
                    end
                end
            end)

            local Drop={}
            function Drop:SetValues(v)
                vals=v; if not multi then val=v[1] end; dVal.Text=display()
                if isOpen then openDD() end
            end
            Library:_regCfg(id,function() return val end,function(v) val=v;dVal.Text=display();if o.Callback then o.Callback(val) end end)
            addIt(it); if o.Callback then task.spawn(o.Callback,val) end
            return Drop
        end

        -- Keybind --------------------------------------------------------------
        function Obj:AddKeybind(id, o)
            local txt=o.Text or id
            local ok2,kc2=pcall(function() return Enum.KeyCode[o.Default or "Unknown"] end)
            local kc=ok2 and kc2 or Enum.KeyCode.Unknown
            local listening=false; local kbW=60
            local lbl  =d("Text",  {Text=txt,Size=13,Font=FONT,Outline=false,Color=T().Text,Visible=false,ZIndex=20})
            local kbBg =d("Square",{Size=Vector2.new(kbW,18),Filled=true,ZIndex=20,Rounding=3,Color=T().Btn,Visible=false})
            local kbTxt=d("Text",  {Text=keyName(kc),Size=11,Font=FONT,Outline=false,Center=true,Color=T().Text,Visible=false,ZIndex=21})
            th(function() lbl.Color=T().Text;kbBg.Color=listening and T().Accent or T().Btn;kbTxt.Color=T().Text end)
            local it={h=26}
            function it.setVis(v) lbl.Visible=v;kbBg.Visible=v;kbTxt.Visible=v end
            function it.setPos(p)
                lbl.Position=fv(p+Vector2.new(IP+1,5))
                kbBg.Position=fv(p+Vector2.new(COL-kbW-IP,4))
                kbTxt.Position=fv(p+Vector2.new(COL-kbW/2-IP,7))
            end
            local Bind={Value=kc}
            on(UserInputService.InputBegan,function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 and over(kbBg.Position,kbBg.Size) then
                    if activeBind then activeBind.cancel() end
                    listening=true;kbBg.Color=T().Accent;kbTxt.Text="..."
                    activeBind={cancel=function() listening=false;kbBg.Color=T().Btn;kbTxt.Text=keyName(kc);activeBind=nil end}
                    return
                end
                if listening and i.UserInputType==Enum.UserInputType.Keyboard then
                    if i.KeyCode==Enum.KeyCode.Escape then
                        listening=false;kbBg.Color=T().Btn;kbTxt.Text=keyName(kc);activeBind=nil
                    else
                        kc=i.KeyCode;Bind.Value=kc;listening=false;kbBg.Color=T().Btn;kbTxt.Text=keyName(kc);activeBind=nil
                        if o.Callback then o.Callback(kc) end
                    end
                end
                if not listening and i.KeyCode==kc then if o.OnKey then o.OnKey() end end
            end)
            Library:_regCfg(id,function() return tostring(kc) end,function(v) local ok3,k3=pcall(function() return Enum.KeyCode[v] end);if ok3 and k3 then kc=k3;Bind.Value=kc;kbTxt.Text=keyName(kc) end end)
            addIt(it); return Bind
        end

        -- Input stub -----------------------------------------------------------
        function Obj:AddInput(id, o)
            local txt=o and o.Text or id; local cur=o and o.Default or ""
            local lbl=d("Text",{Text=txt..": ["..cur.."]",Size=13,Font=FONT,Outline=false,Color=T().Dim,Visible=false,ZIndex=20})
            th(function() lbl.Color=T().Dim end)
            local it={h=22}
            function it.setVis(v) lbl.Visible=v end
            function it.setPos(p) lbl.Position=fv(p+Vector2.new(IP+1,4)) end
            local Inp={}
            function Inp:SetValue(v) cur=v;lbl.Text=txt..": ["..cur.."]";if o and o.Callback then o.Callback(v) end end
            addIt(it); return Inp
        end

        if side=="left" then table.insert(parentTab.L,GB) else table.insert(parentTab.R,GB) end
        layout(); return Obj
    end

    -- ── AddTab ────────────────────────────────────────────────────────────────
    function Win:AddTab(name)
        local Tab={L={},R={}}
        table.insert(Win.Tabs,Tab)
        local tw=#name*7+14; local btn={w=tw,Tab=Tab}; local bP=Vector2.new()
        local bLbl=d("Text",  {Text=name,Size=13,Font=FONT,Outline=false,Color=Win.Active==Tab and T().TabOn or T().TabOff,Visible=true,ZIndex=18})
        local bInd=d("Square",{Size=Vector2.new(tw-4,2),Filled=true,ZIndex=18,Color=T().Accent,Visible=Win.Active==Tab})
        th(function() bLbl.Color=(Win.Active==Tab) and T().TabOn or T().TabOff; bInd.Color=T().Accent end)
        function btn.setPos(p) bP=p;bLbl.Position=p;bInd.Position=fv(p+Vector2.new(2,17)) end
        local function activate()
            for _,ob in ipairs(Win.Btns) do
                if ob.Tab then
                    for _,gb in ipairs(ob.Tab.L) do gb.setVis(false) end
                    for _,gb in ipairs(ob.Tab.R) do gb.setVis(false) end
                    ob.bLbl.Color=T().TabOff; ob.bInd.Visible=false
                end
            end
            if activeDD then activeDD.close();activeDD=nil end
            Win.Active=Tab
            for _,gb in ipairs(Tab.L) do gb.setVis(true) end
            for _,gb in ipairs(Tab.R) do gb.setVis(true) end
            bLbl.Color=T().TabOn; bInd.Visible=true; layout()
        end
        btn.bLbl=bLbl; btn.bInd=bInd
        on(UserInputService.InputBegan,function(i)
            if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            if over(bP,Vector2.new(tw,TABH)) then activate() end
        end)
        table.insert(Win.Btns,btn)
        if not Win.Active then Win.Active=Tab;bLbl.Color=T().TabOn;bInd.Visible=true end
        function Tab:AddLeftGroupbox(n)  return makeGB(Tab,"left", n) end
        function Tab:AddRightGroupbox(n) return makeGB(Tab,"right",n) end
        layout(); return Tab
    end

    -- ── Settings tab (always last, via defer) ─────────────────────────────────
    task.defer(function()
        local st=Win:AddTab("Settings")

        local tg=st:AddLeftGroupbox("Appearance")
        local tNames={} for k in pairs(Library.Themes) do table.insert(tNames,k) end; table.sort(tNames)
        tg:AddDropdown("_theme",{Values=tNames,Default=Library.CurrentThemeName,Text="Color Theme",
            Callback=function(v) Library:SetTheme(v) end})

        local kg=st:AddLeftGroupbox("Keybinds")
        kg:AddLabel("Menu visibility"):AddKeyPicker("_menuKey",{Default="Insert",
            OnKey=function()
                Win.Visible=not Win.Visible
                local chrome={[wBg]=true,[wBar]=true,[wBBt]=true,[wAcc]=true,[wTBg]=true,[wTSep]=true,[wTit]=true}
                for _,obj in ipairs(Library.Drawings) do if not chrome[obj] then pcall(function() obj.Visible=Win.Visible end) end end
            end
        })

        local cg=st:AddRightGroupbox("Config")
        cg:AddButton({Text="Save Config",Func=function()
            if Library:SaveConfig("default") then Library:Notify("Config saved!") else Library:Notify("Save failed (no writefile)") end
        end})
        cg:AddButton({Text="Load Config",Func=function()
            if Library:LoadConfig("default") then Library:Notify("Config loaded!") else Library:Notify("No config found") end
        end})
        cg:AddLabel("Saved to BHub-remastered/configs/")
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
    Library.Connections={}; Library.Drawings={}; Library.ThemeUpdaters={}
    Library.ConfigData={}; activeDD=nil; activeBind=nil
end

return Library

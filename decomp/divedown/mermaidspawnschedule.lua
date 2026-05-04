local game:GetService("ReplicatedStorage").Modules.MermaidSpawnSchedule

ocal u3 = {
    31,
    28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
}

local function u13(p4, p5, p6, p7, p8, p9)
    local v10 = 0
    for v11 = 1970, p4 - 1 do
        v10 = v10 + ((v11 % 4 == 0 and v11 % 100 ~= 0 and true or v11 % 400 == 0) and 366 or 365)
    end
    for v12 = 1, p5 - 1 do
        v10 = v10 + (v12 == 2 and (p4 % 4 == 0 and p4 % 100 ~= 0 or p4 % 400 == 0) and 29 or u3[v12])
    end
    return (v10 + (p6 - 1)) * 86400 + p7 * 3600 + p8 * 60 + p9
end

local function u23(p14)
    local d = os.date("!*t", p14)
    local v15 = d.year
    local v16 = u13(v15, 3, 1, 12, 0, 0)
    local v17 = 1 + (8 - os.date("!*t", v16).wday) % 7 + 7
    local v18 = u13(v15, 11, 1, 12, 0, 0)
    local v19 = 1 + (8 - os.date("!*t", v18).wday) % 7 + 0
    local v20 = u13(v15, 3, v17, 7, 0, 0)
    local v21 = u13(v15, 11, v19, 6, 0, 0)
    local v22
    if v20 <= p14 then
        v22 = p14 < v21
    else
        v22 = false
    end
    return v22
end

local u2 = { 11, 14, 21 }

local function u29(p24)
    local v25 = u23(p24 + 43200) and 4 or 5
    local v26 = {}
    for _, v27 in ipairs(u2) do
        local v28 = p24 + (v27 + v25) * 3600 + 0
        table.insert(v26, v28)
    end
    return v26
end

function get_next_mermaid(p30)
    local v31 = p30 / 86400
    local v32 = math.floor(v31) * 86400
    local v33 = nil
    for _, v34 in ipairs({ v32 - 86400, v32, v32 + 86400 }) do
        for _, v35 in ipairs((u29(v34))) do
            if p30 < v35 and (v33 == nil or v35 < v33) then
                v33 = v35
            end
        end
    end
    return v33
end

-- May 4, 2026, 23:36:07 (UTC+2) -> UTC is 21:36:07
-- os.time for 2026-05-04 21:36:07 UTC
local currentTime = 1777930567 
local nextSpawn = get_next_mermaid(currentTime)

print("Current Time (UTC): " .. os.date("!%Y-%m-%d %H:%M:%S", currentTime))
if nextSpawn then
    print("Next Spawn (UTC): " .. os.date("!%Y-%m-%d %H:%M:%S", nextSpawn))
    print("Relative: " .. (nextSpawn - currentTime) / 60 .. " minutes")
else
    print("No spawn found")
end

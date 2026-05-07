local Compat = loadstring(game:HttpGet("https://raw.githubusercontent.com/bo-xd/Bhub-remastered/main/src/util/ExecutorCompat.lua"))()

print("--- EXECUTOR COMPATIBILITY TEST ---")

print("Drawing Support: ", Compat.Supports["Drawing.new"])
print("FileIO Support:  ", Compat.Supports["writefile"])
print("HTTP Support:    ", Compat.Supports["request"])

print("\n--- Feature Status ---")
local features = {"DrawingAPI", "FileIO", "HTTP", "Clipboard", "Proximity"}

for _, f in ipairs(features) do
    local status = Compat:CanUse(f) and "[ENABLED]" or "[DISABLED - Missing Functions]"
    print(string.format("%-12s: %s", f, status))
end

if not Compat:CanUse("FileIO") then
    warn("Skipping Auto-Config: Executor lacks file system access.")
else
    print("Success: Config system is ready.")
end

if not Compat:CanUse("DrawingAPI") then
    warn("Visuals limited: Falling back to Folder/Highlight ESP.")
end

print("\nTest completed.")
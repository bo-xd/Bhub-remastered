local function MockEnvironment(mode)
    print("--- SIMULATING ENVIRONMENT: " .. mode .. " ---")
    
    if mode == "LowTier" then
        getgenv().Drawing = nil
        getgenv().fireproximityprompt = nil
        print("Set Drawing and Proximity to NIL.")
        
    elseif mode == "NoFileIO" then
        getgenv().writefile = nil
        getgenv().readfile = nil
        getgenv().makefolder = nil
        print("Set FileIO functions to NIL.")
        
    elseif mode == "Strict" then
        getgenv().setclipboard = nil
        getgenv().request = nil
        getgenv().http_request = nil
    end
end

MockEnvironment("LowTier")

loadstring(game:HttpGet("https://raw.githubusercontent.com/bo-xd/Bhub-remastered/main/src/util/ExecutorCompat.lua"))()

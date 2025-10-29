--[[
    File: src/server/init.server.lua
    Tujuan: Server bootstrap dengan manual service loading + auto-discovery test
    Versi Modul: 3.1.0
--]]

print("🚀 OVHL Server Starting...")
print("📍 Fase 1: Manual Bootstrap + Auto-Discovery Test")

local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)

-- Manual service loading sequence
local function LoadServices()
    print("🔧 Loading services manually...")
    
    -- Service loading order berdasarkan dependencies
    local servicesToLoad = {
        "ConfigService",
        "LoggerService", 
        "DependencyResolver",
        "ServiceManager",
        "ModuleLoader"
    }
    
    local loadedCount = 0
    
    for _, serviceName in ipairs(servicesToLoad) do
        local success, service = pcall(function()
            return require(script.services[serviceName])
        end)
        
        if success then
            -- Create instance
            local instance = {}
            setmetatable(instance, service)
            
            -- Register ke OVHL
            OVHL:_registerService(serviceName, instance)
            print("   ✅ " .. serviceName .. " registered")
            loadedCount += 1
            
            -- Manual dependency injection untuk core services
            if serviceName == "ConfigService" then
                instance:Inject({})
                instance:Init()
                instance:Start()
            elseif serviceName == "LoggerService" then
                instance:Inject({ConfigService = OVHL:GetService("ConfigService")})
                instance:Init()
                instance:Start()
            elseif serviceName == "DependencyResolver" then
                instance:Inject({LoggerService = OVHL:GetService("LoggerService")})
                instance:Init() 
                instance:Start()
            elseif serviceName == "ServiceManager" then
                instance:Inject({
                    LoggerService = OVHL:GetService("LoggerService"),
                    DependencyResolver = OVHL:GetService("DependencyResolver"),
                    ConfigService = OVHL:GetService("ConfigService")
                })
                instance:Init()
                instance:Start()
            elseif serviceName == "ModuleLoader" then
                instance:Inject({
                    LoggerService = OVHL:GetService("LoggerService"),
                    DependencyResolver = OVHL:GetService("DependencyResolver"),
                    ConfigService = OVHL:GetService("ConfigService"),
                    ServiceManager = OVHL:GetService("ServiceManager")
                })
                instance:Init()
                instance:Start()
            end
        else
            warn("   ❌ Failed to load: " .. serviceName .. " - " .. tostring(service))
        end
    end
    
    return loadedCount
end

-- Initialize framework
local loadedCount = LoadServices()

print("")
print("🎉 OVHL Server Ready!")
print("📊 Loaded Services: " .. loadedCount)
print("🔍 Testing Auto-Discovery System...")

-- Test auto-discovery setelah semua services loaded
task.delay(3, function()
    print("")
    print("🧪 AUTO-DISCOVERY TEST RESULTS:")
    
    local serviceManager = OVHL:GetService("ServiceManager")
    if serviceManager then
        local services = serviceManager:GetAllServices()
        local runningCount = 0
        
        for name, info in pairs(services) do
            print("   " .. name .. ": " .. info.status)
            if info.status == "running" then
                runningCount += 1
            end
        end
        
        print("   ✅ " .. runningCount .. "/" .. loadedCount .. " services running via auto-discovery")
    else
        print("   ❌ ServiceManager not available for auto-discovery test")
    end
    
    local moduleLoader = OVHL:GetService("ModuleLoader")
    if moduleLoader then
        local modules = moduleLoader:GetAllModules()
        print("   ✅ " .. #modules .. " modules loaded via auto-discovery")
    end
    
    print("")
    print("📊 FINAL OVHL STATUS:")
    OVHL:DebugDump()
end)


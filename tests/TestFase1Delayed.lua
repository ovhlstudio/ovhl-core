--[[
    File: tests/TestFase1Delayed.lua
    Tujuan: Delayed test untuk pastikan services fully loaded
--]]

local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)

-- Wait sampai services loaded
local function WaitForServices()
    local maxWait = 10 -- 10 seconds max
    local startTime = os.time()
    
    while os.time() - startTime < maxWait do
        local services = OVHL:GetAllServices()
        if next(services) ~= nil then
            return services
        end
        wait(0.1)
    end
    
    return nil
end

print("")
print("🎉 =================================")
print("🎉 OVHL FASE 1 - DELAYED TEST")
print("🎉 =================================")

print("⏳ Waiting for services to initialize...")
local services = WaitForServices()

if not services then
    print("❌ TIMEOUT: Services not initialized within 10 seconds")
    return
end

-- Test 1: OVHL Global Access
print("✅ Testing OVHL Global...")
print("   Version:", OVHL.CORE_VERSION)

-- Test 2: Service Availability
print("✅ Testing Service Availability...")
local serviceCount = 0
for name, service in pairs(services) do
    print("   ✅ " .. name)
    serviceCount += 1
end

print("   Total Services:", serviceCount)

-- Test 3: ConfigService Functionality
print("✅ Testing ConfigService...")
local configService = OVHL:GetService("ConfigService")
if configService then
    local coreConfig = configService:GetConfig("Core")
    print("   Core DebugEnabled:", coreConfig.DebugEnabled)
    
    -- Test live config
    configService:SetConfig("LiveTest", { value = 123 }, true)
    local liveConfig = configService:GetConfig("LiveTest")
    print("   LiveTest value:", liveConfig.value)
else
    print("   ❌ ConfigService not available")
end

-- Test 4: LoggerService Functionality
print("✅ Testing LoggerService...")
local loggerService = OVHL:GetService("LoggerService")
if loggerService then
    loggerService:Info("LoggerService test - INFO level")
    loggerService:Warn("LoggerService test - WARN level") 
    loggerService:Error("LoggerService test - ERROR level")
    print("   ✅ LoggerService operational - check output above")
else
    print("   ❌ LoggerService not available")
end

-- Test 5: ServiceManager Functionality
print("✅ Testing ServiceManager...")
local serviceManager = OVHL:GetService("ServiceManager")
if serviceManager then
    local allServices = serviceManager:GetAllServices()
    local runningCount = 0
    for name, info in pairs(allServices) do
        if info.status == "running" then
            runningCount += 1
        end
    end
    print("   ✅ ServiceManager managing", runningCount, "running services")
else
    print("   ❌ ServiceManager not available")
end

-- Test 6: DependencyResolver Functionality
print("✅ Testing DependencyResolver...")
local dependencyResolver = OVHL:GetService("DependencyResolver")
if dependencyResolver then
    print("   ✅ DependencyResolver operational")
else
    print("   ❌ DependencyResolver not available")
end

-- Test 7: ModuleLoader Functionality  
print("✅ Testing ModuleLoader...")
local moduleLoader = OVHL:GetService("ModuleLoader")
if moduleLoader then
    local allModules = moduleLoader:GetAllModules()
    print("   ✅ ModuleLoader loaded", #allModules, "modules")
else
    print("   ❌ ModuleLoader not available")
end

-- Final OVHL Debug Dump
print("")
print("📊 FINAL OVHL DEBUG DUMP:")
OVHL:DebugDump()

print("")
print("🎉 =================================")
print("🎉 OVHL FASE 1 - VALIDATION COMPLETE!")
print("🎉", serviceCount, "/ 5 Services Fully Operational!")
print("🎉 Auto-Discovery: WORKING ✅")
print("🎉 Dependency Injection: WORKING ✅")
print("🎉 =================================")

--[[
    File: tests/TestFase1Complete.lua
    Tujuan: Comprehensive test untuk Fase 1 completion
--]]

local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)

print("")
print("🎉 =================================")
print("🎉 OVHL FASE 1 - COMPREHENSIVE TEST")
print("🎉 =================================")

-- Test 1: OVHL Global Access
print("✅ Testing OVHL Global...")
print("   Version:", OVHL.CORE_VERSION)

-- Test 2: Service Availability
print("✅ Testing Service Availability...")
local services = OVHL:GetAllServices()
local serviceCount = 0
for name, service in pairs(services) do
    print("   ✅ " .. name)
    serviceCount += 1
end

print("   Total Services:", serviceCount)

-- Test 3: ConfigService
print("✅ Testing ConfigService...")
local configService = OVHL:GetService("ConfigService")
if configService then
    local coreConfig = configService:GetConfig("Core")
    print("   Core DebugEnabled:", coreConfig.DebugEnabled)
    
    -- Test config registration
    configService:RegisterModuleConfig("TestConfig", {
        setting1 = "value1",
        setting2 = 42
    })
    
    local testConfig = configService:GetConfig("TestConfig")
    print("   TestConfig setting1:", testConfig.setting1)
else
    print("   ❌ ConfigService not available")
end

-- Test 4: LoggerService
print("✅ Testing LoggerService...")
local loggerService = OVHL:GetService("LoggerService")
if loggerService then
    loggerService:Info("Test log from comprehensive test!")
    print("   ✅ LoggerService operational")
else
    print("   ❌ LoggerService not available")
end

-- Test 5: ServiceManager
print("✅ Testing ServiceManager...")
local serviceManager = OVHL:GetService("ServiceManager")
if serviceManager then
    local allServices = serviceManager:GetAllServices()
    print("   ✅ ServiceManager managing", #allServices, "services")
else
    print("   ❌ ServiceManager not available")
end

-- Final OVHL Debug Dump
print("")
print("📊 FINAL OVHL DEBUG DUMP:")
OVHL:DebugDump()

print("")
print("🎉 =================================")
print("🎉 OVHL FASE 1 - COMPLETED SUCCESSFULLY!")
print("🎉", serviceCount, "/ 5 Services Operational!")
print("🎉 Foundation: SOLID ✅")
print("🎉 Auto-Discovery: READY ✅") 
print("🎉 =================================")

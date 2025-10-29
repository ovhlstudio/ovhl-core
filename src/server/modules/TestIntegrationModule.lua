--[[
    File: src/server/modules/TestIntegrationModule.lua
    Tujuan: Integration test untuk verify EventBus & ConfigService functionality
    Versi Modul: 1.0.1 - FIXED DI
--]]

local TestIntegrationModule = {}
TestIntegrationModule.__index = TestIntegrationModule

TestIntegrationModule.__manifest = {
    name = "TestIntegrationModule",
    version = "1.0.1",
    type = "module",
    dependencies = {"Logger", "EventBusService", "ConfigService"},
    priority = 40,
    domain = "test",
    description = "Integration test untuk verify EventBus & ConfigService - FIXED DI"
}

function TestIntegrationModule.new(logger)
    local self = setmetatable({}, TestIntegrationModule)
    self.logger = logger
    self.testResults = {}
    self.eventBus = nil
    self.configService = nil
    return self
end

function TestIntegrationModule:Inject(services)
    self.logger:Info("🔍 INJECT: Received services", {count = #services})
    
    -- DEBUG: List all available services
    for name, service in pairs(services) do
        self.logger:Debug("📦 Available service: " .. name)
    end
    
    self.eventBus = services.EventBusService
    self.configService = services.ConfigService
    
    if self.eventBus then
        self.logger:Info("✅ EventBusService injected successfully!")
    else
        self.logger:Error("❌ EventBusService injection FAILED!")
    end
    
    if self.configService then
        self.logger:Info("✅ ConfigService injected successfully!")
    else
        self.logger:Error("❌ ConfigService injection FAILED!")
    end
end

function TestIntegrationModule:Init()
    self.logger:Info("🔧 TestIntegrationModule initializing...")
    
    -- Verify dependencies are available
    if not self.eventBus then
        self.logger:Error("🚨 CRITICAL: EventBusService not available!")
        return false
    end
    
    if not self.configService then
        self.logger:Error("🚨 CRITICAL: ConfigService not available!")
        return false
    end
    
    self.logger:Info("✅ All dependencies verified!")
    return true
end

function TestIntegrationModule:Start()
    self.logger:Info("🚀 TestIntegrationModule starting integration tests...")
    
    -- Delay untuk pastikan system ready
    task.delay(5, function()
        self:RunSafeIntegrationTests()
    end)
end

function TestIntegrationModule:RunSafeIntegrationTests()
    self.logger:Info("🎯 STARTING SAFE INTEGRATION TESTS...")
    
    -- TEST dengan safety check
    if not self.eventBus or not self.configService then
        self.logger:Error("🚨 CANNOT RUN TESTS: Dependencies missing!")
        return
    end
    
    -- TEST 1: EventBus Basic dengan safety
    self:TestEventBusBasicSafe()
    
    -- TEST 2: ConfigService Basic dengan safety  
    self:TestConfigServiceBasicSafe()
    
    -- Report results
    task.delay(3, function()
        self:ReportTestResults()
    end)
end

function TestIntegrationModule:TestEventBusBasicSafe()
    self.logger:Info("🧪 TEST 1: EventBus Basic (Safe)")
    
    if not self.eventBus then
        self.logger:Error("❌ TEST 1 SKIPPED: EventBus not available")
        self.testResults.eventBusBasic = false
        return
    end
    
    local testPassed = false
    local unsubscribe
    
    -- Subscribe to test event dengan error handling
    local success, err = pcall(function()
        unsubscribe = self.eventBus:Subscribe("IntegrationTestEvent", function(message, data)
            self.logger:Info("✅ EVENTBUS RECEIVED: " .. tostring(message), data)
            testPassed = (message == "Hello EventBus!" and data.test == true)
            
            if testPassed then
                self.logger:Info("🎉 TEST 1 PASSED: EventBus emit/subscribe working!")
            else
                self.logger:Error("❌ TEST 1 FAILED: EventBus data mismatch")
            end
            
            -- Cleanup
            if unsubscribe then
                unsubscribe()
            end
        end)
    end)
    
    if not success then
        self.logger:Error("❌ TEST 1 FAILED: Subscription error", {error = err})
        self.testResults.eventBusBasic = false
        return
    end
    
    -- Emit test event after a short delay
    task.delay(1, function()
        local emitSuccess, emitErr = pcall(function()
            self.eventBus:Emit("IntegrationTestEvent", "Hello EventBus!", {test = true, number = 42})
        end)
        
        if not emitSuccess then
            self.logger:Error("❌ TEST 1 FAILED: Emit error", {error = emitErr})
            self.testResults.eventBusBasic = false
        end
    end)
    
    self.testResults.eventBusBasic = testPassed
end

function TestIntegrationModule:TestConfigServiceBasicSafe()
    self.logger:Info("🧪 TEST 2: ConfigService Basic (Safe)")
    
    if not self.configService then
        self.logger:Error("❌ TEST 2 SKIPPED: ConfigService not available")
        self.testResults.configServiceBasic = false
        return
    end
    
    local success, err = pcall(function()
        -- Test GetConfig
        local config = self.configService:GetConfig("ConfigService")
        if config and config.AutoSaveInterval then
            self.logger:Info("✅ ConfigService.GetConfig() working - AutoSaveInterval: " .. tostring(config.AutoSaveInterval))
            
            -- Test SetConfig
            local newConfig = {TestValue = 123, TestString = "integration_test"}
            self.configService:SetConfig("TestIntegrationModule", newConfig)
            
            -- Verify set worked
            local retrievedConfig = self.configService:GetConfig("TestIntegrationModule")
            if retrievedConfig and retrievedConfig.TestValue == 123 then
                self.logger:Info("🎉 TEST 2 PASSED: ConfigService get/set working!")
                self.testResults.configServiceBasic = true
            else
                self.logger:Error("❌ TEST 2 FAILED: ConfigService set/get mismatch")
                self.testResults.configServiceBasic = false
            end
        else
            self.logger:Error("❌ TEST 2 FAILED: ConfigService.GetConfig() returned nil")
            self.testResults.configServiceBasic = false
        end
    end)
    
    if not success then
        self.logger:Error("❌ TEST 2 FAILED: ConfigService error", {error = err})
        self.testResults.configServiceBasic = false
    end
end

function TestIntegrationModule:ReportTestResults()
    self.logger:Info("📊 INTEGRATION TEST RESULTS:")
    
    local passed = 0
    local total = 0
    
    for testName, result in pairs(self.testResults) do
        total = total + 1
        if result then
            passed = passed + 1
            self.logger:Info("   ✅ " .. testName .. ": PASSED")
        else
            self.logger:Error("   ❌ " .. testName .. ": FAILED")
        end
    end
    
    if passed == total and total > 0 then
        self.logger:Info("🎉 ALL INTEGRATION TESTS PASSED! (" .. passed .. "/" .. total .. ")")
    else
        self.logger:Warn("⚠️ SOME TESTS FAILED: (" .. passed .. "/" .. total .. " passed)")
    end
end

return TestIntegrationModule

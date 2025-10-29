--[[
    File: src/client/modules/ClientGlobalTest.lua
    Tujuan: Test client global OVHL access dari module scope
    Versi Modul: 1.0.0
--]]

local ClientGlobalTest = {}
ClientGlobalTest.__index = ClientGlobalTest

ClientGlobalTest.__manifest = {
    name = "ClientGlobalTest",
    version = "1.0.0",
    type = "module",
    dependencies = {"Logger"},
    priority = 30,
    domain = "test",
    description = "Test client global OVHL access"
}

function ClientGlobalTest.new(logger)
    local self = setmetatable({}, ClientGlobalTest)
    self.logger = logger
    return self
end

function ClientGlobalTest:Inject(services) end

function ClientGlobalTest:Init()
    self.logger:Info("🔧 ClientGlobalTest initializing...")
    return true
end

function ClientGlobalTest:Start()
    self.logger:Info("🚀 ClientGlobalTest starting...")
    
    -- Test _G.OVHL access dari module scope
    task.delay(2, function()
        self:TestGlobalAccess()
    end)
end

function ClientGlobalTest:TestGlobalAccess()
    self.logger:Info("🎯 TESTING _G.OVHL ACCESS FROM MODULE SCOPE...")
    
    if _G.OVHL then
        self.logger:Info("✅ _G.OVHL FOUND in module scope!")
        
        -- Test basic functionality
        if _G.OVHL:IsClient() then
            self.logger:Info("✅ OVHL:IsClient() = true")
        else
            self.logger:Error("❌ OVHL:IsClient() = false (should be true!)")
        end
        
        local controllers = _G.OVHL:GetAllControllers()
        if controllers then
            self.logger:Info("✅ OVHL:GetAllControllers() successful - Count: " .. tostring(#controllers))
            for name, _ in pairs(controllers) do
                self.logger:Info("   📋 Controller: " .. name)
            end
        else
            self.logger:Error("❌ OVHL:GetAllControllers() failed")
        end
        
        self.logger:Info("🎉 CLIENT GLOBAL ACCESS TEST PASSED!")
    else
        self.logger:Error("🚨 _G.OVHL NOT FOUND in module scope!")
        self.logger:Error("🚨 This means _G scope berbeda antara bootstrap dan modules!")
    end
end

return ClientGlobalTest

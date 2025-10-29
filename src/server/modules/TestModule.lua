--[[
    File: src/server/modules/TestModule.lua
    Tujuan: Test module untuk validasi auto-discovery system
    Versi Modul: 1.0.0
--]]

local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)

local TestModule = {}
TestModule.__index = TestModule

-- MANIFEST WAJIB
TestModule.__manifest = {
    name = "TestModule",
    version = "1.0.0",
    type = "module",
    dependencies = {"LoggerService"},
    priority = 50,
    domain = "test",
    description = "Test module untuk validasi auto-discovery",
    autoload = true
}

-- CONFIG DEFAULT
TestModule.__config = {
    enabled = true,
    message = "Hello from TestModule!"
}

-- PROPERTIES INTERNAL
TestModule.logger = nil
TestModule.config = nil

-- ==================== MODULE METHODS ====================

function TestModule:ShowMessage()
    if self.logger then
        self.logger:Info("TestModule message", {
            message = self.config.message,
            enabled = self.config.enabled
        })
    else
        print("📢 TestModule: " .. self.config.message)
    end
end

-- ==================== LIFECYCLE METHODS ====================

function TestModule:Inject(services)
    self.logger = services.LoggerService
end

function TestModule:Init()
    self.config = OVHL:GetConfig("TestModule") or self.__config
    
    if self.logger then
        self.logger:Info("TestModule initialized", {
            enabled = self.config.enabled
        })
    end
    
    return self.config.enabled
end

function TestModule:Start()
    if self.logger then
        self.logger:Info("TestModule started")
    end
    
    -- Schedule test message
    task.delay(2, function()
        self:ShowMessage()
    end)
    
    return true
end

return TestModule

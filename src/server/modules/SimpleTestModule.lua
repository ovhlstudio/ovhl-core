local SimpleTestModule = {}
SimpleTestModule.__index = SimpleTestModule

SimpleTestModule.__manifest = {
    name = "SimpleTestModule",
    version = "1.0.0",
    type = "module",
    dependencies = {"Logger"},  -- ONLY LOGGER FOR NOW
    priority = 50,
    domain = "test",
    description = "Simple test module to verify basic functionality"
}

function SimpleTestModule.new(logger)
    local self = setmetatable({}, SimpleTestModule)
    self.logger = logger
    return self
end

function SimpleTestModule:Inject(services)
    self.logger:Info("✅ SimpleTestModule injected successfully!")
    self.logger:Debug("🔍 Available services:", {services = services})
end

function SimpleTestModule:Init()
    self.logger:Info("🔧 SimpleTestModule initializing...")
    return true
end

function SimpleTestModule:Start()
    self.logger:Info("🚀 SimpleTestModule started!")
    
    -- SIMPLE TEST SEQUENCE
    task.delay(2, function()
        self.logger:Info("🎯 TEST 1: Basic logging - PASSED!")
    end)
    
    task.delay(4, function()
        self.logger:Info("🎯 TEST 2: Task scheduling - PASSED!")
    end)
    
    task.delay(6, function()
        self.logger:Info("🎉 ALL BASIC TESTS COMPLETED SUCCESSFULLY!")
    end)
end

return SimpleTestModule

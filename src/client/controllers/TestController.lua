local TestController = {}
TestController.__index = TestController

TestController.__manifest = {
    name = "TestController",
    version = "1.0.0",
    type = "controller",
    dependencies = {"Logger"},
    priority = 80,
    domain = "test",
    description = "Test controller for client bootstrap verification"
}

function TestController.new(logger)
    local self = setmetatable({}, TestController)
    self.logger = logger
    return self
end

function TestController:Inject(services) end

function TestController:Init()
    self.logger:Info("TestController initialized successfully!")
    return true
end

function TestController:Start()
    self.logger:Info("TestController started successfully!")
end

return TestController

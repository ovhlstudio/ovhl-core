local TestService = {}
TestService.__index = TestService

TestService.__manifest = {
    name = "TestService",
    version = "1.0.0",
    type = "service",
    dependencies = {"Logger"},
    priority = 80,
    domain = "test",
    description = "Test service for bootstrap verification"
}

function TestService.new(logger)
    local self = setmetatable({}, TestService)
    self.logger = logger
    return self
end

function TestService:Inject(services) end

function TestService:Init()
    self.logger:Info("TestService initialized successfully!")
    return true
end

function TestService:Start()
    self.logger:Info("TestService started successfully!")
end

return TestService

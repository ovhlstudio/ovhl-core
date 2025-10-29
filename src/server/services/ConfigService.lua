local ConfigService = {}
ConfigService.__index = ConfigService

ConfigService.__manifest = {
    name = "ConfigService",
    version = "1.0.0",
    type = "service",
    dependencies = {"Logger"},
    priority = 70,
    domain = "core",
    description = "Manages game configuration and live config updates"
}

ConfigService.__config = {
    AutoSaveInterval = 300,
    EnableLiveConfigUpdates = true,
    DefaultGameMode = "Survival",
    MaxPlayers = 50
}

function ConfigService.new(logger)
    local self = setmetatable({}, ConfigService)
    self.logger = logger
    self.configs = {}
    self.listeners = {}
    self._services = {}  -- Store services for lazy access
    return self
end

function ConfigService:Inject(services)
    self._services = services  -- Store all services
    self.logger:Debug("ConfigService injected with services", {
        serviceCount = #services
    })
end

function ConfigService:Init()
    self.logger:Info("ConfigService initializing...")
    
    -- Load default config from self
    if self.__config then
        self.configs["ConfigService"] = self.__config
        self.logger:Debug("Loaded default config", {service = "ConfigService"})
    end
    
    return true
end

function ConfigService:Start()
    self.logger:Info("ConfigService started")
    
    -- LAZY get EventBus if available
    local eventBus = self._services.EventBusService
    if eventBus then
        eventBus:Subscribe("ConfigChanged", function(moduleName, newConfig)
            self:UpdateConfig(moduleName, newConfig)
        end)
        self.logger:Debug("Registered with EventBus")
    else
        self.logger:Warn("EventBusService not available for ConfigService")
    end
end

-- ==================== PUBLIC API ====================

function ConfigService:GetConfig(moduleName)
    return self.configs[moduleName] or {}
end

function ConfigService:SetConfig(moduleName, config)
    local oldConfig = self.configs[moduleName]
    self.configs[moduleName] = config
    
    self.logger:Info("Config updated", {
        module = moduleName,
        old = oldConfig,
        new = config
    })
    
    -- LAZY emit event if EventBus available
    local eventBus = self._services.EventBusService
    if eventBus then
        eventBus:Emit("ConfigChanged", moduleName, config)
    end
    
    -- Call listeners
    if self.listeners[moduleName] then
        for _, listener in ipairs(self.listeners[moduleName]) do
            task.spawn(function()
                pcall(listener, moduleName, config)
            end)
        end
    end
end

function ConfigService:UpdateConfig(moduleName, configUpdates)
    local currentConfig = self:GetConfig(moduleName)
    local newConfig = {}
    
    -- Merge configs
    for k, v in pairs(currentConfig) do
        newConfig[k] = v
    end
    for k, v in pairs(configUpdates) do
        newConfig[k] = v
    end
    
    self:SetConfig(moduleName, newConfig)
end

function ConfigService:RegisterConfigListener(moduleName, callback)
    if not self.listeners[moduleName] then
        self.listeners[moduleName] = {}
    end
    table.insert(self.listeners[moduleName], callback)
    
    self.logger:Debug("Config listener registered", {module = moduleName})
    
    -- Return unsubscribe function
    return function()
        for i, listener in ipairs(self.listeners[moduleName]) do
            if listener == callback then
                table.remove(self.listeners[moduleName], i)
                self.logger:Debug("Config listener removed", {module = moduleName})
                break
            end
        end
    end
end

function ConfigService:GetAllConfigs()
    return self.configs
end

function ConfigService:ResetConfig(moduleName)
    self.configs[moduleName] = nil
    self.logger:Info("Config reset", {module = moduleName})
    
    local eventBus = self._services.EventBusService
    if eventBus then
        eventBus:Emit("ConfigChanged", moduleName, nil)
    end
end

return ConfigService

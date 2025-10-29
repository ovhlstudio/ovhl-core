--[[
    File: src/server/services/ServiceManager.lua
    Tujuan: Auto-discovery dan management untuk services
    Versi Modul: 3.0.0
--]]

local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)

local ServiceManager = {}
ServiceManager.__index = ServiceManager

-- MANIFEST WAJIB
ServiceManager.__manifest = {
    name = "ServiceManager",
    version = "3.0.0",
    type = "service",
    dependencies = {"LoggerService", "DependencyResolver", "ConfigService"},
    priority = 80,
    domain = "system",
    description = "Auto-discovery dan lifecycle management untuk services"
}

-- PROPERTIES INTERNAL
ServiceManager.logger = nil
ServiceManager.dependencyResolver = nil
ServiceManager.configService = nil
ServiceManager.loadedServices = {}

-- ==================== CORE SERVICE MANAGEMENT ====================

function ServiceManager:DiscoverServices()
    local servicesFolder = script.Parent
    local discoveredServices = {}
    
    self.logger:Info("Discovering services...", {folder = tostring(servicesFolder)})
    
    for _, child in ipairs(servicesFolder:GetChildren()) do
        if child:IsA("ModuleScript") and child ~= script then
            local success, serviceModule = pcall(require, child)
            
            if success and serviceModule.__manifest then
                local manifest = serviceModule.__manifest
                
                if manifest.type == "service" then
                    table.insert(discoveredServices, serviceModule)
                    self.logger:Debug("Discovered service", {
                        name = manifest.name,
                        version = manifest.version
                    })
                end
            else
                self.logger:Warn("Invalid service module", {
                    module = child.Name,
                    error = not success and serviceModule or "No manifest"
                })
            end
        end
    end
    
    return discoveredServices
end

function ServiceManager:InitializeService(serviceModule)
    local manifest = serviceModule.__manifest
    local serviceName = manifest.name
    
    self.logger:Info("Initializing service", {service = serviceName})
    
    -- Create service instance
    local serviceInstance = {}
    setmetatable(serviceInstance, serviceModule)
    
    -- Store instance
    self.loadedServices[serviceName] = {
        instance = serviceInstance,
        manifest = manifest,
        status = "initializing"
    }
    
    return serviceInstance
end

function ServiceManager:InjectDependencies(serviceInstance, servicesMap)
    local manifest = serviceInstance.__manifest
    local dependencies = manifest.dependencies or {}
    
    local resolvedServices = {}
    for _, depName in ipairs(dependencies) do
        if servicesMap[depName] then
            resolvedServices[depName] = servicesMap[depName].instance
        else
            self.logger:Error("Dependency not found", {
                service = manifest.name,
                dependency = depName
            })
            return false
        end
    end
    
    if serviceInstance.Inject then
        local success, err = pcall(serviceInstance.Inject, serviceInstance, resolvedServices)
        if not success then
            self.logger:Error("Dependency injection failed", {
                service = manifest.name,
                error = err
            })
            return false
        end
    end
    
    return true
end

function ServiceManager:LoadServices()
    self.logger:Info("Starting service loading process...")
    
    -- Discover services
    local discoveredServices = self:DiscoverServices()
    if #discoveredServices == 0 then
        self.logger:Warn("No services discovered")
        return true
    end
    
    -- Resolve dependencies
    local loadOrder = self.dependencyResolver:ResolveLoadOrder(discoveredServices)
    if not loadOrder then
        self.logger:Error("Failed to resolve service dependencies")
        return false
    end
    
    -- Create service instances map
    local servicesMap = {}
    for _, serviceModule in ipairs(discoveredServices) do
        local serviceName = serviceModule.__manifest.name
        servicesMap[serviceName] = {
            module = serviceModule,
            instance = self:InitializeService(serviceModule)
        }
    end
    
    -- Phase 1: Inject dependencies
    self.logger:Info("Phase 1: Injecting dependencies...")
    for _, serviceName in ipairs(loadOrder) do
        local serviceInfo = servicesMap[serviceName]
        if serviceInfo then
            local success = self:InjectDependencies(serviceInfo.instance, servicesMap)
            if not success then
                return false
            end
        end
    end
    
    -- Phase 2: Initialize services
    self.logger:Info("Phase 2: Initializing services...")
    for _, serviceName in ipairs(loadOrder) do
        local serviceInfo = servicesMap[serviceName]
        if serviceInfo and serviceInfo.instance.Init then
            local success, result = pcall(serviceInfo.instance.Init, serviceInfo.instance)
            if not success then
                self.logger:Error("Service initialization failed", {
                    service = serviceName,
                    error = result
                })
                self.loadedServices[serviceName].status = "failed"
            else
                self.loadedServices[serviceName].status = result and "initialized" or "disabled"
                if result then
                    self.logger:Info("Service initialized", {service = serviceName})
                end
            end
        end
    end
    
    -- Phase 3: Start services
    self.logger:Info("Phase 3: Starting services...")
    for _, serviceName in ipairs(loadOrder) do
        local serviceInfo = servicesMap[serviceName]
        if serviceInfo and serviceInfo.instance.Start and self.loadedServices[serviceName].status == "initialized" then
            local success, err = pcall(serviceInfo.instance.Start, serviceInfo.instance)
            if not success then
                self.logger:Error("Service startup failed", {
                    service = serviceName,
                    error = err
                })
                self.loadedServices[serviceName].status = "startup_failed"
            else
                self.loadedServices[serviceName].status = "running"
                self.logger:Info("Service started", {service = serviceName})
            end
        end
    end
    
    self.logger:Info("Service loading completed", {
        total = #discoveredServices,
        running = self:GetRunningServiceCount()
    })
    
    return true
end

function ServiceManager:GetRunningServiceCount()
    local count = 0
    for _, serviceInfo in pairs(self.loadedServices) do
        if serviceInfo.status == "running" then
            count += 1
        end
    end
    return count
end

-- ==================== LIFECYCLE METHODS ====================

function ServiceManager:Inject(services)
    self.logger = services.LoggerService
    self.dependencyResolver = services.DependencyResolver
    self.configService = services.ConfigService
end

function ServiceManager:Init()
    OVHL:_registerService("ServiceManager", self)
    self.logger:Info("ServiceManager initialized")
    return true
end

function ServiceManager:Start()
    self.logger:Info("ServiceManager starting service discovery...")
    
    local success = self:LoadServices()
    if not success then
        self.logger:Error("ServiceManager failed to load services")
        return false
    end
    
    self.logger:Info("ServiceManager started successfully")
    return true
end

-- ==================== PUBLIC API ====================

function ServiceManager:GetService(serviceName)
    local serviceInfo = self.loadedServices[serviceName]
    return serviceInfo and serviceInfo.instance
end

function ServiceManager:GetAllServices()
    return self.loadedServices
end

return ServiceManager

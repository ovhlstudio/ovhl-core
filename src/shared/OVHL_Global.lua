--[[
    File: src/shared/OVHL_Global.lua
    Tujuan: Global API accessor untuk OVHL framework (Server & Client)
    Versi Modul: 1.0.1
--]]

local OVHLGlobal = {}
OVHLGlobal.__index = OVHLGlobal

function OVHLGlobal.new(config)
    local self = setmetatable({}, OVHLGlobal)
    
    self._services = config.services or {}
    self._modules = config.modules or {}
    self._controllers = config.controllers or {}
    self._logger = config.logger
    self._isClient = config.isClient or false
    
    if self._logger then
        self._logger:Info("OVHL Global API initialized", {isClient = self._isClient})
    else
        print("ℹ️ [OVHL] Global API initialized (isClient: " .. tostring(self._isClient) .. ")")
    end
    
    return self
end

-- SERVICE/MODULE ACCESS
function OVHLGlobal:GetService(serviceName)
    if self._isClient then
        return self._controllers[serviceName] or self._services[serviceName]
    else
        return self._services[serviceName]
    end
end

function OVHLGlobal:GetModule(moduleName)
    return self._modules[moduleName]
end

function OVHLGlobal:GetConfig(moduleName)
    local module = self:GetService(moduleName) or self:GetModule(moduleName)
    if module and module.__config then
        return module.__config
    end
    return nil
end

-- SERVER-ONLY API
function OVHLGlobal:Emit(eventName, ...)
    if self._isClient then
        if self._logger then
            self._logger:Warn("Emit is server-only, use Fire/Invoke for client-server communication")
        end
        return
    end
    
    local eventBus = self:GetService("EventBusService")
    if eventBus and eventBus.Emit then
        eventBus:Emit(eventName, ...)
    else
        if self._logger then
            self._logger:Warn("EventBusService not available for event: " .. tostring(eventName))
        end
    end
end

function OVHLGlobal:Subscribe(eventName, callback)
    if self._isClient then
        if self._logger then
            self._logger:Warn("Subscribe is server-only, use Listen for client-server communication")
        end
        return function() end
    end
    
    local eventBus = self:GetService("EventBusService")
    if eventBus and eventBus.Subscribe then
        return eventBus:Subscribe(eventName, callback)
    else
        if self._logger then
            self._logger:Warn("EventBusService not available for subscription: " .. tostring(eventName))
        end
        return function() end
    end
end

-- CLIENT-ONLY API
function OVHLGlobal:Fire(remoteName, ...)
    if not self._isClient then
        if self._logger then
            self._logger:Warn("Fire is client-only, use Emit for server internal events")
        end
        return
    end
    
    local remoteClient = self:GetService("RemoteClient")
    if remoteClient and remoteClient.Fire then
        remoteClient:Fire(remoteName, ...)
    else
        if self._logger then
            self._logger:Warn("RemoteClient not available for remote: " .. tostring(remoteName))
        end
    end
end

function OVHLGlobal:Invoke(remoteName, ...)
    if not self._isClient then
        if self._logger then
            self._logger:Warn("Invoke is client-only")
        end
        return nil
    end
    
    local remoteClient = self:GetService("RemoteClient")
    if remoteClient and remoteClient.Invoke then
        return remoteClient:Invoke(remoteName, ...)
    else
        if self._logger then
            self._logger:Warn("RemoteClient not available for remote: " .. tostring(remoteName))
        end
        return nil
    end
end

function OVHLGlobal:Listen(remoteName, callback)
    if not self._isClient then
        if self._logger then
            self._logger:Warn("Listen is client-only")
        end
        return function() end
    end
    
    local remoteClient = self:GetService("RemoteClient")
    if remoteClient and remoteClient.Listen then
        return remoteClient:Listen(remoteName, callback)
    else
        if self._logger then
            self._logger:Warn("RemoteClient not available for listening: " .. tostring(remoteName))
        end
        return function() end
    end
end

function OVHLGlobal:SetState(key, value)
    if not self._isClient then
        if self._logger then
            self._logger:Warn("SetState is client-only")
        end
        return
    end
    
    local stateManager = self:GetService("StateManager")
    if stateManager and stateManager.SetState then
        stateManager:SetState(key, value)
    else
        if self._logger then
            self._logger:Warn("StateManager not available for state: " .. tostring(key))
        end
    end
end

function OVHLGlobal:GetState(key)
    if not self._isClient then
        if self._logger then
            self._logger:Warn("GetState is client-only")
        end
        return nil
    end
    
    local stateManager = self:GetService("StateManager")
    if stateManager and stateManager.GetState then
        return stateManager:GetState(key)
    else
        if self._logger then
            self._logger:Warn("StateManager not available for state: " .. tostring(key))
        end
        return nil
    end
end

function OVHLGlobal:SubscribeState(key, callback)
    if not self._isClient then
        if self._logger then
            self._logger:Warn("SubscribeState is client-only")
        end
        return function() end
    end
    
    local stateManager = self:GetService("StateManager")
    if stateManager and stateManager.Subscribe then
        return stateManager:Subscribe(key, callback)
    else
        if self._logger then
            self._logger:Warn("StateManager not available for state subscription: " .. tostring(key))
        end
        return function() end
    end
end

-- UTILITY METHODS
function OVHLGlobal:GetAllServices()
    return self._services
end

function OVHLGlobal:GetAllModules()
    return self._modules
end

function OVHLGlobal:GetAllControllers()
    return self._controllers
end

function OVHLGlobal:IsClient()
    return self._isClient
end

function OVHLGlobal:IsServer()
    return not self._isClient
end

function OVHLGlobal:GetLogger()
    return self._logger
end

-- FIX: Ensure _G assignment works in client
return OVHLGlobal

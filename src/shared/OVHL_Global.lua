--[[
    File: src/shared/OVHL_Global.lua  
    Tujuan: Global API accessor untuk OVHL framework - REAL IMPLEMENTATION
    Versi Modul: 3.0.0
--]]

local OVHL = {}
OVHL.CORE_VERSION = "3.0.0"

-- Real storage untuk framework
OVHL._services = {}
OVHL._configs = {}
OVHL._eventListeners = {}
OVHL._state = {}

-- Helper function
local function getTableKeys(tbl)
    local keys = {}
    for key in pairs(tbl or {}) do
        table.insert(keys, key)
    end
    return keys
end

-- ==================== CORE API ====================

function OVHL:GetConfig(moduleName)
    local configService = self._services.ConfigService
    if configService then
        return configService:GetConfig(moduleName)
    end
    return self._configs[moduleName] or {}
end

function OVHL:GetService(serviceName)
    return self._services[serviceName]
end

function OVHL:GetAllServices()
    return self._services
end

-- ==================== EVENT BUS ====================

function OVHL:Emit(eventName, ...)
    if self._eventListeners[eventName] then
        for _, callback in ipairs(self._eventListeners[eventName]) do
            local success, err = pcall(callback, ...)
            if not success then
                warn("[OVHL] Event handler error: " .. tostring(err))
            end
        end
    end
end

function OVHL:Subscribe(eventName, callback)
    if not self._eventListeners[eventName] then
        self._eventListeners[eventName] = {}
    end
    
    table.insert(self._eventListeners[eventName], callback)
    
    return function()
        if self._eventListeners[eventName] then
            for i, cb in ipairs(self._eventListeners[eventName]) do
                if cb == callback then
                    table.remove(self._eventListeners[eventName], i)
                    break
                end
            end
        end
    end
end

-- ==================== CLIENT API ====================

function OVHL:SetState(key, value)
    self._state[key] = value
    self:Emit("StateChanged", key, value)
end

function OVHL:GetState(key, defaultValue)
    return self._state[key] or defaultValue
end

function OVHL:Fire(remoteName, ...)
    -- TODO: Implement dengan RemoteManager
    print("[OVHL] Fire: " .. remoteName .. " | Args: " .. tostring(#{...}))
end

function OVHL:Invoke(remoteName, ...)
    -- TODO: Implement dengan RemoteManager  
    print("[OVHL] Invoke: " .. remoteName .. " | Args: " .. tostring(#{...}))
    return nil
end

function OVHL:Listen(remoteName, callback)
    -- TODO: Implement dengan RemoteManager
    print("[OVHL] Listen: " .. remoteName)
    return { Disconnect = function() end }
end

-- ==================== FRAMEWORK INTERNAL ====================

function OVHL:_registerService(serviceName, serviceInstance)
    self._services[serviceName] = serviceInstance
end

function OVHL:_registerConfig(moduleName, config)
    self._configs[moduleName] = config
end

function OVHL:_getServiceCount()
    return #getTableKeys(self._services)
end

function OVHL:_getConfigCount()
    return #getTableKeys(self._configs)
end

-- ==================== DEBUG UTILITIES ====================

function OVHL:DebugDump()
    print("=== OVHL DEBUG DUMP ===")
    print("Version: " .. self.CORE_VERSION)
    print("Services: " .. self:_getServiceCount())
    for name, service in pairs(self._services) do
        print("  - " .. name)
    end
    
    print("Configs: " .. self:_getConfigCount())
    for name, config in pairs(self._configs) do
        print("  - " .. name)
    end
    
    print("Event Listeners: " .. #getTableKeys(self._eventListeners))
    for event, listeners in pairs(self._eventListeners) do
        print("  - " .. event .. " (" .. #listeners .. " listeners)")
    end
    print("========================")
end

return OVHL

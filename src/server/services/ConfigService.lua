--[[
    File: src/server/services/ConfigService.lua
    Tujuan: Central configuration management
    Versi Modul: 3.0.0
--]]

local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)

local ConfigService = {}
ConfigService.__index = ConfigService

-- MANIFEST WAJIB
ConfigService.__manifest = {
    name = "ConfigService",
    version = "3.0.0",
    type = "service",
    dependencies = {},
    priority = 100,
    domain = "system",
    description = "Central configuration management dengan live updates"
}

-- CONFIG DEFAULT
ConfigService.__config = {
    enableLiveConfig = false,
    cacheDuration = 300
}

-- PROPERTIES INTERNAL
ConfigService.configCache = {}
ConfigService.defaultConfigs = {}
ConfigService.liveConfigs = {}

-- HELPER FUNCTION
local function getTableKeys(tbl)
    local keys = {}
    for key in pairs(tbl or {}) do
        table.insert(keys, key)
    end
    return keys
end

-- ==================== CORE METHODS ====================

function ConfigService:GetConfig(moduleName)
    -- Priority: Live -> Cache -> Default -> Empty
    if self.liveConfigs[moduleName] then
        return self.liveConfigs[moduleName]
    end
    
    if self.configCache[moduleName] then
        return self.configCache[moduleName]
    end
    
    if self.defaultConfigs[moduleName] then
        return self.defaultConfigs[moduleName]
    end
    
    if moduleName == "Core" then
        return { DebugEnabled = true, LogLevel = "INFO" }
    end
    
    return {}
end

function ConfigService:SetConfig(moduleName, config, isLive)
    if type(moduleName) ~= "string" or type(config) ~= "table" then
        return false
    end
    
    if isLive then
        self.liveConfigs[moduleName] = config
    else
        self.configCache[moduleName] = config
    end
    
    OVHL:Emit("ConfigUpdated", moduleName, config)
    return true
end

function ConfigService:RegisterModuleConfig(moduleName, defaultConfig)
    if type(defaultConfig) ~= "table" then
        defaultConfig = {}
    end
    
    self.defaultConfigs[moduleName] = defaultConfig
    return true
end

function ConfigService:GetAllConfigs()
    return {
        default = self.defaultConfigs,
        cache = self.configCache,
        live = self.liveConfigs
    }
end

-- ==================== LIFECYCLE METHODS ====================

function ConfigService:Inject(services)
    -- No dependencies needed
end

function ConfigService:Init()
    -- Setup default configs
    self.defaultConfigs = self.__config.defaultConfigs or {}
    
    -- Register default Core config
    self:RegisterModuleConfig("Core", {
        DebugEnabled = true,
        LogLevel = "INFO"
    })
    
    -- Register diri sendiri di OVHL
    OVHL:_registerService("ConfigService", self)
    
    print("✅ ConfigService initialized")
    return true
end

function ConfigService:Start()
    print("✅ ConfigService started")
    return true
end

-- ==================== DEBUG UTILITIES ====================

function ConfigService:DebugDump()
    print("=== CONFIGSERVICE DEBUG DUMP ===")
    print("Default Configs: " .. #getTableKeys(self.defaultConfigs))
    for name in pairs(self.defaultConfigs) do
        print("  - " .. name)
    end
    print("Cached Configs: " .. #getTableKeys(self.configCache))
    print("Live Configs: " .. #getTableKeys(self.liveConfigs))
    print("=================================")
end

return ConfigService

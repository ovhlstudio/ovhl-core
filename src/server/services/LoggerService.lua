--[[
    File: src/server/services/LoggerService.lua
    Tujuan: Structured logging system dengan level control
    Versi Modul: 3.0.0
--]]

local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)

local LoggerService = {}
LoggerService.__index = LoggerService

-- MANIFEST WAJIB
LoggerService.__manifest = {
    name = "LoggerService",
    version = "3.0.0",
    type = "service",
    dependencies = {"ConfigService"},
    priority = 95,
    domain = "system",
    description = "Structured logging dengan debug control"
}

-- CONFIG DEFAULT
LoggerService.__config = {
    enableColors = true,
    timestampFormat = "ISO"
}

-- PROPERTIES INTERNAL
LoggerService.debugEnabled = false
LoggerService.configService = nil

-- ==================== CORE LOGGING METHODS ====================

function LoggerService:_formatMessage(level, message, data)
    local timestamp = DateTime.now():ToIsoDate()
    local callerInfo = debug.info(3, "s") or "unknown"
    
    local logEntry = {
        timestamp = timestamp,
        level = level,
        message = tostring(message),
        caller = callerInfo
    }
    
    if data and next(data) then
        logEntry.data = data
    end
    
    return string.format("[%s] [%s] %s", level, timestamp, tostring(message))
end

function LoggerService:_logInternal(level, message, data)
    -- Skip debug logs jika debug disabled
    if level == "DEBUG" and not self.debugEnabled then
        return
    end
    
    local success, result = pcall(function()
        local formatted = self:_formatMessage(level, message, data)
        
        -- Output ke console dengan level-based styling
        if level == "ERROR" then
            warn("🔴 " .. formatted)
        elseif level == "WARN" then
            warn("🟡 " .. formatted)
        else
            print("🔵 " .. formatted)
        end
        
        -- Log data tambahan jika ada
        if data and next(data) then
            local dataCount = 0
            for _ in pairs(data) do dataCount += 1 end
            print("   📊 Data: " .. dataCount .. " keys")
            for key, value in pairs(data) do
                print("      " .. tostring(key) .. ": " .. tostring(value))
            end
        end
    end)
    
    if not success then
        warn("[LOGGER_ERROR] Failed to log: " .. tostring(result))
    end
end

-- ==================== PUBLIC API METHODS ====================

function LoggerService:Debug(message, data)
    self:_logInternal("DEBUG", message, data)
end

function LoggerService:Info(message, data)
    self:_logInternal("INFO", message, data)
end

function LoggerService:Warn(message, data)
    self:_logInternal("WARN", message, data)
end

function LoggerService:Error(message, data)
    self:_logInternal("ERROR", message, data)
end

-- ==================== LIFECYCLE METHODS ====================

function LoggerService:Inject(services)
    self.configService = services.ConfigService
end

function LoggerService:Init()
    -- Get config dari ConfigService
    local coreConfig = self.configService:GetConfig("Core")
    self.debugEnabled = coreConfig.DebugEnabled or false
    
    local loggerConfig = self.configService:GetConfig("LoggerService")
    self.config = loggerConfig or self.__config
    
    -- Register diri sendiri di OVHL
    OVHL:_registerService("LoggerService", self)
    
    self:Info("LoggerService initialized", {
        debugEnabled = self.debugEnabled
    })
    
    return true
end

function LoggerService:Start()
    self:Info("LoggerService started successfully")
    return true
end

return LoggerService

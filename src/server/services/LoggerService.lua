local LoggerService = {}
LoggerService.__index = LoggerService

LoggerService.__manifest = {
    name = "LoggerService",
    version = "1.0.0",
    type = "service",
    dependencies = {},
    priority = 100,
    domain = "core",
    description = "Structured logging service"
}

LoggerService.__config = {
    LogLevel = "INFO",
    EnableTimestamps = true,
    EnableContext = true,
    OutputToConsole = true
}

local LOG_LEVELS = {DEBUG = 10, INFO = 20, WARN = 30, ERROR = 40, NONE = 100}

function LoggerService.new()
    local self = setmetatable({}, LoggerService)
    self._currentLevel = LOG_LEVELS.INFO
    self._config = LoggerService.__config
    return self
end

function LoggerService:Inject(services) end

function LoggerService:Init()
    self:Info("LoggerService initialized")
    return true
end

function LoggerService:Start()
    self:Debug("LoggerService started")
end

function LoggerService:_shouldLog(level)
    return LOG_LEVELS[level] >= self._currentLevel
end

function LoggerService:_formatMessage(level, message, context)
    local parts = {}
    if self._config.EnableTimestamps then
        table.insert(parts, "[" .. os.date("%H:%M:%S") .. "]")
    end
    table.insert(parts, "[" .. level .. "]")
    table.insert(parts, message)
    if self._config.EnableContext and context and next(context) then
        local contextStr = ""
        for key, value in pairs(context) do
            if contextStr ~= "" then contextStr = contextStr .. ", " end
            contextStr = contextStr .. key .. "=" .. tostring(value)
        end
        table.insert(parts, "{" .. contextStr .. "}")
    end
    return table.concat(parts, " ")
end

function LoggerService:_output(level, message, context)
    if not self:_shouldLog(level) then return end
    local formatted = self:_formatMessage(level, message, context)
    if self._config.OutputToConsole then
        print(formatted)
    end
end

function LoggerService:Debug(message, context) self:_output("DEBUG", message, context) end
function LoggerService:Info(message, context) self:_output("INFO", message, context) end
function LoggerService:Warn(message, context) self:_output("WARN", message, context) end
function LoggerService:Error(message, context) self:_output("ERROR", message, context) end

function LoggerService:SetLogLevel(level)
    local upperLevel = string.upper(level)
    if LOG_LEVELS[upperLevel] then
        self._currentLevel = LOG_LEVELS[upperLevel]
        return true
    end
    return false
end

return LoggerService

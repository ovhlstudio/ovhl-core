--[[
    File: src/server/services/DataService.lua
    Tujuan: DataStore wrapper dengan session lock & retry logic
    Versi Modul: 1.0.0
--]]

local DataService = {}
DataService.__index = DataService

DataService.__manifest = {
    name = "DataService",
    version = "1.0.0",
    type = "service",
    dependencies = {"Logger", "ConfigService"},
    priority = 60,
    domain = "core",
    description = "DataStore wrapper dengan session locking & retry logic"
}

DataService.__config = {
    AutoSaveInterval = 60,
    RetryAttempts = 3,
    RetryDelay = 1,
    EnableSessionLock = true,
    DefaultData = {
        coins = 0,
        level = 1,
        experience = 0,
        inventory = {}
    }
}

function DataService.new(logger)
    local self = setmetatable({}, DataService)
    self.logger = logger
    self.dataStores = {}
    self.playerSessions = {}
    self.config = DataService.__config
    return self
end

function DataService:Inject(services)
    self.configService = services.ConfigService
    self.eventBus = services.EventBusService
    self.logger:Debug("DataService injected with dependencies")
end

function DataService:Init()
    self.logger:Info("DataService initializing...")
    
    -- Apply config overrides
    local config = self.configService:GetConfig("DataService")
    if config then
        for k, v in pairs(config) do
            if self.config[k] ~= nil then
                self.config[k] = v
            end
        end
    end
    
    return true
end

function DataService:Start()
    self.logger:Info("DataService started")
    
    -- Start auto-save loop
    if self.config.AutoSaveInterval > 0 then
        task.spawn(function()
            while true do
                task.wait(self.config.AutoSaveInterval)
                self:AutoSaveAll()
            end
        end)
    end
end

-- ==================== CORE DATA OPERATIONS ====================

function DataService:GetDataStore(player, dataStoreName)
    dataStoreName = dataStoreName or "PlayerData"
    local key = "Player_" .. player.UserId
    
    if not self.dataStores[key] then
        self.dataStores[key] = {
            main = game:GetService("DataStoreService"):GetDataStore(dataStoreName),
            session = dataStoreName .. "_Session",
            cache = {}
        }
    end
    
    return self.dataStores[key]
end

function DataService:GetPlayerData(player, dataStoreName)
    local dataStore = self:GetDataStore(player, dataStoreName)
    local sessionKey = tostring(player.UserId)
    
    -- Check session lock
    if self.config.EnableSessionLock then
        local sessionLock = dataStore.main:UpdateAsync(sessionKey, function(current)
            if current and current ~= "LOCKED" then
                return "LOCKED"
            end
            return "LOCKED"
        end)
        
        if not sessionLock then
            self.logger:Warn("Session lock failed", {player = player.Name})
            return nil, "Session lock failed"
        end
    end
    
    -- Get data with retry logic
    local data, errorMessage
    for attempt = 1, self.config.RetryAttempts do
        local success, result = pcall(function()
            return dataStore.main:GetAsync(sessionKey)
        end)
        
        if success then
            data = result or table.clone(self.config.DefaultData)
            break
        else
            errorMessage = result
            self.logger:Warn("DataStore get failed attempt " .. attempt, {
                player = player.Name,
                error = result
            })
            task.wait(self.config.RetryDelay)
        end
    end
    
    if not data then
        self.logger:Error("Failed to get player data after retries", {
            player = player.Name,
            error = errorMessage
        })
        return nil, errorMessage or "DataStore failure"
    end
    
    -- Cache data and track session
    dataStore.cache[sessionKey] = table.clone(data)
    self.playerSessions[sessionKey] = {
        player = player,
        dataStore = dataStore,
        lastSave = os.time()
    }
    
    self.logger:Debug("Player data loaded", {player = player.Name})
    return data
end

function DataService:SavePlayerData(player, dataStoreName)
    local dataStore = self:GetDataStore(player, dataStoreName)
    local sessionKey = tostring(player.UserId)
    local session = self.playerSessions[sessionKey]
    
    if not session or not dataStore.cache[sessionKey] then
        self.logger:Warn("No data to save", {player = player.Name})
        return false, "No data to save"
    end
    
    local data = dataStore.cache[sessionKey]
    
    -- Save with retry logic
    local success, errorMessage
    for attempt = 1, self.config.RetryAttempts do
        local saveSuccess, saveError = pcall(function()
            dataStore.main:SetAsync(sessionKey, data)
        end)
        
        if saveSuccess then
            success = true
            session.lastSave = os.time()
            break
        else
            errorMessage = saveError
            self.logger:Warn("DataStore save failed attempt " .. attempt, {
                player = player.Name,
                error = saveError
            })
            task.wait(self.config.RetryDelay)
        end
    end
    
    if success then
        self.logger:Debug("Player data saved", {player = player.Name})
        
        -- Emit data saved event
        if self.eventBus then
            self.eventBus:Emit("PlayerDataSaved", player, data)
        end
        
        return true
    else
        self.logger:Error("Failed to save player data after retries", {
            player = player.Name,
            error = errorMessage
        })
        return false, errorMessage or "Save failure"
    end
end

function DataService:UpdatePlayerData(player, updates, dataStoreName)
    local sessionKey = tostring(player.UserId)
    local dataStore = self:GetDataStore(player, dataStoreName)
    
    if not dataStore.cache[sessionKey] then
        self.logger:Warn("No active session for update", {player = player.Name})
        return false, "No active session"
    end
    
    -- Apply updates
    for key, value in pairs(updates) do
        dataStore.cache[sessionKey][key] = value
    end
    
    self.logger:Debug("Player data updated", {
        player = player.Name,
        updates = updates
    })
    
    -- Emit data updated event
    if self.eventBus then
        self.eventBus:Emit("PlayerDataUpdated", player, updates, dataStore.cache[sessionKey])
    end
    
    return true, dataStore.cache[sessionKey]
end

function DataService:ReleasePlayerSession(player, dataStoreName)
    local dataStore = self:GetDataStore(player, dataStoreName)
    local sessionKey = tostring(player.UserId)
    
    -- Save before release
    if dataStore.cache[sessionKey] then
        self:SavePlayerData(player, dataStoreName)
    end
    
    -- Release session lock
    if self.config.EnableSessionLock then
        pcall(function()
            dataStore.main:UpdateAsync(sessionKey, function(current)
                return nil
            end)
        end)
    end
    
    -- Cleanup
    dataStore.cache[sessionKey] = nil
    self.playerSessions[sessionKey] = nil
    
    self.logger:Debug("Player session released", {player = player.Name})
    
    -- Emit session released event
    if self.eventBus then
        self.eventBus:Emit("PlayerSessionReleased", player)
    end
end

-- ==================== UTILITY METHODS ====================

function DataService:AutoSaveAll()
    local saved = 0
    local failed = 0
    
    for sessionKey, session in pairs(self.playerSessions) do
        if session.player and session.player.Parent then
            local success = self:SavePlayerData(session.player)
            if success then
                saved = saved + 1
            else
                failed = failed + 1
            end
        else
            -- Player left, cleanup
            self.playerSessions[sessionKey] = nil
        end
    end
    
    if saved > 0 or failed > 0 then
        self.logger:Info("Auto-save completed", {
            saved = saved,
            failed = failed,
            total = saved + failed
        })
    end
end

function DataService:GetActiveSessions()
    local sessions = {}
    for sessionKey, session in pairs(self.playerSessions) do
        if session.player and session.player.Parent then
            table.insert(sessions, {
                player = session.player.Name,
                userId = session.player.UserId,
                lastSave = session.lastSave
            })
        end
    end
    return sessions
end

function DataService:ForceSaveAll()
    self.logger:Info("Force saving all active sessions...")
    return self:AutoSaveAll()
end

return DataService

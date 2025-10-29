--[[
    File: src/server/services/RemoteManagerService.lua
    Tujuan: Server-side remote handler dengan security middleware
    Versi Modul: 1.0.4 - COMPATIBLE WITH FIXED NETWORKSCHEMA
--]]

local RemoteManagerService = {}
RemoteManagerService.__index = RemoteManagerService

RemoteManagerService.__manifest = {
    name = "RemoteManagerService",
    version = "1.0.4",
    type = "service",
    dependencies = {"Logger", "EventBusService"},
    priority = 50,
    domain = "core",
    description = "Server-side remote handler - COMPATIBLE WITH FIXED NETWORKSCHEMA"
}

RemoteManagerService.__config = {
    EnableRateLimiting = true,
    RateLimitWindow = 60,
    MaxRequestsPerWindow = 100,
    EnableSchemaValidation = false, -- Keep disabled for now
    EnableLogging = true
}

function RemoteManagerService.new(logger)
    local self = setmetatable({}, RemoteManagerService)
    self.logger = logger
    self.handlers = {}
    self.rateLimits = {}
    self.remoteEvent = nil
    self.remoteFunction = nil
    self.config = RemoteManagerService.__config
    return self
end

function RemoteManagerService:Inject(services)
    self.eventBus = services.EventBusService
    self.logger:Debug("RemoteManagerService injected")
end

function RemoteManagerService:Init()
    self.logger:Info("RemoteManagerService initializing...")
    
    -- Create RemoteEvent and RemoteFunction
    self.remoteEvent = Instance.new("RemoteEvent")
    self.remoteEvent.Name = "OVHL_RemoteEvent"
    self.remoteEvent.Parent = game:GetService("ReplicatedStorage"):WaitForChild("OVHL_Shared")
    
    self.remoteFunction = Instance.new("RemoteFunction")
    self.remoteFunction.Name = "OVHL_RemoteFunction"  
    self.remoteFunction.Parent = game:GetService("ReplicatedStorage"):WaitForChild("OVHL_Shared")
    
    return true
end

function RemoteManagerService:Start()
    self.logger:Info("RemoteManagerService started")
    
    -- SAFE event handler - no ... usage
    self.remoteEvent.OnServerEvent:Connect(function(player, remoteName, arg1, arg2, arg3, arg4, arg5)
        local args = {}
        if arg1 ~= nil then table.insert(args, arg1) end
        if arg2 ~= nil then table.insert(args, arg2) end  
        if arg3 ~= nil then table.insert(args, arg3) end
        if arg4 ~= nil then table.insert(args, arg4) end
        if arg5 ~= nil then table.insert(args, arg5) end
        self:HandleFire(player, remoteName, args)
    end)
    
    -- SAFE function handler - no ... usage
    self.remoteFunction.OnServerInvoke = function(player, remoteName, arg1, arg2, arg3, arg4, arg5)
        local args = {}
        if arg1 ~= nil then table.insert(args, arg1) end
        if arg2 ~= nil then table.insert(args, arg2) end
        if arg3 ~= nil then table.insert(args, arg3) end
        if arg4 ~= nil then table.insert(args, arg4) end
        if arg5 ~= nil then table.insert(args, arg5) end
        return self:HandleInvoke(player, remoteName, args)
    end
    
    self.logger:Info("Remote handlers registered")
end

-- ==================== SAFE MIDDLEWARE ====================

function RemoteManagerService:CheckRateLimit(player, remoteName)
    if not self.config.EnableRateLimiting then
        return true
    end
    
    local playerId = tostring(player.UserId)
    local window = math.floor(os.time() / self.config.RateLimitWindow)
    local key = playerId .. ":" .. remoteName .. ":" .. window
    
    if not self.rateLimits[key] then
        self.rateLimits[key] = 0
    end
    
    self.rateLimits[key] = self.rateLimits[key] + 1
    
    if self.rateLimits[key] > self.config.MaxRequestsPerWindow then
        self.logger:Warn("Rate limit exceeded", {
            player = player.Name,
            remote = remoteName,
            count = self.rateLimits[key]
        })
        return false
    end
    
    return true
end

function RemoteManagerService:LogRequest(player, remoteName, args, success, result)
    if not self.config.EnableLogging then
        return
    end
    
    if success then
        self.logger:Debug("Remote request", {
            player = player.Name,
            remote = remoteName,
            args = #args
        })
    else
        self.logger:Warn("Remote request failed", {
            player = player.Name,
            remote = remoteName, 
            error = result
        })
    end
end

-- ==================== SAFE REQUEST HANDLING ====================

function RemoteManagerService:HandleFire(player, remoteName, args)
    -- Middleware chain
    if not self:CheckRateLimit(player, remoteName) then
        self:LogRequest(player, remoteName, args, false, "Rate limit exceeded")
        return
    end
    
    -- Find handler
    local handler = self.handlers[remoteName]
    if not handler then
        self:LogRequest(player, remoteName, args, false, "No handler registered")
        return
    end
    
    -- Execute handler dengan safe argument passing
    local success, result
    if #args == 0 then
        success, result = pcall(handler, player)
    elseif #args == 1 then
        success, result = pcall(handler, player, args[1])
    elseif #args == 2 then
        success, result = pcall(handler, player, args[1], args[2])
    elseif #args == 3 then
        success, result = pcall(handler, player, args[1], args[2], args[3])
    elseif #args == 4 then
        success, result = pcall(handler, player, args[1], args[2], args[3], args[4])
    elseif #args == 5 then
        success, result = pcall(handler, player, args[1], args[2], args[3], args[4], args[5])
    else
        -- Fallback untuk banyak arguments (should be rare)
        local allArgs = {player}
        for i, arg in ipairs(args) do
            table.insert(allArgs, arg)
        end
        success, result = pcall(handler, unpack(allArgs))
    end
    
    self:LogRequest(player, remoteName, args, success, result)
    
    -- Emit event
    if self.eventBus then
        self.eventBus:Emit("RemoteRequestProcessed", player, remoteName, success, result)
    end
end

function RemoteManagerService:HandleInvoke(player, remoteName, args)
    -- Middleware chain
    if not self:CheckRateLimit(player, remoteName) then
        self:LogRequest(player, remoteName, args, false, "Rate limit exceeded")
        return {success = false, error = "Rate limit exceeded"}
    end
    
    -- Find handler
    local handler = self.handlers[remoteName]
    if not handler then
        self:LogRequest(player, remoteName, args, false, "No handler registered")
        return {success = false, error = "No handler registered"}
    end
    
    -- Execute handler dengan safe argument passing
    local success, result
    if #args == 0 then
        success, result = pcall(handler, player)
    elseif #args == 1 then
        success, result = pcall(handler, player, args[1])
    elseif #args == 2 then
        success, result = pcall(handler, player, args[1], args[2])
    elseif #args == 3 then
        success, result = pcall(handler, player, args[1], args[2], args[3])
    elseif #args == 4 then
        success, result = pcall(handler, player, args[1], args[2], args[3], args[4])
    elseif #args == 5 then
        success, result = pcall(handler, player, args[1], args[2], args[3], args[4], args[5])
    else
        -- Fallback untuk banyak arguments
        local allArgs = {player}
        for i, arg in ipairs(args) do
            table.insert(allArgs, arg)
        end
        success, result = pcall(handler, unpack(allArgs))
    end
    
    self:LogRequest(player, remoteName, args, success, result)
    
    -- Emit event
    if self.eventBus then
        self.eventBus:Emit("RemoteInvokeProcessed", player, remoteName, success, result)
    end
    
    if success then
        return {success = true, data = result}
    else
        return {success = false, error = result}
    end
end

-- ==================== PUBLIC API ====================

function RemoteManagerService:RegisterHandler(remoteName, handler)
    if self.handlers[remoteName] then
        self.logger:Warn("Overwriting handler", {remote = remoteName})
    end
    
    self.handlers[remoteName] = handler
    self.logger:Info("Handler registered", {remote = remoteName})
end

function RemoteManagerService:UnregisterHandler(remoteName)
    if self.handlers[remoteName] then
        self.handlers[remoteName] = nil
        self.logger:Info("Handler unregistered", {remote = remoteName})
        return true
    end
    return false
end

function RemoteManagerService:FireClient(player, remoteName, arg1, arg2, arg3, arg4, arg5)
    if not self.remoteEvent then
        self.logger:Error("RemoteEvent not ready")
        return false
    end
    
    local success = pcall(function()
        if arg5 ~= nil then
            self.remoteEvent:FireClient(player, remoteName, arg1, arg2, arg3, arg4, arg5)
        elseif arg4 ~= nil then
            self.remoteEvent:FireClient(player, remoteName, arg1, arg2, arg3, arg4)
        elseif arg3 ~= nil then
            self.remoteEvent:FireClient(player, remoteName, arg1, arg2, arg3)
        elseif arg2 ~= nil then
            self.remoteEvent:FireClient(player, remoteName, arg1, arg2)
        elseif arg1 ~= nil then
            self.remoteEvent:FireClient(player, remoteName, arg1)
        else
            self.remoteEvent:FireClient(player, remoteName)
        end
    end)
    
    return success
end

function RemoteManagerService:FireAllClients(remoteName, arg1, arg2, arg3, arg4, arg5)
    if not self.remoteEvent then
        self.logger:Error("RemoteEvent not ready")
        return false
    end
    
    local success = pcall(function()
        if arg5 ~= nil then
            self.remoteEvent:FireAllClients(remoteName, arg1, arg2, arg3, arg4, arg5)
        elseif arg4 ~= nil then
            self.remoteEvent:FireAllClients(remoteName, arg1, arg2, arg3, arg4)
        elseif arg3 ~= nil then
            self.remoteEvent:FireAllClients(remoteName, arg1, arg2, arg3)
        elseif arg2 ~= nil then
            self.remoteEvent:FireAllClients(remoteName, arg1, arg2)
        elseif arg1 ~= nil then
            self.remoteEvent:FireAllClients(remoteName, arg1)
        else
            self.remoteEvent:FireAllClients(remoteName)
        end
    end)
    
    return success
end

function RemoteManagerService:GetHandlerCount()
    local count = 0
    for _ in pairs(self.handlers) do
        count = count + 1
    end
    return count
end

function RemoteManagerService:GetRegisteredHandlers()
    local handlers = {}
    for name in pairs(self.handlers) do
        table.insert(handlers, name)
    end
    return handlers
end

return RemoteManagerService

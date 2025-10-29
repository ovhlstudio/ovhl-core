local EventBusService = {}
EventBusService.__index = EventBusService

EventBusService.__manifest = {
    name = "EventBusService",
    version = "1.0.0",
    type = "service",
    dependencies = {"Logger"},
    priority = 70,
    domain = "core",
    description = "Internal pub/sub event system for server modules"
}

EventBusService.__config = {
    EnableEventHistory = false,
    MaxHistorySize = 100,
    EnableWildcardSubscriptions = true
}

function EventBusService.new(logger)
    local self = setmetatable({}, EventBusService)
    self.logger = logger
    self.subscriptions = {}
    self.wildcardSubscriptions = {}
    self.eventHistory = {}
    self.config = EventBusService.__config
    return self
end

function EventBusService:Inject(services) end

function EventBusService:Init()
    self.logger:Info("EventBusService initializing...")
    return true
end

function EventBusService:Start()
    self.logger:Info("EventBusService started")
end

-- ==================== CORE EVENT SYSTEM ====================

function EventBusService:Emit(eventName, ...)
    local args = {...}
    
    self.logger:Debug("Event emitted", {
        event = eventName,
        args = args
    })
    
    -- Store in history if enabled
    if self.config.EnableEventHistory then
        table.insert(self.eventHistory, {
            event = eventName,
            args = args,
            timestamp = os.time()
        })
        
        -- Trim history if too large
        if #self.eventHistory > self.config.MaxHistorySize then
            table.remove(self.eventHistory, 1)
        end
    end
    
    -- Call specific event subscribers
    if self.subscriptions[eventName] then
        for _, subscription in ipairs(self.subscriptions[eventName]) do
            task.spawn(function()
                local success, err = pcall(subscription.callback, unpack(args))
                if not success then
                    self.logger:Error("Event handler failed", {
                        event = eventName,
                        error = err,
                        subscriber = subscription.id
                    })
                end
            end)
        end
    end
    
    -- Call wildcard subscribers
    if self.config.EnableWildcardSubscriptions and self.wildcardSubscriptions["*"] then
        for _, subscription in ipairs(self.wildcardSubscriptions["*"]) do
            task.spawn(function()
                local success, err = pcall(subscription.callback, eventName, unpack(args))
                if not success then
                    self.logger:Error("Wildcard handler failed", {
                        event = eventName,
                        error = err,
                        subscriber = subscription.id
                    })
                end
            end)
        end
    end
    
    -- Call pattern wildcard subscribers
    if self.config.EnableWildcardSubscriptions then
        for pattern, subscriptions in pairs(self.wildcardSubscriptions) do
            if pattern ~= "*" and string.match(eventName, pattern) then
                for _, subscription in ipairs(subscriptions) do
                    task.spawn(function()
                        local success, err = pcall(subscription.callback, eventName, unpack(args))
                        if not success then
                            self.logger:Error("Pattern handler failed", {
                                event = eventName,
                                pattern = pattern,
                                error = err,
                                subscriber = subscription.id
                            })
                        end
                    end)
                end
            end
        end
    end
end

function EventBusService:Subscribe(eventName, callback)
    local subscriptionId = tostring(math.random(1, 1000000)) .. "_" .. os.time()
    
    local subscription = {
        id = subscriptionId,
        callback = callback,
        eventName = eventName
    }
    
    -- Check if it's a wildcard subscription
    if self.config.EnableWildcardSubscriptions and (eventName == "*" or string.find(eventName, "[%*%?]")) then
        if not self.wildcardSubscriptions[eventName] then
            self.wildcardSubscriptions[eventName] = {}
        end
        table.insert(self.wildcardSubscriptions[eventName], subscription)
    else
        -- Regular subscription
        if not self.subscriptions[eventName] then
            self.subscriptions[eventName] = {}
        end
        table.insert(self.subscriptions[eventName], subscription)
    end
    
    self.logger:Debug("Event subscription added", {
        event = eventName,
        subscriptionId = subscriptionId
    })
    
    -- Return unsubscribe function
    return function()
        self:Unsubscribe(eventName, subscriptionId)
    end
end

function EventBusService:Unsubscribe(eventName, subscriptionId)
    -- Try regular subscriptions
    if self.subscriptions[eventName] then
        for i, sub in ipairs(self.subscriptions[eventName]) do
            if sub.id == subscriptionId then
                table.remove(self.subscriptions[eventName], i)
                self.logger:Debug("Event subscription removed", {
                    event = eventName,
                    subscriptionId = subscriptionId
                })
                return true
            end
        end
    end
    
    -- Try wildcard subscriptions
    if self.wildcardSubscriptions[eventName] then
        for i, sub in ipairs(self.wildcardSubscriptions[eventName]) do
            if sub.id == subscriptionId then
                table.remove(self.wildcardSubscriptions[eventName], i)
                self.logger:Debug("Wildcard subscription removed", {
                    event = eventName,
                    subscriptionId = subscriptionId
                })
                return true
            end
        end
    end
    
    self.logger:Warn("Subscription not found for removal", {
        event = eventName,
        subscriptionId = subscriptionId
    })
    return false
end

function EventBusService:Once(eventName, callback)
    local unsubscribe
    local function onceHandler(...)
        if unsubscribe then
            unsubscribe()
        end
        callback(...)
    end
    
    unsubscribe = self:Subscribe(eventName, onceHandler)
    return unsubscribe
end

-- ==================== UTILITY METHODS ====================

function EventBusService:GetSubscriptionCount(eventName)
    local count = 0
    if self.subscriptions[eventName] then
        count = count + #self.subscriptions[eventName]
    end
    if self.wildcardSubscriptions[eventName] then
        count = count + #self.wildcardSubscriptions[eventName]
    end
    return count
end

function EventBusService:GetAllSubscriptions()
    local allSubs = {}
    
    for eventName, subs in pairs(self.subscriptions) do
        allSubs[eventName] = {type = "regular", count = #subs}
    end
    
    for pattern, subs in pairs(self.wildcardSubscriptions) do
        allSubs[pattern] = {type = "wildcard", count = #subs}
    end
    
    return allSubs
end

function EventBusService:ClearSubscriptions(eventName)
    if eventName then
        self.subscriptions[eventName] = nil
        self.wildcardSubscriptions[eventName] = nil
        self.logger:Info("Cleared subscriptions", {event = eventName})
    else
        self.subscriptions = {}
        self.wildcardSubscriptions = {}
        self.logger:Info("Cleared all subscriptions")
    end
end

function EventBusService:GetEventHistory()
    if not self.config.EnableEventHistory then
        return {}
    end
    return self.eventHistory
end

function EventBusService:SetConfig(configUpdates)
    for k, v in pairs(configUpdates) do
        if self.config[k] ~= nil then
            self.config[k] = v
        end
    end
    self.logger:Info("EventBus config updated", {config = configUpdates})
end

return EventBusService

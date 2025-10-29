local DependencyResolver = {}
DependencyResolver.__index = DependencyResolver

DependencyResolver.__manifest = {
    name = "DependencyResolver",
    version = "1.0.0",
    type = "service",
    dependencies = {"Logger"},
    priority = 90,
    domain = "core",
    description = "Client-side dependency resolution"
}

function DependencyResolver.new(logger)
    local self = setmetatable({}, DependencyResolver)
    self.logger = logger
    return self
end

function DependencyResolver:Inject(services) end
function DependencyResolver:Init() return true end
function DependencyResolver:Start() end

function DependencyResolver:Resolve(discoveredModules)
    local loadOrder = {}
    table.sort(discoveredModules, function(a, b)
        local prioA = a.manifest.priority or 50
        local prioB = b.manifest.priority or 50
        return prioA > prioB
    end)
    for _, moduleData in ipairs(discoveredModules) do
        table.insert(loadOrder, moduleData.name)
    end
    self.logger:Info("Client dependency resolution completed", {loadOrder = loadOrder})
    return loadOrder
end

return DependencyResolver

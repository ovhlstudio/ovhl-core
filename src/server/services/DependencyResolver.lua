--[[
    File: src/server/services/DependencyResolver.lua
    Tujuan: Dependency graph solver untuk load order management
    Versi Modul: 3.0.0
--]]

local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)

local DependencyResolver = {}
DependencyResolver.__index = DependencyResolver

-- MANIFEST WAJIB
DependencyResolver.__manifest = {
    name = "DependencyResolver",
    version = "3.0.0",
    type = "service",
    dependencies = {"LoggerService"},
    priority = 90,
    domain = "system",
    description = "Dependency graph solver untuk load order"
}

-- PROPERTIES INTERNAL
DependencyResolver.logger = nil

-- ==================== CORE RESOLVER METHODS ====================

function DependencyResolver:BuildDependencyGraph(modules)
    local graph = {
        nodes = {},
        edges = {}
    }
    
    -- Build nodes
    for _, module in ipairs(modules) do
        local manifest = module.__manifest
        graph.nodes[manifest.name] = {
            module = module,
            priority = manifest.priority or 50,
            dependencies = manifest.dependencies or {}
        }
    end
    
    -- Build edges
    for moduleName, node in pairs(graph.nodes) do
        for _, depName in ipairs(node.dependencies) do
            table.insert(graph.edges, {
                from = depName,
                to = moduleName
            })
        end
    end
    
    return graph
end

function DependencyResolver:TopologicalSort(graph)
    local visited = {}
    local tempMarked = {}
    local result = {}
    
    local function visit(nodeName)
        if tempMarked[nodeName] then
            self.logger:Error("Circular dependency detected", {node = nodeName})
            return false
        end
        
        if not visited[nodeName] then
            tempMarked[nodeName] = true
            
            -- Visit semua dependencies
            for _, edge in ipairs(graph.edges) do
                if edge.from == nodeName then
                    if not visit(edge.to) then
                        return false
                    end
                end
            end
            
            tempMarked[nodeName] = false
            visited[nodeName] = true
            table.insert(result, 1, nodeName)
        end
        
        return true
    end
    
    -- Visit semua nodes dengan priority sorting
    local nodesByPriority = {}
    for nodeName in pairs(graph.nodes) do
        table.insert(nodesByPriority, {
            name = nodeName,
            priority = graph.nodes[nodeName].priority
        })
    end
    
    table.sort(nodesByPriority, function(a, b)
        return a.priority > b.priority
    end)
    
    for _, node in ipairs(nodesByPriority) do
        if not visited[node.name] then
            if not visit(node.name) then
                return nil
            end
        end
    end
    
    return result
end

function DependencyResolver:ResolveLoadOrder(modules)
    self.logger:Info("Resolving dependency graph", {moduleCount = #modules})
    
    local graph = self:BuildDependencyGraph(modules)
    local loadOrder = self:TopologicalSort(graph)
    
    if loadOrder then
        self.logger:Info("Dependency resolution completed", {
            loadOrder = table.concat(loadOrder, " → ")
        })
    end
    
    return loadOrder
end

-- ==================== LIFECYCLE METHODS ====================

function DependencyResolver:Inject(services)
    self.logger = services.LoggerService
end

function DependencyResolver:Init()
    OVHL:_registerService("DependencyResolver", self)
    self.logger:Info("DependencyResolver initialized")
    return true
end

function DependencyResolver:Start()
    self.logger:Info("DependencyResolver started successfully")
    return true
end

return DependencyResolver

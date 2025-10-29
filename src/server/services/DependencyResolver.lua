local DependencyResolver = {}
DependencyResolver.__index = DependencyResolver

DependencyResolver.__manifest = {
    name = "DependencyResolver",
    version = "1.0.0",
    type = "service",
    dependencies = {"Logger"},
    priority = 90,
    domain = "core",
    description = "Dependency resolution and load order calculation"
}

function DependencyResolver.new(logger)
    local self = setmetatable({}, DependencyResolver)
    self.logger = logger
    self.logger:Info("DependencyResolver initialized")
    return self
end

function DependencyResolver:Inject(services) end
function DependencyResolver:Init() self.logger:Debug("DependencyResolver init complete") return true end
function DependencyResolver:Start() self.logger:Debug("DependencyResolver started") end

function DependencyResolver:_buildDependencyGraph(discoveredModules)
    local graph = {nodes = {}, edges = {}}
    for _, moduleData in ipairs(discoveredModules) do
        local moduleName = moduleData.name
        graph.nodes[moduleName] = {
            name = moduleName,
            priority = moduleData.manifest.priority or 50,
            moduleData = moduleData
        }
        local dependencies = moduleData.manifest.dependencies or {}
        for _, depName in ipairs(dependencies) do
            table.insert(graph.edges, {from = depName, to = moduleName})
        end
    end
    return graph
end

function DependencyResolver:_detectCircularDependencies(graph)
    local visited, recursionStack, circularPaths = {}, {}, {}
    local function dfs(nodeName)
        if not graph.nodes[nodeName] then return false end
        visited[nodeName] = true
        recursionStack[nodeName] = true
        for _, edge in ipairs(graph.edges) do
            if edge.from == nodeName then
                local dependencyName = edge.to
                if not graph.nodes[dependencyName] then
                    self.logger:Warn("Missing dependency", {module = nodeName, missing = dependencyName})
                elseif not visited[dependencyName] then
                    if dfs(dependencyName) then return true end
                elseif recursionStack[dependencyName] then
                    table.insert(circularPaths, {from = nodeName, to = dependencyName})
                    return true
                end
            end
        end
        recursionStack[nodeName] = false
        return false
    end
    for nodeName, _ in pairs(graph.nodes) do
        if not visited[nodeName] then
            if dfs(nodeName) then return true, circularPaths end
        end
    end
    return false, {}
end

function DependencyResolver:_topologicalSort(graph)
    local visited, tempMark, result = {}, {}, {}
    local function visit(nodeName)
        if tempMark[nodeName] then return false end
        if not visited[nodeName] then
            tempMark[nodeName] = true
            for _, edge in ipairs(graph.edges) do
                if edge.from == nodeName and graph.nodes[edge.to] then
                    if not visit(edge.to) then return false end
                end
            end
            tempMark[nodeName] = false
            visited[nodeName] = true
            local inserted = false
            for i = 1, #result do
                local existingNode = graph.nodes[result[i]]
                local currentNode = graph.nodes[nodeName]
                if currentNode.priority > existingNode.priority then
                    table.insert(result, i, nodeName)
                    inserted = true
                    break
                end
            end
            if not inserted then table.insert(result, nodeName) end
        end
        return true
    end
    for nodeName, _ in pairs(graph.nodes) do
        if not visit(nodeName) then return nil end
    end
    return result
end

function DependencyResolver:Resolve(discoveredModules)
    self.logger:Debug("Resolving dependencies", {moduleCount = #discoveredModules})
    local graph = self:_buildDependencyGraph(discoveredModules)
    local hasCircular, circularPaths = self:_detectCircularDependencies(graph)
    if hasCircular then
        self.logger:Error("Circular dependency detected!", {circularPaths = circularPaths})
        return nil, "Circular dependency detected"
    end
    local loadOrder = self:_topologicalSort(graph)
    if not loadOrder then
        self.logger:Error("Failed to calculate load order")
        return nil, "Failed to calculate load order"
    end
    self.logger:Info("Dependency resolution completed", {loadOrder = loadOrder, moduleCount = #loadOrder})
    return loadOrder
end

return DependencyResolver

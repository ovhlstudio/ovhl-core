--[[
    File: src/server/services/ModuleLoader.lua
    Tujuan: Auto-discovery dan management untuk game modules
    Versi Modul: 3.0.0
--]]

local OVHL = require(game.ReplicatedStorage.OVHL_Shared.OVHL_Global)

local ModuleLoader = {}
ModuleLoader.__index = ModuleLoader

-- MANIFEST WAJIB
ModuleLoader.__manifest = {
    name = "ModuleLoader",
    version = "3.0.0",
    type = "service",
    dependencies = {"LoggerService", "DependencyResolver", "ConfigService", "ServiceManager"},
    priority = 70,
    domain = "system",
    description = "Auto-discovery dan lifecycle management untuk game modules"
}

-- PROPERTIES INTERNAL
ModuleLoader.logger = nil
ModuleLoader.dependencyResolver = nil
ModuleLoader.configService = nil
ModuleLoader.serviceManager = nil
ModuleLoader.loadedModules = {}

-- ==================== CORE MODULE MANAGEMENT ====================

function ModuleLoader:DiscoverModules()
    local modulesFolder = script.Parent.Parent:FindFirstChild("modules")
    if not modulesFolder then
        self.logger:Warn("Modules folder not found")
        return {}
    end
    
    local discoveredModules = {}
    
    self.logger:Info("Discovering modules...", {folder = tostring(modulesFolder)})
    
    for _, child in ipairs(modulesFolder:GetChildren()) do
        if child:IsA("ModuleScript") then
            local success, module = pcall(require, child)
            
            if success and module.__manifest then
                local manifest = module.__manifest
                
                if manifest.type == "module" and (manifest.autoload ~= false) then
                    table.insert(discoveredModules, module)
                    self.logger:Debug("Discovered module", {
                        name = manifest.name,
                        version = manifest.version
                    })
                end
            else
                self.logger:Warn("Invalid module", {
                    module = child.Name,
                    error = not success and module or "No manifest"
                })
            end
        end
    end
    
    return discoveredModules
end

function ModuleLoader:LoadModules()
    self.logger:Info("Starting module loading process...")
    
    -- Discover modules
    local discoveredModules = self:DiscoverModules()
    if #discoveredModules == 0 then
        self.logger:Warn("No modules discovered")
        return true
    end
    
    -- Resolve dependencies
    local loadOrder = self.dependencyResolver:ResolveLoadOrder(discoveredModules)
    if not loadOrder then
        self.logger:Error("Failed to resolve module dependencies")
        return false
    end
    
    -- Create module instances
    for _, moduleName in ipairs(loadOrder) do
        for _, module in ipairs(discoveredModules) do
            if module.__manifest.name == moduleName then
                local moduleInstance = {}
                setmetatable(moduleInstance, module)
                
                self.loadedModules[moduleName] = {
                    instance = moduleInstance,
                    manifest = module.__manifest,
                    status = "loaded"
                }
                
                self.logger:Info("Module loaded", {module = moduleName})
                break
            end
        end
    end
    
    self.logger:Info("Module loading completed", {
        total = #discoveredModules,
        loaded = #loadOrder
    })
    
    return true
end

-- ==================== LIFECYCLE METHODS ====================

function ModuleLoader:Inject(services)
    self.logger = services.LoggerService
    self.dependencyResolver = services.DependencyResolver
    self.configService = services.ConfigService
    self.serviceManager = services.ServiceManager
end

function ModuleLoader:Init()
    OVHL:_registerService("ModuleLoader", self)
    self.logger:Info("ModuleLoader initialized")
    return true
end

function ModuleLoader:Start()
    self.logger:Info("ModuleLoader starting module discovery...")
    
    local success = self:LoadModules()
    if not success then
        self.logger:Error("ModuleLoader failed to load modules")
        return false
    end
    
    self.logger:Info("ModuleLoader started successfully")
    return true
end

-- ==================== PUBLIC API ====================

function ModuleLoader:GetModule(moduleName)
    local moduleInfo = self.loadedModules[moduleName]
    return moduleInfo and moduleInfo.instance
end

function ModuleLoader:GetAllModules()
    return self.loadedModules
end

return ModuleLoader

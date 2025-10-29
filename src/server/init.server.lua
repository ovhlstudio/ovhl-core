local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local BOOTSTRAP_STATE = {phase = "NOT_STARTED", services = {}, modules = {}, errors = {}}

print("🚀 OVHL Server Bootstrap Starting...")
print("📋 PHASE 1: Loading Foundation Services (Manual)")

BOOTSTRAP_STATE.phase = "LOADING_FOUNDATION"

local LoggerService
do
    local success, result = pcall(function() return require(script.services.LoggerService) end)
    if not success then error("❌ [OVHL BOOTSTRAP] FAILED to load LoggerService: " .. tostring(result)) end
    LoggerService = result
end

local logger = LoggerService.new()
logger:Init()
logger:Start()
logger:Info("LoggerService loaded successfully")

local DependencyResolver
do
    local success, result = pcall(function() return require(script.services.DependencyResolver) end)
    if not success then
        logger:Error("Failed to load DependencyResolver", {error = result})
        error("❌ [OVHL BOOTSTRAP] FAILED to load DependencyResolver: " .. tostring(result))
    end
    DependencyResolver = result
end

local resolver = DependencyResolver.new(logger)
resolver:Init()
resolver:Start()
logger:Info("DependencyResolver loaded successfully")

local function FindInDiscovered(name, discoveredList)
    for _, item in ipairs(discoveredList) do if item.name == name then return item end end
    return nil
end

local function ValidateManifest(manifest, moduleName, logger)
    if not manifest then logger:Warn("Missing __manifest", {module = moduleName}) return false end
    if not manifest.name then logger:Error("Manifest missing 'name' field", {module = moduleName}) return false end
    if not manifest.version then logger:Error("Manifest missing 'version' field", {module = moduleName}) return false end
    if not manifest.type then logger:Error("Manifest missing 'type' field", {module = moduleName}) return false end
    if manifest.name ~= moduleName then
        logger:Error("Name mismatch in manifest", {module = moduleName, manifestName = manifest.name})
        return false
    end
    local validTypes = {"service", "controller", "module", "component"}
    local isValidType = false
    for _, validType in ipairs(validTypes) do
        if manifest.type == validType then isValidType = true break end
    end
    if not isValidType then
        logger:Error("Invalid type in manifest", {module = moduleName, type = manifest.type})
        return false
    end
    return true
end

local function AutoDiscoverModules(folder, logger, resolver, manuallyLoaded)
    logger:Info("Auto-discovering modules", {folder = folder.Name})
    local discovered = {}
    manuallyLoaded = manuallyLoaded or {}
    for _, moduleScript in ipairs(folder:GetChildren()) do
        if not moduleScript:IsA("ModuleScript") then continue end
        local moduleName = moduleScript.Name
        if manuallyLoaded[moduleName] then logger:Debug("Skipping manually loaded module", {module = moduleName}) continue end
        local success, module = pcall(require, moduleScript)
        if not success then
            logger:Error("Failed to require module", {module = moduleName, error = module})
            table.insert(BOOTSTRAP_STATE.errors, {module = moduleName, error = "Require failed: " .. tostring(module)})
            continue
        end
        if not ValidateManifest(module.__manifest, moduleName, logger) then
            table.insert(BOOTSTRAP_STATE.errors, {module = moduleName, error = "Invalid manifest"})
            continue
        end
        table.insert(discovered, {name = moduleName, module = module, manifest = module.__manifest, instance = nil})
        logger:Debug("Discovered module", {module = moduleName, type = module.__manifest.type, version = module.__manifest.version})
    end
    local loadOrder = resolver:Resolve(discovered)
    if not loadOrder then
        logger:Error("Dependency resolution failed for folder", {folder = folder.Name})
        return nil, nil
    end
    logger:Info("Auto-discovery completed", {folder = folder.Name, discovered = #discovered, loadOrder = loadOrder})
    return discovered, loadOrder
end

local function InitializeModules(discovered, loadOrder, logger, existingInstances)
    existingInstances = existingInstances or {}
    local instances = existingInstances
    logger:Info("Initializing modules", {count = #loadOrder})
    for _, moduleName in ipairs(loadOrder) do
        local moduleData = FindInDiscovered(moduleName, discovered)
        if not moduleData then logger:Error("Module not found in discovered list", {module = moduleName}) continue end
        local success, instance = pcall(function() return moduleData.module.new(logger) end)
        if success then
            instances[moduleName] = instance
            moduleData.instance = instance
            logger:Debug("Created instance", {module = moduleName})
        else
            logger:Error("Failed to create instance", {module = moduleName, error = instance})
            table.insert(BOOTSTRAP_STATE.errors, {module = moduleName, error = "Instance creation failed: " .. tostring(instance)})
        end
    end
    for _, moduleName in ipairs(loadOrder) do
        local instance = instances[moduleName]
        if instance and instance.Inject then
            local success, err = pcall(function() instance:Inject(instances) end)
            if not success then logger:Error("Injection failed", {module = moduleName, error = err}) end
        end
    end
    for _, moduleName in ipairs(loadOrder) do
        local instance = instances[moduleName]
        if instance and instance.Init then
            local success, result = pcall(function() return instance:Init() end)
            if not success then
                logger:Error("Initialization failed", {module = moduleName, error = result})
                table.insert(BOOTSTRAP_STATE.errors, {module = moduleName, error = "Init failed: " .. tostring(result)})
            elseif result == false then
                logger:Warn("Module initialization aborted", {module = moduleName})
                instances[moduleName] = nil
            end
        end
    end
    for _, moduleName in ipairs(loadOrder) do
        local instance = instances[moduleName]
        if instance and instance.Start then
            task.spawn(function()
                local success, err = pcall(function() instance:Start() end)
                if not success then logger:Error("Start failed", {module = moduleName, error = err}) end
            end)
        end
    end
    return instances
end

print("📋 PHASE 2: Auto-Discovering Services")
BOOTSTRAP_STATE.phase = "DISCOVERING_SERVICES"

local manuallyLoadedServices = {LoggerService = true, DependencyResolver = true}
local discoveredServices, serviceLoadOrder = AutoDiscoverModules(script.services, logger, resolver, manuallyLoadedServices)

if not discoveredServices then error("❌ [OVHL BOOTSTRAP] Service discovery failed!") end

print("📋 PHASE 3: Initializing Services")
BOOTSTRAP_STATE.phase = "INITIALIZING_SERVICES"

local serviceInstances = {Logger = logger, DependencyResolver = resolver}
serviceInstances = InitializeModules(discoveredServices, serviceLoadOrder, logger, serviceInstances)
BOOTSTRAP_STATE.services = serviceInstances

print("📋 PHASE 4: Auto-Discovering Modules")
BOOTSTRAP_STATE.phase = "DISCOVERING_MODULES"

local discoveredModules, moduleLoadOrder = AutoDiscoverModules(script.modules, logger, resolver)

if discoveredModules then
    print("📋 PHASE 4.1: Initializing Modules")
    BOOTSTRAP_STATE.phase = "INITIALIZING_MODULES"
    local moduleInstances = InitializeModules(discoveredModules, moduleLoadOrder, logger)
    BOOTSTRAP_STATE.modules = moduleInstances
else
    logger:Warn("No modules discovered or module discovery failed")
    BOOTSTRAP_STATE.modules = {}
end

print("📋 PHASE 5: Creating OVHL Global API")
BOOTSTRAP_STATE.phase = "CREATING_GLOBAL_API"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OVHL_Shared = ReplicatedStorage:WaitForChild("OVHL_Shared")

if not OVHL_Shared then
    logger:Error("OVHL_Shared folder not found in ReplicatedStorage")
else
    local OVHLGlobal = require(OVHL_Shared:WaitForChild("OVHL_Global"))
    _G.OVHL = OVHLGlobal.new({services = serviceInstances, modules = BOOTSTRAP_STATE.modules, logger = logger})
    logger:Info("OVHL Global API created successfully")
end

print("📋 PHASE 6: System Ready")
BOOTSTRAP_STATE.phase = "READY"

_G.OVHL_READY = true
_G.OVHL_BOOTSTRAP_STATE = BOOTSTRAP_STATE

logger:Info("🎉 OVHL Server Bootstrap COMPLETED!", {
    services = #serviceLoadOrder,
    modules = discoveredModules and #moduleLoadOrder or 0,
    errors = #BOOTSTRAP_STATE.errors
})

print("🎉 OVHL SERVER READY!")
print("📊 Bootstrap Summary:")
print("   ✅ Services: " .. tostring(#serviceLoadOrder))
print("   ✅ Modules: " .. tostring(discoveredModules and #moduleLoadOrder or 0))
print("   ⚠️  Errors: " .. tostring(#BOOTSTRAP_STATE.errors))

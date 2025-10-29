--[[
    File: src/shared/NetworkSchema.lua  
    Tujuan: Validation schema untuk RemoteManager
    Versi Modul: 1.0.1 - NO ... USAGE
--]]

local t = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages").t)

local NetworkSchema = {}

-- Player Management
NetworkSchema["Player:JoinGame"] = t.tuple(t.string) -- gameMode
NetworkSchema["Player:LeaveGame"] = t.tuple()
NetworkSchema["Player:UpdateProfile"] = t.tuple(t.string, t.optional(t.string)) -- displayName, status

-- Economy & Shop
NetworkSchema["Shop:BuyItem"] = t.tuple(t.string, t.integer) -- itemName, quantity
NetworkSchema["Shop:SellItem"] = t.tuple(t.string, t.integer) -- itemName, quantity
NetworkSchema["Shop:GetCatalog"] = t.tuple()
NetworkSchema["Economy:AddCoins"] = t.tuple(t.integer) -- amount
NetworkSchema["Economy:SpendCoins"] = t.tuple(t.integer) -- amount

-- Inventory & Items
NetworkSchema["Inventory:EquipItem"] = t.tuple(t.string) -- itemId
NetworkSchema["Inventory:UnequipItem"] = t.tuple(t.string) -- itemId
NetworkSchema["Inventory:UseItem"] = t.tuple(t.string) -- itemId
NetworkSchema["Inventory:GetItems"] = t.tuple()

-- Gameplay
NetworkSchema["Combat:Attack"] = t.tuple(t.string) -- target
NetworkSchema["Combat:UseAbility"] = t.tuple(t.string, t.optional(t.string)) -- abilityId, target
NetworkSchema["Quest:Accept"] = t.tuple(t.string) -- questId
NetworkSchema["Quest:Complete"] = t.tuple(t.string) -- questId
NetworkSchema["Quest:Abandon"] = t.tuple(t.string) -- questId

-- Social & Teams
NetworkSchema["Team:Create"] = t.tuple(t.string) -- teamName
NetworkSchema["Team:Join"] = t.tuple(t.string) -- teamId
NetworkSchema["Team:Leave"] = t.tuple()
NetworkSchema["Team:Invite"] = t.tuple(t.string) -- playerName
NetworkSchema["Friend:Add"] = t.tuple(t.string) -- playerName
NetworkSchema["Friend:Remove"] = t.tuple(t.string) -- playerName

-- Admin & Moderation
NetworkSchema["Admin:Kick"] = t.tuple(t.string, t.string) -- playerName, reason
NetworkSchema["Admin:Ban"] = t.tuple(t.string, t.string, t.number) -- playerName, reason, duration
NetworkSchema["Admin:Teleport"] = t.tuple(t.string, t.Vector3) -- playerName, position

-- UI & Client Events
NetworkSchema["UI:ButtonClick"] = t.tuple(t.string) -- buttonId
NetworkSchema["UI:InputChange"] = t.tuple(t.string, t.string) -- inputId, value
NetworkSchema["UI:MenuToggle"] = t.tuple(t.string, t.boolean) -- menuId, state

-- Test & Debug
NetworkSchema["Test:Ping"] = t.tuple()
NetworkSchema["Test:Echo"] = t.tuple(t.string) -- message

-- Data Management
NetworkSchema["Data:Save"] = t.tuple()
NetworkSchema["Data:Load"] = t.tuple()

-- SIMPLIFIED validation function - no ... usage
function NetworkSchema.Validate(remoteName, args)
    local schema = NetworkSchema[remoteName]
    
    if not schema then
        return false, "Unknown remote: " .. tostring(remoteName)
    end
    
    local success, result = pcall(function()
        if type(args) == "table" then
            return schema(unpack(args))
        else
            return schema(args)
        end
    end)
    
    if not success then
        return false, "Schema validation failed: " .. tostring(result)
    end
    
    return true, result
end

-- Type checking utilities
NetworkSchema.Types = {
    Player = t.instanceOf("Player"),
    Vector3 = t.Vector3,
    Color3 = t.Color3,
    NumberRange = t.NumberRange,
    UDim = t.UDim,
    UDim2 = t.UDim2,
    Ray = t.Ray,
    Region3 = t.Region3
}

return NetworkSchema

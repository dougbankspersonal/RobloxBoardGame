--[[
Random assortment of useful functions.
Note: before adding stuff here see if it's already in Cryo:
https://roblox.github.io/cryo-internal/api-reference
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Cryo = require(ReplicatedStorage.Cryo)

local Utils = {}

Utils.SnackFortUserId = 5845980262

local debugPrintEnabledLabels = {
    Buttons = false,
    ClientTableDescriptions = false,
    Friends = false,
    GameConfig = false,
    GameMetadata = false,
    GamePlay = false,
    GuiUtils = false,
    InviteToTable = false,
    Layout = false,
    MessageLog = false,
    Mocks = false,
    RemoveInvite = false,
    SanityChecks = true,
    Sound = false,
    TablePlaying = false,
    TableUpdated = false,
    User = false,
    UserLayout = false,
}

function Utils.splitString(str: string, delimiter: string): {string}
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

-- String starts with given start.
function Utils.stringStartsWith(str: string, start: string): boolean
    return str:sub(1, #start) == start
end

-- verify two tables have the same set of keys.
function Utils.tablesHaveSameKeys(table1: {[any]: any}, table2: {[any]: any}): boolean
    for key, _ in table1 do
        if table2[key] == nil then
            return false
        end
    end
    for key, _ in table2 do
        if table1[key] == nil then
            return false
        end
    end
    return true
end

-- is a value in a number-indexed array?
function Utils.arrayHasValue(array: {any}, value: any): boolean
    local index = Cryo.List.find(array, value)
    return index ~= nil
end

-- Two arrays have exactly same entries, mod order.
function Utils.unsortedListsMatch(list1: {any}, list2: {any}): boolean
    if #list1 ~= #list2 then
        return false
    end
    for _, value in ipairs(list1) do
        if not Utils.arrayHasValue(list2, value) then
            return false
        end
    end
    return true
end

function Utils.tableSize(table: {[any]: any}): number
    assert(table ~= nil, "tableSize: table is nil")
    local keys = Cryo.Dictionary.keys(table)
    return #keys
end

local debugPrintLabelCheck = function(label:string): boolean
    -- should be a label I know.
    local keys = Cryo.Dictionary.keys(debugPrintEnabledLabels)
    local found = Cryo.List.find(keys, label) ~= nil
    assert(found, "Unknown debugPrint label: " .. label)
    return debugPrintEnabledLabels[label]
end

function Utils.debugPrint(label, ...)
    if RunService:IsStudio() and debugPrintLabelCheck(label) then
        print(...)
    end
end

function Utils.debugDumpChildren(label: string, instance: Instance)
    local rdDummy
    local function recursiveDump(_instance: Instance, depth: number)
        local prefix = string.rep("  ", depth)
        print(prefix .. _instance.Name .. "(" .. _instance.ClassName .. ")")
        for _, child in ipairs(_instance:GetChildren()) do
            rdDummy(child, depth + 1)
        end
    end
    rdDummy = recursiveDump

    if RunService:IsStudio() and debugPrintLabelCheck(label) then
        print("Dumping children of " .. instance.Name)
        recursiveDump(instance, 0)
    end
end

function Utils.debugMapUserId(userId: CommonTypes.UserId): CommonTypes.UserId
    -- In studio we use mock userIds. When we try to get name or picture of that user things break.
    if RunService:IsStudio() then
        if userId < 0 then
            return userId + 1000000
        end
    end
    return userId
end

function Utils.getRandomKey(table: {[any]: any}): any
    local keys = Cryo.Dictionary.keys(table)
    local randomIndex = math.random(1, #keys)
    return keys[randomIndex]
end

function Utils.randomizeArray(array: {any}): {any}
    local result = Cryo.List.join(array, {})
    for i = #result, 2, -1 do
        local j = math.random(i)
        result[i], result[j] = result[j], result[i]
    end
    return result
end

return Utils

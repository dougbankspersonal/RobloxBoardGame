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

if RunService:IsStudio() then
    -- FIXME(dbanks)
    -- I don't know a way around this.  StudioService has what I want but can only be used in
    -- Plugin.
    -- If running in Studio, I want user ID of the person logged in to Studio: he is allowed to
    -- play as a mock user.
    -- Seems like i just have to hard wire my user id?
    Utils.StudioUserId = 5845980262
end

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
    SanityChecks = false,
    Sound = false,
    TablePlaying = false,
    TableUpdated = false,
    User = false,
    UserLayout = false,
}

debugPrintEnabledLabels.GamePlay = true

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

-- For debugging.
-- In Studio, the dude logged in is allowed to take actions on behalf of any mock user.
function Utils.firstUserCanPlayAsSecondUser(tableDescription: CommonTypes.TableDescription, firstUserId: CommonTypes.UserId, secondUserId:CommonTypes.UserId): boolean
    -- Better be a member of the game.
    assert(firstUserId, "firstUserId is nil")
    assert(secondUserId, "secondUserId is nil")

    Utils.debugPrint("Mocks", "firstUserCanPlayAsSecondUser: firstUserId = ", firstUserId)
    Utils.debugPrint("Mocks", "firstUserCanPlayAsSecondUser: secondUserId = ", secondUserId)

    -- If current player is attemped actor, fine.
    if firstUserId == secondUserId then
        Utils.debugPrint("Mocks", "firstUserCanPlayAsSecondUser: they match")
        return true
    end

    Utils.debugPrint("Mocks", "firstUserCanPlayAsSecondUser: tableDescription = ", tableDescription)
    -- If current player is mock and attempted actor is host, fine.
    if Utils.StudioUserId  == firstUserId and tableDescription.mockUserIds[secondUserId] then
        Utils.debugPrint("Mocks", "firstUserCanPlayAsSecondUser: firstUserId is Utils.StudioUserId and secondUserId is mock")
        return true
    end

    -- No good.
    return false
end

return Utils

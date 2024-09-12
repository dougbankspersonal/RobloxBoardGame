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

local debugPrintEnabledLabels = {
    Buttons = false,
    Friends = false,
    GameConfig = false,
    GameInstance = false,
    GameMetadata = false,
    GuiUtils = true,
    InviteToTable = false,
    Layout = false,
    Mocks = false,
    RemoveInvite = false,
    Sound = false,
    ClientTableDescriptions = false,
    TablePlaying = false,
    TableUpdated = false,
    UserLayout = false,
}

-- String starts with given start.
Utils.stringStartsWith = function(str: string, start: string): boolean
    return str:sub(1, #start) == start
end

-- verify two tables have the same set of keys.
Utils.tablesHaveSameKeys = function(table1: {[any]: any}, table2: {[any]: any}): boolean
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
Utils.arrayHasValue = function(array: {any}, value: any): boolean
    local index = Cryo.List.find(array, value)
    return index ~= nil
end

Utils.tableSize = function(table: {[any]: any}): number
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

Utils.debugPrint = function(label, ...)
    if RunService:IsStudio() and debugPrintLabelCheck(label) then
        print(...)
    end
end

Utils.debugDumpChildren = function(label: string, instance: Instance)
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

Utils.debugMapUserId = function(userId: CommonTypes.UserId): CommonTypes.UserId
    -- In studio we use mock userIds. When we try to get name or picture of that user things break.
    if RunService:IsStudio() then
        if userId < 0 then
            return userId + 1000000
        end
    end
    return userId
end

Utils.getRandomKey = function(table: {[any]: any}): any
    local keys = Cryo.Dictionary.keys(table)
    local randomIndex = math.random(1, #keys)
    return keys[randomIndex]
end

Utils.sanityCheckGameDetailsByGameId = function(gameDetailsByGameId: CommonTypes.GameDetailsByGameId)
    assert(gameDetailsByGameId ~= nil, "Should have non-nil gameDetailsByGameId")
    for gameId, gameDetails in pairs(gameDetailsByGameId) do
        assert(gameDetails.gameId == gameId, "gameId should match key")
        assert(gameDetails.gameImage ~= nil, "Should have non-nil gameImage")
        assert(gameDetails.name ~= nil, "Should have non-nil name")
        assert(gameDetails.description ~= nil, "Should have non-nil description")
        assert(gameDetails.maxPlayers ~= nil, "Should have non-nil maxPlayers")
        assert(gameDetails.minPlayers ~= nil, "Should have non-nil minPlayers")
    end
end

Utils.sanityCheckGameUIsByGameId = function(gameUIsByGameId: CommonTypes.GameUIsByGameId)
    assert(gameUIsByGameId ~= nil, "Should have non-nil gameUIsByGameId")
    for _, gameUIs in pairs(gameUIsByGameId) do
        assert(gameUIs.build ~= nil, "Should have non-nil build")
        assert(gameUIs.destroy ~= nil, "Should have non-nil destroy")
        assert(gameUIs.handlePlayerLeftGame ~= nil, "Should have non-nil handlePlayerLeftGame")
    end
end

Utils.sanityCheckGameInstanceFunctionsByGameId = function(gameInstanceFunctionsByGameId: CommonTypes.GameInstanceFunctionsByGameId)
    assert(gameInstanceFunctionsByGameId ~= nil, "Should have non-nil gameUIsByGameId")
    for _, gameInstanceFunctions in pairs(gameInstanceFunctionsByGameId) do
        assert(gameInstanceFunctions.onPlay ~= nil, "Should have non-nil onPlay")
        assert(gameInstanceFunctions.onEnd ~= nil, "Should have non-nil onPlay")
        assert(gameInstanceFunctions.onPlayerLeft ~= nil, "Should have non-nil onPlay")
    end
end

return Utils

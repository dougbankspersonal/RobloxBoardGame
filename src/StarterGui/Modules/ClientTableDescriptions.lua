--[[
We keep a client-side notion of all available tables.
Use this to get/set/update them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local TableDescription = require(RobloxBoardGameShared.Modules.TableDescription)

local Cryo = require(ReplicatedStorage.Cryo)

local ClientTableDescriptions = {
}

ClientTableDescriptions.tableDescriptionsByTableId = {} :: CommonTypes.TableDescriptionsByTableId

ClientTableDescriptions.setTableDescriptions = function(tableDescriptionsByTableId: CommonTypes.TableDescriptionsByTableId)
    ClientTableDescriptions.tableDescriptionsByTableId = tableDescriptionsByTableId
end

ClientTableDescriptions.getTableDescription = function(tableId: CommonTypes.TableId): CommonTypes.TableDescription?
    return ClientTableDescriptions.tableDescriptionsByTableId[tableId]
end

ClientTableDescriptions.addTableDescription = function(tableDescription: CommonTypes.TableDescription)
    ClientTableDescriptions.tableDescriptionsByTableId[tableDescription.tableId] = tableDescription
end

ClientTableDescriptions.removeTableDescription = function(tableId: CommonTypes.TableId)
    ClientTableDescriptions.tableDescriptionsByTableId[tableId] = nil
end

ClientTableDescriptions.updateTableDescription = function(tableDescription: CommonTypes.TableDescription)
    ClientTableDescriptions.tableDescriptionsByTableId[tableDescription.tableId] = tableDescription
end

-- Find the table this user belongs to.
-- Should never be true that user is part of more than one table.
ClientTableDescriptions.getTableWithUserId = function(userId: number): CommonTypes.TableDescription?
    local retVal = nil

    for _, tableDescription in pairs(ClientTableDescriptions.tableDescriptionsByTableId) do
        if tableDescription.memberUserIds[userId] then
            -- Should only ever be one.
            assert(retVal == nil, "User should only be in one table")
            retVal = tableDescription
            -- we could just break here but I want to prove this assumption that any user is part of
            -- no more than 1 table, so we keep going.
        end
    end
    return retVal
end

-- Find all tables where:
--   * Table is invite-only.
--   * Local user is invited.
--   * Table is in the "waiting" state.
--   * Table is not full.
--
-- Return an array of ids for these tables.
ClientTableDescriptions.getTableIdsForInvitedWaitingTables = function(userId: CommonTypes.UserId): { CommonTypes.TableId }
    assert(userId, "userId must be provided")
    local tableIds = {}
    for _, tableDescription in pairs(ClientTableDescriptions.tableDescriptionsByTableId) do
        if TableDescription.playerCanJoinInvitedTable(userId, tableDescription) then
            table.insert(tableIds, tableDescription.tableId)
        end
    end

    return tableIds
end

-- Find all tables where:
--   * Table is public.
--   * Table is in the "waiting" state.
--   * Table is not full.
--
-- Return an array of ids for these tables.
ClientTableDescriptions.getTableIdsForPublicWaitingTables = function(userId: CommonTypes.UserId): { CommonTypes.TableId }
    assert(userId, "userId must be provided")
    local tableIds = {}
    for _, tableDescription in pairs(ClientTableDescriptions.tableDescriptionsByTableId) do
        if TableDescription.playerCanJoinPublicTable(userId, tableDescription) then
            table.insert(tableIds, tableDescription.tableId)
        end
    end

    return tableIds
end

ClientTableDescriptions.cleanUpTypes = function(tableDescription: CommonTypes.TableDescription): CommonTypes.TableDescription
    local retVal = Cryo.Dictionary.join(tableDescription, {})

    retVal.memberUserIds = {}
    for userId, v in tableDescription.memberUserIds do
        local userIdAsNumber = tonumber(userId)
        retVal.memberUserIds[userIdAsNumber] = v
    end

    retVal.invitedUserIds = {}
    for userId, v in tableDescription.invitedUserIds do
        retVal.invitedUserIds[tonumber(userId)] = v
    end

    if tableDescription.nonDefaultGameOptions then
        retVal.nonDefaultGameOptions = {}
        for gameOptionId, v in tableDescription.nonDefaultGameOptions do
            retVal.nonDefaultGameOptions[tonumber(gameOptionId)] = v
        end
    end

    return retVal
end

ClientTableDescriptions.localPlayerIsAtTable = function(tableId: CommonTypes.TableId): boolean
    local player = game.Players.LocalPlayer
    if not player then
        return false
    end
    local userId = player.UserId
    local tableDescription = ClientTableDescriptions.tableDescriptionsByTableId[tableId]
    if not tableDescription then
        return false
    end
    return tableDescription.memberUserIds[userId] ~= nil
end

return ClientTableDescriptions
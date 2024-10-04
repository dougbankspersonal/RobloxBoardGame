--[[
We keep a client-side notion of all available tables.
Use this to get/set/update them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local TableDescription = require(RobloxBoardGameShared.Modules.TableDescription)
local TableDescripton = require(RobloxBoardGameShared.Modules.TableDescription)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

local ClientTableDescriptions = {
}

ClientTableDescriptions.tableDescriptionsByTableId = {} :: CommonTypes.TableDescriptionsByTableId


-- Async because we do some work fetching per-user data.
ClientTableDescriptions.setTableDescriptionsAsync = function(tableDescriptionsByTableId: CommonTypes.TableDescriptionsByTableId)
    ClientTableDescriptions.tableDescriptionsByTableId = tableDescriptionsByTableId
    for _, tableDescription in pairs(tableDescriptionsByTableId) do
        TableDescripton.sanityCheck(tableDescription)
        TableDescription.fetchUserDataAsync(tableDescription)
    end
end

-- Async because we do some work fetching per-user data.
ClientTableDescriptions.addTableDescriptionAsync = function(tableDescription: CommonTypes.TableDescription)
    TableDescripton.sanityCheck(tableDescription)
    TableDescription.fetchUserDataAsync(tableDescription)
    ClientTableDescriptions.tableDescriptionsByTableId[tableDescription.tableId] = tableDescription
end

ClientTableDescriptions.updateTableDescriptionAsync = function(tableDescription: CommonTypes.TableDescription)
    Utils.debugPrint("GamePlay", "updateTableDescriptionAsync 001 tableDescription = ", tableDescription)
    TableDescripton.sanityCheck(tableDescription)
    TableDescription.fetchUserDataAsync(tableDescription)
    Utils.debugPrint("GamePlay", "updateTableDescriptionAsync 002 tableDescription = ", tableDescription)
    ClientTableDescriptions.tableDescriptionsByTableId[tableDescription.tableId] = tableDescription
end

ClientTableDescriptions.getTableDescription = function(tableId: CommonTypes.TableId): CommonTypes.TableDescription?
    return ClientTableDescriptions.tableDescriptionsByTableId[tableId]
end

ClientTableDescriptions.removeTableDescription = function(tableId: CommonTypes.TableId)
    ClientTableDescriptions.tableDescriptionsByTableId[tableId] = nil
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
        if TableDescription.playerCanJoinInvitedTable(tableDescription, userId) then
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
        if TableDescription.playerCanJoinPublicTable(tableDescription, userId) then
            table.insert(tableIds, tableDescription.tableId)
        end
    end

    return tableIds
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
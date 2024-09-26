--[[
We keep a client-side notion of all available tables.
Use this to get/set/update them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local TableDescription = require(RobloxBoardGameShared.Modules.TableDescription)

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
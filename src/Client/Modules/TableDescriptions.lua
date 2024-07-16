--[[
Functions to build and update the UI for selecting a table to join or creating a table.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared...
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)

local TableDescriptions = {
}

TableDescriptions.tableDescriptionsByTableId = {} :: CommonTypes.TableDescriptionsByTableId

TableDescriptions.setTableDescriptions = function(tableDescriptionsByTableId: CommonTypes.TableDescriptionsByTableId)
    TableDescriptions.tableDescriptionsByTableId = tableDescriptionsByTableId
end

TableDescriptions.getTableDescription = function(tableId: CommonTypes.TableId): CommonTypes.TableDescription?
    return TableDescriptions.tableDescriptionsByTableId[tableId]
end

TableDescriptions.addTableDescription = function(tableDescription: CommonTypes.TableDescription)
    TableDescriptions.tableDescriptionsByTableId[tableDescription.tableId] = tableDescription
end

TableDescriptions.removeTableDescription = function(tableId: CommonTypes.TableId)
    TableDescriptions.tableDescriptionsByTableId[tableId] = nil
end

TableDescriptions.updateTableDescription = function(tableDescription: CommonTypes.TableDescription)
    TableDescriptions.tableDescriptionsByTableId[tableDescription.tableId] = tableDescription
end

-- Find the table this user belongs to.
-- Should never be true that user is part of more than one table.
TableDescriptions.getTableWithUserId = function(userId: number): CommonTypes.TableDescription?
    local retVal = nil

    for _, tableDescription in pairs(TableDescriptions.tableDescriptionsByTableId) do
        if tableDescription.memberUserIds[userId] then
            -- Should only ever be one.
            assert(retVal == nil, "User should only be in one table")
            retVal = tableDescription
        end
    end
    return retVal
end

TableDescriptions.playerCanJoinInvitedTable = function(userId: CommonTypes.UserId, tableId: CommonTypes.TableId): boolean
    local tableDescription = TableDescriptions.tableDescriptionsByTableId[tableId]
    if not tableDescription then
        return false
    end
    if tableDescription.isPublic then
        return false
    end
    if tableDescription.memberUserIds[userId] then
        return false
    end
    if not tableDescription.invitedUserIds[userId] then
        return false
    end
    return tableDescription.gameTableState == GameTableStates.WaitingForPlayers
end

TableDescriptions.playerCanJoinPublicTable = function(userId: CommonTypes.UserId, tableId: CommonTypes.TableId): boolean
    local tableDescription = TableDescriptions.tableDescriptionsByTableId[tableId]
    if not tableDescription then
        return false
    end
    if not tableDescription.isPublic then
        return false
    end
    if tableDescription.memberUserIds[userId] then
        return false
    end

    return tableDescription.gameTableState == GameTableStates.WaitingForPlayers
end


-- Find all tables where:
--   * Table is invite-only.
--   * Local user is invited.
--   * Table is in the "waiting" state.
--   * Table is not full.
--
-- Return an array of ids for these tables.
TableDescriptions.getTableIdsForInvitedWaitingTables = function(userId: CommonTypes.UserId): { CommonTypes.TableId }
    local tableIds = {}
    for _, tableDescription in pairs(TableDescriptions.tableDescriptionsByTableId) do
        if TableDescriptions.playerCanJoinInvitedTable(userId, tableDescription) then
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
-- Return an array of ids for these tables.TableDescriptions.getTableIdsForPublicWaitingTables = function(): { CommonTypes.TableId }
TableDescriptions.getTableIdsForPublicWaitingTables = function(userId: CommonTypes.UserId): { CommonTypes.TableId }
    local tableIds = {}
    for _, tableDescription in pairs(TableDescriptions.tableDescriptionsByTableId) do
        if TableDescriptions.playerCanJoinPublicTable(userId, tableDescription) then
            table.insert(tableIds, tableDescription.tableId)
        end
    end

    return tableIds
end

return TableDescriptions
--[[
Functions to build and update the UI for selecting a table to join or creating a table.
]]

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

local sortTableDescriptionsByTableId = function(a, b)
    return a.tableId < b.tableId
end

-- Find all tables where:
--   Local user is invited.
--   Table is in the "waiting" state.
-- Sort by tableId with later table ids coming last (perhaps my own bias but and
-- old invite is more "urgent" than a new one).
--
-- Returns an array.  Note that we need consistent sort:
-- * UI uses array order to determine button order, we want that to be consistent.
-- * If we use tableId -> description map, there's no guaranteed/consistent order.
TableDescriptions.getSortedInvitedWaitingTablesForUser = function(userId: CommonTypes.UserId): { CommonTypes.TableDescription }
    local invitedTables = {}
    for _, tableDescription in pairs(TableDescriptions.tableDescriptionsByTableId) do
        if tableDescription.gameTableState == GameTableStates.WaitingForPlayers and
            (not tableDescription.isPublic) and
            tableDescription.invitedUserIds[userId] then
            table.insert(invitedTables, tableDescription)
        end
    end

    table.sort(invitedTables, sortTableDescriptionsByTableId)

    return invitedTables
end

TableDescriptions.getSortedPublicWaitingTables = function(): { CommonTypes.TableDescription }
    local publicTables = {}
    for _, tableDescription in pairs(TableDescriptions.tableDescriptionsByTableId) do
        if tableDescription.gameTableState == GameTableStates.WaitingForPlayers and tableDescription.isPublic then
            table.insert(publicTables, tableDescription)
        end
    end

    table.sort(publicTables, sortTableDescriptionsByTableId)

    return publicTables
end

return TableDescriptions
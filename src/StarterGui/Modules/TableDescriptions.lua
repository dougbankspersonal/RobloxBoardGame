--[[
Functions to build and update the UI for selecting a table to join or creating a table.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)

local Cryo = require(ReplicatedStorage.Cryo)

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
            -- we could just break here but I want to prove this assumption that any user is part of
            -- no more than 1 table, so we keep going.
        end
    end
    return retVal
end

TableDescriptions.getNumberOfPlayersAtTable = function(tableDescription: CommonTypes.TableDescription): number
    assert(tableDescription, "tableDescription must be provided")
    assert(tableDescription.memberUserIds, "tableDescription.memberUserIds must be provided")
    assert(tableDescription.hostUserId, "tableDescription.hostUserId must be provided")
    assert(tableDescription.memberUserIds[tableDescription.hostUserId], "hostUserId must be in memberUserIds")
    return Cryo.Dictionary.size(tableDescription.memberUserIds)
end

TableDescriptions.tableHasRoom = function(tableDescription: CommonTypes.TableDescription): boolean
    return tableDescription.maxPlayers > TableDescriptions.getNumberOfPlayersAtTable(tableDescription)
end

TableDescriptions.playerCanJoinInvitedTable = function(userId: CommonTypes.UserId, tableDescription: CommonTypes.TableDescription): boolean
    assert(userId, "userId must be provided")
    assert(tableDescription, "tableDescription must be provided")

    if tableDescription.isPublic then
        return false
    end

    if tableDescription.memberUserIds[userId] then
        return false
    end

    if not tableDescription.invitedUserIds[userId] then
        return false
    end

    if not TableDescriptions.tableHasRoom(tableDescription) then
        return false
    end

    return tableDescription.gameTableState == GameTableStates.WaitingForPlayers
end

TableDescriptions.playerCanJoinPublicTable = function(userId: CommonTypes.UserId, tableDescription: CommonTypes.TableDescription): boolean
    assert(tableDescription, "tableDescription must be provided")

    if not tableDescription.isPublic then
        return false
    end

    if tableDescription.memberUserIds[userId] then
        return false
    end

    if not TableDescriptions.tableHasRoom(tableDescription) then
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
    assert(userId, "userId must be provided")
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
-- Return an array of ids for these tables.
TableDescriptions.getTableIdsForPublicWaitingTables = function(userId: CommonTypes.UserId): { CommonTypes.TableId }
    assert(userId, "userId must be provided")
    local tableIds = {}
    for _, tableDescription in pairs(TableDescriptions.tableDescriptionsByTableId) do
        if TableDescriptions.playerCanJoinPublicTable(userId, tableDescription) then
            table.insert(tableIds, tableDescription.tableId)
        end
    end

    return tableIds
end

TableDescriptions.getMembersWithoutHost = function(tableDescription: CommonTypes.TableDescription): { [CommonTypes.UserId]: boolean }
    local membersWithoutHost = {}
    for userId, _ in pairs(tableDescription.memberUserIds) do
        if userId ~= tableDescription.hostUserId then
            membersWithoutHost[userId] = true
        end
    end
    return membersWithoutHost
end

TableDescriptions.cleanUpTypes = function(tableDescription: CommonTypes.TableDescription): CommonTypes.TableDescription
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

TableDescriptions.localPlayerIsAtTable = function(tableId: CommonTypes.TableId): boolean
    local player = game.Players.LocalPlayer
    if not player then
        return false
    end
    local userId = player.UserId
    local tableDescription = TableDescriptions.tableDescriptionsByTableId[tableId]
    if not tableDescription then
        return false
    end
    return tableDescription.memberUserIds[userId] ~= nil
end

return TableDescriptions
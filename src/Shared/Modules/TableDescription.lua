-- Queries about a table description.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)
local Cryo = require(ReplicatedStorage.Cryo)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

local TableDescription = {}

TableDescription.getNumberOfPlayersAtTable = function(tableDescription: CommonTypes.TableDescription): number
    assert(tableDescription, "tableDescription must be provided")
    assert(tableDescription.memberUserIds, "tableDescription.memberUserIds must be provided")
    assert(tableDescription.hostUserId, "tableDescription.hostUserId must be provided")
    assert(tableDescription.memberUserIds[tableDescription.hostUserId], "hostUserId must be in memberUserIds")
    return #(Cryo.Dictionary.keys(tableDescription.memberUserIds))
end

TableDescription.tableHasRoom = function(tableDescription: CommonTypes.TableDescription): boolean
    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    return gameDetails.maxPlayers > TableDescription.getNumberOfPlayersAtTable(tableDescription)
end

TableDescription.playerCanJoinInvitedTable = function(userId: CommonTypes.UserId, tableDescription: CommonTypes.TableDescription): boolean
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

    if not TableDescription.tableHasRoom(tableDescription) then
        return false
    end

    return tableDescription.gameTableState == GameTableStates.WaitingForPlayers
end

TableDescription.playerCanJoinPublicTable = function(userId: CommonTypes.UserId, tableDescription: CommonTypes.TableDescription): boolean
    assert(tableDescription, "tableDescription must be provided")

    if not tableDescription.isPublic then
        return false
    end

    if tableDescription.memberUserIds[userId] then
        return false
    end

    if not TableDescription.tableHasRoom(tableDescription) then
        return false
    end

    return tableDescription.gameTableState == GameTableStates.WaitingForPlayers
end

return TableDescription
-- Create, query, update functions related to a TableDescription.
-- FIXME(dbanks)
-- I would like to make this a class, but these things get sent along as args
-- to events, and I am not sure if the "classiness" would work.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Cryo = require(ReplicatedStorage.Cryo)

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)
local PlayerUtils = require(RobloxBoardGameShared.Modules.PlayerUtils)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

local TableDescription = {}

TableDescription.fetchUserDataAsync = function(tableDescription: CommonTypes.TableDescription)
    -- For everyone I might care about, prefetch the user info.
    local memberUserIds = Cryo.Dictionary.keys(tableDescription.memberUserIds)
    local invitedUserIds = Cryo.Dictionary.keys(tableDescription.invitedUserIds)
    local allUserIds = Cryo.List.join(memberUserIds, invitedUserIds)

    Utils.debugPrint("Mocks", "Doug allUserIds = ", allUserIds)
    Utils.debugPrint("Mocks", "Doug PlayerUtils = ", PlayerUtils)

    PlayerUtils.asyncFetchPlayerInfo(allUserIds)
end

TableDescription.createTableDescription = function(tableId: CommonTypes.TableId, hostUserId: CommonTypes.UserId, gameId: CommonTypes.GameId, isPublic: boolean): CommonTypes.TableDescription
    return {
        tableId = tableId,
        memberUserIds = {
            [hostUserId] = true,
        },
        isPublic = isPublic,
        hostUserId = hostUserId,
        invitedUserIds = {},
        gameId = gameId,
        gameTableState = GameTableStates.WaitingForPlayers,
        mockUserIds = {},
    }
end

TableDescription.sanityCheck = function(tableDescription: CommonTypes.TableDescription)
    assert(tableDescription, "tableDescription must be provided")
    assert(tableDescription.tableId, "tableId must be provided")
    assert(tableDescription.memberUserIds, "memberUserIds must be provided")
    assert(tableDescription.hostUserId, "hostUserId must be provided")
    assert(tableDescription.invitedUserIds, "invitedUserIds must be provided")
    assert(tableDescription.gameId, "gameId must be provided")
    assert(tableDescription.gameTableState, "gameTableState must be provided")
    assert(tableDescription.memberUserIds[tableDescription.hostUserId], "hostUserId must be in memberUserIds")
    if RunService:IsStudio() then
        assert(tableDescription.mockUserIds, "mockUserIds must be provided")
    end
end

TableDescription.getNumberOfPlayersAtTable = function(tableDescription: CommonTypes.TableDescription): number
    return #(Cryo.Dictionary.keys(tableDescription.memberUserIds))
end

TableDescription.tableHasRoom = function(tableDescription: CommonTypes.TableDescription): boolean
    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    return gameDetails.maxPlayers > TableDescription.getNumberOfPlayersAtTable(tableDescription)
end

TableDescription.playerCanJoinInvitedTable = function(tableDescription: CommonTypes.TableDescription, userId: CommonTypes.UserId): boolean
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

TableDescription.playerCanJoinPublicTable = function(tableDescription: CommonTypes.TableDescription, userId: CommonTypes.UserId): boolean
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

TableDescription.isMockUserId = function(tableDescription: CommonTypes.TableDescription, userId: CommonTypes.UserId): boolean
    assert(tableDescription, "tableDescription must be provided")
    assert(userId, "userId must be provided")
    return tableDescription.mockUserIds[userId] or false
end

TableDescription.getPlayers = function(tableDescription: CommonTypes.TableDescription): { Player }
    assert(tableDescription, "tableDescription must be provided")
    -- Get Player for everyone I think is in the game.
    -- Due to timing issues and mocking for tests, Player may not actually exist: just leave those out.
    local players = {}
    for userId, _ in tableDescription.memberUserIds do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            table.insert(players, player)
        end
    end
    return players
end

--[[
When sent over a wire table descriptions are changed.
Specifically, keys that are ints become strings.  Turn them back.
]]

TableDescription.sanitizeTableDescriptionsByTableId = function(tableDescriptionsByTableId: CommonTypes.TableDescriptionsByTableId): CommonTypes.TableDescriptionsByTableId
    local retVal = {}
    for stringTableId, tableDescription in pairs(tableDescriptionsByTableId) do
        local tableId = tonumber(stringTableId)
        retVal[tableId] = TableDescription.sanitizeTableDescription(tableDescription)
    end
    return retVal
end

TableDescription.sanitizeTableDescription = function(tableDescription: CommonTypes.TableDescription): CommonTypes.TableDescription
    local retVal = Cryo.Dictionary.join(tableDescription, {})

    retVal.memberUserIds = {}
    for stringUserId, v in tableDescription.memberUserIds do
        retVal.memberUserIds[tonumber(stringUserId)] = v
    end

    retVal.invitedUserIds = {}
    for stringUserId, v in tableDescription.invitedUserIds do
        retVal.invitedUserIds[tonumber(stringUserId)] = v
    end

    if RunService:IsStudio() then
        retVal.mockUserIds = {}
        for stringUserId, v in tableDescription.mockUserIds do
            retVal.mockUserIds[tonumber(stringUserId)] = v
        end
    end

    return retVal
end

return TableDescription
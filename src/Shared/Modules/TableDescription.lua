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

local TableDescription = {}

function TableDescription.fetchUserDataAsync(tableDescription: CommonTypes.TableDescription)
    -- For everyone I might care about, prefetch the user info.
    local memberUserIds = Cryo.Dictionary.keys(tableDescription.memberUserIds)
    local invitedUserIds = Cryo.Dictionary.keys(tableDescription.invitedUserIds)
    local allUserIds = Cryo.List.join(memberUserIds, invitedUserIds)

    PlayerUtils.asyncFetchPlayerInfo(allUserIds)
end

function TableDescription.createTableDescription(tableId: CommonTypes.TableId, hostUserId: CommonTypes.UserId, gameId: CommonTypes.GameId, isPublic: boolean): CommonTypes.TableDescription
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

function TableDescription.getNumberOfPlayersAtTable(tableDescription: CommonTypes.TableDescription): number
    return #(Cryo.Dictionary.keys(tableDescription.memberUserIds))
end

function TableDescription.tableHasRoom(tableDescription: CommonTypes.TableDescription): boolean
    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    return gameDetails.maxPlayers > TableDescription.getNumberOfPlayersAtTable(tableDescription)
end

function TableDescription.playerCanJoinInvitedTable(tableDescription: CommonTypes.TableDescription, userId: CommonTypes.UserId): boolean
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

function TableDescription.playerCanJoinPublicTable(tableDescription: CommonTypes.TableDescription, userId: CommonTypes.UserId): boolean
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

function TableDescription.isMockUserId(tableDescription: CommonTypes.TableDescription, userId: CommonTypes.UserId): boolean
    assert(tableDescription, "tableDescription must be provided")
    assert(userId, "userId must be provided")
    return tableDescription.mockUserIds[userId] or false
end

function TableDescription.getPlayers(tableDescription: CommonTypes.TableDescription): { Player }
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

function TableDescription.sanitizeTableDescriptionsByTableId(tableDescriptionsByTableId: CommonTypes.TableDescriptionsByTableId): CommonTypes.TableDescriptionsByTableId
    local retVal = {}
    for stringTableId, tableDescription in pairs(tableDescriptionsByTableId) do
        local tableId = tonumber(stringTableId)
        retVal[tableId] = TableDescription.sanitizeTableDescription(tableDescription)
    end
    return retVal
end

function TableDescription.sanitizeTableDescription(tableDescription: CommonTypes.TableDescription): CommonTypes.TableDescription
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

function TableDescription.sanityCheck(tableDescription: CommonTypes.TableDescription)
    assert(tableDescription, "tableDescription must be provided")
    assert(tableDescription.tableId, "tableId must be provided")
    assert(typeof(tableDescription.tableId) == "number", "tableId must be a number")
    assert(tableDescription.hostUserId, "hostUserId must be provided")
    assert(typeof(tableDescription.hostUserId) == "number", "hostUserId must be a number")
    assert(tableDescription.gameId, "gameId must be provided")
    assert(typeof(tableDescription.gameId) == "number", "gameId must be a number")
    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    assert(gameDetails, "gameDetails must be provided")

    assert(tableDescription.gameTableState, "gameTableState must be provided")
    assert(typeof(tableDescription.gameTableState) == "number", "gameTableState must be a string")

    assert(tableDescription.memberUserIds, "memberUserIds must be provided")
    for userId, _ in pairs(tableDescription.memberUserIds) do
        assert(typeof(userId) == "number", "userId must be a number")
    end
    assert(tableDescription.invitedUserIds, "invitedUserIds must be provided")
    for userId, _ in pairs(tableDescription.invitedUserIds) do
        assert(typeof(userId) == "number", "userId must be a number")
    end
    -- Invites only if private.
    if tableDescription.isPublic then
        local invitedUserIds = Cryo.Dictionary.keys(tableDescription.invitedUserIds)
        assert(#invitedUserIds == 0, "If there are invited users, the table must be private")
    end

    -- Host should be a member.
    assert(tableDescription.memberUserIds[tableDescription.hostUserId], "hostUserId must be in memberUserIds")

    if RunService:IsStudio() then
        for mockUserId, _ in pairs(tableDescription.mockUserIds) do
            assert(typeof(mockUserId) == "number", "mockUserId must be a number")
            local isMember = tableDescription.memberUserIds[mockUserId]
            local isInvited = tableDescription.invitedUserIds[mockUserId]
            assert(isMember or isInvited, "Any mock user should be invited or member")
        end
    end
end

return TableDescription
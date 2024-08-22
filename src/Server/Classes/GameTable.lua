--[[
    Server-concept only.
    Class for a game table.
    Any instance of game table is stored in a global array: this file also
    provides static functions to fetch created tables based on table Id.
]]


local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local GameInstance = require(RobloxBoardGameServer.Classes.GameInstance)

local GameTable = {}
GameTable.__index = GameTable

local nextGameTableId: CommonTypes.TableId = 10000

export type GameTable = {
    -- members
    gameDetails: CommonTypes.GameDetails,
    gameInstance: GameInstance.GameInstance?,
    tableDescription: CommonTypes.TableDescription,
    isMock: boolean,

    -- static functions.
    new: (hostUserId: CommonTypes.UserId, gameDetails: CommonTypes.GameDetails, isPublic: boolean) -> GameTable,
    getGameTable: (tableId: CommonTypes.TableId) -> GameTable,
    createNewTable: (hostUserId: CommonTypes.UserId, isPublic: boolean) -> GameTable?,
    getAllGameTables: () -> { [CommonTypes.TableId]: GameTable },

    -- const member  functions.
    -- Shortcuts to ask questions about table.
    isMember: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    isInvitedToTable: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    isHost: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    getTableDescription: (self: GameTable) -> CommonTypes.TableDescription,
    getTableId: (self: GameTable) -> CommonTypes.TableId,
    getGameId: (self: GameTable) -> CommonTypes.GameId,

    -- non-const functions.  Each returns true iff something changed.
    destroyTable: (self: GameTable, userIds: {CommonTypes.UserId}) -> boolean,
    joinTable: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    inviteToTable: (self: GameTable, userId: CommonTypes.UserId, inviteeId: CommonTypes.UserId) -> boolean,
    setInvites: (self: GameTable, userId: CommonTypes.UserId, inviteeIds: {CommonTypes.UserId}) -> boolean,
    removeGuestFromTable: (self: GameTable, userId: CommonTypes.UserId, guestId: CommonTypes.UserId) -> boolean,
    removeInviteForTable: (self: GameTable, userId: CommonTypes.UserId, inviteId: CommonTypes.UserId) -> boolean,
    leaveTable: (self: GameTable, userId: CommonTypes.UserId) -> boolean,

    startGame: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    endGame: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    transitionFromEndToReplay: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
}

local gameTables = {} :: { [CommonTypes.TableId]: GameTable }


GameTable.getAllGameTables = function(): { [CommonTypes.TableId]: GameTable }
    return gameTables
end

GameTable.new = function(hostUserId: CommonTypes.UserId, gameId: CommonTypes.GameId, isPublic: boolean): GameTable
    local self = {}
    setmetatable(self, GameTable)

    local tableId = nextGameTableId
    nextGameTableId = nextGameTableId + 1

    self.isMock = false

    -- Fill in table description.
    self.tableDescription = {
        tableId = tableId,
        memberUserIds = {
            [hostUserId] = true,
        },
        isPublic = isPublic,
        hostUserId = hostUserId,
        invitedUserIds = {},
        gameId = gameId,
        gameTableState = GameTableStates.WaitingForPlayers,
    } :: CommonTypes.TableDescription

    self.gameDetails = GameDetails.getGameDetails(gameId)
    self.gameInstance = nil

    gameTables[tableId] = self

    return self
end

GameTable.getGameTable = function(tableId): GameTable
    return gameTables[tableId]
end

-- Return the table iff the table can be created.
GameTable.createNewTable = function(hostUserId: CommonTypes.UserId, gameId: CommonTypes.GameId, isPublic: boolean): GameTable?
    -- You cannot create a new table while you are joined to a table.
    for _, gameTable in pairs(gameTables) do
        if gameTable.tableDescription.memberUserIds[hostUserId] then
            return nil
        end
    end

    -- Game must exist.
    local gameDetails = GameDetails.getGameDetails(gameId)
    if not gameDetails then
        return nil
    end

    local newGameTable = GameTable.new(hostUserId, gameId, isPublic)
    return newGameTable
end

function GameTable:getTableId(): CommonTypes.TableId
    return self.tableDescription.tableId
end

function GameTable:getGameId(): CommonTypes.GameId
    return self.tableDescription.gameId
end

function GameTable:isMember(userId: CommonTypes.UserId): boolean
    return self.tableDescription.memberUserIds[userId]
end

function GameTable:isInvitedToTable(userId: CommonTypes.UserId): boolean
    return self.tableDescription.invitedUserIds[userId] or false
end

function GameTable:isHost(userId: CommonTypes.UserId): boolean
    return self.tableDescription.hostUserId == userId
end

function GameTable:destroyTable(userId: CommonTypes.UserId): boolean
    assert(userId, "Should have a userId")

    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    -- Kill any ongoing game.
    if self.gameInstance then
        self.gameInstance:destroy()
        self.gameInstance = nil
    end

    gameTables[self:getTableId()] = nil

    return true
end

-- Try to add user as member of table.
-- Return true iff successful.
function GameTable:joinTable(userId: CommonTypes.UserId): boolean
    assert(userId, "Should have a userId")

    -- Host can't join his own table.
    if self:isHost(userId) then
        return
    end

    -- Game already started, no.
    if self.tableDescription.gameTableState ~= GameTableStates.WaitingForPlayers then
        return false
    end

    -- Already a member, no.
    if self:isMember(userId) then
        return false
    end

    -- not public, not invited: no.
    if not self.tableDescription.isPublic and not self:isInvitedToTable(userId) then
        return false
    end

    -- too many players already, no.
    if self.gameDetails.maxPlayers <= Utils.tableSize(self.tableDescription.memberUserIds) then
        return false
    end

    self.tableDescription.memberUserIds[userId] = true

    -- Once a player is a Member they are no longer invited.
    self.tableDescription.invitedUserIds[userId] = nil

    return true
end

-- Try to add user as invitee of table.
-- Return true iff anything changes.
function GameTable:inviteToTable(userId: CommonTypes.UserId, inviteeId: CommonTypes.UserId): boolean
    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    -- Game already started, no.
    if self.tableDescription.gameTableState ~= GameTableStates.WaitingForPlayers then
        return false
    end

    -- Can't invite self.
    if userId == inviteeId then
        return false
    end

    -- Already a member, no.
    if self:isMember(inviteeId) then
        return false
    end

    -- Already invited, no.
    if self:isInvitedToTable(inviteeId) then
        return false
    end

    self.tableDescription.invitedUserIds[inviteeId] = true
    return true
end

-- Set invites to exactly this list.
-- Return true iff anything changes.
function GameTable:setInvites(userId: CommonTypes.UserId, inviteeIds: {CommonTypes.UserId}): boolean
    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    -- Game already started, no.
    if self.tableDescription.gameTableState ~= GameTableStates.WaitingForPlayers then
        return false
    end

    local newInvitedUserIds = {}

    for _, inviteeId in inviteeIds do
        -- Can't invite self.
        if userId == inviteeId then
            continue
        end

        -- Already a member, no.
        if self:isMember(inviteeId) then
            continue
        end

        newInvitedUserIds[inviteeId] = true
    end

    -- Did something change?
    local somethingChanged = false
    if not Utils.tablesHaveSameKeys(self.tableDescription.invitedUserIds, newInvitedUserIds) then
        somethingChanged = true
        self.tableDescription.invitedUserIds = newInvitedUserIds
    end

    return somethingChanged
end

function GameTable:removeGuestFromTable(userId: CommonTypes.UserId, guestId: CommonTypes.UserId): boolean
    assert(userId, "userId must be provided")
    assert(guestId, "guestId must be provided")

    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    -- Can't remove self.
    if userId == guestId then
        return false
    end

    -- Can't remove a non-member.
    if not self:isMember(guestId) then
        return false
    end

    self.tableDescription.memberUserIds[guestId] = nil
    -- Just for kicks remove the invite too.
    self.tableDescription.invitedUserIds[guestId] = nil
    return true
end

function GameTable:removeInviteForTable(userId: CommonTypes.UserId, inviteeId: CommonTypes.UserId): boolean
    Utils.debugPrint("RemoveInvite", "Doug: GameTable:removeInviteForTable userId = ", userId)
    -- Must be the host.
    if not self:isHost(userId) then
        Utils.debugPrint("RemoveInvite", "Doug: GameTable:removeInviteForTable 001")
        return false
    end

    -- Must be an invitee.
    if not self:isInvitedToTable(inviteeId) then
        Utils.debugPrint("RemoveInvite", "Doug: GameTable:removeInviteForTable 002")
        return false
    end

    self.tableDescription.invitedUserIds[inviteeId] = nil
    Utils.debugPrint("RemoveInvite", "Doug: GameTable:removeInviteForTable 003")
    return true
end

function GameTable:leaveTable(userId): boolean
    -- Host can't leave.
    if self:isHost(userId) then
        return false
    end

    -- Can't leave if not a member.
    if not self:isMember(userId) then
        return false
    end

    -- Remove the user.
    self.tableDescription.memberUserIds[userId] = nil

    -- Let the game deal with any fallout from the player leaving.
    if self.gameInstance then
        self.gameInstance:playerLeft(userId)
    end

    return true
end

function GameTable:startGame(userId: CommonTypes.UserId): boolean
    -- Only host can start.
    if self:isHost(userId) then
        return false
    end

    -- Game already started, no.
    if self.tableDescription.gameTableState == GameTableStates.Playing then
        return false
    end

    -- Right number of players?
    local numPlayers = Utils.tableSize(self.tableDescription.memberUserIds)
    if numPlayers < self.gameDetails.minPlayers then
        return false
    end
    if numPlayers > self.gameDetails.maxPlayers then
        return false
    end

    assert(self.gameInstance == nil, "Game instance already exists"	)
    self.tableDescription.gameTableState = GameTableStates.Playing
    self.gameInstance = GameInstance.new(self:getTableId(), self:getGameId())

    return true
end

function GameTable:endGame(userId: CommonTypes.UserId): boolean
    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    -- Game isn't playing, no.
    if self.tableDescription.gameTableState ~= GameTableStates.Playing then
        return false
    end

    self.tableDescription.gameTableState = GameTableStates.Finished
    self.gameInstance:endGame()
    self.gameInstance = nil

    return true
end

function GameTable:transitionFromEndToReplay(userId: CommonTypes.UserId): CommonTypes.TableDescription
    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    --We are not in "game finished" state, no.
    if self.tableDescription.gameTableState ~= GameTableStates.Finished then
        return false
    end

    self.tableDescription.gameTableState = GameTableStates.WaitingForPlayers
    return true
end

function GameTable:getTableDescription(): CommonTypes.TableDescription
    return self.tableDescription
end

return GameTable
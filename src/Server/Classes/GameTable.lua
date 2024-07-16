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
local gameTables = {}

GameTable.__index = GameTable

local nextGameTableId: CommonTypes.TableId = 0

export type GameTable = {
    -- members
    gameDetails: CommonTypes.GameDetails,
    gameInstance: GameInstance.GameInstance?,
    tableDescription: CommonTypes.TableDescription,

    -- static functions.
    new: (hostUserId: CommonTypes.UserId, gameDetails: CommonTypes.GameDetails, isPublic: boolean) -> GameTable,
    getGameTable: (tableId: CommonTypes.TableId) -> GameTable,
    createNewTable: (hostUserId: CommonTypes.UserId, isPublic: boolean) -> GameTable?,
    getAllGameTables: () -> { [CommonTypes.TableId]: GameTable },

    -- member  functions.
    destroy: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    join: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    invite: (self: GameTable, userId: CommonTypes.UserId, inviteeId: CommonTypes.UserId) -> boolean,
    leave: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    startGame: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    endGame: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
}

GameTable.getAllGameTables = function(): { [CommonTypes.TableId]: GameTable }
    return gameTables
end

GameTable.new = function(hostUserId: CommonTypes.UserId, gameId: CommonTypes.GameId, isPublic: boolean): GameTable
    local self = {}
    setmetatable(self, GameTable)

    local tableId = nextGameTableId
    nextGameTableId = nextGameTableId + 1

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

    self.invited = {}
    self.gameDetails = GameDetails.getGameDetails(gameId)
    self.gameInstance = nil

    gameTables[GameTable.id] = self

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

function GameTable:destroy(userId): boolean
    -- Not host, no.
    if self.hostUserId ~= userId then
        return false
    end

    -- Kill any ongoing game.
    if self.gameInstance then
        self.gameInstance:destroy()
        self.gameInstance = nil
    end

    gameTables[self.id] = nil

    return true
end

function GameTable:join(userId: CommonTypes.UserId): boolean
    -- Game already started, no.
    if self.tableDescription.gameTableState ~= GameTableStates.WaitingForPlayers then
        return false
    end

    -- Already a member, no.
    if self.memberUserIds[userId] then
        return false
    end

    -- not public, not invited: no.
    if not self.tableDescription.isPublic and not self.invited[userId] then
        return false
    end

    -- too many players already, no.
    if self.gameDetails.MaxPlayers == #self.tableDescription.memberUserIds then
        return false
    end


    table.insert(self.tableDescription.memberUserIds, userId)
    return true
end

-- True iff player can be invited to table.
function GameTable:invite(userId, inviteeId): boolean
    -- Game already started, no.
    if self.tableDescription.gameTableState ~= GameTableStates.WaitingForPlayers then
        return false
    end

    -- Already a member, no.
    if Utils.arrayHasValue(self.tableDescription.memberUserIds, userId) then
        return false
    end

    -- Already invited, no.
    if self.invited[inviteeId] then
        return false
    end

    self.invited[inviteeId] = true
    return true
end

function GameTable:leave(userId): boolean
    -- Host can't leave.
    if userId == self.hostUserId then
        return false
    end

    -- Remove this user from the array, if present.
    local removed = Utils.removeFromArray(self.tableDescription.memberUserIds, userId)
    if not removed then
        return false
    end

    -- Let the game deal with any fallout from the player leaving.
    if self.gameInstance then
        self.gameInstance:playerLeft(userId)
    end

    return true
end

function GameTable:startGame(userId: CommonTypes.UserId): boolean
    -- Not the host, no.
    if self.hostUserId ~= userId then
        return false
    end

    -- Game already started, no.
    if self.tableDescription.gameTableState == GameTableStates.Playing then
        return false
    end

    -- Right number of players?
    local numPlayers = #self.members
    if numPlayers < self.gameDetails.MinPlayers then
        return false
    end
    if numPlayers > self.gameDetails.MaxPlayers then
        return false
    end

    assert(self.gameInstance == nil, "Game instance already exists"	)
    self.tableDescription.gameTableState = GameTableStates.Playing
    self.gameInstance = GameInstance.new(self.id, self.gameDetails.gameId)

    return true
end

function GameTable:endGame(userId: CommonTypes.UserId): boolean
    -- Not the host, no.
    if self.hostUserId ~= userId then
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

function GameTable:endGame(userId: CommonTypes.UserId): boolean
    -- Not the host, no.
    if self.hostUserId ~= userId then
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
    -- Not the host, no.
    if self.hostUserId ~= userId then
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
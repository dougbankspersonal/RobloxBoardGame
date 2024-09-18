--[[
    Server-concept only.
    Types for server classes.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local ServerTypes = {}

export type GameInstance = {
    tableId: CommonTypes.TableId,
    gameId: CommonTypes.GameId,
    gameInstanceGUID: CommonTypes.GameInstanceGUID,

    new: (tableId: CommonTypes.TableId, gameId: CommonTypes.GameId) -> GameInstance,

    playGame: (self:GameInstance) -> nil,
    endGame: (self:GameInstance) -> nil,
    playerLeft: (self:GameInstance, userId: CommonTypes.UserId) -> nil,
    destroy: (self:GameInstance) -> nil,
}

export type GameTable = {
    -- members
    gameDetails: CommonTypes.GameDetails,
    gameInstance: GameInstance?,
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
    getGameInstanceGUID: (self:GameTable) -> CommonTypes.GameInstanceGUID,

    -- non-const functions.  Each returns true iff something changed.
    goToWaiting: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    destroyTable: (self: GameTable, userIds: {CommonTypes.UserId}) -> boolean,
    joinTable: (self: GameTable, userId: CommonTypes.UserId, opt_isMock: boolean?) -> boolean,
    inviteToTable: (self: GameTable, userId: CommonTypes.UserId, inviteeId: CommonTypes.UserId) -> boolean,
    setInvites: (self: GameTable, userId: CommonTypes.UserId, inviteeIds: {CommonTypes.UserId}) -> boolean,
    removeGuestFromTable: (self: GameTable, userId: CommonTypes.UserId, guestId: CommonTypes.UserId) -> boolean,
    removeInviteForTable: (self: GameTable, userId: CommonTypes.UserId, inviteId: CommonTypes.UserId) -> boolean,
    leaveTable: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    updateGameOptions: (self: GameTable, userId: CommonTypes.UserId, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions) -> boolean,

    startGame: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    endGame: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    endGameEarly: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
}

return ServerTypes
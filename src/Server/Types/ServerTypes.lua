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
    gameId: CommonTypes.GameId,
    gameInstanceGUID: CommonTypes.GameInstanceGUID,
    tableDescription: CommonTypes.TableDescription,

    new: (CommonTypes.GameId, CommonTypes.TableDescription) -> GameInstance,

    playGame: (GameInstance) -> nil,
    endGame: (GameInstance) -> nil,
    playerLeft: (GameInstance, userId: CommonTypes.UserId) -> nil,
    destroy: (GameInstance) -> nil,
}

export type GameTable = {
    -- members
    gameDetails: CommonTypes.GameDetails,
    gameInstance: GameInstance?,
    tableDescription: CommonTypes.TableDescription,
    isMock: boolean,

    -- static functions.
    new: (CommonTypes.UserId, CommonTypes.GameDetails, boolean) -> GameTable,
    getGameTable: (CommonTypes.TableId) -> GameTable,
    createNewTable: (CommonTypes.UserId, boolean) -> GameTable?,
    getAllGameTables: () -> { [CommonTypes.TableId]: GameTable },

    -- const member  functions.
    -- Shortcuts to ask questions about table.
    isMember: (GameTable, CommonTypes.UserId) -> boolean,
    isInvitedToTable: (GameTable, CommonTypes.UserId) -> boolean,
    isHost: (GameTable, CommonTypes.UserId) -> boolean,
    getTableDescription: (GameTable) -> CommonTypes.TableDescription,
    getTableId: (GameTable) -> CommonTypes.TableId,
    getGameId: (GameTable) -> CommonTypes.GameId,
    getGameInstanceGUID: (GameTable) -> CommonTypes.GameInstanceGUID,

    -- non-const functions.  Each returns true iff something changed.
    goToWaiting: (GameTable, CommonTypes.UserId) -> boolean,
    destroyTable: (GameTable, {CommonTypes.UserId}) -> boolean,
    joinTable: (GameTable, CommonTypes.UserId, boolean?) -> boolean,
    inviteToTable: (GameTable, CommonTypes.UserId, CommonTypes.UserId) -> boolean,
    setInvites: (GameTable, CommonTypes.UserId, {CommonTypes.UserId}) -> boolean,
    removeGuestFromTable: (GameTable, CommonTypes.UserId, CommonTypes.UserId) -> boolean,
    removeInviteForTable: (GameTable, CommonTypes.UserId, CommonTypes.UserId) -> boolean,
    leaveTable: (GameTable, CommonTypes.UserId) -> boolean,
    updateGameOptions: (GameTable, CommonTypes.UserId, CommonTypes.NonDefaultGameOptions) -> boolean,

    startGame: (GameTable, CommonTypes.UserId) -> boolean,
    endGame: (GameTable, CommonTypes.UserId) -> boolean,
    endGameEarly: (GameTable, CommonTypes.UserId) -> boolean,
}

return ServerTypes
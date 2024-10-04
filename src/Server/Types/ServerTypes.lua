local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local ServerTypes = {}

export type CreateTableHandler = (CommonTypes.UserId, CommonTypes.GameDetails, boolean, boolean?) -> GameTable

export type GameTable = {
    -- members
    gameDetails: CommonTypes.GameDetails,
    tableDescription: CommonTypes.TableDescription,

    -- static functions.
    new: CreateTableHandler,

    -- const member  functions.
    -- Shortcuts to ask questions about table.
    isMember: (GameTable, CommonTypes.UserId) -> boolean,
    isInvitedToTable: (GameTable, CommonTypes.UserId) -> boolean,
    isHost: (GameTable, CommonTypes.UserId) -> boolean,
    getTableDescription: (GameTable) -> CommonTypes.TableDescription,
    getTableId: (GameTable) -> CommonTypes.TableId,
    getGameId: (GameTable) -> CommonTypes.GameId,
    getGameInstanceGUID: (GameTable) -> CommonTypes.GameInstanceGUID,
    canEndGame: (GameTable, CommonTypes.UserId) -> boolean,
    canDestroy: (GameTable, CommonTypes.UserId) -> boolean,
    getServerGameInstance: (GameTable) -> CommonTypes.ServerGameInstance?,
    sanityCheck: (GameTable) -> nil,

    -- non-const functions.  Each returns true iff something changed.
    destroy: (GameTable) -> nil,
    joinTable: (GameTable, CommonTypes.UserId, boolean?) -> boolean,
    inviteToTable: (GameTable, CommonTypes.UserId, CommonTypes.UserId, boolean?) -> boolean,
    setInvites: (GameTable, CommonTypes.UserId, {CommonTypes.UserId}) -> boolean,
    removeGuestFromTable: (GameTable, CommonTypes.UserId, CommonTypes.UserId) -> boolean,
    removeInviteForTable: (GameTable, CommonTypes.UserId, CommonTypes.UserId) -> boolean,
    leaveTable: (GameTable, CommonTypes.UserId) -> boolean,
    updateGameOptions: (GameTable, CommonTypes.UserId, CommonTypes.NonDefaultGameOptions) -> boolean,
    startGame: (GameTable, CommonTypes.UserId) -> boolean,
    endGame: (GameTable) -> nil,
}

return ServerTypes
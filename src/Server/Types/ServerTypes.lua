local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local ServerTypes = {}

export type GameTable = {
    -- members
    gameDetails: CommonTypes.GameDetails,
    tableDescription: CommonTypes.TableDescription,
    isMock: boolean,

    -- static functions.
    new: (CommonTypes.UserId, CommonTypes.GameDetails, boolean) -> GameTable,

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
    getServerGameInstance: (GameTable) -> CommonTypes.ServerGameInstance,
    sanityCheck: (GameTable) -> nil,

    -- non-const functions.  Each returns true iff something changed.
    goToWaiting: (GameTable, CommonTypes.UserId) -> boolean,
    destroy: (GameTable) -> nil,
    joinTable: (GameTable, CommonTypes.UserId, boolean?) -> boolean,
    inviteToTable: (GameTable, CommonTypes.UserId, CommonTypes.UserId) -> boolean,
    setInvites: (GameTable, CommonTypes.UserId, {CommonTypes.UserId}) -> boolean,
    removeGuestFromTable: (GameTable, CommonTypes.UserId, CommonTypes.UserId) -> boolean,
    removeInviteForTable: (GameTable, CommonTypes.UserId, CommonTypes.UserId) -> boolean,
    leaveTable: (GameTable, CommonTypes.UserId) -> boolean,
    updateGameOptions: (GameTable, CommonTypes.UserId, CommonTypes.NonDefaultGameOptions) -> boolean,
    startGame: (GameTable, CommonTypes.UserId) -> boolean,
    endGame: (GameTable) -> nil,
}

return ServerTypes
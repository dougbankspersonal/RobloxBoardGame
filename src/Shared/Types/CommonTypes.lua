-- Common types

-- A user creates a table to host a game.
-- User other players join table, then host launches table, creating the game.
-- This id uniquely identifies a table within the experience.
export type TableId = number

-- A game is one of the board games that can be played in this experience.
-- You might have an experience with a single board game.
-- Or you might have a "board game night" experience where people can choose from a variety of games.
-- This id uniquely identifies a game within the experience.
export type GameId = number

-- Standard Roblox user id.
export type UserId = number

-- Standard Roblox asset
export type AssetId = number

-- Everything you need to know about a table.
-- A summary passed to clients so they know what's going on.
export type TableDescription = {
    tableId: TableId,
	hostPlayerId: UserId,
	memberPlayerIds: {UserId},
    isPublic: boolean,
    invitedPlayerIds: {UserId},
    gameId: GameId,
}

-- Everything you need to know about a game.
-- Available on both client and server.
export type GameDetails = {
    gameId: GameId,
    gameImage: AssetId,
    name: string,
    description: string,
    maxPlayers: number,
    minPlayers: number,
}

export type GameDetailsByGameId = {
    [GameId]: GameDetails,
}

-- Meta-level functions to start, stop, exit a game instance.
-- Defined by client of this library.
-- Available on server only.
export type GameInstanceFunctions = {
    onPlay: () -> nil,
    onEnd: () -> nil,
    onPlayerLeft: (playerId: UserId) -> nil,
}

export type GameInstanceFunctionsByGameId = {
    [GameId]: GameInstanceFunctions,
}

-- How to configure a dialog.
export type DialogButtonConfig = {
    text: string,
    callback: () -> (),
}

export type DialogConfig = {
    title: string,
    description: string,
    buttons: {DialogButtonConfig},
}

export type GameTableState = number
export type GameTableStates = {
	WaitingForPlayers: GameTableState, 
	Playing: GameTableState, 
	Finished: GameTableState,
}

export type UIMode = number
export type UIModes = {
	None: UIMode, 
	TableSelection: UIMode, 
	TableWaiting: UIMode,
    TablePlaying: UIMode,
}

export type GameUI = {

}

export type GameUIs = {
    [GameId]: GameUI,
}

return nil
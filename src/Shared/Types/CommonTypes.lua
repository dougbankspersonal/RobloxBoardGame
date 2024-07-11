-- Common types

-- Some enumerated types.
export type GameTableState = number
export type GameTableStates = {
    WaitingForPlayers: GameTableState,
    Playing: GameTableState,
    Finished: GameTableState,
}

export type UIMode = number
export type UIModes = {
    Loading: UIMode,
    TableSelection: UIMode,
    TableWaiting: UIMode,
    TablePlaying: UIMode,
    None: UIMode,
}

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

-- Everything a client needs to know about a created table so it can be
-- properly rendered/described.
export type TableDescription = {
    tableId: TableId,
    hostPlayerId: UserId,
    isPublic: boolean,
    -- Maps from user Id to true.  Basically a set.
    -- For all the functions we are dealing with when checking/modifying, set works better than array.
    -- Only drawback in on server when we render, we may wind up with inconsistent ordering.
    -- Solution: sort by player name.
    memberPlayerIds: {
        [UserId]: boolean,
    },
    invitedPlayerIds: {
        [UserId]: boolean,
    },
    gameId: GameId,
    gameTableState: GameTableState,
}

-- We tend to keep these in a table indexed on tableId so it's easy
-- to find/remove.
export type TableDescriptionsByTableId = {
    [TableId]: TableDescription,
}

--[[
Descriptors for games.

General idea:
RobloxBoardGame library allows you to create an experience with multiple board games (imagine a "board game library")
Players create a table to play games, and in creating a table they select one of the games from the library: they are
hosting this game at this table.

So to use RBB library, an experience needs to pass in some data/functions descrbing the library.

Instead of one monolithic table for each game, we've split it into multiple blocks:

GameDetails:
    Metadata about the game (name, images, description, min/max players, etc).
    Available on both client and server.
GameInstanceFunctions:
    Functions used to start, stop, remove players from the game.
    Available only on server.
GameUIs
    Functions to build/destroy the UI for the game.
    Available only on Client.

These are all keyed by GameId, so you can look up the data for a game by its id.

When using the library, you need to provide these three blocks of data for each game you want to support.
The blocks of data go in XXXbyGameId tables, where the key is the GameId.
]]

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

export type GameInstanceFunctions = {
    onPlay: () -> nil,
    onEnd: () -> nil,
    onPlayerLeft: (playerId: UserId) -> nil,
}

export type GameInstanceFunctionsByGameId = {
    [GameId]: GameInstanceFunctions,
}

export type GameUIs = {
    setupUI: () -> nil,
}

export type GameUIsByGameId = {
    [GameId]: GameUIs,
}

local CommonTypes = {
}

return CommonTypes
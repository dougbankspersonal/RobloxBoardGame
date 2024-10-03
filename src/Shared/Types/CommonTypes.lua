-- Common types

-- Some enumerated types.
export type GameTableState = number
export type GameTableStates = {
    WaitingForPlayers: GameTableState,
    Playing: GameTableState,
}

export type UIMode = number
export type UIModes = {
    Loading: UIMode,
    TableSelection: UIMode,
    TableWaitingForPlayers: UIMode,
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

-- Each  game *instance* has a globally unique id.
export type GameInstanceGUID = string

-- Standard Roblox user id.
export type UserId = number

-- Standard Roblox asset
export type AssetId = number

export type GameOptionId = string

export type BooleanOrNumber = boolean | number

export type NonDefaultGameOptions = {
    [GameOptionId]: BooleanOrNumber,
}

-- Everything a client needs to know about a created table so it can be
-- properly rendered/described.
export type TableDescription = {
    tableId: TableId,
    hostUserId: UserId,
    isPublic: boolean,
    gameId: GameId,
    -- Game is waiting, playing, etc.  An enum.
    gameTableState: GameTableState,

    -- Any game-specific tweaks that have been set.
    opt_nonDefaultGameOptions: NonDefaultGameOptions?,

    -- Iff the gameTableState is Playing, there should be non-nil gameInstanceGUID in there.
    gameInstanceGUID: GameInstanceGUID?,

    -- Maps from user Id to true.  Basically a set.
    -- For all the functions we are dealing with when checking/modifying, set works better than array.
    -- Note: the host is in this set.
    -- Note: everyone at the table is a "member".  Anyone who is not the host is also a "guest".
    memberUserIds: {
        [UserId]: boolean,
    },
    invitedUserIds: {
        [UserId]: boolean,
    },
    -- These are "mock" players, not real people.
    mockUserIds: {
        [UserId]: boolean,
    },
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
ServerGameInstanceConstructors:
    For each game, a function to create a server-side game instance.
ClientGameInstanceFunctions:
    For each game, a function to create a client-side game instance.

These are all keyed by GameId, so you can look up the data for a game by its id.

When using the library, you need to provide these three blocks of data for each game you want to support.
The blocks of data go in XXXbyGameId tables, where the key is the GameId.
]]
export type GameOptionVariant = {
    name: string,
    description: string,
}

export type GameOption = {
    name: string,
    gameOptionId: GameOptionId,
    details: string,
    opt_variants: {GameOptionVariant}?
}

export type GameDetails = {
    gameId: GameId,
    gameImage: string,
    name: string,
    description: string,
    maxPlayers: number,
    minPlayers: number,
    -- Games may be configurable:
    --   * use these rules variants.
    --   * use these expansions.
    -- Host should be able to set these, and guests should be able to see the selections.
    -- In reality, there may be dependencies between these, e.g. you can only
    -- use expansion B if you are also using A, or you can't use rules variant A with
    -- expansion C.
    -- We don't model that here: we just provide a list of configs, present that to
    -- the user as a set of checkboxes, and pass the selections on to the game.
    -- It is up to the game to make sense of any conficting/confusing/nonsensical selections
    -- and message the user about it.
    gameOptions: {GameOption}?,
}

export type GameDetailsByGameId = {
    [GameId]: GameDetails,
}

-- Details on why game ended.
-- Some are generic, some are game-specific.
export type GameEndDetails = {
    -- Game ended because it was at a table that got destroyed.
    tableDestroyed: boolean?,
    -- Host clicked a button to end the game.
    -- * Maybe game is over, there's a winner.
    -- * Maybe host just decided to kill the game mid-stride.
    -- * Maybe it's a casual game where you just play until you're bored.
    -- Specifying which of these cases is more up to the specific game instance.
    -- Thi is just high-level, universal "host deliberately ended the game".
    hostEndedGame: boolean?,
    -- Game specific details.  Up to the game to decide what if anything to put here.
    gameSpecificDetails: any?
}

export type ServerGameInstance = {
    tableDescription: TableDescription,

    -- Assert all is well.
    sanityCheck: (ServerGameInstance) -> nil,

    -- There is no "start play" function: creatinng the instance starts the game.
    -- The game is done, destroy it.
    destroy: (ServerGameInstance) -> nil,
    -- System notification when a player leaves.
    playerLeftGame: (ServerGameInstance, userId: UserId) -> nil,
    -- For some reason we have decided the end the game.
    -- Add any game-specific info we might want about how/why the game ended, state at end of game, etc.
    getGameSpecificGameEndDetails: (ServerGameInstance) -> any?,
}

export type ServerGameInstanceConstructor = (TableDescription) -> ServerGameInstance

export type ServerGameInstanceConstructorsByGameId = {
    [GameId]: ServerGameInstanceConstructor,
}

-- Any client game instance has to implement these functions/have these members.
export type ClientGameInstance = {
    tableDescription: TableDescription,

    -- Assert all is well.
    sanityCheck: (ClientGameInstance) -> nil,

    -- The game is over.  Destroy the game instance (self), do any instance-specific cleanup.
    -- Note you do NOT need to worry about the following:
    --   * Connections to remote events.  If you used ClientEventUtils.connectToGameEvent to connect to the event, it
    --     will be disconnected automatically.
    --   * Any GUI elements under the game instance's main frame (passed in through makeClientGameInstance): those are
    --     automatically destroyed.
    destroy: (ClientGameInstance) -> nil,

    -- Your game is being notified that a player has bounced.
    -- You may want to add game-specific logic for this:
    --   * Cleaning up UI elements referring to the player.
    --   * Some custom notifications to the player, so and so is gone.
    --   * A custom notification to the host: player is gone, what do you want to do now? (Some games
    --     cannot really continue once a player leaves).
    --
    -- If you return true, nothing further will happen.
    -- If you return false, a boilerplate "so and so has left" message will be displayed with no further actions.
    --
    -- Note that this is all CLIENT ONLY.  There's a server-side equivalent where you update game state, handle host-specific
    -- choices about what to do next, etc.
    onPlayerLeftTable: (ClientGameInstance, userId: UserId) -> boolean,

    -- The game has been ended by the host.
    -- Do we want to message the local user about this somehow?
    -- All the info about why game ended is in GameEndDetails.
    -- If the instance has something intelligent to say about details, it messages the user and returns true.
    -- Otherwise return false, and some system-level notificaiton might show up.
    notifyThatHostEndedGame: (ClientGameInstance, GameEndDetails) -> boolean,
}

export type ClientGameInstanceFunctions = {
    makeClientGameInstance: (TableDescription, Frame) -> ClientGameInstance,
    getClientGameInstance: () -> ClientGameInstance?,
}

export type ClientGameInstanceFunctionsByGameId = {
    [GameId]: ClientGameInstanceFunctions,
}


local CommonTypes = {
}

return CommonTypes
--[[
Enumerated type for UIModes.
The game is always in one of these states.
  * None: game just started, nothing is rendering.
  * Loading: we are waiting to download data about tables.  User can't do anything until they load.
  * TableSelection: local user is not part of any table.  UI to create or join a table.
  * TableWaitingForPlayers: local user is part of a table that is waiting for players to join.  UI to
    view table data, manage table and start game (host only), or leave table (guest only).
  * TablePlaying: local user is part of a table that is playing a game.  Most of the UI is custom to the
    game, but there's outer chrome with controls to end the game or remove players (host only) or to
    leave the table (guest only).
  ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local UIModes: CommonTypes.UIModes = {
    Loading = 0,
    TableSelection = 1,
    TableWaitingForPlayers = 2,
    TablePlaying = 3,
    None = 5,
} :: CommonTypes.UIModes

return UIModes
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local UIModes: {string: CommonTypes.UIMode} = {    
    None = "None",
    TableSelection = "TableSelection",
    TableWaiting = "TableWaiting",
    TablePlaying = "TablePlaying",
} :: {string: CommonTypes.UIMode}


local UIModes = {}

UIModes.GameTableStates = {
	WaitingForPlayers = 0,
	Playing = 1,
	Finished = 2
} :: GameTableStates

return UIModes
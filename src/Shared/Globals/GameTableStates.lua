local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameTableStates: CommonTypes.GameTableStates = {    
    WaitingForPlayers = 0,
    Playing = 1,
    Finished = 2,
} :: CommonTypes.GameTableStates

return GameTableStates
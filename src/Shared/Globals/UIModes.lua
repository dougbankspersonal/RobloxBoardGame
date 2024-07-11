local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local UIModes: CommonTypes.UIModes = {
    Loading = 0,
    TableSelection = 1,
    TableWaiting = 2,
    TablePlaying = 3,
    None = 4,
} :: CommonTypes.UIModes

return UIModes
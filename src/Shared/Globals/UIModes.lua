local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local UIModes: {string: CommonTypes.UIMode} = {    
    None = "None",
    TableSelection = "TableSelection",
    TableWaiting = "TableWaiting",
    TablePlaying = "TablePlaying",
} :: {string: CommonTypes.UIMode}

return UIModes
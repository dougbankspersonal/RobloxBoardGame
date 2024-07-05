--[[
    GameDetails.lua
    This file contains the GameDetails module, which is responsible for storing and providing access to game details.
    Game details are stored in a table, and can be accessed by their gameId.

    For parties using the RobloxBoardGame library: server and all clients:
    * Declare a table of hard-coded game details (CommonTypes.GameDetails) describing 
      each board game in your Roblox experience.
    * This declaration should be in shared storage, available to both client and server.
    * Very early in both client and server lifespan, call GameDetails.setAllGameDetails, 
      passing in the table of game details.
    * Later, when you need to know about a game, call GameDetails.getGameDetails, passing in the gameId.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameDetails = {} 

local _allGameDetails = {} :: {CommonTypes.GameDetails}

GameDetails.setAllGameDetails = function(allGameDetails: {CommonTypes.GameDetails}): nil
    _allGameDetails = allGameDetails
end

GameDetails.getGameDetails = function(gameId: CommonTypes.GameId): CommonTypes.GameDetails?
    for _, gameDetails in ipairs(_allGameDetails) do
        if gameDetails.gameId == gameId then
            return gameDetails
        end
    end
    return nil
end

GameDetails.getAllGameDetails = function(): {CommonTypes.GameDetails}
    return _allGameDetails
end 

return GameDetails
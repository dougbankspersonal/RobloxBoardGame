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

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameDetails = {}

local gameDetailsByGameId = {} :: CommonTypes.GameDetailsByGameId

GameDetails.setAllGameDetails = function(_gameDetailsByGameId: CommonTypes.GameDetailsByGameId): nil
    gameDetailsByGameId = _gameDetailsByGameId
end

GameDetails.getGameDetails = function(gameId: CommonTypes.GameId): CommonTypes.GameDetails?
    if gameDetailsByGameId[gameId] then
        return gameDetailsByGameId[gameId]
    else
        return nil
    end
end

GameDetails.getAllGameDetails = function(): CommonTypes.GameDetailsByGameId
    return gameDetailsByGameId
end

GameDetails.getGameOptionById = function(gameDetails:CommonTypes.GameDetails, optionId: string): CommonTypes.GameOption?
    assert(gameDetails, "gameDetails must be provided")
    assert(optionId, "optionId must be provided")
    for _, option in gameDetails.gameOptions do
        if option.gameOptionId == optionId then
            return option
        end
    end
    return nil
end

return GameDetails
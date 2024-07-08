--[[
    GameInstanceFunctions.lua
    This file contains the GameInstanceFunctions module, which is responsible for storing and providing access to 
    externally configured game instance functions.
    This is a server-side concept.
    GameInstanceFunctions are stored in a table, and can be accessed by their gameId.

    For parties using the RobloxBoardGame library: server only:
    * Declare a table of hard-coded game instance functions (CommonTypes.GameInstanceFunctions) describing 
      each the basic entry/exit functions for each board game in your experience.
    * This declaration should be in server storage.
    * Very early in \server lifespan, call GameInstanceFunctions.setAllGameInstanceFunctions, 
      passing in the table of GameInstanceFunctions.
    * Later, when you need to know about a game's functions, call GameInstanceFunctions.getGameInstanceFunctions,
      passing in the gameId.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameInstanceFunctions = {}

local gameInstanceFunctionsByGameId = {} :: CommonTypes.GameInstanceFunctionsByGameId

GameInstanceFunctions.setAllGameInstanceFunctions = function(_gameInstanceFunctionsByGameId: CommonTypes.GameInstanceFunctionsByGameId): nil
  gameInstanceFunctionsByGameId = _gameInstanceFunctionsByGameId
end

GameInstanceFunctions.getGameInstanceFunctions = function(gameId: CommonTypes.GameId): CommonTypes.GameInstanceFunctions?
    for gId, gameInstanceFunctions in ipairs(gameInstanceFunctionsByGameId) do
        if gId == gameId then
            return gameInstanceFunctions
        end
    end
    return nil
end

return GameInstanceFunctions
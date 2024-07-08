--[[
    GameUIs.lua
    This file contains the GameUIs module, which is responsible for storing and providing access to 
    externally configured game ui functions.
    This is a client-side concept.
    GameUIs are stored in a table, and can be accessed by their gameId.

    For parties using the RobloxBoardGame library: client only:
    * Declare a table of hard-coded GameUIs (CommonTypes.GameUIs) describing 
      the "build the gui" logic for the game.
    * This declaration should be in client storage.
    * Very early in client lifespan, call GameUIs.setAllGameUIs, 
      passing in the table of GameUIs.
    * Later, when you need to know about a game's UI, call GameUIs.getGameUIs,
      passing in the gameId.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameUIs = {}

local allGameUIs = {} :: CommonTypes.GameUIs

GameUIs.setAllGameUIs = function(_allGameUIs: CommonTypes.GameUIs): nil
    allGameUIs = _allGameUIs
end

GameUIs.getGameUI = function(gameId: CommonTypes.GameId): CommonTypes.GameUI?
    for gId, gameUI in ipairs(allGameUIs) do
        if gId == gameId then
            return gameUI
        end
    end
    return nil
end

return GameUIs
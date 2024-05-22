-- Configured with game details by client of this library.
local CommonTypes = require(script.Parent.Parent.Types.CommonTypes)

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
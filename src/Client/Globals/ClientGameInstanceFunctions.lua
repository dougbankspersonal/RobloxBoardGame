--[[
    ClientGameInstanceFunctions.lua
    Store and provide access to externally configured ctors for client-side game instances.
    This is a client-side concept.

    For parties using the RobloxBoardGame library: client only:
    * For each game, declare a ctor that creates a client-side instance to manage client side of game.
    * This declaration should be in client storage.
    * Very early in client lifespan, call ClientGameInstanceFunctions.setAllClientGameInstanceFunctions,
      passing in the table of ClientGameInstanceFunctionsByGameId.
    * Later, when it's time to get or make client=side game instance, we use these functions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local ClientGameInstanceFunctions = {}

local clientGameInstanceFunctionsByGameId = {} :: CommonTypes.ClientGameInstanceFunctionsByGameId

function ClientGameInstanceFunctions.setAllClientGameInstanceFunctions(_clientGameInstanceFunctionsByGameId: CommonTypes.ClientGameInstanceFunctionsByGameId): nil
    clientGameInstanceFunctionsByGameId = _clientGameInstanceFunctionsByGameId
end

function ClientGameInstanceFunctions.getClientGameInstanceFunctions(gameId: CommonTypes.GameId): CommonTypes.ClientGameInstanceFunctions?
  return clientGameInstanceFunctionsByGameId[gameId]
end

return ClientGameInstanceFunctions
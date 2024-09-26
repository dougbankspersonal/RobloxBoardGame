--[[
    ServerGameInstanceConstructors.lua
    This file contains the ServerGameInstanceConstructors module, which is responsible for storing and providing access to
    externally configured game instance constructors.
    This is a server-side concept.
    ServerGameInstanceConstructors are stored in a table, and can be accessed by their gameId.

    For parties using the RobloxBoardGame library:
    * On server, declare a table of game instance constructors: table maps gameId to a ctor making an
      instance of that game.
    * This declaration should be in server storage.
    * Very early in server lifespan, call ServerGameInstanceConstructors.setAllServerGameInstanceConstructors,
      passing in the table of ServerGameInstanceConstructorsByGameId.
    * Each ctor should make an instance which is able to handle the basic play, end, etc. lifespan.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local ServerGameInstanceConstructors = {}

local serverGameInstanceConstructorsByGameId = {} :: CommonTypes.ServerGameInstanceConstructorsByGameId

ServerGameInstanceConstructors.setAllServerGameInstanceConstructors = function(_serverGameInstanceConstructorsByGameId: CommonTypes.ServerGameInstanceConstructorsByGameId): nil
    serverGameInstanceConstructorsByGameId = _serverGameInstanceConstructorsByGameId
end

ServerGameInstanceConstructors.getServerGameInstanceConstructor = function(gameId: CommonTypes.GameId): CommonTypes.ServerGameInstanceConstructor?
  return serverGameInstanceConstructorsByGameId[gameId]
end

return ServerGameInstanceConstructors
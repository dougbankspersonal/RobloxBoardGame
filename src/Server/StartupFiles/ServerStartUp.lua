-- Main function to call when starting your board game.
-- Call from a Server script ASAP.
-- Creates events, listens for them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local GameInstanceFunctions = require(RobloxBoardGameServer.Globals.GameInstanceFunctions)
local ServerEventManagement = require(RobloxBoardGameServer.Modules.ServerEventManagement)

local ServerStartUp = {}

local function createRemoteEvents()
    ServerEventManagement.createClientToServerEvents()
    ServerEventManagement.createServerToClientEvents()
end

ServerStartUp.ServerStartUp = function(gameDetailsByGameId: CommonTypes.GameDetailsByGameId, gameInstanceFunctionsByGameId: CommonTypes.GameInstanceFunctionsByGameId): nil
    -- Sanity checks.
    assert(gameDetailsByGameId, "gameDetailsByGameId is nil")
    assert(gameInstanceFunctionsByGameId, "gameInstanceFunctionsByGameId is nil")
    print("Doug: gameDetailsByGameId = ", gameDetailsByGameId)
    print("Doug: gameInstanceFunctionsByGameId = ", gameInstanceFunctionsByGameId)
    assert(Utils.tablesHaveSameKeys(gameDetailsByGameId, gameInstanceFunctionsByGameId), "tables should have same keys")
    assert(#gameDetailsByGameId > 0, "Should have at least one game")

    GameDetails.setAllGameDetails(gameDetailsByGameId)
    GameInstanceFunctions.setAllGameInstanceFunctions(gameInstanceFunctionsByGameId)
    createRemoteEvents()
end

return ServerStartUp
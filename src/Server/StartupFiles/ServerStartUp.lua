-- Main function to call when starting your board game.
-- Call from a Server script ASAP.
-- Creates events, listens for them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cryo = require(ReplicatedStorage.Cryo)

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local EventUtils = require(RobloxBoardGameShared.Modules.EventUtils)
local SanityChecks = require(RobloxBoardGameShared.Modules.SanityChecks)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local ServerGameInstanceConstructors = require(RobloxBoardGameServer.Globals.ServerGameInstanceConstructors)
local ServerEventManagement = require(RobloxBoardGameServer.Modules.ServerEventManagement)
local ServerEventUtils = require(RobloxBoardGameServer.Modules.ServerEventUtils)
local DebugStateHandler = require(RobloxBoardGameServer.Modules.DebugStateHandler)
local ServerPlayerWatcher = require(RobloxBoardGameServer.Modules.ServerPlayerWatcher)

local ServerStartUp = {}

local function setUpRemoteEventsAndFunctions()
    local tableEventsFolder = ServerEventUtils.createFolder(EventUtils.FolderNameTableEvents)
    local tableFunctionsFolder = ServerEventUtils.createFolder(EventUtils.FolderNameTableFunctions)

    ServerEventManagement.setupRemoteCommunications(tableEventsFolder, tableFunctionsFolder)
end

local function sanityCheckServerGameInstanceConstructorsByGameId(serverGameInstanceConstructorsByGameId: CommonTypes.ServerGameInstanceConstructorsByGameId)
    assert(serverGameInstanceConstructorsByGameId ~= nil, "Should have non-nil serverGameInstanceConstructorsByGameId")
    assert(Cryo.Dictionary.keys(serverGameInstanceConstructorsByGameId) ~= nil, "Should have non-nil keys")
    assert(#Cryo.Dictionary.keys(serverGameInstanceConstructorsByGameId) > 0, "Should have at least one game")
    for gameId, serverGameInstanceConstructor in serverGameInstanceConstructorsByGameId do
        assert(typeof(gameId) == "number", "gameId should be a number")
        assert(typeof(serverGameInstanceConstructor) == "function", "serverGameInstanceConstructor should be a function")
    end
end

ServerStartUp.ServerStartUp = function(gameDetailsByGameId: CommonTypes.GameDetailsByGameId, serverGameInstanceConstructorsByGameId: CommonTypes.ServerGameInstanceConstructorsByGameId): nil
    -- Sanity checks.
    SanityChecks.sanityCheckGameDetailsByGameId(gameDetailsByGameId)
    sanityCheckServerGameInstanceConstructorsByGameId(serverGameInstanceConstructorsByGameId)

    assert(Utils.tablesHaveSameKeys(gameDetailsByGameId, serverGameInstanceConstructorsByGameId), "tables should have same keys")
    assert(Utils.tableSize(gameDetailsByGameId) > 0, "Should have at least one game")

    GameDetails.setAllGameDetails(gameDetailsByGameId)
    ServerGameInstanceConstructors.setAllServerGameInstanceConstructors(serverGameInstanceConstructorsByGameId)

    ServerPlayerWatcher.startWatchingPlayers()
    setUpRemoteEventsAndFunctions()

    if RunService:IsStudio() then
        DebugStateHandler.enterDebugState()
    end
end

return ServerStartUp
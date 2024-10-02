-- Main function to call when starting your board game.
-- Call from a Server script ASAP.
-- Creates events, listens for them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local EventUtils = require(RobloxBoardGameShared.Modules.EventUtils)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local ServerGameInstanceConstructors = require(RobloxBoardGameServer.Globals.ServerGameInstanceConstructors)
local ServerEventManagement = require(RobloxBoardGameServer.Modules.ServerEventManagement)
local GameTable = require(RobloxBoardGameServer.Classes.GameTable)
local ServerTypes = require(RobloxBoardGameServer.Types.ServerTypes)
local ServerEventUtils = require(RobloxBoardGameServer.Modules.ServerEventUtils)
local DebugStateHandler = require(RobloxBoardGameServer.Modules.DebugStateHandler)

local ServerStartUp = {}

local function createTableHandler(hostId: CommonTypes.UserId, gameId: CommonTypes.GameId, isPublic: boolean): ServerTypes.GameTable?
    local gameTable = GameTable.new(hostId, gameId, isPublic)
    return gameTable
end

local function setUpRemoteEventsAndFunctions()
    local tableEventsFolder = ServerEventUtils.createFolder(EventUtils.FolderNameTableEvents)
    local tableFunctionsFolder = ServerEventUtils.createFolder(EventUtils.FolderNameTableFunctions)

    ServerEventManagement.setupRemoteCommunications(tableEventsFolder, tableFunctionsFolder, createTableHandler)
end

ServerStartUp.ServerStartUp = function(gameDetailsByGameId: CommonTypes.GameDetailsByGameId, serverGameInstanceConstructorsByGameId: CommonTypes.ServerGameInstanceConstructorsByGameId): nil
    -- Sanity checks.
    assert(gameDetailsByGameId, "gameDetailsByGameId is nil")
    assert(serverGameInstanceConstructorsByGameId, "serverGameInstanceConstructorsByGameId is nil")
    assert(Utils.tablesHaveSameKeys(gameDetailsByGameId, serverGameInstanceConstructorsByGameId), "tables should have same keys")
    assert(Utils.tableSize(gameDetailsByGameId) > 0, "Should have at least one game")


    -- Sanity check on tables coming in from client of RobloxBoardGame library.
    Utils.sanityCheckGameDetailsByGameId(gameDetailsByGameId)
    Utils.sanityCheckServerGameInstanceConstructorsByGameId(serverGameInstanceConstructorsByGameId)

    GameDetails.setAllGameDetails(gameDetailsByGameId)
    ServerGameInstanceConstructors.setAllServerGameInstanceConstructors(serverGameInstanceConstructorsByGameId)
    setUpRemoteEventsAndFunctions()

    if RunService:IsStudio() then
        DebugStateHandler.enterDebugState()
    end
end

return ServerStartUp
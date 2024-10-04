local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cryo = require(ReplicatedStorage.Cryo)

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local GameTable = require(RobloxBoardGameServer.Classes.GameTable)
local ServerEventUtils = require(RobloxBoardGameServer.Modules.ServerEventUtils)

local DebugStateHandler = {}

DebugStateHandler.SettingNone = "None"
DebugStateHandler.SettingPublicGameLocalHost = "PublicGameLocalHost"
DebugStateHandler.SettingPublicGameMockHostLocalNotMember = "PublicGameMockHostLocalNotMember"
DebugStateHandler.SettingPublicGameMockHostLocalIsMember = "PublicGameMockHostLocalIsMember"

DebugStateHandler.Setting = DebugStateHandler.SettingPublicGameLocalHost

function DebugStateHandler.publicGameLocalHost()
    -- Make an instance of the first configured game.
    local gameDetailsByGameId = GameDetails.getAllGameDetails()
    local gameIds = Cryo.Dictionary.keys(gameDetailsByGameId)
    assert(#gameIds > 0, "Should have at least one game")
    local firstGameId = gameIds[1]

    -- Make a table for the game.
    local gameTable = GameTable.new(Utils.StudioUserId, firstGameId, true)
    -- Add some mock players.
    gameTable:joinTable(ServerEventUtils.generateMockUserId(), true)
    gameTable:joinTable(ServerEventUtils.generateMockUserId(), true)

    -- Start the game.
    gameTable:startGame(Utils.StudioUserId)
end

function DebugStateHandler.setupGame(configs: {[string]: boolean})
    -- Make an instance of the first configured game.
    local gameDetailsByGameId = GameDetails.getAllGameDetails()
    local gameIds = Cryo.Dictionary.keys(gameDetailsByGameId)
    assert(#gameIds > 0, "Should have at least one game")
    local firstGameId = gameIds[1]

    -- Make a table for the game.
    -- Host is local or mock?
    local hostUserId
    if configs.mockHost then
        hostUserId = ServerEventUtils.generateMockUserId()
    else
        hostUserId = Utils.StudioUserId
    end

    local isPublic = configs.isPublic or false
    local gameTable = GameTable.new(hostUserId, firstGameId, isPublic)

    if configs.mockHost then
        gameTable.tableDescription.mockUserIds[hostUserId] = true
    end

    -- Add some mock players.
    local mockPlayerCount = 2
    for _ = 1, mockPlayerCount do
        local mockUserId = ServerEventUtils.generateMockUserId()
        if not isPublic then
            gameTable:inviteToTable(hostUserId, mockUserId, true)
        end
        gameTable:joinTable(mockUserId, true)
    end

    -- Maybe add local player as non-host.
    if configs.mockHost then
        if configs.localIsMember then
            if not isPublic then
                gameTable:inviteToTable(hostUserId, Utils.StudioUserId)
            end
            gameTable:joinTable(Utils.StudioUserId)
        end
    end

    -- Start the game.
    gameTable:startGame(hostUserId)
end

-- Shortcut to jump into a game right away.
function DebugStateHandler.enterDebugState()
    assert(RunService:IsStudio(), "Should be in studio")

    if DebugStateHandler.Setting == DebugStateHandler.SettingNone then
        return
    end

    if DebugStateHandler.Setting == DebugStateHandler.SettingPublicGameLocalHost then
        DebugStateHandler.setupGame({
            isPublic = true,
        })
    elseif DebugStateHandler.Setting == DebugStateHandler.SettingPublicGameMockHostLocalNotMember then
        DebugStateHandler.setupGame({
            isPublic = true,
            mockHost = true,
        })
    elseif DebugStateHandler.Setting == DebugStateHandler.SettingPublicGameMockHostLocalIsMember then
        DebugStateHandler.setupGame({
            isPublic = true,
            mockHost = true,
            localIsMember = true,
        })
    end
end

return DebugStateHandler
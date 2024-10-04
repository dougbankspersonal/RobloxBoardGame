--[[
Debug tools to quickly jump into some state:
 * A table is created and ready to join.
 * A table is created and joined.
 * A table is created and the game is playing.
 ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local CommonTypes= require(RobloxBoardGameShared.Types.CommonTypes)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local GameTable = require(RobloxBoardGameServer.Classes.GameTable)
local ServerEventUtils = require(RobloxBoardGameServer.Modules.ServerEventUtils)
local ServerTypes = require(RobloxBoardGameServer.Types.ServerTypes)

local DebugStateHandler = {}

DebugStateHandler.SettingNone = "None"
DebugStateHandler.SettingPublicGameLocalHost = "PublicGameLocalHost"
DebugStateHandler.SettingPublicGameMockHostLocalNotMember = "PublicGameMockHostLocalNotMember"
DebugStateHandler.SettingPublicGameMockHostLocalIsMember = "PublicGameMockHostLocalIsMember"

DebugStateHandler.Setting = DebugStateHandler.SettingPublicGameLocalHost

-- Shortcut to jump into a game right away.
function DebugStateHandler.enterDebugState(realPlayerUserId: CommonTypes.UserId, opt_configs: CommonTypes.DebugStateConfigs?): ServerTypes.GameTable?
    assert(RunService:IsStudio(), "Should be in studio")

    if not opt_configs then
        return nil
    end

    local configs = opt_configs

    -- at the very least we need a valid game id.
    assert(configs.gameId, "Should have a game id")
    local gameDetails = GameDetails.getGameDetails(configs.gameId)
    assert(gameDetails, "Should have game details")

    -- Make a table
    -- Host is 'real player' or mock?
    local hostUserId
    if configs.mockHost then
        hostUserId = ServerEventUtils.generateMockUserId()
    else
        hostUserId = realPlayerUserId
    end

    local isPublic = configs.isPublic or false
    local gameTable = GameTable.new(hostUserId, configs.gameId, isPublic)
    assert(gameTable.tableDescription.mockUserIds, "Should have mockUserIds")
    if configs.mockHost then
        gameTable.tableDescription.mockUserIds[hostUserId] = true
    end

    -- Add players.
    -- If configured with a number, use that.
    -- If, but game is playing, use min players for game.
    -- Else use 0.
    local playerCount = configs.playerCount or 0
    if playerCount == 0 and configs.startGame then
        playerCount = gameDetails.minPlayers
    end

    for _ = 1, playerCount do
        local mockUserId = ServerEventUtils.generateMockUserId()
        if not isPublic then
            gameTable:inviteToTable(hostUserId, mockUserId, true)
        end
        gameTable:joinTable(mockUserId, true)
    end

    -- If we are set to use a mock host and we want to 'real user' to join, make that
    -- happen.
    if configs.mockHost then
        if configs.localIsMember then
            if not isPublic then
                gameTable:inviteToTable(hostUserId, realPlayerUserId)
            end
            gameTable:joinTable(realPlayerUserId)
        end
    end

    if configs.startGame then
        gameTable:startGame(hostUserId)
    end

    return gameTable
end

return DebugStateHandler
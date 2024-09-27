local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
DebugStateHandler.SettingJumpIntoGame = "JumpIntoGame"

DebugStateHandler.Setting = DebugStateHandler.None


function DebugStateHandler.jumpIntoGame()
    -- Make an instance of the first configured game.
    local gameDetailsByGameId = GameDetails.getAllGameDetails()
    local gameIds = Cryo.Dictionary.keys(gameDetailsByGameId)
    assert(#gameIds > 0, "Should have at least one game")
    local firstGameId = gameIds[1]

    -- Make a table for the game.
    local gameTable = GameTable.new(Utils.SnackFortUserId, firstGameId, true)
    -- Add some mock players.
    gameTable:joinTable(ServerEventUtils.generateMockUserId(), true)
    gameTable:joinTable(ServerEventUtils.generateMockUserId(), true)

    -- Start the game.
    gameTable:startGame(Utils.SnackFortUserId)
end

-- Shortcut to jump into a game right away.
function DebugStateHandler.enterDebugState()
    if DebugStateHandler.Setting == DebugStateHandler.SettingNone then
        return
    end

    if DebugStateHandler.Setting == DebugStateHandler.SettingJumpIntoGame then
        DebugStateHandler.jumpIntoGame()
    end
end

return DebugStateHandler
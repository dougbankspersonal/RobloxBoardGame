--[[
    Server-concept only.
    Class for a game instance.  Kind of a generic wrapper: client of this library
    will pass in functions to call on startup and teardown of game.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local GameInstanceFunctions = require(RobloxBoardGameServer.Globals.GameInstanceFunctions)

local GameInstance = {}

GameInstance.__index = GameInstance

export type GameInstance = {
    tableId: CommonTypes.TableId,
    gameId: CommonTypes.GameId,

    new: (tableId: CommonTypes.TableId, gameId: CommonTypes.GameId) -> GameInstance,

    playGame: (self:GameInstance) -> nil,
    endGame: (self:GameInstance) -> nil,
    playerLeft: (self:GameInstance, userId: CommonTypes.UserId) -> nil,
    destroy: (self:GameInstance) -> nil,
}

GameInstance.new = function (tableId: CommonTypes.TableId, gameId: CommonTypes.GameId): GameInstance
    local self = {}
    setmetatable(self, GameInstance)

    self.tableId = tableId
    self.gameId = gameId

    Utils.debugPrint("GameInstance", "Doug: GameInstance.new: gameId = ", self.gameId)

    return self
end

function GameInstance:playGame()
    local gameInstanceFunctions = GameInstanceFunctions.getGameInstanceFunctions(self.gameId)
    Utils.debugPrint("GameInstance", "Doug: playGame: gameId = ", self.gameId)
    Utils.debugPrint("GameInstance", "Doug: playGame: gameId = ", self.gameInstanceFunctions)
    assert(gameInstanceFunctions, "playGame: GameInstanceFunctions not found for gameId: " .. self.gameId)
    assert(gameInstanceFunctions.onPlay, "onPlay is required")
    return gameInstanceFunctions.onPlay()
end

function GameInstance:endGame()
    Utils.debugPrint("GameInstance", "Doug: self.gameId = ", self.gameId)

    local gameInstanceFunctions = GameInstanceFunctions.getGameInstanceFunctions(self.gameId)
    Utils.debugPrint("GameInstance", "Doug: endGame: gameId = ", self.gameId)
    Utils.debugPrint("GameInstance", "Doug: endGame: gameInstanceFunctions = ", gameInstanceFunctions)
    assert(gameInstanceFunctions, "endGame: GameInstanceFunctions not found for gameId: " .. self.gameId)
    assert(gameInstanceFunctions.onEnd, "onEnd is required")
    return gameInstanceFunctions.onEnd()
end

function GameInstance:playerLeft(userId: CommonTypes.UserId)
    local gameInstanceFunctions = GameInstanceFunctions.getGameInstanceFunctions(self.gameId)
    assert(gameInstanceFunctions, "playerLeft: GameInstanceFunctions not found for gameId: " .. self.gameId)
    assert(gameInstanceFunctions.onPlayerLeft, "onPlayerLeft is required")
    return gameInstanceFunctions.onPlayerLeft(userId)
end

function GameInstance:destroy()
    -- Any cleanup work?
end

return GameInstance
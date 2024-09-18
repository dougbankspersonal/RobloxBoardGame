--[[
    Server-concept only.
    Class for a game instance.  Kind of a generic wrapper: client of this library
    will pass in functions to call on startup and teardown of game.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local GameInstanceFunctions = require(RobloxBoardGameServer.Globals.GameInstanceFunctions)
local ServerTypes = require(RobloxBoardGameServer.Types.ServerTypes)
local GameInstance = {}

GameInstance.__index = GameInstance

GameInstance.new = function (gameId: CommonTypes.GameId, tableDescription: CommonTypes.TableDescription): ServerTypes.GameInstance
    local self = {}
    setmetatable(self, GameInstance)

    self.gameId = gameId
    self.tableDescription = tableDescription

    self.gameInstanceGUID = HttpService:GenerateGUID(false)

    Utils.debugPrint("GameInstance", "Doug: GameInstance.new: gameId = ", self.gameId)

    return self
end

function GameInstance:playGame()
    local gameInstanceFunctions = GameInstanceFunctions.getGameInstanceFunctions(self.gameId)
    Utils.debugPrint("GameInstance", "Doug: playGame: gameId = ", self.gameId)
    Utils.debugPrint("GameInstance", "Doug: playGame: gameId = ", self.gameInstanceFunctions)
    assert(gameInstanceFunctions, "playGame: GameInstanceFunctions not found for gameId: " .. self.gameId)
    assert(gameInstanceFunctions.onPlay, "onPlay is required")
    return gameInstanceFunctions.onPlay(self.gameInstanceGUID, self.tableDescription)
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
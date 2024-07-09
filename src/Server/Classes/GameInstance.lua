--[[
    Server-concept only.
    Class for a game instance.  Kind of a generic wrapper: client of this library 
    will pass in functions to call on startup and teardown of game.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local RobloxBoardGameServer = script.Parent.Parent

local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
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

function GameInstance.new(tableId: CommonTypes.TableId, gameId: CommonTypes.GameId): GameInstance
    local self = {}
    setmetatable(self, GameInstance)
    
    self.tableId = tableId
    self.gameId = gameId

    return self
end

function GameInstance:playGame()
    local gameInstanceFunctions = GameInstanceFunctions.getGameInstanceFunctions(self.gameId)
    assert(gameInstanceFunctions, "GameInstanceFunctions not found for gameId: " .. self.gameId)
    assert(gameInstanceFunctions.onPlay, "onPlay is required")
    return gameInstanceFunctions.onPlay()
end

function GameInstance:endGame()
    local gameInstanceFunctions = GameInstanceFunctions.getGameInstanceFunctions(self.gameId)
    assert(gameInstanceFunctions, "GameInstanceFunctions not found for gameId: " .. self.gameId)
    assert(gameInstanceFunctions.onEnd, "onEnd is required")
    return gameInstanceFunctions.onEnd()
end

function GameInstance:playerLeft(userId: CommonTypes.UserId)
    local gameInstanceFunctions = GameInstanceFunctions.getGameInstanceFunctions(self.gameId)
    assert(gameInstanceFunctions, "GameInstanceFunctions not found for gameId: " .. self.gameId)
    assert(gameInstanceFunctions.onPlayerLeft, "onPlayerLeft is required")
    return gameInstanceFunctions.onPlayerLeft(userId)
end

function GameInstance:destroy()
    -- Any cleanup work?
end

return GameInstance
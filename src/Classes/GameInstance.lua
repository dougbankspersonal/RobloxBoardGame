--[[
    Server-concept only.
    Class for a game instance.  Kind of a generic wrapper: client of this library 
    will pass in functions to call on startup and teardown of game.
]]

local CommonTypes = require(script.Parent.Parent.Types.CommonTypes)

local GameInstance = {}

GameInstance.__index = GameInstance

export type GameInstance = {
    tableId: CommonTypes.TableId,
	gameId: CommonTypes.GameId,
    onPlay: () -> nil,
    onEnd: () -> nil,
    onPlayerLeft: (playerId: CommonTypes.UserId) -> nil,

	new: (tableId: CommonTypes.TableId, gameId: CommonTypes.GameId) -> GameInstance,

	playGame: (self:GameInstance) -> nil,
	endGame: (self:GameInstance) -> nil,
    playerLeft: (self:GameInstance, playerId: CommonTypes.UserId) -> nil,
	destroy: (self:GameInstance) -> nil,
}

function GameInstance.new(tableId: CommonTypes.TableId, gameId: CommonTypes.GameId): GameInstance
	local gameInstance = {}
	setmetatable(gameInstance, GameInstance)
	
	gameInstance.tableId = tableId
    gameInstance.gameId = gameId

    local gameDetails = 
    
    assert(onPlay, "onPlay is required")
    assert(onEnd, "onPlay is required")
    assert(onPlayerLeft, "onPlay is required")
    gameInstance.onPlay = onPlay
    gameInstance.onEnd = onEnd
    gameInstance.onPlayerLeft = onPlayerLeft

	return gameInstance
end

function GameInstance:playGame()
	return self.onPlay()
end

function GameInstance:endGame()
	return self.onEnd()
end

function GameInstance:playerLeft(playerId: CommonTypes.UserId)
    return self.onPlayerLeft(playerId)
end

function GameInstance:destroy()
    -- Any cleanup work?
end

return GameInstance
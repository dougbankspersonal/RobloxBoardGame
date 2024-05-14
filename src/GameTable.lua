local GameTable = {}
local gameTables = {}

GameTable.__index = GameTable

local nextGameTableId = 0

GameTable.GameTableStates = {
	WaitingForPlayers = 0,
	Playing = 1,
	Finished = 2
}


function GameTable.new(hostPlayerId, gameDetails, public)
	local gameTable = {}
	setmetatable(gameTable, GameTable)
	
	gameTable.id = nextGameTableId
	nextGameTableId = nextGameTableId + 1

	gameTable.hostPlayerId = hostPlayerId
	gameTable.gameTableState = GameTable.GameTableStates.WaitingForPlayers
	gameTable.members = {
		[hostPlayerId] = true,
	}
	gameTable.invited = {}
	gameTable.gameDetails = gameDetails
	gameTable.gameInstance = nil
	gameTable.public = public

	gameTables[GameTable.id] = gameTable

	return gameTable
end

function GameTable.getGameTable(tableId): GameTable
	return gameTables[tableId]
end

-- Return the table iff the table can be created.
function GameTable.createNewTable(hostPlayerId, public): GameTable
	-- You cannot create a new table while you are joined to a table.
	for _, gameTable in pairs(gameTables) do
		if gameTable.members[hostPlayerId] then
			return nil
		end
	end

	local newGameTable = GameTable.new(hostPlayerId, public)
	return newGameTable
end

function GameTable:destroy(playerId): boolean
	-- Not host, no.
	if self.hostPlayerId ~= playerId then
		return false
	end

	-- Kill any ongoing game.
	if self.gameInstance then 
		self.gameInstance:destroy()
		self.gameInstance = nil
	end

	gameTables[self.id] = nil
	
	return true
end

function GameTable:join(playerId): boolean
	-- Game already started, no.
	if self.gameTableState ~= GameTable.GameTableStates.WaitingForPlayers then
		return false
	end

	-- Already a member, no.
	if self.members[playerId] then
		return false
	end

	-- not public, not invited: no.
	if not self.public and not self.invited[playerId] then
		return false
	end

	-- too many players already, no.
	if self.gameDetails.maxPlayers == #self.members then
		return false
	end


	self.members[playerId] = true
	return true
end
	
-- True iff player can be invited to table.
function GameTable:invite(playerId, inviteeId): boolean
	-- Game already started, no.
	if self.gameTableState ~= GameTable.GameTableStates.WaitingForPlayers then
		return false
	end

	-- Already a member, no.
	if self.members[playerId] then
		return false
	end

	-- Already invited, no.
	if self.invited[inviteeId] then
		return false
	end

	self.invited[inviteeId] = true
	return true
end

function GameTable:leave(playerId): boolean
	-- Not a member, no.
	if not self.members[playerId] then
		return false
	end

	self.members[playerId] = nil

	-- Let the game deal with any fallout from the player leaving.
	if self.gameInstance then
		self.gameInstance:playerLeft(playerId)
	end

	return true
end

function GameTable:startGame(playerId): boolean
	-- Not the host, no.
	if self.hostPlayerId ~= playerId then
		return false
	end

	-- Game already started, no.
	if self.gameTableState == GameTable.GameTableStates.Playing then
		return false
	end

	-- Right number of players?
	local numPlayers = #gameTable.members
	if numPlayers < self.gameDetails.minPlayers then 
		return false
	end
	if numPlayers > self.gameDetails.maxPlayers then 
		return false
	end

	assert(self.gameInstance == nil)
	self.gameTableState = GameTable.GameTableStates.Playing
	self.gameInstance = self.gameDetails.makeGameInstance(gameTable)

	return true
end

function GameTable:endGame(playerId, tableId): boolean
	-- Not the host, no.
	if self.hostPlayerId ~= playerId then
		return false
	end

	-- Game isn't playing, no.
	if self.gameTableState ~= GameTable.GameTableStates.Playing then
		return false
	end

	self.gameTableState = GameTable.GameTableStates.Finished
	self.gameInstance:endGame()
	self.gameInstance = nil

	return true
end

return GameTable
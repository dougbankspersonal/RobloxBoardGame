--[[
    Server-concept only.
    Class for a game table.
]]


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared

local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

local RobloxBoardGameServer = script.Parent.Parent
local GameInstance = require(RobloxBoardGameServer.Classes.GameInstance)

local GameTable = {}
local gameTables = {}

GameTable.__index = GameTable

local nextGameTableId: CommonTypes.TableId = 0

export type GameTable = {
    gameTableState: CommonTypes.GameTableState,
    gameDetails: CommonTypes.GameDetails,
    gameInstance: GameInstance.GameInstance?,

    tableDescription: CommonTypes.TableDescription,

    GameTableStates: {string: CommonTypes.GameTableState},

    new: (hostUserId: CommonTypes.UserId, gameDetails: CommonTypes.GameDetails, public: boolean) -> GameTable,
    getGameTable: (tableId: CommonTypes.TableId) -> GameTable,
    createNewTable: (hostUserId: CommonTypes.UserId, public: boolean) -> GameTable,
    destroy: (self: GameTable, userId: CommonTypes.UserId) -> boolean,

    join: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    invite: (self: GameTable, userId: CommonTypes.UserId, inviteeId: CommonTypes.UserId) -> boolean,
    leave: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    startGame: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
    endGame: (self: GameTable, userId: CommonTypes.UserId) -> boolean,
}

GameTable.GameTableStates = {
    WaitingForPlayers = 0,
    Playing = 1,
    Finished = 2
} :: {string: CommonTypes.GameTableState}

function GameTable.new(hostUserId: CommonTypes.UserId, gameId: CommonTypes.GameId, public: boolean): GameTable
    local self = {}
    setmetatable(self, GameTable)
    
    self.tableDescription.tableId = nextGameTableId
    nextGameTableId = nextGameTableId + 1

    self.tableDescription.hostUserId = hostUserId
    self.tableDescription.gameTableState = GameTable.GameTableStates.WaitingForPlayers
    self.tableDescription.members = {
        [hostUserId] = true,
    }
    self.invited = {}
    self.gameDetails = GameDetails.getGameDetails(gameId)
    self.gameInstance = nil
    self.public = public

    gameTables[GameTable.id] = self

    return self
end

function GameTable.getGameTable(tableId): GameTable
    return gameTables[tableId]
end

-- Return the table iff the table can be created.
function GameTable.createNewTable(hostUserId: CommonTypes.UserId, public): GameTable
    -- You cannot create a new table while you are joined to a table.
    for _, gameTable in pairs(gameTables) do
        if gameTable.members[hostUserId] then
            return nil
        end
    end

    local newGameTable = GameTable.new(hostUserId, public)
    return newGameTable
end

function GameTable:destroy(userId): boolean
    -- Not host, no.
    if self.hostUserId ~= userId then
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

function GameTable:join(userId): boolean
    -- Game already started, no.
    if self.gameTableState ~= GameTable.GameTableStates.WaitingForPlayers then
        return false
    end

    -- Already a member, no.
    if self.members[userId] then
        return false
    end

    -- not public, not invited: no.
    if not self.public and not self.invited[userId] then
        return false
    end

    -- too many players already, no.
    if self.gameDetails.MaxPlayers == #self.members then
        return false
    end


    self.members[userId] = true
    return true
end
    
-- True iff player can be invited to table.
function GameTable:invite(userId, inviteeId): boolean
    -- Game already started, no.
    if self.gameTableState ~= GameTable.GameTableStates.WaitingForPlayers then
        return false
    end

    -- Already a member, no.
    if self.members[userId] then
        return false
    end

    -- Already invited, no.
    if self.invited[inviteeId] then
        return false
    end

    self.invited[inviteeId] = true
    return true
end

function GameTable:leave(userId): boolean
    -- Not a member, no.
    if not self.members[userId] then
        return false
    end

    self.members[userId] = nil

    -- Let the game deal with any fallout from the player leaving.
    if self.gameInstance then
        self.gameInstance:playerLeft(userId)
    end

    return true
end

function GameTable:startGame(userId: CommonTypes.UserId): boolean
    -- Not the host, no.
    if self.hostUserId ~= userId then
        return false
    end

    -- Game already started, no.
    if self.gameTableState == GameTable.GameTableStates.Playing then
        return false
    end

    -- Right number of players?
    local numPlayers = #self.members
    if numPlayers < self.gameDetails.MinPlayers then 
        return false
    end
    if numPlayers > self.gameDetails.MaxPlayers then 
        return false
    end

    assert(self.gameInstance == nil, "Game instance already exists"	)
    self.gameTableState = GameTable.GameTableStates.Playing
    self.gameInstance = GameInstance.new(self.id, self.gameDetails.gameId)

    return true
end

function GameTable:endGame(userId: CommonTypes.UserId): boolean
    -- Not the host, no.
    if self.hostUserId ~= userId then
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
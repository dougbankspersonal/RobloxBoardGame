--[[
    Server-concept only.
    Class for a game table.
    Any instance of game table is stored in a global array: this file also
    provides static functions to fetch created tables based on table Id.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Cryo = require(ReplicatedStorage.Cryo)

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local TableDescription = require(RobloxBoardGameShared.Modules.TableDescription)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local ServerGameInstanceConstructors = require(RobloxBoardGameServer.Globals.ServerGameInstanceConstructors)
local ServerGameInstances = require(RobloxBoardGameServer.Modules.ServerGameInstances)
local ServerTypes = require(RobloxBoardGameServer.Types.ServerTypes)
local GameTablesStorage = require(RobloxBoardGameServer.Modules.GameTablesStorage)
local ServerEventManagement = require(RobloxBoardGameServer.Modules.ServerEventManagement)

local GameTable = {}
GameTable.__index = GameTable

local nextGameTableId: CommonTypes.TableId = 10000

GameTable.new = function(hostUserId: CommonTypes.UserId, gameId: CommonTypes.GameId, isPublic: boolean): ServerTypes.GameTable
    local self = {}
    setmetatable(self, GameTable)

    local tableId = nextGameTableId
    nextGameTableId = nextGameTableId + 1

    self.isMock = false

    -- Fill in table description.
    self.tableDescription = TableDescription.createTableDescription(tableId, hostUserId, gameId, isPublic)

    self.gameDetails = GameDetails.getGameDetails(gameId)

    GameTablesStorage.addTable(self)

    return self
end

function GameTable:getTableId(): CommonTypes.TableId
    return self.tableDescription.tableId
end

function GameTable:getGameId(): CommonTypes.GameId
    return self.tableDescription.gameId
end

function GameTable:getGameInstanceGUID(): CommonTypes.GameInstanceGUID?
    return self.tableDescription.gameInstanceGUID
end

function GameTable:isMember(userId: CommonTypes.UserId): boolean
    return self.tableDescription.memberUserIds[userId]
end

function GameTable:isInvitedToTable(userId: CommonTypes.UserId): boolean
    return self.tableDescription.invitedUserIds[userId] or false
end

function GameTable:isHost(userId: CommonTypes.UserId): boolean
    Utils.debugPrint("TablePlaying", "GameTable:isHost userId = ", userId)
    Utils.debugPrint("TablePlaying", "GameTable:isHost self.tableDescription.hostUserId = ", self.tableDescription.hostUserId)
    return self.tableDescription.hostUserId == userId
end

function GameTable:destroyTable(userId: CommonTypes.UserId): boolean
    assert(userId, "Should have a userId")

    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    -- Kill any ongoing game.
    if self.tableDescription.gameTableState == GameTableStates.Playing then
        self:endGame(userId)
    end

    GameTablesStorage.removeTable(self)

    return true
end

-- Try to add user as member of table.
-- Return true iff successful.
function GameTable:joinTable(userId: CommonTypes.UserId, opt_isMock:boolean?): boolean
    assert(userId, "Should have a userId")

    -- Host can't join his own table.
    if self:isHost(userId) then
        return
    end

    -- Game already started, no.
    if self.tableDescription.gameTableState ~= GameTableStates.WaitingForPlayers then
        return false
    end

    -- Already a member, no.
    if self:isMember(userId) then
        return false
    end

    -- not public, not invited: no.
    if not self.tableDescription.isPublic and not self:isInvitedToTable(userId) then
        return false
    end

    -- too many players already, no.
    if self.gameDetails.maxPlayers <= Utils.tableSize(self.tableDescription.memberUserIds) then
        return false
    end

    self.tableDescription.memberUserIds[userId] = true

    -- Once a player is a Member they are no longer invited.
    self.tableDescription.invitedUserIds[userId] = nil

    -- If this is a mock player, make a note of that.
    if opt_isMock then
        self.tableDescription.mockUserIds[userId] = true
    end

    return true
end

-- Try to add user as invitee of table.
-- Return true iff anything changes.
function GameTable:inviteToTable(userId: CommonTypes.UserId, inviteeId: CommonTypes.UserId): boolean
    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    -- Game already started, no.
    if self.tableDescription.gameTableState ~= GameTableStates.WaitingForPlayers then
        return false
    end

    -- Can't invite self.
    if userId == inviteeId then
        return false
    end

    -- Already a member, no.
    if self:isMember(inviteeId) then
        return false
    end

    -- Already invited, no.
    if self:isInvitedToTable(inviteeId) then
        return false
    end

    self.tableDescription.invitedUserIds[inviteeId] = true
    return true
end

-- Set invites to exactly this list.
-- Return true iff anything changes.
function GameTable:setInvites(userId: CommonTypes.UserId, inviteeIds: {CommonTypes.UserId}): boolean
    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    -- Game already started, no.
    if self.tableDescription.gameTableState ~= GameTableStates.WaitingForPlayers then
        return false
    end

    local newInvitedUserIds = {}

    for _, inviteeId in inviteeIds do
        -- Can't invite self.
        if userId == inviteeId then
            continue
        end

        -- Already a member, no.
        if self:isMember(inviteeId) then
            continue
        end

        newInvitedUserIds[inviteeId] = true
    end

    -- Did something change?
    local somethingChanged = false
    if not Utils.tablesHaveSameKeys(self.tableDescription.invitedUserIds, newInvitedUserIds) then
        somethingChanged = true
        self.tableDescription.invitedUserIds = newInvitedUserIds
    end

    return somethingChanged
end

function GameTable:removeGuestFromTable(userId: CommonTypes.UserId, guestId: CommonTypes.UserId): boolean
    assert(userId, "userId must be provided")
    assert(guestId, "guestId must be provided")

    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    -- Can't remove self.
    if userId == guestId then
        return false
    end

    -- Can't remove a non-member.
    if not self:isMember(guestId) then
        return false
    end

    self.tableDescription.memberUserIds[guestId] = nil
    -- Just for kicks remove the invite too.
    self.tableDescription.invitedUserIds[guestId] = nil
    return true
end

function GameTable:removeInviteForTable(userId: CommonTypes.UserId, inviteeId: CommonTypes.UserId): boolean
    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    -- Must be an invitee.
    if not self:isInvitedToTable(inviteeId) then
        return false
    end

    self.tableDescription.invitedUserIds[inviteeId] = nil
    return true
end

function GameTable:leaveTable(userId: CommonTypes.UserId): boolean
    assert(userId, "userId must be provided")
    Utils.debugPrint("Mocks", "leaveTable userId = ", userId)
    Utils.debugPrint("Mocks", "leaveTable self.tableDescription.hostUserId = ", self.tableDescription.hostUserId)
    Utils.debugPrint("Mocks", "leaveTable self.tableDescription.memberUserIds = ", self.tableDescription.memberUserIds)

    -- Host can't leave.
    if self:isHost(userId) then
        Utils.debugPrint("Mocks", "leaveTable 001")
        return false
    end

    -- Can't leave if not a member.
    if not self:isMember(userId) then
        Utils.debugPrint("Mocks", "leaveTable 002")
        return false
    end

    -- Remove the user.
    self.tableDescription.memberUserIds[userId] = nil
    self.tableDescription.invitedUserIds[userId] = nil
    self.tableDescription.mockUserIds[userId] = nil

    Utils.debugPrint("Mocks", "leaveTable 003")

    -- Let the game deal with any fallout from the player leaving.
    if self.tableDescription.gameTableState == GameTableStates.Playing then
        Utils.debugPrint("Mocks", "leaveTable 04")
        local serverGameInstance = ServerGameInstances.getGameInstance(self.tableDescription.gameInstanceGUID)
        assert(serverGameInstance, "gameInstance should exist if gameTableState is Playing")
        -- sanity check: this is the same table description as in our game instance, right?
        -- Like having modfified it above, we have modified the copy used in game instance?
        assert(Cryo.Dictionary.equals(self.tableDescription, serverGameInstance.tableDescription), "tableDescription should be the same as in game instance")

        serverGameInstance:playerLeftGame(userId)
    end

    Utils.debugPrint("Mocks", "leaveTable 005")
    return true
end

function GameTable:updateGameOptions(userId: CommonTypes.UserId, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions): boolean
    -- Only host can update game options.
    if not self:isHost(userId) then
        return false
    end

    -- Must be in waiting mode.
    if self.tableDescription.gameTableState ~= GameTableStates.WaitingForPlayers then
        return false
    end

    -- Game options should all make sense.

    for gameOptionId, value in nonDefaultGameOptions do
        local gameOption = GameDetails.getGameOptionById(self.gameDetails, gameOptionId)
        if not gameOption then
            return false
        end

        if gameOption.opt_variants then
            if type(value) ~= "number" then
                return false
            end
            if value < 1 or value > #gameOption.opt_variants then
                return false
            end
        else
            if type(value) ~= "boolean" then
                return false
            end
        end
    end

    -- Slap them in there.
    self.tableDescription.opt_nonDefaultGameOptions = nonDefaultGameOptions
    return true
end

function GameTable:startGame(userId: CommonTypes.UserId): boolean
    -- Only host can start.
    if not self:isHost(userId) then
        return false
    end

    -- Game already started, no.
    if self.tableDescription.gameTableState == GameTableStates.Playing then
        return false
    end

    -- Right number of players?
    local numPlayers = Utils.tableSize(self.tableDescription.memberUserIds)
    if numPlayers < self.gameDetails.minPlayers then
        return false
    end
    if numPlayers > self.gameDetails.maxPlayers then
        return false
    end

    assert(self.tableDescription.gameTableState ~= GameTableStates.Playing, "gameTableState already Playing")
    assert(self.tableDescription.gameInstanceGUID == nil, "gameInstanceGUID already exists")
    self.tableDescription.gameTableState = GameTableStates.Playing
    self.tableDescription.gameInstanceGUID = HttpService:GenerateGUID(false)

    -- Create communication channels for game-specific messages.
    ServerEventManagement.setupRemoteCommunicationsForGame(self.tableDescription.gameInstanceGUID)
    -- Make the instance and start the game playing.
    local serverGameInstanceConstructor = self:getServerGameInstanceConstructor()
    -- _After this an instance for the game exists on the server, game is playing.
    local serverGameInstance = serverGameInstanceConstructor(self.tableDescription)
    serverGameInstance:sanityCheck()
    ServerGameInstances.addServerGameInstance(serverGameInstance)

    return true
end

function GameTable:getServerGameInstanceConstructor(): CommonTypes.ServerGameInstanceConstructor
    assert(self.tableDescription.gameId, "getServerGameInstanceConstructor: gameId is required")
   local giCtor = ServerGameInstanceConstructors.getServerGameInstanceConstructor(self.tableDescription.gameId)

    assert(giCtor, "getServerGameInstanceConstructor: giCtor not found for gameId: " .. self.tableDescription.gameId)

    return giCtor
end

function GameTable:endGame(userId: CommonTypes.UserId): boolean
    -- Must be the host.
    if not self:isHost(userId) then
        return false
    end

    -- Game isn't playing, no.
    if self.tableDescription.gameTableState ~= GameTableStates.Playing then
        return false
    end

    -- Stop listening for game-specific messages.
    ServerEventManagement.removeServerToClientEventsForGame(self.tableDescription.gameInstanceGUID)

    local serverGameInstance = ServerGameInstances.getGameInstance(self.tableDescription.gameInstanceGUID)
    ServerGameInstances.removeServerGameInstance(self.tableDescription.gameInstanceGUID)
    assert(serverGameInstance, "should have gameInstance")
    serverGameInstance:destroy()

    self.tableDescription.gameTableState = GameTableStates.WaitingForPlayers
    self.tableDescription.gameInstanceGUID = nil


    return true
end


function GameTable:getTableDescription(): CommonTypes.TableDescription
    return self.tableDescription
end

return GameTable
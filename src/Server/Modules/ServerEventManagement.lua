--[[
Logic for creating and handling events on the server.
FIXME(dbanks)
This has gotta overstuffed.
We could trim this down to just be make events/functions, listen to events/functions and ping local signals when things fire.
Then move actual logic into third party observer.
Like all the handleXXX functions.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cryo = require(ReplicatedStorage.Cryo)

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local TableDescription = require(RobloxBoardGameShared.Modules.TableDescription)
local EventUtils = require(RobloxBoardGameShared.Modules.EventUtils)
local SanityChecks = require(RobloxBoardGameShared.Modules.SanityChecks)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local ServerEventUtils = require(RobloxBoardGameServer.Modules.ServerEventUtils)
local GameTablesStorage = require(RobloxBoardGameServer.Modules.GameTablesStorage)
local ServerTypes = require(RobloxBoardGameServer.Types.ServerTypes)
local GameTable = require(RobloxBoardGameServer.Classes.GameTable)

local ServerEventManagement = {}

-- Notify every player of an event.
local function sendToAllPlayersInExperience(eventName, ...)
    local tableEvents = ReplicatedStorage:FindFirstChild(EventUtils.FolderNameTableEvents)
    assert(tableEvents, "TableEvents not found")
    local event = tableEvents:FindFirstChild(eventName)
    assert(event, "Event not found: " .. eventName)
    event:FireAllClients(...)
end

local function handleJoinTable(actorId: CommonTypes.UserId, gameTable: ServerTypes.GameTable, opt_isMock: boolean?)
    Utils.debugPrint("Mocks", "handleJoinTable actorId = ", actorId, " opt_isMock = ", opt_isMock)
    if gameTable:joinTable(actorId, opt_isMock) then
        sendToAllPlayersInExperience(EventUtils.EventNameTableUpdated, gameTable:getTableDescription())
    end
end

local function handleAddInvite(actorId: CommonTypes.UserId, inviteeId: CommonTypes.UserId, gameTable: ServerTypes.GameTable)
    if gameTable:inviteToTable(actorId, inviteeId) then
        sendToAllPlayersInExperience(EventUtils.EventNameTableUpdated, gameTable:getTableDescription())
    end
end

local function handleStartGame(actorId: CommonTypes.UserId, gameTable: ServerTypes.GameTable)
    if gameTable:startGame(actorId) then
        sendToAllPlayersInExperience(EventUtils.EventNameTableUpdated, gameTable:getTableDescription())
    end
end

local function handleUserLeavingTable(userId: CommonTypes.UserId, gameTable: ServerTypes.GameTable)
    -- The host is not allowed to leave the table: leaves a useless orphaned table.
    -- If he wants to leave he has to destroy.
    -- Client side does not provide a path for host to send this message so it must be spoof, ignore.
    if gameTable.tableDescription.hostUserId == userId then
        return
    end

    if gameTable:leaveTable(userId) then
        -- For a waiting table, nothing extra to do: table is modified, updated table will be broadcast with
        -- EventNameTableUpdated, done.
        -- If a game is going through, it's a bit disruptive: all the players should have some UI
        -- experience showing that the player left, and the host may get some controls to react
        -- somehow (maybe end the game or somehow adjust gameplay to account for missing player).
        if gameTable.tableDescription.gameInstanceGUID then
            ServerEventUtils.sendEventForPlayersInGame(gameTable.tableDescription,
                EventUtils.EventNamePlayerLeftTable,
                userId)
        end
        sendToAllPlayersInExperience(EventUtils.EventNameTableUpdated, gameTable:getTableDescription())
    end
end

local function handleMockNonHostMemberLeaves(gameTable: ServerTypes.GameTable)
    Utils.debugPrint("Mocks", "handleMockNonHostMemberLeaves 001")
    -- Pick a random mock member who is NOT the host.
    local mockUserIds = Cryo.Dictionary.keys(gameTable.tableDescription.mockUserIds)
    Utils.debugPrint("Mocks", "handleMockNonHostMemberLeaves mockUserIds = ", mockUserIds)
    if not mockUserIds then
        Utils.debugPrint("Mocks", "handleMockNonHostMemberLeaves 002")
        return
    end
    local nonHostUserIds = Cryo.List.map(mockUserIds, function(userId)
        if userId ~= gameTable.tableDescription.hostUserId then
            return userId
        end
        return nil
    end)
    Utils.debugPrint("Mocks", "handleMockNonHostMemberLeaves nonHostUserIds = ", nonHostUserIds)
    if #nonHostUserIds == 0 then
        Utils.debugPrint("Mocks", "handleMockNonHostMemberLeaves 003")
        return
    end

    Utils.debugPrint("Mocks", "handleMockNonHostMemberLeaves 004")
    local leavingUserId = nonHostUserIds[1]
    assert(leavingUserId, "Should have a leavingUserId")

    handleUserLeavingTable(leavingUserId, gameTable)
end

local function handleEndGame(actorUserId: CommonTypes.UserId, gameTable: ServerTypes.GameTable, gameEndDetails: CommonTypes.GameEndDetails): boolean
    assert(actorUserId, "actorUserId should be defined")
    assert(gameTable, "gameTable should be defined")
    assert(gameEndDetails, "gameEndDetails should be defined")

    if not gameTable:canEndGame(actorUserId) then
        return false
    end

    local serverGameInstance = gameTable:getServerGameInstance()

    -- Add whatever extra info we might care about on why this ended.
    gameEndDetails.gameSpecificDetails = serverGameInstance:getGameSpecificGameEndDetails()
    SanityChecks.sanityCheckServerGameInstance(serverGameInstance)

    Utils.debugPrint("GamePlay", "ServerEventManagement handleEndGame: gameEndDetails = ", gameEndDetails)

    Utils.debugPrint("GamePlay", "ServerEventManagement handleEndGame: sending NotifyThatHostEndedGame")
    -- First use non-modified game table to send events to members that this game is gonna die.
    ServerEventUtils.sendEventForPlayersInGame(gameTable:getTableDescription(), EventUtils.EventNameNotifyThatHostEndedGame, gameEndDetails)

    Utils.debugPrint("GamePlay", "ServerEventManagement calling gameTable.endGame")
    -- Now end the game.
    -- This should unset game-specific state (like gameInstanceGUID),
    -- remove anythinig we made assocaited with the game (server game instance,
    -- game-specific events, etc).
    gameTable:endGame()

    -- Broadcast new table state to the world.
    Utils.debugPrint("GamePlay", "ServerEventManagement sending TableUpdated")
    sendToAllPlayersInExperience(EventUtils.EventNameTableUpdated, gameTable:getTableDescription())
    return true
end

local function handleCreateTable(hostUserId: CommonTypes.UserId, gameId: CommonTypes.GameId, isPublic: boolean, opt_twiddleCallback: (ServerTypes.GameTable) -> nil)
    local gameTable = GameTable.new(hostUserId, gameId, isPublic)
    if not gameTable then
        return
    end

    if opt_twiddleCallback then
        opt_twiddleCallback(gameTable)
    end

    sendToAllPlayersInExperience(EventUtils.EventNameTableCreated, gameTable:getTableDescription())
end


function ServerEventManagement.handleDestroyTable(actorUserId: CommonTypes.UserId, gameTable: ServerTypes.GameTable)
    -- We separate out 'can' from 'do it' because it's useful to have the table around while we do some cleanup
    -- work.
    if not gameTable:canDestroy(actorUserId) then
        -- Ignore, someone is trying to do something they should not.
        return
    end

    -- If there is a game going, end it.  The 'end the game' logic includes info on why game ended: we
    -- note that it's because the table was destroyed.
    if gameTable.tableDescription.gameInstanceGUID then
        local gameEndDetails = {
            tableDestroyed = true,
        } :: CommonTypes.GameEndDetails
        local success = handleEndGame(actorUserId, gameTable, gameEndDetails)
        -- This better work.
        assert(success, "Should have been able to end game")
    end

    local tableId = gameTable.tableDescription.tableId

    gameTable:destroy()
    sendToAllPlayersInExperience(EventUtils.EventNameTableDestroyed, tableId)
end

-- Convenience function for creating a remote event that is specific to a game table.
-- The event comes in with tableId as first argument (after player).
-- Iff the table id is legit, the event is passed to the handler with the game table as the second argument.
local function createGameTableRemoteEvent(tableEventsFolder: Folder, eventName: string, opt_onServerEventForTable: (Player, any) -> nil)
    assert(tableEventsFolder, "tableEventsFolder should be defined")
    assert(eventName, "eventName should be defined")

    local augmentedOnServerEvent
    if opt_onServerEventForTable then
        augmentedOnServerEvent = function(player, tableId: CommonTypes.TableId, ...)
            local gameTable = GameTablesStorage.getGameTableByTableId(tableId)
            -- Sanity check the table.
            gameTable:sanityCheck()
            if not gameTable then
                return
            end
            opt_onServerEventForTable(player, gameTable, ...)
        end
    end
    ServerEventUtils.createRemoteEvent(tableEventsFolder, eventName, augmentedOnServerEvent)
end

local function createGameTableMockRemoteEvent(tableEventsFolder: Folder, eventName: string, opt_onServerEventForTable: (any) -> nil)
    local adjustedCallback
    if opt_onServerEventForTable then
        adjustedCallback = function(player: Player, ...): nil
            if player.UserId ~= Utils.StudioUserId then
                return
            end
            opt_onServerEventForTable(...)
        end
    end
    createGameTableRemoteEvent(tableEventsFolder, eventName, adjustedCallback)
end

local function makeFetchTableDescriptionsByTableIdRemoteFunction(tableFunctionsFolder: Folder)
    assert(tableFunctionsFolder, "tableFunctionsFolder should be defined")

    -- Remote function to fetch all tables.
    ServerEventUtils.createRemoteFunction(tableFunctionsFolder, EventUtils.FunctionNameFetchTableDescriptionsByTableId, function(_): CommonTypes.TableDescriptionsByTableId
        local gameTables = GameTablesStorage.getGameTablesByTableId()
        local retVal = {} :: CommonTypes.TableDescriptionsByTableId
        for tableId, gameTable in gameTables do
            retVal[tableId] = gameTable.tableDescription
        end
        return retVal
    end)
end

local function mockInviteAndPossiblyAddUser(gameTable: ServerTypes.GameTable, userId: CommonTypes.UserId, shouldJoin: boolean)
    -- If not public, invite the player who sent the mock.
    if not gameTable.tableDescription.isPublic then
        local success = gameTable:inviteToTable(gameTable.tableDescription.hostUserId, userId)
        assert(success, "Should have been able to invite")
    end

    if shouldJoin then
        local success = gameTable:joinTable(userId, true)
        assert(success, "Should have been able to join")
    end
end

local function addMockEventHandlers(tableEventsFolder: Folder)
    assert(RunService:IsStudio(), "Should only be run in Studio")

    createGameTableMockRemoteEvent(tableEventsFolder, EventUtils.EventNameAddMockMember, function(gameTable)
        local actorId = ServerEventUtils.generateMockUserId()
        handleJoinTable(actorId, gameTable, true)
    end)

    createGameTableMockRemoteEvent(tableEventsFolder, EventUtils.EventNameMockNonHostMemberLeaves, function(gameTable)
        Utils.debugPrint("Mocks", "ServerEventManagement handling EventNameMockNonHostMemberLeaves")
        handleMockNonHostMemberLeaves(gameTable)
    end)

    createGameTableMockRemoteEvent(tableEventsFolder, EventUtils.EventNameMockHostDestroysTable, function(gameTable)
        ServerEventManagement.handleDestroyTable(gameTable.tableDescription.hostUserId, gameTable)
    end)

    createGameTableMockRemoteEvent(tableEventsFolder, EventUtils.EventNameAddMockInvite, function(gameTable)
        local inviteeId = ServerEventUtils.generateMockUserId()
        handleAddInvite(gameTable.tableDescription.hostUserId, inviteeId, gameTable)
    end)

    createGameTableMockRemoteEvent(tableEventsFolder, EventUtils.EventNameMockInviteAcceptance, function(gameTable)
        local keys = Cryo.Dictionary.keys(gameTable.tableDescription.invitedUserIds)
        if #keys == 0 then
            return
        end
        local actorId = keys[1]
        handleJoinTable(actorId, gameTable, true)
    end)

    createGameTableMockRemoteEvent(tableEventsFolder, EventUtils.EventNameMockStartGame, function(gameTable)
        local actorId = gameTable.tableDescription.hostUserId
        handleStartGame(actorId, gameTable)
    end)

    -- Destroy all Mock Tables.
    ServerEventUtils.createRemoteEvent(tableEventsFolder, EventUtils.EventNameDestroyAllMockTables, function(player)
        if player.UserId ~= Utils.StudioUserId then
            return
        end
        Utils.debugPrint("Mocks", "Doug; Destroying all Mock Tables")
        local tablesByTableId = GameTablesStorage.getGameTablesByTableId()
        assert(tablesByTableId, "Should have tablesByTableId")
        for _, gameTable in tablesByTableId do
            if gameTable.isMock then
                ServerEventManagement.handleDestroyTable(gameTable.tableDescription.hostUserId, gameTable)
            end
        end
    end)

    -- Make a mock table.
    ServerEventUtils.createRemoteEvent(tableEventsFolder, EventUtils.EventNameCreateMockTable, function(player: Player, isPublic: boolean, shouldJoin: boolean, isHost: boolean)
        if player.UserId ~= Utils.StudioUserId then
            return
        end
        Utils.debugPrint("Mocks", "Doug; Mocking Table")
        -- Make a random table.
        -- Get a random game id.
        local gameDetailsByGameId = GameDetails.getAllGameDetails()
        local gameId = Utils.getRandomKey(gameDetailsByGameId)

        local hostUserId
        if isHost then
            hostUserId = player.UserId
        else
            hostUserId = ServerEventUtils.generateMockUserId()
        end

        handleCreateTable(hostUserId, gameId, isPublic, function(gameTable: ServerTypes.GameTable)
            if not isHost then
                mockInviteAndPossiblyAddUser(gameTable, player.UserId, shouldJoin)
            end
            local tableDescription = gameTable:getTableDescription()
            -- Add random people up to seating limit.
            local gameDetails = GameDetails.getGameDetails(gameTable.tableDescription.gameId)
            local openSlots = gameDetails.maxPlayers - TableDescription.getNumberOfPlayersAtTable(tableDescription)
            -- If the party in question has not joined, leave an extra seat.
            if not shouldJoin then
                openSlots = openSlots - 1
            end

            for _ = 1, openSlots do
                mockInviteAndPossiblyAddUser(gameTable, ServerEventUtils.generateMockUserId(), true)
            end
        end)
    end)
end

local function setupClientToServerEvents(tableEventsFolder: Folder)
    -- Events sent from client to server.
    -- Event to create a new table.
    ServerEventUtils.createRemoteEvent(tableEventsFolder, EventUtils.EventNameCreateNewTable, function(player, gameId, isPublic)
        handleCreateTable(player.UserId, gameId, isPublic)
    end)

    -- Event to destroy a table.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameDestroyTable, function(player, gameTable)
        ServerEventManagement.handleDestroyTable(player.UserId, gameTable)
    end)

    -- Event to join a table.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameJoinTable, function(player, gameTable)
        handleJoinTable(player.UserId, gameTable)
    end)

    -- Event to invite someone to table.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameInvitePlayerToTable, function(player, gameTable, inviteeId)
        handleAddInvite(player.UserId, inviteeId, gameTable)
    end)

    -- Set the invites to this set of people, removing or adding as needed.
    -- Returns true if anything actually changed.
    -- If some invites are bad and some good, we apply the bad and ignore the good.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameSetTableInvites, function(player: Player, gameTable, inviteeIds: {CommonTypes.UserId})
        if gameTable:setInvites(player.UserId, inviteeIds) then
            sendToAllPlayersInExperience(EventUtils.EventNameTableUpdated, gameTable:getTableDescription())
        end
    end)

    -- Event to remove someone to table.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameRemoveGuestFromTable, function(player, gameTable, userId)
        if gameTable:removeGuestFromTable(player.UserId, userId) then
            sendToAllPlayersInExperience(EventUtils.EventNameTableUpdated, gameTable:getTableDescription())
        end
    end)

    -- Event to remove an invite from a table.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameRemoveInviteForTable, function(player, gameTable, userId)
        if gameTable:removeInviteForTable(player.UserId, userId) then
            sendToAllPlayersInExperience(EventUtils.EventNameTableUpdated, gameTable:getTableDescription())
        end
    end)

    -- Event to update game options.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameSetTableGameOptions, function(player, gameTable, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions)
        if gameTable:updateGameOptions(player.UserId, nonDefaultGameOptions) then
            sendToAllPlayersInExperience(EventUtils.EventNameTableUpdated, gameTable:getTableDescription())
        end
    end)

    -- Event to leave a table.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameLeaveTable, function(player, gameTable)
        handleUserLeavingTable(player.UserId, gameTable)
    end)

    -- Start playing the game.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameStartGame, function(player, gameTable)
        handleStartGame(player.UserId, gameTable)
    end)

    -- Event for host to end the game currently playing at a table.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameEndGame, function(player: Player, gameTable: ServerTypes.GameTable)
        Utils.debugPrint("GamePlay", "ServerEventManagement calling handleEndGame")
        local gameEndDetails = {
            hostEndedGame = true,
        } :: CommonTypes.GameEndDetails

        handleEndGame(player.UserId, gameTable, gameEndDetails)
    end)

    if RunService:IsStudio() then
        addMockEventHandlers(tableEventsFolder)
    end
end

local function setupServerToClientEvents(tableEventsFolder: Folder)
    -- Notification that a new table was created.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameTableCreated)
    -- Notification that a table was destroyed.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameTableDestroyed)
    -- Notification that something about this table has changed.
    createGameTableRemoteEvent(tableEventsFolder, EventUtils.EventNameTableUpdated)
end

--[[
Startup Function making all the events where client sends to server.
]]
ServerEventManagement.setupRemoteCommunications = function(tableEventsFolder: Folder, tableFunctionsFolder: Folder)
    assert(tableEventsFolder, "tableEventsFolder should be defined")
    assert(tableFunctionsFolder, "tableFunctionsFolder should be defined")

    -- Make remote function called by client to get all tables.
    makeFetchTableDescriptionsByTableIdRemoteFunction(tableFunctionsFolder)

    setupClientToServerEvents(tableEventsFolder)
    setupServerToClientEvents(tableEventsFolder)
end

return ServerEventManagement
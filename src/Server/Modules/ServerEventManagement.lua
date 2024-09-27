--[[
Logic for creating and handling events on the server.
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

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local ServerEventUtils = require(RobloxBoardGameServer.Modules.ServerEventUtils)
local GameTablesStorage = require(RobloxBoardGameServer.Modules.GameTablesStorage)
local ServerTypes = require(RobloxBoardGameServer.Types.ServerTypes)

local ServerEventManagement = {}

-- Notify every player of an event.
local function sendToAllPlayersInExperience(eventName, ...)
    local tableEvents = ReplicatedStorage:FindFirstChild(EventUtils.TableEventsFolderName)
    assert(tableEvents, "TableEvents not found")
    local event = tableEvents:FindFirstChild(eventName)
    assert(event, "Event not found: " .. eventName)
    event:FireAllClients(...)
end

local handleUserLeavingTable = function(userId: CommonTypes.UserId, gameTable: ServerTypes.GameTable)
    Utils.debugPrint("Mocks", "handleUserLeavingTable userId = ", userId, " gameTable = ", gameTable)
    if gameTable:leaveTable(userId) then
        Utils.debugPrint("Mocks", "leaveTable worked")
        assert(gameTable.tableDescription, "Should have a tableDescription")
        -- People coming and going from a table where no game is playing: who cares.
        -- But if game is active, we want to notify everyone.
        if gameTable.tableDescription.gameInstanceGUID then
            ServerEventUtils.sendEventForPlayersInGame(gameTable.tableDescription,
                "PlayerLeftTable",
                userId)
        end
        sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
    end
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
            if not gameTable then
                return
            end
            opt_onServerEventForTable(player, gameTable, ...)
        end
    end
    ServerEventUtils.createRemoteEvent(tableEventsFolder, eventName, augmentedOnServerEvent)
end

local function makeFetchTableDescriptionsByTableIdRemoteFunction(tableFunctionsFolder: Folder)
    assert(tableFunctionsFolder, "tableFunctionsFolder should be defined")

    -- Remote function to fetch all tables.
    ServerEventUtils.createRemoteFunction(tableFunctionsFolder, "FetchTableDescriptionsByTableId", function(_): CommonTypes.TableDescriptionsByTableId
        local gameTables = GameTablesStorage.getGameTablesByTableId()
        local retVal = {} :: CommonTypes.TableDescriptionsByTableId
        for tableId, gameTable in gameTables do
            retVal[tableId] = gameTable.tableDescription
        end
        return retVal
    end)
end

local mockInviteAndPossiblyAddUser = function(gameTable: ServerTypes.GameTable, userId: CommonTypes.UserId, shouldJoin: boolean)
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

local function addMockEventHandlers(tableEventsFolder: Folder, createTableHandler: (CommonTypes.UserId, CommonTypes.GameId, boolean) -> nil)
    assert(RunService:IsStudio(), "Should only be run in Studio")

    createGameTableRemoteEvent(tableEventsFolder, "AddMockMember", function(_, gameTable)
        if not gameTable.tableDescription.isPublic then
            return
        end
        if not gameTable:joinTable(ServerEventUtils.generateMockUserId(), true) then
            return
        end
        sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
    end)

    createGameTableRemoteEvent(tableEventsFolder, "MockMemberLeaves", function(_, gameTable)
        -- Pick a random mock member.
        Utils.debugPrint("Mocks", "MockMemberLeaves 001")
        local mockUserIds = Cryo.Dictionary.keys(gameTable.tableDescription.mockUserIds)
        Utils.debugPrint("Mocks", "MockMemberLeaves mockUserIds = ", mockUserIds)
        if not mockUserIds or #mockUserIds == 0 then
            Utils.debugPrint("Mocks", "MockMemberLeaves 001.5")
            return
        end

        Utils.debugPrint("Mocks", "MockMemberLeaves 002")
        local leavingUserId = mockUserIds[1]
        assert(leavingUserId, "Should have a leavingUserId")
        Utils.debugPrint("Mocks", "MockMemberLeaves leavingUserId = ", leavingUserId)
        handleUserLeavingTable(leavingUserId, gameTable)
    end)

    createGameTableRemoteEvent(tableEventsFolder, "AddMockInvite", function(player, gameTable)
        if gameTable.tableDescription.isPublic then
            return
        end
        if not gameTable:inviteToTable(player.UserId, ServerEventUtils.generateMockUserId(), true) then
            return
        end
        sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
    end)

    createGameTableRemoteEvent(tableEventsFolder, "MockInviteAcceptance", function(_, gameTable)
        if gameTable.tableDescription.isPublic then
            return
        end
        local keys = Cryo.Dictionary.keys(gameTable.tableDescription.invitedUserIds)
        if #keys == 0 then
            return
        end
        local accepteeId = keys[1]
        if gameTable:joinTable(accepteeId, true) then
            sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
        end
    end)

    createGameTableRemoteEvent(tableEventsFolder, "MockStartGame", function(_, gameTable)
        if gameTable:startGame(gameTable.tableDescription.hostUserId) then
            sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Destroy all Mock Tables.
    ServerEventUtils.createRemoteEvent(tableEventsFolder, "DestroyAllMockTables", function(player)
        Utils.debugPrint("Mocks", "Doug; Destroying all Mock Tables")
        local tablesByTableId = GameTablesStorage.getGameTablesByTableId()
        assert(tablesByTableId, "Should have tablesByTableId")
        for tableId, gameTable in tablesByTableId do
            if gameTable.isMock then
                gameTable:destroyTable(player.UserId)
                sendToAllPlayersInExperience("TableDestroyed", tableId)
            end
        end
    end)

    -- Make a mock table.
    ServerEventUtils.createRemoteEvent(tableEventsFolder, "MockTable", function(player: Player, isPublic: boolean, shouldJoin: boolean, isHost: boolean)
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
        local gameTable = createTableHandler(hostUserId, gameId, isPublic)
        if not gameTable then
            Utils.debugPrint("Mocks", "Doug; Mocking Table: no table")
            return
        end

        if not isHost then
            mockInviteAndPossiblyAddUser(gameTable, player.UserId, shouldJoin)
        end

        gameTable.isMock = true

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

        Utils.debugPrint("Mocks", "Doug; Mocking Table: broadcasting TableCreated tableDescription = ", tableDescription)

        -- Broadcast the new table to all players
        sendToAllPlayersInExperience("TableCreated", tableDescription)
    end)
end

local function setupClientToServerEvents(tableEventsFolder: Folder, createTableHandler: (CommonTypes.UserId, CommonTypes.GameId, boolean) -> nil)
    -- Events sent from client to server.
    -- Event to create a new table.
    ServerEventUtils.createRemoteEvent(tableEventsFolder, "CreateNewTable", function(player, gameId, isPublic)
        local gameTable = createTableHandler(player.UserId, gameId, isPublic)
        if not gameTable then
            return
        end

        -- Broadcast the new table to all players
        sendToAllPlayersInExperience("TableCreated", gameTable.tableDescription)
    end)

    createGameTableRemoteEvent(tableEventsFolder, "GoToWaiting", function(player, gameTable)
        if gameTable:goToWaiting(player.UserId) then
            sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Event to destroy a table.
    createGameTableRemoteEvent(tableEventsFolder, "DestroyTable", function(player, gameTable)
        assert(gameTable, "Should have a gameTable")
        assert(gameTable.tableDescription, "Should have a tableDescription")
        local gameTableId = gameTable:getTableId()
        assert(gameTableId, "Should have a gameTableId")

        if gameTable:destroyTable(player.UserId) then
            sendToAllPlayersInExperience("TableDestroyed", gameTableId)
        end
    end)

    -- Event to join a table.
    createGameTableRemoteEvent(tableEventsFolder, "JoinTable", function(player, gameTable)
        if gameTable:joinTable(player.UserId) then
            sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Event to invite someone to table.
    createGameTableRemoteEvent(tableEventsFolder, "InvitePlayerToTable", function(player, gameTable, inviteeId)
        if gameTable:inviteToTable(player.UserId, inviteeId) then
            sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Set the invites to this set of people, removing or adding as needed.
    -- Returns true if anything actually changed.
    -- If some invites are bad and some good, we apply the bad and ignore the good.
    createGameTableRemoteEvent(tableEventsFolder, "SetTableInvites", function(player: Player, gameTable, inviteeIds: {CommonTypes.UserId})
        if gameTable:setInvites(player.UserId, inviteeIds) then
            sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Event to remove someone to table.
    createGameTableRemoteEvent(tableEventsFolder, "RemoveGuestFromTable", function(player, gameTable, userId)
        if gameTable:removeGuestFromTable(player.UserId, userId) then
            sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Event to remove an invite from a table.
    createGameTableRemoteEvent(tableEventsFolder, "RemoveInviteForTable", function(player, gameTable, userId)
        if gameTable:removeInviteForTable(player.UserId, userId) then
            sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Event to update game options.
    createGameTableRemoteEvent(tableEventsFolder, "SetTableGameOptions", function(player, gameTable, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions)
        if gameTable:updateGameOptions(player.UserId, nonDefaultGameOptions) then
            sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Event to leave a table.
    createGameTableRemoteEvent(tableEventsFolder, "LeaveTable", function(player, gameTable)
        handleUserLeavingTable(player.UserId, gameTable)
    end)

    -- Start playing the game.
    createGameTableRemoteEvent(tableEventsFolder, "StartGame", function(player, gameTable)
        Utils.debugPrint("TablePlaying", "Doug: ServerEventManager StartGame tableId = ", gameTable:getTableDescription().tableId)
        if gameTable:startGame(player.UserId) then
            Utils.debugPrint("TablePlaying", "Doug: ServerEventManager StartGame startGame worked")
            sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription(), gameTable:getGameInstanceGUID())
        end
    end)

    -- Event for host to end the game currently playing at a table.
    createGameTableRemoteEvent(tableEventsFolder, "EndGame", function(player, gameTable)
        if gameTable:endGame(player.UserId) then
            sendToAllPlayersInExperience("HostAbortedGame", gameTable:getTableDescription().tableId)
            sendToAllPlayersInExperience("TableUpdated", gameTable:getTableDescription())
        end
    end)

    if RunService:IsStudio() then
        addMockEventHandlers(tableEventsFolder, createTableHandler)
    end
end

local function setupServerToClientEvents(tableEventsFolder: Folder)
    -- Notification that a new table was created.
    createGameTableRemoteEvent(tableEventsFolder, "TableCreated")
    -- Notification that a table was destroyed.
    createGameTableRemoteEvent(tableEventsFolder, "TableDestroyed")
    -- Notification that something about this table has changed.
    createGameTableRemoteEvent(tableEventsFolder, "TableUpdated")
    -- Notification that host has ended game early.
    createGameTableRemoteEvent(tableEventsFolder, "HostAbortedGame")
end

--[[
Startup Function making all the events where client sends to server.
]]
ServerEventManagement.setupRemoteCommunications = function(tableEventsFolder: Folder, tableFunctionsFolder: Folder, createTableHandler: (CommonTypes.UserId, CommonTypes.GameId, boolean) -> nil)
    assert(tableEventsFolder, "tableEventsFolder should be defined")
    assert(tableFunctionsFolder, "tableFunctionsFolder should be defined")
    -- FIXME(dbanks)
    -- Changed this to just emit a signal.
    assert(createTableHandler, "createTableHandler should be defined")

    -- Make remote function called by client to get all tables.
    makeFetchTableDescriptionsByTableIdRemoteFunction(tableFunctionsFolder)

    setupClientToServerEvents(tableEventsFolder, createTableHandler)
    setupServerToClientEvents(tableEventsFolder)
end

ServerEventManagement.setupRemoteCommunicationsForGame = function(gameInstanceGUID: CommonTypes.GameInstanceGUID)
    -- Notification that player has left a table.
    ServerEventUtils.createGameEventFolder(gameInstanceGUID)
    ServerEventUtils.createGameFunctionFolder(gameInstanceGUID)
    ServerEventUtils.createGameRemoteEvent(gameInstanceGUID, "PlayerLeftTable")
end

ServerEventManagement.removeServerToClientEventsForGame = function(gameInstanceGUID: CommonTypes.GameInstanceGUID)
    ServerEventUtils.removeGameEventsFolder(gameInstanceGUID)
end

return ServerEventManagement
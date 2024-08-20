--[[
Logic for creating and handling events on the server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

local Cryo = require(ReplicatedStorage.Cryo)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local GameTable = require(RobloxBoardGameServer.Classes.GameTable)

local ServerEventManagement = {}

local _mockUserId = 2000000

local function getNextMockUserId()
    _mockUserId = _mockUserId + 1
    return _mockUserId
end

-- Notify every player of an event.
local function sendToAllPlayers(eventName, data)
    local tableEvents = ReplicatedStorage:FindFirstChild("TableEvents")
    assert(tableEvents, "TableEvents not found")
    local event = tableEvents:FindFirstChild(eventName)
    assert(event, "Event not found: " .. eventName)
    event:FireAllClients(data)
end

local function getOrMakeRepicatedStorageFolder(folderName)
    local folder = ReplicatedStorage:FindFirstChild(folderName)
    if folder then
        assert(folder:IsA("Folder"), "Expected folder, got " .. folder.ClassName)
    else
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = ReplicatedStorage
    end
    return folder
end

--[[
Adding a remote event on server.
If no folder with given name, make one.
Make event with given name and handler.
]]
local function createRemoteEvent(parentFolderName, eventName, onServerEvent)
    local folder = getOrMakeRepicatedStorageFolder(parentFolderName)
    local event = Instance.new("RemoteEvent")
    event.Name = eventName
    event.Parent = folder
    if onServerEvent then
        event.OnServerEvent:Connect(onServerEvent)
    end
end

-- Convenience function for creating a remote event that is specific to a game table.
-- The event comes in with tableId as first argument (after player).
-- Iff the table id is legit, the event is passed to the handler with the game table as the second argument.
local function createGameTableRemoteEvent(eventName: string, onServerEventForTable: (Player, any) -> nil)
    local augmentedOnServerEvent
    if onServerEventForTable then
        augmentedOnServerEvent = function(player, tableId: CommonTypes.TableId, ...)
            local gameTable = GameTable.getGameTable(tableId)
            if not gameTable then
                return
            end
            onServerEventForTable(player, gameTable, ...)
        end
    end
    createRemoteEvent("TableEvents", eventName, augmentedOnServerEvent)
end

local function makeFetchTableDescriptionsByTableIdRemoteFunction()
    -- Remote function to fetch all tables.
    local folder = getOrMakeRepicatedStorageFolder("TableFunctions")
    local remoteFunction = Instance.new("RemoteFunction")
    remoteFunction.Parent = folder
    remoteFunction.Name = "FetchTableDescriptionsByTableId"
    remoteFunction.OnServerInvoke = function(_): CommonTypes.TableDescriptionsByTableId
        local gameTables = GameTable.getAllGameTables()
        local retVal = {} :: CommonTypes.TableDescriptionsByTableId
        for tableId, gameTable in gameTables do
            retVal[tableId] = gameTable:getTableDescription()
        end
        return retVal
    end
end

--[[
Startup Function making all the events where client sends to server.
]]
ServerEventManagement.createClientToServerEvents = function()
    -- Make remote function called by client to get all tables.
    makeFetchTableDescriptionsByTableIdRemoteFunction()

    -- Events sent from client to server.
    -- Event to create a new table.
    createRemoteEvent("TableEvents", "CreateNewTable", function(player, gameId, isPublic)
        -- Try to make the table. It will fail if something is wrong:
        -- * gameId is invalid.
        -- * player is already in a table.
        local gameTable = GameTable.createNewTable(player.UserId, gameId, isPublic)
        if not gameTable then
            return
        end

        local tableDescription = gameTable:getTableDescription()

        -- Broadcast the new table to all players
        sendToAllPlayers("TableCreated", tableDescription)
    end)

    -- Event to destroy a table.
    createGameTableRemoteEvent("DestroyTable", function(player, gameTable)
        assert(gameTable, "Should have a gameTable")
        assert(gameTable.tableDescription, "Should have a tableDescription")
        local gameTableId = gameTable:getTableId()
        assert(gameTableId, "Should have a gameTableId")

        if gameTable:destroyTable(player.UserId) then
            sendToAllPlayers("TableDestroyed", gameTableId)
        end
    end)

    -- Event to join a table.
    createGameTableRemoteEvent("JoinTable", function(player, gameTable)
        if gameTable:joinTable(player.UserId) then
            sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Event to invite someone to table.
    createGameTableRemoteEvent("InvitePlayerToTable", function(player, gameTable, inviteeId)
        if gameTable:inviteToTable(player.UserId, inviteeId) then
            sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Event to remove someone to table.
    createGameTableRemoteEvent("RemoveGuestFromTable", function(player, gameTable, userId)
        if gameTable:removeGuestFromTable(player.UserId, userId) then
            sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Event to remove an invite from a table.
    createGameTableRemoteEvent("RemoveInviteForTable", function(player, gameTable, userId)
        Utils.debugPrint("RemoveInvite", "Doug: RemoveInviteForTable 001")
        if gameTable:removeInviteForTable(player.UserId, userId) then
            Utils.debugPrint("RemoveInvite", "Doug: RemoveInviteForTable 002")
            sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Event to leave a table.
    createGameTableRemoteEvent("LeaveTable", function(player, gameTable)
        if gameTable:leaveTable(player.UserId) then
            sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Start playing the game.
    createGameTableRemoteEvent("StartGame", function(player, gameTable)
        if gameTable:startGame(player.UserId) then
            sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- The game is now over.
    createGameTableRemoteEvent("EndGame", function(player, gameTable)
        if gameTable:endGame(player.UserId) then
            sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Transition from "all done" back to "waiting for players".
    createGameTableRemoteEvent("ReplayGame", function(player, gameTable)
        if gameTable:transitionFromEndToReplay(player.UserId) then
            sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
        end
    end)

    if RunService:IsStudio() then
        createGameTableRemoteEvent("AddMockMember", function(_, gameTable)
            Utils.debugPrint("Mocks", "Doug: Adding mock member")
            if not gameTable.tableDescription.isPublic then
                return
            end
            if not gameTable:joinTable(getNextMockUserId()) then
                return
            end
            sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
        end)

        createGameTableRemoteEvent("AddMockInvite", function(player, gameTable)
            Utils.debugPrint("Mocks", "Doug; Adding mock invite")
            if gameTable.tableDescription.isPublic then
                return
            end
            if not gameTable:inviteToTable(player.UserId, getNextMockUserId()) then
                Utils.debugPrint("Mocks", "Doug: AddMockInvite: invite to table failed")
                return
            end
            Utils.debugPrint("Mocks", "Doug: AddMockInvite: broadcasting new table.")
            sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
        end)

        createGameTableRemoteEvent("MockInviteAcceptance", function(_, gameTable)
            if gameTable.tableDescription.isPublic then
                return
            end
            local keys = Cryo.Dictionary.keys(gameTable.tableDescription.invitedUserIds)
            if #keys == 0 then
                return
            end
            local accepteeId = keys[1]
            if gameTable:joinTable(accepteeId) then
                sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
            end
        end)

        -- Destroy all Mock Tables.
        createRemoteEvent("TableEvents", "DestroyAllMockTables", function(player)
            Utils.debugPrint("Mocks", "Doug; Destroying all Mock Tables")
            local allTables = GameTable.getAllGameTables()
            for tableId, gameTable in allTables do
                if gameTable.isMock then
                    gameTable:destroyTable(player.UserId)
                    sendToAllPlayers("TableDestroyed", tableId)
                end
            end
        end)

        -- Make a mock table.
        createRemoteEvent("TableEvents", "MockTable", function(player, isPublic)
            Utils.debugPrint("Mocks", "Doug; Mocking Table")
            -- Make a random table.
            -- Get a random game id.
            local gameDetailsByGameId = GameDetails.getAllGameDetails()
            local gameId = Utils.getRandomKey(gameDetailsByGameId)

            local mockUserId = getNextMockUserId()
            local gameTable = GameTable.createNewTable(mockUserId, gameId, isPublic)
            if not gameTable then
                Utils.debugPrint("Mocks", "Doug; Mocking Table: no table")
                return
            end

            -- If not public, invite the player who sent the mock.
            if not isPublic then
                gameTable:inviteToTable(player.UserId, mockUserId)
            end

            gameTable.isMock = true

            local tableDescription = gameTable:getTableDescription()

            Utils.debugPrint("Mocks", "Doug; Mocking Table: broadcasting TableCreated tableDescription = ", tableDescription)

            -- Broadcast the new table to all players
            sendToAllPlayers("TableCreated", tableDescription)
        end)
    end
end

ServerEventManagement.createServerToClientEvents = function()
    -- Notification that a new table was created.
    createGameTableRemoteEvent("TableCreated")
    -- Notification that a table was destroyed.
    createGameTableRemoteEvent("TableDestroyed")
    -- Notification that something about this table has changed.
    createGameTableRemoteEvent("TableUpdated")
end


return ServerEventManagement
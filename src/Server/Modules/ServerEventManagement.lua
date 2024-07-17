--[[
Logic for creating and handling events on the server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local GameTable = require(RobloxBoardGameServer.Classes.GameTable)

local ServerEventManagement = {}

-- Notify every player of an event.
local function sendToAllPlayers(eventName, data)
    local event = game.ReplicatedStorage[eventName]
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
        -- Add some fake delay so I can see the loading screen...
        for i = 1, 10 do
            task.wait(1)
            print("Doug: fake waiting ", i)
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
        -- Does the game exist?
        local gameDetails = GameDetails.getGameDetails(gameId)
        if not gameDetails then
            return
        end

        -- Try to make the table. It will fail if something is wrong (e.g. the prospective
        -- host is already in a table).
        local gameTable = GameTable.createNewTable(player.UserId, gameDetails, isPublic)
        if not gameTable then
            return
        end

        -- Broadcast the new table to all players
        sendToAllPlayers("TableCreated", gameTable:getTableDescription())
    end)

    -- Event to destroy a table.
    createGameTableRemoteEvent("DestroyTable", function(player, gameTable)
        local gameTableId = gameTable.id
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
        if gameTable:removeInviteForTable(player.UserId, userId) then
            sendToAllPlayers("TableUpdated", gameTable:getTableDescription())
        end
    end)

    -- Event to leave a table.
    createGameTableRemoteEvent("LeaveTable", function(player, gameTable)
        if gameTable:leave(player.UserId) then
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
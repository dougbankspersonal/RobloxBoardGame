--[[
Utils around RemoteEvents and Functions which should only be called on Server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local EventUtils = require(RobloxBoardGameShared.Modules.EventUtils)
local TableDescription = require(RobloxBoardGameShared.Modules.TableDescription)
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local TableDescripton = require(RobloxBoardGameShared.Modules.TableDescription)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local GameTablesStorage = require(RobloxBoardGameServer.Modules.GameTablesStorage)

local ServerEventUtils = {}

local _mockUserId = 2000000

-- Whenever we need an id for some mock user, call this.
-- Gives a unique valid id each time.
function ServerEventUtils.generateMockUserId()
    _mockUserId = _mockUserId + 1
    return _mockUserId
end

-- Make a folder with the given name under ReplicatedStorage.
-- It's an error to call this if a folder with this name already exists.
function ServerEventUtils.createFolder(folderName: string): Folder
    local folder = EventUtils.getReplicatedStorageFolder(folderName)
    assert(folder == nil, "Folder already exists: " .. folderName)

    folder = Instance.new("Folder")
    folder.Name = folderName
    folder.Parent = ReplicatedStorage
    return folder
end

-- Create a folder under ReplicatedStorage to hold events for this particular game instance.
function ServerEventUtils.createGameEventFolder(gameInstanceGUID: CommonTypes.GameInstanceGUID): Folder
    local folderName = EventUtils.getGameEventFolderName(gameInstanceGUID)
    return ServerEventUtils.createFolder(folderName)
end

-- Create a folder under ReplicatedStorage to hold remote functions for this particular game instance.
function ServerEventUtils.createGameFunctionFolder(gameInstanceGUID: CommonTypes.GameInstanceGUID): Folder
    local folderName = EventUtils.getGameFunctionFolderName(gameInstanceGUID)
    return ServerEventUtils.createFolder(folderName)
end

-- Game is over: destroy folder holding events for this game.
function ServerEventUtils.removeGameEventsFolder(gameInstanceGUID: CommonTypes.GameInstanceGUID)
    local folder = EventUtils.getFolderForGameEvents(gameInstanceGUID)
    assert(folder, "Folder not found: " .. gameInstanceGUID)
    if folder then
        folder:Destroy()
    end
end

-- Game is over: destroy folder holding remote functions for this game.
function ServerEventUtils.removeGameFunctionsFolder(gameInstanceGUID: CommonTypes.GameInstanceGUID)
    local folder = EventUtils.getFolderForGameFunctions(gameInstanceGUID)
    assert(folder, "Folder not found: " .. gameInstanceGUID)
    if folder then
        folder:Destroy()
    end
end


-- Make a remote event with given name in given folder.
-- If this event is fired on client sent to server, run the given callback.
function ServerEventUtils.createRemoteEvent(folder: Folder, eventName: string, opt_onServerEvent): RBXScriptConnection?
    assert(folder, "Folder not found")

    -- This event should not exist yet.
    local existingEvent = folder:FindFirstChild(eventName)
    assert(existingEvent == nil, "Event already exists: " .. eventName)

    local event = Instance.new("RemoteEvent")
    event.Name = eventName
    event.Parent = folder
    local opt_connection: RBXScriptConnection?
    if opt_onServerEvent then
        opt_connection = event.OnServerEvent:Connect(opt_onServerEvent)
    end
    return opt_connection
end

local eventConnectionsByGameInstanceGUID: {[CommonTypes.GameInstanceGUID]: {RBXScriptConnection}} = {}

--[[
Make a remote event that's specific to the given game instance.
Only parties in game should send messages to the event, and only parties in the game should listen to it.
]]
function ServerEventUtils.createGameRemoteEvent(gameInstanceGUID: CommonTypes.GameInstanceGUID, eventName: string, onServerEventForGame)
    local folder = EventUtils.getFolderForGameEvents(gameInstanceGUID)
    local connection = ServerEventUtils.createRemoteEvent(folder, eventName, function(player, ...)
        -- parties not in the game have no business sending messages to this event.
        local gameTable = GameTablesStorage.getGameTableByGameInstanceGUID(gameInstanceGUID)
        if not gameTable then
            return
        end
        if not gameTable:isMember(player.UserId) then
            return
        end
        onServerEventForGame(player, ...)
    end)
    local connections = eventConnectionsByGameInstanceGUID[gameInstanceGUID] or {}
    table.insert(connections, connection)
end

-- Any Connections we made listening to events for a particular game, disconnect.
function ServerEventUtils.removeGameEventConnections(gameInstanceGUID: CommonTypes.GameInstanceGUID)
    local connections = eventConnectionsByGameInstanceGUID[gameInstanceGUID]
    if not connections then
        return
    end
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    eventConnectionsByGameInstanceGUID[gameInstanceGUID] = nil
end

--[[
Make a remote function with given name in given folder.
When function is triggered on client, hit the callback.
]]
function ServerEventUtils.createRemoteFunction(folder: Folder, functionName: string, onServerInvoke)
    assert(folder, "Folder not found")
    -- This function should not exist yet.
    local existingFunction = folder:FindFirstChild(functionName)
    assert(existingFunction == nil, "Function already exists: " .. functionName)

    local f = Instance.new("RemoteFunction")
    f.Name = functionName
    f.Parent = folder
    f.OnServerInvoke = onServerInvoke
end

--[[
Make a remote function that's specific to the given game instance.
Only parties in game should send messages to the event, and only parties in the game should listen to it.
]]
function ServerEventUtils.createGameRemoteFunction(gameInstanceGUID: CommonTypes.GameInstanceGUID, functionName: string, onServerInvoke)
    local folder = EventUtils.getFolderForGameFunctions(gameInstanceGUID)
    assert(folder, "Folder not found: " .. gameInstanceGUID)
    ServerEventUtils.createRemoteFunction(folder, functionName, onServerInvoke)
end

--[[
On server, fire this event for just these players.
]]
function ServerEventUtils.sendEventForPlayers(event: RemoteEvent, players: {Players}, ...)
    assert(event, "Event not found")
    for _, player in ipairs(players) do
        event:FireClient(player, ...)
    end
end

--[[
Server is sending an event only to players in this game.
]]
function ServerEventUtils.sendEventForPlayersInGame(tableDescription: CommonTypes.TableDescription, eventName: string, ...)
    TableDescripton.sanityCheck(tableDescription)
    assert(eventName, "eventName not found")
    local eventForGame = EventUtils.getRemoteEventForGame(tableDescription.gameInstanceGUID, eventName)
    assert(eventForGame, "Event not found")
    local players = TableDescription.getPlayers(tableDescription)
    ServerEventUtils.sendEventForPlayers(eventForGame, players, ...)
end

function ServerEventUtils.setupRemoteCommunicationsForGame(gameInstanceGUID: CommonTypes.GameInstanceGUID)
    -- Notification that player has left a table.
    ServerEventUtils.createGameEventFolder(gameInstanceGUID)
    ServerEventUtils.createGameFunctionFolder(gameInstanceGUID)
    ServerEventUtils.createGameRemoteEvent(gameInstanceGUID, EventUtils.EventNamePlayerLeftTable)
    ServerEventUtils.createGameRemoteEvent(gameInstanceGUID, EventUtils.EventNameNotifyThatHostEndedGame)
end

return ServerEventUtils

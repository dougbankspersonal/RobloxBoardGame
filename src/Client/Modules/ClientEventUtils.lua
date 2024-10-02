--[[
Utils for sending and receiving messages, client-side.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local EventUtils = require(RobloxBoardGameShared.Modules.EventUtils)

local ClientEventUtils = {}

local clientEventConnectionsByGameInstanceGUID = {} :: {[CommonTypes.GameInstanceGUID]: {RBXScriptConnection}}

-- We are listening to some game-specific event.
-- We store it so when game is over we can delete all the connections together.
function ClientEventUtils.storeConnectionForGame(gameInstanceGUID: CommonTypes.GameInstanceGUID, connection: RBXScriptConnection)
    local connections = clientEventConnectionsByGameInstanceGUID[gameInstanceGUID]
    if not connections then
        connections = {}
        clientEventConnectionsByGameInstanceGUID[gameInstanceGUID] = connections
    end
    table.insert(connections, connection)
end

-- Connect to an event for a particular game.
-- This assumes that the event is living under the game-specific folder defined in these util classes.
function ClientEventUtils.connectToGameEvent(gameInstanceGUID: CommonTypes.GameInstanceGUID, eventName: string, callback: (CommonTypes.GameInstanceGUID, any) -> nil)
    local folder = EventUtils.getFolderForGameEvents(gameInstanceGUID)
    assert(folder, "Folder not found for gameInstanceGUID: " .. gameInstanceGUID)
    local event = folder:WaitForChild(eventName)
    assert(event, "Event not found: " .. eventName)
    local connection = event.OnClientEvent:Connect(function(...)
        callback(gameInstanceGUID, ...)
    end)
    ClientEventUtils.storeConnectionForGame(gameInstanceGUID, connection)
end

-- This game is over.
-- Any connections we had listening to events belonging the game can be dropped.
ClientEventUtils.removeGameEventConnections = function(gameInstanceGUID: CommonTypes.GameInstanceGUID)
    assert(gameInstanceGUID, "gameInstanceGUID must be provided")

    local connections = clientEventConnectionsByGameInstanceGUID[gameInstanceGUID]
    if not connections then
        return
    end
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    clientEventConnectionsByGameInstanceGUID[gameInstanceGUID] = nil
end

return ClientEventUtils

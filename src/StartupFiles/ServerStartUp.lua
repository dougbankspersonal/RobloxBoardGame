-- Main function to call when starting your board game.
-- Call from a Server script ASAP.
-- Creates events, listens for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommonTypes = require(script.Parent.Parent.Types.CommonTypes)
local GameTable = require(script.Parent.Parent.Classes.GameTable)
local GameDetails =  require(script.Parent.Parent.Globals.GameDetails)

local ServerStartUp = {}
local gameDetailsList = {}

function createRemoteEvent(parentFolderName, eventName, onServerEvent)
    print("Doug: createRemoteEvent")
    print("Doug: parentFolderName = ", parentFolderName)
    print("Doug: eventName = ", eventName)
    local folder = ReplicatedStorage:FindFirstChild(parentFolderName)
    if not folder then 
        folder = Instance.new("Folder")
        folder.Name = parentFolderName
        folder.Parent = ReplicatedStorage
    end
    local event = Instance.new("RemoteEvent")
    event.Name = eventName
    event.Parent = folder
    if onServerEvent then 
        event.OnServerEvent:Connect(onServerEvent)
    end
end

function createGameTableRemoteEvent(eventName, onServerEvent)
    local augmentedOnServerEvent
    if onServerEvent then 
        augmentedOnServerEvent = function(player, tableId, ...)
            local gameTable = GameTable.getGameTable(tableId)
            if not gameTable then
                return
            end
            onServerEvent(player, gameTable, ...)
        end
    end
    createRemoteEvent("TableEvents", eventName, augmentedOnServerEvent)
end

function sendToAllPlayers(eventName, data)
    local event = game.ReplicatedStorage[eventName]
    assert(event, "Event not found: " .. eventName)
    event:FireAllClients(data)
end

function createClientToServerEvents()
    -- events sent from client to server.
    createRemoteEvent("TableEvents", "CreateNewGameTable", function(player, gameId, public)
        -- Does the game exist?
        local gameDetails = gameDetailsList[gameId]
        if not gameDetails then
            return
        end

        -- Player can host a table?
        local gameTable = GameTable.createNewTable(player.UserId, gameDetails, public)
        if not gameTable then 
            return 
        end

        -- Broadcast the new table to all players
        sendToAllPlayers("TableCreated", gameTable:GetSummary())        
    end)

    createGameTableRemoteEvent("DestroyTable", function(player, gameTable)
        local gameTableId = gameTable.id
        if gameTable:destroy(player.UserId) then
            sendToAllPlayers("TableDestroyed", gameTableId)       
        end
    end)

    createGameTableRemoteEvent("JoinGameTable", function(player, gameTable)
        if gameTable:join(player.UserId) then
            sendToAllPlayers("TableUpdated", gameTable:GetSummary())       
        end
    end)

    createGameTableRemoteEvent("InviteToTable", function(player, gameTable, inviteeId)
        if gameTable:invite(player.UserId, inviteeId) then 
            sendToAllPlayers("TableUpdated", gameTable:GetSummary()) 
        end       
    end)

    createGameTableRemoteEvent("LeaveTable", function(player, gameTable)
        if gameTable:leave(player.UserId) then 
            sendToAllPlayers("TableUpdated", gameTable:GetSummary()) 
        end       
    end)

    createGameTableRemoteEvent("StartGame", function(player, gameTable)
        if gameTable:startGame(player.UserId) then 
            sendToAllPlayers("TableUpdated", gameTable:GetSummary()) 
        end       
    end)

    createGameTableRemoteEvent("EndGame", function(player, gameTable)
        if gameTable:endGame(player.UserId) then 
            sendToAllPlayers("TableUpdated", gameTable:GetSummary()) 
        end       
    end)

    createGameTableRemoteEvent("ReplayWithCurrentMembers", function(player, gameTable)
        if gameTable:startGame(player.UserId) then 
            sendToAllPlayers("TableUpdated", gameTable:GetSummary()) 
        end       
    end)
end

function createServerToClientEvents()
    -- Events sent from server to clients.
    createGameTableRemoteEvent("TableCreated")
    createGameTableRemoteEvent("TableDestroyed")
    createGameTableRemoteEvent("TableUpdated")
end

function createRemoteEvents()
    createClientToServerEvents()
    createServerToClientEvents()
end

function ServerStartUp.StartUp(_allGameDetails: {CommonTypes.GameDetails}): nil
    GameDetails.setAllGameDetails(_allGameDetails)
    createRemoteEvents()
end

return ServerStartUp
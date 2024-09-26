--[[
Useful functions for how we handle events.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local EventUtils = {}

EventUtils.TableEventsFolderName = "TableEvents"
EventUtils.TableFunctionsFolderName = "TableFunctions"

function EventUtils.getGameEventFolderName(gameInstanceGUID: CommonTypes.GameInstanceGUID): string
    return "GameEvents_" .. gameInstanceGUID
end

function EventUtils.getGameFunctionFolderName(gameInstanceGUID: CommonTypes.GameInstanceGUID): string
    return "GameFunctions_" .. gameInstanceGUID
end

function EventUtils.getReplicatedStorageFolder(folderName: string): Folder?
    local folder = ReplicatedStorage:FindFirstChild(folderName)
    if folder then
        assert(folder:IsA("Folder"), "Expected folder, got " .. folder.ClassName)
    end
    return folder
end

function EventUtils.getFolderForGameEvents(gameInstanceGUID: CommonTypes.GameInstanceGUID): Folder?
    local folderName = EventUtils.getGameEventFolderName(gameInstanceGUID)
    return EventUtils.getReplicatedStorageFolder(folderName)
end

function EventUtils.getFolderForGameFunctions(gameInstanceGUID: CommonTypes.GameInstanceGUID): Folder?
    local folderName = EventUtils.getGameFunctionFolderName(gameInstanceGUID)
    return EventUtils.getReplicatedStorageFolder(folderName)
end

function EventUtils.getRemoteEventForGame(gameInstanceGUID: CommonTypes.GameInstanceGUID, eventName: string): RemoteEvent
    assert(gameInstanceGUID, "gameInstanceGUID not set")
    assert(eventName, "eventName not set")
    local folder = EventUtils.getFolderForGameEvents(gameInstanceGUID)
    assert(folder, "Folder not found for gameInstanceGUID: " .. gameInstanceGUID)
    local event = folder:WaitForChild(eventName)
    assert(event, "Event not found: " .. eventName)
    return event
end

function EventUtils.getRemoteFunctionForGame(gameInstanceGUID: CommonTypes.GameInstanceGUID, functionName: string): RemoteFunction
    assert(gameInstanceGUID, "gameInstanceGUID not set")
    assert(functionName, "functionName not set")
    local folder = EventUtils.getFolderForGameFunctions(gameInstanceGUID)
    assert(folder, "Folder not found for gameInstanceGUID: " .. gameInstanceGUID)
    local event = folder:WaitForChild(functionName)
    assert(event, "Function not found: " .. functionName)
    return event
end

return EventUtils

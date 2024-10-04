--[[
Useful functions for how we handle events.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local EventUtils = {}

EventUtils.FolderNameTableEvents = "TableEvents"
EventUtils.FolderNameTableFunctions = "TableFunctions"

--[[
Client -> Server event names.
]]
-- External to game: these are about table creation, config, destruction.
EventUtils.EventNameCreateNewTable  = "CreateNewTable"
EventUtils.EventNameDestroyTable = "DestroyTable"

EventUtils.EventNameStartGame = "StartGame"
EventUtils.EventNameEndGame = "EndGame"

EventUtils.EventNameLeaveTable = "LeaveTable"

EventUtils.EventNameJoinTable = "JoinTable"
EventUtils.EventNameInvitePlayerToTable = "InvitePlayerToTable"
EventUtils.EventNameSetTableGameOptions = "SetTableGameOptions"
EventUtils.EventNameRemoveInviteForTable = "RemoveInviteForTable"
EventUtils.EventNameSetTableInvites = "SetTableInvites"
EventUtils.EventNameRemoveGuestFromTable = "RemoveGuestFromTable"

-- Mock events.
EventUtils.EventNameCreateMockTable = "CreateMockTable"
EventUtils.EventNameAddMockMember = "AddMockMember"
EventUtils.EventNameDestroyAllMockTables = "DestroyAllMockTables"
EventUtils.EventNameAddMockInvite = "AddMockInvite"
EventUtils.EventNameMockInviteAcceptance = "MockInviteAcceptance"
EventUtils.EventNameMockStartGame = "MockStartGame"
EventUtils.EventNameMockNonHostMemberLeaves = "MockNonHostMemberLeaves"
EventUtils.EventNameMockHostDestroysTable = "MockHostDestroysTable"

--[[
Client -> Server function names.
]]
EventUtils.FunctionNameFetchTableDescriptionsByTableId = "FetchTableDescriptionsByTableId"

--[[
Server -> Client evnet names.
]]
-- Universal: everyone gets these.
EventUtils.EventNameTableUpdated = "TableUpdated"
EventUtils.EventNameTableDestroyed = "TableDestroyed"
EventUtils.EventNameTableCreated = "TableCreated"
-- Game-specific: only for players in a particular game.
EventUtils.EventNamePlayerLeftTable = "PlayerLeftTable"
EventUtils.EventNameNotifyThatHostEndedGame = "NotifyThatHostEndedGame"

-- Get the name of the folder holding events for a particular game instance.
function EventUtils.getGameEventFolderName(gameInstanceGUID: CommonTypes.GameInstanceGUID): string
    return "GameEvents_" .. gameInstanceGUID
end

-- Get the name of the folder holding remote functions for a particular game instance.
function EventUtils.getGameFunctionFolderName(gameInstanceGUID: CommonTypes.GameInstanceGUID): string
    return "GameFunctions_" .. gameInstanceGUID
end

-- Get a child folder of ReplicatedStorage by name.
function EventUtils.getReplicatedStorageFolder(folderName: string): Folder?
    local folder = ReplicatedStorage:FindFirstChild(folderName)
    if folder then
        assert(folder:IsA("Folder"), "Expected folder, got " .. folder.ClassName)
    end
    return folder
end

-- Get the folder holding remote events for a particular game instance.
function EventUtils.getFolderForGameEvents(gameInstanceGUID: CommonTypes.GameInstanceGUID): Folder?
    local folderName = EventUtils.getGameEventFolderName(gameInstanceGUID)
    return EventUtils.getReplicatedStorageFolder(folderName)
end

-- Get the folder holding remote functions for a particular game instance.
function EventUtils.getFolderForGameFunctions(gameInstanceGUID: CommonTypes.GameInstanceGUID): Folder?
    local folderName = EventUtils.getGameFunctionFolderName(gameInstanceGUID)
    return EventUtils.getReplicatedStorageFolder(folderName)
end

-- Get the named remote event for a particular game instance.
function EventUtils.getRemoteEventForGame(gameInstanceGUID: CommonTypes.GameInstanceGUID, eventName: string): RemoteEvent
    assert(gameInstanceGUID, "gameInstanceGUID not set")
    assert(eventName, "eventName not set")
    local folder = EventUtils.getFolderForGameEvents(gameInstanceGUID)
    assert(folder, "Folder not found for gameInstanceGUID: " .. gameInstanceGUID)
    local event = folder:WaitForChild(eventName)
    assert(event, "Event not found: " .. eventName)
    return event
end

-- Get the named remote function for a particular game instance.
function EventUtils.getRemoteFunctionForGame(gameInstanceGUID: CommonTypes.GameInstanceGUID, functionName: string): RemoteFunction
    assert(gameInstanceGUID, "gameInstanceGUID not set")
    assert(functionName, "functionName not set")
    local folder = EventUtils.getFolderForGameFunctions(gameInstanceGUID)
    assert(folder, "Folder not found for gameInstanceGUID: " .. gameInstanceGUID)
    local fn = folder:WaitForChild(functionName)
    assert(fn, "Function not found: " .. functionName)
    return fn
end

return EventUtils

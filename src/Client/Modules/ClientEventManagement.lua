--[[
Client side event management: listening to events from the server, sending events to server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local EventUtils = require(RobloxBoardGameShared.Modules.EventUtils)
local TableDescription = require(RobloxBoardGameShared.Modules.TableDescription)

local ClientEventManagement = {}

local tableEvents = ReplicatedStorage:WaitForChild(EventUtils.TableEventsFolderName)
if not tableEvents then
    assert(false, "TableEvents missing")
    return
end

local tableFunctions = ReplicatedStorage:WaitForChild(EventUtils.TableFunctionsFolderName)
if not tableFunctions then
    assert(false, "TableFunctions missing")
    return
end

-- Every new player starts in the table selection lobby.
ClientEventManagement.fetchTableDescriptionsByTableIdAsync = function(): CommonTypes.TableDescriptionsByTableId
    local fetchTableDescriptionsByTableIdRemoteFunction = tableFunctions:WaitForChild("FetchTableDescriptionsByTableId")
    if not fetchTableDescriptionsByTableIdRemoteFunction then
        assert(false, "fetchTableDescriptionsByTableIdRemoteFunction remote function missing")
        return {} :: CommonTypes.TableDescriptionsByTableId
    end
    local raw_tableDescriptionsByTableId = fetchTableDescriptionsByTableIdRemoteFunction:InvokeServer()
    -- Sanitize right away.
    local clean_raw_tableDescriptionsByTableId = TableDescription.sanitizeTableDescriptionsByTableId(raw_tableDescriptionsByTableId)
    return clean_raw_tableDescriptionsByTableId
end

local setupMockEventFunctions = function()
    assert(RunService:IsStudio(), "setupMockEventFunctions should only be called in Studio")

    ClientEventManagement.mockTable = function(isPublic: boolean, joined: boolean, isHost: boolean)
        local event = ReplicatedStorage.TableEvents:WaitForChild("MockTable")
        assert(event, "MockTable event missing")
        event:FireServer(isPublic, joined, isHost)
    end

    ClientEventManagement.destroyAllMockTables = function()
        local event = ReplicatedStorage.TableEvents:WaitForChild("DestroyAllMockTables")
        assert(event, "DestroyAllMockTables event missing")
        event:FireServer()
    end

    ClientEventManagement.addMockMember = function(tableId: CommonTypes.TableId)
        local event = ReplicatedStorage.TableEvents:WaitForChild("AddMockMember")
        assert(event, "AddMockMember event missing")
        event:FireServer(tableId)
    end

    ClientEventManagement.mockMemberLeaves = function(tableId: CommonTypes.TableId)
        local event = ReplicatedStorage.TableEvents:WaitForChild("MockMemberLeaves")
        assert(event, "MockMemberLeaves event missing")
        Utils.debugPrint("Mocks", "firing mockMemberLeaves event")
        event:FireServer(tableId)
    end

    ClientEventManagement.addMockInvite = function(tableId: CommonTypes.TableId)
        local event = ReplicatedStorage.TableEvents:WaitForChild("AddMockInvite")
        assert(event, "AddMockInvite event missing")
        event:FireServer(tableId)
    end

    ClientEventManagement.mockInviteAcceptance = function(tableId: CommonTypes.TableId)
        local event = ReplicatedStorage.TableEvents:WaitForChild("MockInviteAcceptance")
        assert(event, "MockInviteAcceptance event missing")
        event:FireServer(tableId)
    end

    ClientEventManagement.mockStartGame = function(tableId: CommonTypes.TableId)
        local event = ReplicatedStorage.TableEvents:WaitForChild("MockStartGame")
        assert(event, "MockStartGame event missing")
        event:FireServer(tableId)
    end
end

ClientEventManagement.listenToServerEvents = function(onTableCreated: (tableDescription: CommonTypes.TableDescription) -> nil,
    -- FIXME(dbanks)
    -- Change all these to signals.
    onTableDestroyed: (tableId: CommonTypes.TableId) -> nil,
    onTableUpdated: (tableDescription: CommonTypes.TableDescription) -> nil,
    onHostAbortedGame: (tableId: CommonTypes.TableId) -> nil)

    assert(onTableCreated, "tableCreated must be provided")
    assert(onTableDestroyed, "tableDestroyed must be provided")
    assert(onTableUpdated, "tableUpdated must be provided")

    local event
    event = tableEvents:WaitForChild("TableCreated")
    assert(event, "TableCreated event missing")
    event.OnClientEvent:Connect(function(raw_tableDescription: CommonTypes.TableDescription)
        local clean_tableDescription = TableDescription.sanitizeTableDescription(raw_tableDescription)
        onTableCreated(clean_tableDescription)
    end)

    event = tableEvents:WaitForChild("TableDestroyed")
    assert(event, "TableDestroyed event missing")
    event.OnClientEvent:Connect(onTableDestroyed)

    event = tableEvents:WaitForChild("TableUpdated")
    assert(event, "TableUpdated event missing")
    event.OnClientEvent:Connect(function(raw_tableDescription: CommonTypes.TableDescription)
        local tableDescription = TableDescription.sanitizeTableDescription(raw_tableDescription)
        onTableUpdated(tableDescription)
    end)

    event = tableEvents:WaitForChild("HostAbortedGame")
    assert(event, "HostAbortedGame event missing")
    event.OnClientEvent:Connect(onHostAbortedGame)
end

local clientEventConnectionsByGameInstanceGUID = {} :: {[CommonTypes.GameInstanceGUID]: {RBXScriptConnection}}

ClientEventManagement.listenToServerEventsForActiveGame = function(gameInstanceGUID: CommonTypes.GameInstanceGUID,
    onPlayerLeftTable: (CommonTypes.UserId) -> nil)

    assert(gameInstanceGUID, "gameInstanceGUID must be provided")
    assert(onPlayerLeftTable, "onPlayerLeftTable must be provided")

    local event = EventUtils.getRemoteEventForGame(gameInstanceGUID, "PlayerLeftTable")
    assert(event, "PlayerLeftTable event missing")
    local connection = event.OnClientEvent:Connect(function(...)
        onPlayerLeftTable(...)
    end)
    clientEventConnectionsByGameInstanceGUID[gameInstanceGUID] = {
        connection,
    }
end

ClientEventManagement.cancelServerEventsForActiveGame = function(gameInstanceGUID: CommonTypes.GameInstanceGUID)
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

ClientEventManagement.createTable = function(gameId: CommonTypes.GameId, isPublic: boolean)
    local event = ReplicatedStorage.TableEvents:WaitForChild("CreateNewTable")
    assert(event, "CreateNewTable event missing")
    event:FireServer(gameId, isPublic)
end

ClientEventManagement.goToWaiting = function(tableId: CommonTypes.TableId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("GoToWaiting")
    assert(event, "GoToWaiting event missing")
    event:FireServer(tableId)
end

ClientEventManagement.destroyTable = function(tableId: CommonTypes.TableId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("DestroyTable")
    assert(event, "DestroyTable event missing")
    event:FireServer(tableId)
end

ClientEventManagement.joinTable = function(tableId: CommonTypes.TableId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("JoinTable")
    assert(event, "JoinTable event missing")
    event:FireServer(tableId)
end

ClientEventManagement.leaveTable = function(tableId: CommonTypes.TableId)
    Utils.debugPrint("Mocks", "firing leaveTable event")
    local event = ReplicatedStorage.TableEvents:WaitForChild("LeaveTable")
    assert(event, "LeaveTable event missing")
    event:FireServer(tableId)
end

ClientEventManagement.startGame = function(tableId: CommonTypes.TableId)
    Utils.debugPrint("TablePlaying", "Doug: ClientEventManagement.startGame tableId = ", tableId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("StartGame")
    assert(event, "StartGame event missing")
    event:FireServer(tableId)
end

ClientEventManagement.invitePlayerToTable = function(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("InvitePlayerToTable")
    assert(event, "InvitePlayerToTable event missing")
    event:FireServer(tableId, userId)
end

ClientEventManagement.setTableInvites = function(tableId: CommonTypes.TableId, userIds: {CommonTypes.UserId})
    local event = ReplicatedStorage.TableEvents:WaitForChild("SetTableInvites")
    assert(event, "SetTableInvites event missing")
    event:FireServer(tableId, userIds)
end

ClientEventManagement.removeGuestFromTable = function(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("RemoveGuestFromTable")
    assert(event, "RemoveGuestFromTable event missing")
    event:FireServer(tableId, userId)
end

ClientEventManagement.removeInviteForTable = function(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("RemoveInviteForTable")
    assert(event, "RemoveInviteForTable event missing")
    event:FireServer(tableId, userId)
end

ClientEventManagement.setTableGameOptions = function(tableId: CommonTypes.TableId, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions)
    local event = ReplicatedStorage.TableEvents:WaitForChild("SetTableGameOptions")
    assert(event, "SetTableGameOptions event missing")
    event:FireServer(tableId, nonDefaultGameOptions)
end

ClientEventManagement.endGame = function(tableId: CommonTypes.TableId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("EndGame")
    assert(event, "EndGame event missing")
    event:FireServer(tableId)
end

if RunService:IsStudio() then
    setupMockEventFunctions()
end

return ClientEventManagement
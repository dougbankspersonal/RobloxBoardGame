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

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local ClientEventUtils = require(RobloxBoardGameClient.Modules.ClientEventUtils)

local ClientEventManagement = {}

local tableEvents = ReplicatedStorage:WaitForChild(EventUtils.FolderNameTableEvents)
if not tableEvents then
    assert(false, "TableEvents missing")
    return
end

local tableFunctions = ReplicatedStorage:WaitForChild(EventUtils.FolderNameTableFunctions)
if not tableFunctions then
    assert(false, "TableFunctions missing")
    return
end

-- Every new player starts in the table selection lobby.
ClientEventManagement.fetchTableDescriptionsByTableIdAsync = function(): CommonTypes.TableDescriptionsByTableId
    local fetchTableDescriptionsByTableIdRemoteFunction = tableFunctions:WaitForChild(EventUtils.FunctionNameFetchTableDescriptionsByTableId)
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

    ClientEventManagement.createMockTable = function(isPublic: boolean, joined: boolean, isHost: boolean)
        local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameCreateMockTable)
        assert(event, "Event missing")
        event:FireServer(isPublic, joined, isHost)
    end

    ClientEventManagement.destroyTablesWithMockHost = function()
        local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameDestroyTablesWithMockHosts)
        assert(event, "Event missing")
        event:FireServer()
    end

    ClientEventManagement.addMockMember = function(tableId: CommonTypes.TableId)
        local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameAddMockMember)
        assert(event, "Event missing")
        event:FireServer(tableId)
    end

    ClientEventManagement.mockNonHostMemberLeaves = function(tableId: CommonTypes.TableId)
        local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameMockNonHostMemberLeaves)
        assert(event, "Event missing")
        Utils.debugPrint("Mocks", "ClientEventManagement.mockNonHostMemberLeaves")
        event:FireServer(tableId)
    end

    ClientEventManagement.mockHostDestroysTable = function(tableId: CommonTypes.TableId)
        local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameMockHostDestroysTable)
        assert(event, "Event missing")
        event:FireServer(tableId)
    end

    ClientEventManagement.addMockInvite = function(tableId: CommonTypes.TableId)
        local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameAddMockInvite)
        assert(event, "Event missing")
        event:FireServer(tableId)
    end

    ClientEventManagement.mockInviteAcceptance = function(tableId: CommonTypes.TableId)
        local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameMockInviteAcceptance)
        assert(event, "Event missing")
        event:FireServer(tableId)
    end

    ClientEventManagement.mockStartGame = function(tableId: CommonTypes.TableId)
        local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameMockStartGame)
        assert(event, "Event missing")
        event:FireServer(tableId)
    end
end

ClientEventManagement.listenToServerEvents = function(onTableCreated: (tableDescription: CommonTypes.TableDescription) -> nil,
    -- FIXME(dbanks)
    -- Change all these to signals.
    onTableDestroyed: (tableId: CommonTypes.TableId) -> nil,
    onTableUpdated: (tableDescription: CommonTypes.TableDescription) -> nil)

    assert(onTableCreated, "tableCreated must be provided")
    assert(onTableDestroyed, "tableDestroyed must be provided")
    assert(onTableUpdated, "tableUpdated must be provided")

    local event
    event = tableEvents:WaitForChild(EventUtils.EventNameTableCreated)
    assert(event, "TableCreated event missing")
    event.OnClientEvent:Connect(function(raw_tableDescription: CommonTypes.TableDescription)
        local clean_tableDescription = TableDescription.sanitizeTableDescription(raw_tableDescription)
        onTableCreated(clean_tableDescription)
    end)

    event = tableEvents:WaitForChild(EventUtils.EventNameTableDestroyed)
    assert(event, "TableDestroyed event missing")
    event.OnClientEvent:Connect(onTableDestroyed)

    event = tableEvents:WaitForChild(EventUtils.EventNameTableUpdated)
    assert(event, "TableUpdated event missing")
    event.OnClientEvent:Connect(function(raw_tableDescription: CommonTypes.TableDescription)
        Utils.debugPrint("GamePlay", "ClientEventManagement got TableUpdated")
        local tableDescription = TableDescription.sanitizeTableDescription(raw_tableDescription)
        onTableUpdated(tableDescription)
    end)
end

ClientEventManagement.listenToServerEventsForActiveGame = function(gameInstanceGUID: CommonTypes.GameInstanceGUID,
    onPlayerLeftTable: (CommonTypes.GameInstanceGUID, CommonTypes.UserId) -> nil,
    notifyThatHostEndedGame: (CommonTypes.GameInstanceGUID, CommonTypes.GameEndDetails) -> nil)

    assert(gameInstanceGUID, "gameInstanceGUID must be provided")
    assert(onPlayerLeftTable, "onPlayerLeftTable must be provided")

    ClientEventUtils.connectToGameEvent(gameInstanceGUID, EventUtils.EventNamePlayerLeftTable, onPlayerLeftTable)
    ClientEventUtils.connectToGameEvent(gameInstanceGUID, EventUtils.EventNameNotifyThatHostEndedGame, notifyThatHostEndedGame)
end

ClientEventManagement.createTable = function(gameId: CommonTypes.GameId, isPublic: boolean)
    local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameCreateNewTable)
    assert(event, "event missing")
    event:FireServer(gameId, isPublic)
end

ClientEventManagement.destroyTable = function(tableId: CommonTypes.TableId)
    local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameDestroyTable)
    assert(event, "event missing")
    event:FireServer(tableId)
end

ClientEventManagement.joinTable = function(tableId: CommonTypes.TableId)
    local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameJoinTable)
    assert(event, "event missing")
    event:FireServer(tableId)
end

ClientEventManagement.leaveTable = function(tableId: CommonTypes.TableId)
    Utils.debugPrint("Mocks", "firing leaveTable event")
    local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameLeaveTable)
    assert(event, "event missing")
    event:FireServer(tableId)
end

ClientEventManagement.startGame = function(tableId: CommonTypes.TableId)
    local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameStartGame)
    assert(event, "event missing")
    event:FireServer(tableId)
end

ClientEventManagement.invitePlayerToTable = function(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameInvitePlayerToTable)
    assert(event, "event missing")
    event:FireServer(tableId, userId)
end

ClientEventManagement.setTableInvites = function(tableId: CommonTypes.TableId, userIds: {CommonTypes.UserId})
    local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameSetTableInvites)
    assert(event, "event missing")
    event:FireServer(tableId, userIds)
end

ClientEventManagement.removeGuestFromTable = function(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameRemoveGuestFromTable)
    assert(event, "event missing")
    event:FireServer(tableId, userId)
end

ClientEventManagement.removeInviteForTable = function(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameRemoveInviteForTable)
    assert(event, "event missing")
    event:FireServer(tableId, userId)
end

ClientEventManagement.setTableGameOptions = function(tableId: CommonTypes.TableId, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions)
    local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameSetTableGameOptions)
    assert(event, "event missing")
    event:FireServer(tableId, nonDefaultGameOptions)
end

ClientEventManagement.endGame = function(tableId: CommonTypes.TableId)
    local event = ReplicatedStorage.TableEvents:WaitForChild(EventUtils.EventNameEndGame)
    assert(event, "event missing")
    Utils.debugPrint("GamePlay", "ClientEventManagement.endGame")
    event:FireServer(tableId)
end

if RunService:IsStudio() then
    setupMockEventFunctions()
end

return ClientEventManagement
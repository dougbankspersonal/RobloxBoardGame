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

local publicEvents = ReplicatedStorage:WaitForChild(EventUtils.FolderNamePublicEvents)
if not publicEvents then
    assert(false, EventUtils.FolderNamePublicEvents .. " missing")
    return
end

local tableFunctions = ReplicatedStorage:WaitForChild(EventUtils.FolderNamePublicFunctions)
if not tableFunctions then
    assert(false, EventUtils.FolderNamePublicFunctions .. " missing")
    return
end

-- Every new player starts in the table selection lobby.
function ClientEventManagement.fetchTableDescriptionsByTableIdAsync(): CommonTypes.TableDescriptionsByTableId
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

    function ClientEventManagement.createMockTable(isPublic: boolean, joined: boolean, isHost: boolean)
        local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameCreateMockTable)
        assert(event, "Event missing")
        event:FireServer(isPublic, joined, isHost)
    end

    function ClientEventManagement.destroyTablesWithMockHost()
        local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameDestroyTablesWithMockHosts)
        assert(event, "Event missing")
        event:FireServer()
    end

    function ClientEventManagement.addMockMember(tableId: CommonTypes.TableId)
        local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameAddMockMember)
        assert(event, "Event missing")
        event:FireServer(tableId)
    end

    function ClientEventManagement.mockNonHostMemberLeaves(tableId: CommonTypes.TableId)
        local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameMockNonHostMemberLeaves)
        assert(event, "Event missing")
        Utils.debugPrint("Mocks", "ClientEventManagement.mockNonHostMemberLeaves")
        event:FireServer(tableId)
    end

    function ClientEventManagement.mockHostDestroysTable(tableId: CommonTypes.TableId)
        local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameMockHostDestroysTable)
        assert(event, "Event missing")
        event:FireServer(tableId)
    end

    function ClientEventManagement.addMockInvite(tableId: CommonTypes.TableId)
        local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameAddMockInvite)
        assert(event, "Event missing")
        event:FireServer(tableId)
    end

    function ClientEventManagement.mockInviteAcceptance(tableId: CommonTypes.TableId)
        local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameMockInviteAcceptance)
        assert(event, "Event missing")
        event:FireServer(tableId)
    end

    function ClientEventManagement.mockStartGame(tableId: CommonTypes.TableId)
        local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameMockStartGame)
        assert(event, "Event missing")
        event:FireServer(tableId)
    end
end

function ClientEventManagement.listenToServerEvents(onTableCreated: (tableDescription: CommonTypes.TableDescription) -> nil,
    -- FIXME(dbanks)
    -- Change all these to signals.
    onTableDestroyed: (tableId: CommonTypes.TableId) -> nil,
    onTableUpdated: (tableDescription: CommonTypes.TableDescription) -> nil)

    assert(onTableCreated, "tableCreated must be provided")
    assert(onTableDestroyed, "tableDestroyed must be provided")
    assert(onTableUpdated, "tableUpdated must be provided")

    local event
    event = publicEvents:WaitForChild(EventUtils.EventNameSendAnalyticsRecordCount)
    assert(event, "SendAnalyticsRecordCount event missing")
    event.OnClientEvent:Connect(function(conversationId: number, recordCount: number)
        local bindableEvent = ClientEventManagement.getOrMakeBindableEvent(EventUtils.BindableEventNameAnalyticsRecordCount)
        bindableEvent:Fire(conversationId, recordCount)
    end)

    event = publicEvents:WaitForChild(EventUtils.EventNameSendAnalyticsRecordsHandful)
    assert(event, "SendAnalyticsRecordsHandful event missing")
    event.OnClientEvent:Connect(function(conversationId: number, gameRecords: {CommonTypes.AnalyticsGameRecord}, isFinal: number)
        local bindableEvent = ClientEventManagement.getOrMakeBindableEvent(EventUtils.BindableEventNameAnalyticsHandful)
        bindableEvent:Fire(conversationId, gameRecords, isFinal)
    end)

    event = publicEvents:WaitForChild(EventUtils.EventNameTableCreated)
    assert(event, "TableCreated event missing")
    event.OnClientEvent:Connect(function(raw_tableDescription: CommonTypes.TableDescription)
        local clean_tableDescription = TableDescription.sanitizeTableDescription(raw_tableDescription)
        onTableCreated(clean_tableDescription)
    end)

    event = publicEvents:WaitForChild(EventUtils.EventNameTableDestroyed)
    assert(event, "TableDestroyed event missing")
    event.OnClientEvent:Connect(onTableDestroyed)

    event = publicEvents:WaitForChild(EventUtils.EventNameTableUpdated)
    assert(event, "TableUpdated event missing")
    event.OnClientEvent:Connect(function(raw_tableDescription: CommonTypes.TableDescription)
        Utils.debugPrint("GamePlay", "ClientEventManagement got TableUpdated")
        local tableDescription = TableDescription.sanitizeTableDescription(raw_tableDescription)
        onTableUpdated(tableDescription)
    end)
end

function ClientEventManagement.getAnalyticsRecordCount(gameId: CommonTypes.GameId, conversationId: number)
    assert(gameId, "gameId should be defined")
    assert(conversationId, "conversationId should be defined")
local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameGetAnalyticsRecordCount)
    assert(event, "event missing")
    event:FireServer(gameId, conversationId)
end

function ClientEventManagement.getAnalyticsRecords(gameId: CommonTypes.GameId, conversationId: number)
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameGetAnalyticsRecords)
    assert(event, "event missing")
    event:FireServer(gameId, conversationId)
end

function ClientEventManagement.listenToServerEventsForActiveGame(gameInstanceGUID: CommonTypes.GameInstanceGUID,
    onPlayerLeftTable: (CommonTypes.GameInstanceGUID, CommonTypes.UserId) -> nil,
    notifyThatHostEndedGame: (CommonTypes.GameInstanceGUID, CommonTypes.GameEndDetails) -> nil)

    assert(gameInstanceGUID, "gameInstanceGUID must be provided")
    assert(onPlayerLeftTable, "onPlayerLeftTable must be provided")

    ClientEventUtils.connectToGameEvent(gameInstanceGUID, EventUtils.EventNamePlayerLeftTable, onPlayerLeftTable)
    ClientEventUtils.connectToGameEvent(gameInstanceGUID, EventUtils.EventNameNotifyThatHostEndedGame, notifyThatHostEndedGame)
end

function ClientEventManagement.createTable(gameId: CommonTypes.GameId, isPublic: boolean)
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameCreateNewTable)
    assert(event, "event missing")
    event:FireServer(gameId, isPublic)
end

function ClientEventManagement.destroyTable(tableId: CommonTypes.TableId)
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameDestroyTable)
    assert(event, "event missing")
    event:FireServer(tableId)
end

function ClientEventManagement.joinTable(tableId: CommonTypes.TableId)
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameJoinTable)
    assert(event, "event missing")
    event:FireServer(tableId)
end

function ClientEventManagement.leaveTable(tableId: CommonTypes.TableId)
    Utils.debugPrint("Mocks", "firing leaveTable event")
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameLeaveTable)
    assert(event, "event missing")
    event:FireServer(tableId)
end

function ClientEventManagement.startGame(tableId: CommonTypes.TableId)
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameStartGame)
    assert(event, "event missing")
    event:FireServer(tableId)
end

function ClientEventManagement.invitePlayerToTable(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameInvitePlayerToTable)
    assert(event, "event missing")
    event:FireServer(tableId, userId)
end

function ClientEventManagement.setTableInvites(tableId: CommonTypes.TableId, userIds: {CommonTypes.UserId})
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameSetTableInvites)
    assert(event, "event missing")
    event:FireServer(tableId, userIds)
end

function ClientEventManagement.removeGuestFromTable(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameRemoveGuestFromTable)
    assert(event, "event missing")
    event:FireServer(tableId, userId)
end

function ClientEventManagement.removeInviteForTable(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameRemoveInviteForTable)
    assert(event, "event missing")
    event:FireServer(tableId, userId)
end

function ClientEventManagement.setTableGameOptions(tableId: CommonTypes.TableId, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions)
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameSetTableGameOptions)
    assert(event, "event missing")
    event:FireServer(tableId, nonDefaultGameOptions)
end

function ClientEventManagement.endGame(tableId: CommonTypes.TableId)
    local event = EventUtils.getPublicRemoteEvent(EventUtils.EventNameEndGame)
    assert(event, "event missing")
    Utils.debugPrint("GamePlay", "ClientEventManagement.endGame")
    event:FireServer(tableId)
end

local bindableEventsByName: {[string]: BindableEvent} = {}
function ClientEventManagement.getOrMakeBindableEvent(eventName: string): BindableEvent
    local bindableEvent = bindableEventsByName[eventName]
    if not bindableEvent then
        bindableEvent = Instance.new("BindableEvent")
        bindableEvent.Name = eventName
        bindableEvent.Parent = script
        bindableEventsByName[eventName] = bindableEvent
    end
    return bindableEvent
end

if RunService:IsStudio() then
    setupMockEventFunctions()
end

return ClientEventManagement
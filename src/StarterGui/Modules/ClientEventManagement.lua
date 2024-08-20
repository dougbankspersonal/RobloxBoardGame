--[[
Client side event management: listening to events from the server, sending events to server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

local ClientEventManagement = {}

local tableEvents = ReplicatedStorage:WaitForChild("TableEvents")
if not tableEvents then
    assert(false, "TableEvents missing")
    return
end
local tableFunctions = ReplicatedStorage:WaitForChild("TableFunctions")
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
    local tableDescriptionsByTableId = fetchTableDescriptionsByTableIdRemoteFunction:InvokeServer()
    return tableDescriptionsByTableId
end

ClientEventManagement.listenToServerEvents = function(onTableCreated: (tableDescription: CommonTypes.TableDescription) -> nil,
    onTableDestroyed: (tableId: CommonTypes.TableId) -> nil,
    onTableUpdated: (tableDescription: CommonTypes.TableDescription) -> nil)

    assert(onTableCreated, "tableCreated must be provided")
    assert(onTableDestroyed, "tableDestroyed must be provided")
    assert(onTableUpdated, "tableUpdated must be provided")

    local event
    event = tableEvents:WaitForChild("TableCreated")
    assert(event, "TableCreated event missing")
    event.OnClientEvent:Connect(function(...)
        onTableCreated(...)
    end)

    event = tableEvents:WaitForChild("TableDestroyed")
    assert(event, "TableDestroyed event missing")
    event.OnClientEvent:Connect(onTableDestroyed)

    event = tableEvents:WaitForChild("TableUpdated")
    assert(event, "TableUpdated event missing")
    event.OnClientEvent:Connect(onTableUpdated)
end

ClientEventManagement.createTable = function(gameId: CommonTypes.GameId, isPublic: boolean)
    local event = ReplicatedStorage.TableEvents:WaitForChild("CreateNewTable")
    assert(event, "CreateNewTable event missing")
    event:FireServer(gameId, isPublic)
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
    local event = ReplicatedStorage.TableEvents:WaitForChild("LeaveTable")
    assert(event, "LeaveTable event missing")
    event:FireServer(tableId)
end

ClientEventManagement.startGame = function(tableId: CommonTypes.TableId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("StartGame")
    assert(event, "StartGame event missing")
    event:FireServer(tableId)
end

ClientEventManagement.invitePlayerToTable = function(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("InvitePlayerToTable")
    assert(event, "InvitePlayerToTable event missing")
    event:FireServer(tableId, userId)
end

ClientEventManagement.removeGuestFromTable = function(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("RemoveGuestFromTable")
    assert(event, "RemoveGuestFromTable event missing")
    event:FireServer(tableId, userId)
end

ClientEventManagement.removeInviteForTable = function(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    print("Doug: ClientEventManagement.removeInviteForTable 001 userId = ", userId)
    local event = ReplicatedStorage.TableEvents:WaitForChild("RemoveInviteForTable")
    assert(event, "RemoveInviteForTable event missing")
    event:FireServer(tableId, userId)
end

ClientEventManagement.mockTable = function(isPublic: boolean)
    if RunService:IsStudio() then
        local event = ReplicatedStorage.TableEvents:WaitForChild("MockTable")
        assert(event, "MockTable event missing")
        event:FireServer(isPublic)
    end
end

ClientEventManagement.destroyAllMockTables = function()
    if RunService:IsStudio() then
        local event = ReplicatedStorage.TableEvents:WaitForChild("DestroyAllMockTables")
        assert(event, "DestroyAllMockTables event missing")
        event:FireServer()
    end
end

ClientEventManagement.addMockMember = function(tableId: CommonTypes.TableId)
    if RunService:IsStudio() then
        local event = ReplicatedStorage.TableEvents:WaitForChild("AddMockMember")
        assert(event, "AddMockMember event missing")
        event:FireServer(tableId)
    end
end

ClientEventManagement.addMockInvite = function(tableId: CommonTypes.TableId)
    if RunService:IsStudio() then
        local event = ReplicatedStorage.TableEvents:WaitForChild("AddMockInvite")
        assert(event, "AddMockInvite event missing")
        event:FireServer(tableId)
    end
end

ClientEventManagement.mockInviteAcceptance = function(tableId: CommonTypes.TableId)
    if RunService:IsStudio() then
        local event = ReplicatedStorage.TableEvents:WaitForChild("MockInviteAcceptance")
        assert(event, "MockInviteAcceptance event missing")
        event:FireServer(tableId)
    end
end

return ClientEventManagement
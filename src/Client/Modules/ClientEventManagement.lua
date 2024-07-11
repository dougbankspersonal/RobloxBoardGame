--[[
Client side event management: listening to events from the server, sending events to server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local UIModes = require(RobloxBoardGameShared.Globals.UIModes)

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
ClientEventManagement.uiModeFromServer = UIModes.TableSelection :: CommonTypes.UIMode

ClientEventManagement.fetchTableDescriptionsByTableIdAsync = function(): CommonTypes.TableDescriptionsByTableId
    local fetchTableDescriptionsByTableIdRemoteFunction = tableFunctions:WaitForChild("FetchTableDescriptionsByTableId")
    if not fetchTableDescriptionsByTableIdRemoteFunction then
        assert(false, "fetchTableDescriptionsByTableIdRemoteFunction remote function missing")
        return {} :: CommonTypes.TableDescriptionsByTableId
    end
    return fetchTableDescriptionsByTableIdRemoteFunction:InvokeServer()
end

ClientEventManagement.listenToServerEvents = function(onTableCreated: (tableDescription: CommonTypes.TableDescription) -> nil,
    onTableDestroyed: (tableId: CommonTypes.TableId) -> nil,
    onTableUpdated: (tableDescription: CommonTypes.TableDescription) -> nil)

    assert(onTableCreated, "tableCreated must be provided")
    assert(onTableDestroyed, "tableDestroyed must be provided")
    assert(onTableUpdated, "tableUpdated must be provided")

    local event
    event = tableEvents:WaitForChild("TableCreated")
    event.OnClientEvent:Connect(onTableCreated)

    event = tableEvents:WaitForChild("TableDestroyed")
    event.OnClientEvent:Connect(onTableDestroyed)

    event = tableEvents:WaitForChild("TableUpdated")
    event.OnClientEvent:Connect(onTableUpdated)
end

ClientEventManagement.createTable = function(gameId: CommonTypes.GameId, isPublic: boolean)
    local event = ReplicatedStorage.TableEvents:WaitForChild("CreateNewGameTable")
    event:FireServer(gameId, isPublic)
end

return ClientEventManagement
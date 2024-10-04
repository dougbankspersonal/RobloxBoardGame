local GameTablesStorage = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local ServerTypes = require(RobloxBoardGameServer.Types.ServerTypes)

local gameTablesByTableId : {[CommonTypes.TableId]: ServerTypes.GameTable} = {}

function GameTablesStorage.addTable(gameTable: ServerTypes.GameTable): nil
    local tableId = gameTable.tableDescription.tableId

    assert(gameTablesByTableId[tableId] == nil, "GameTablesStorage.addTable: table already exists: " .. tableId)
    gameTablesByTableId[tableId] = gameTable
end

function GameTablesStorage.removeTable(tableId: CommonTypes.TableId): nil
    assert(tableId, "GameTablesStorage.removeTable: tableId is nil")
    assert(gameTablesByTableId[tableId], "GameTablesStorage.removeTable: table does not exist: " .. tableId)
    gameTablesByTableId[tableId] = nil
end

function GameTablesStorage.getGameTableByTableId(tableId: CommonTypes.TableId): ServerTypes.GameTable?
    return gameTablesByTableId[tableId]
end

function GameTablesStorage.getTableWithHost(hostUserId: CommonTypes.UserId): ServerTypes.GameTable?
    for _, gameTable in pairs(gameTablesByTableId) do
        if gameTable.tableDescription.hostUserId == hostUserId then
            return gameTable
        end
    end
    return nil
end

function GameTablesStorage.getFirstTableWithMember(userId: CommonTypes.UserId): ServerTypes.GameTable?
    for _, gameTable in pairs(gameTablesByTableId) do
        if gameTable:isMember(userId) then
            return gameTable
        end
    end
    return nil
end

function GameTablesStorage.getGameTableByGameInstanceGUID(gameInstanceGUID: CommonTypes.GameInstanceGUID): ServerTypes.GameTable?
    for _, gameTable in pairs(gameTablesByTableId) do
        if gameTable:getGameInstanceGUID() == gameInstanceGUID then
            return gameTable
        end
    end
    return nil
end

function GameTablesStorage.getGameTablesByTableId(): {[CommonTypes.TableId]: ServerTypes.GameTable}
    return gameTablesByTableId
end

return GameTablesStorage
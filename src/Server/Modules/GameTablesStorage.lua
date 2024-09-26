local GameTablesStorage = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- Server
local RobloxBoardGameServer = script.Parent.Parent
local ServerTypes = require(RobloxBoardGameServer.Types.ServerTypes)

local gameTablesByTableId : {[CommonTypes.TableId]: ServerTypes.GameTable} = {}

GameTablesStorage.addTable = function(gameTable: ServerTypes.GameTable): nil
    assert(gameTable, "GameTablesStorage.addTable: gameTable is nil")
    assert(gameTable.tableDescription, "GameTablesStorage.addTable: gameTable.tableDescription is nil")
    local tableId = gameTable.tableDescription.tableId
    assert(tableId, "GameTablesStorage.addTable: tableId is nil")

    assert(gameTablesByTableId[tableId] == nil, "GameTablesStorage.addTable: table already exists: " .. tableId)
    gameTablesByTableId[tableId] = gameTable
end

GameTablesStorage.removeTable = function(tableId: CommonTypes.TableId): nil
    assert(tableId, "GameTablesStorage.removeTable: tableId is nil")
    assert(gameTablesByTableId[tableId], "GameTablesStorage.removeTable: table does not exist: " .. tableId)
    gameTablesByTableId[tableId] = nil
end

GameTablesStorage.getGameTableByTableId = function(tableId: CommonTypes.TableId): ServerTypes.GameTable?
    return gameTablesByTableId[tableId]
end

GameTablesStorage.getFirstTableWithMember = function(userId: CommonTypes.UserId): ServerTypes.GameTable?
    for _, gameTable in pairs(gameTablesByTableId) do
        if gameTable:isMember(userId) then
            return gameTable
        end
    end
    return nil
end

GameTablesStorage.getGameTableByGameInstanceGUID = function(gameInstanceGUID: CommonTypes.GameInstanceGUID): ServerTypes.GameTable?
    for _, gameTable in pairs(gameTablesByTableId) do
        if gameTable:getGameInstanceGUID() == gameInstanceGUID then
            return gameTable
        end
    end
    return nil
end

GameTablesStorage.getGameTablesByTableId = function(): {[CommonTypes.TableId]: ServerTypes.GameTable}
    return gameTablesByTableId
end

return GameTablesStorage
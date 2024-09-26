local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local ServerGameInstances = {}

local serverGameInstancesByGameInstanceGUID = {} :: {[CommonTypes.GameInstanceGUID]: CommonTypes.ServerGameInstance}

function ServerGameInstances.addServerGameInstance(serverGameInstance: CommonTypes.ServerGameInstance): nil
    assert(serverGameInstance, "serverGameInstance is nil")
    assert(serverGameInstance.tableDescription, "serverGameInstance.tableDescription is nil")
    local gameInstanceGUID = serverGameInstance.tableDescription.gameInstanceGUID
    assert(gameInstanceGUID, "gameInstanceGUID is nil")
    assert(serverGameInstancesByGameInstanceGUID[gameInstanceGUID] == nil, "serverGameInstance already exists")
    serverGameInstancesByGameInstanceGUID[gameInstanceGUID] = serverGameInstance
end

function ServerGameInstances.getServerGameInstance(gameInstanceGUID: CommonTypes.GameInstanceGUID): CommonTypes.ServerGameInstance
    assert(gameInstanceGUID, "gameInstanceGUID is nil")
    local retVal = serverGameInstancesByGameInstanceGUID[gameInstanceGUID]
    assert(retVal, "serverGameInstance not found")
    return retVal
end

function ServerGameInstances.removeServerGameInstance(gameInstanceGUID: CommonTypes.GameInstanceGUID): nil
    assert(gameInstanceGUID, "gameInstanceGUID is nil")
    serverGameInstancesByGameInstanceGUID[gameInstanceGUID] = nil
end

return ServerGameInstances
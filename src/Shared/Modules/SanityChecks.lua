local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local TableDescription = require(RobloxBoardGameShared.Modules.TableDescription)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

local SanityChecks = {}

function SanityChecks.sanityCheckGameDetailsByGameId(gameDetailsByGameId: CommonTypes.GameDetailsByGameId)
    assert(gameDetailsByGameId ~= nil, "Should have non-nil gameDetailsByGameId")
    for gameId, gameDetails in pairs(gameDetailsByGameId) do
        assert(typeof(gameId) == "number", "gameId should be a number")
        GameDetails.sanityCheck(gameDetails)
    end
end

function SanityChecks.sanityCheckServerGameInstance(serverGameInstance: CommonTypes.ServerGameInstance)
    assert(serverGameInstance, "serverGameInstance is nil")
    local tableDescription = serverGameInstance.tableDescription
    TableDescription.sanityCheck(tableDescription)

    -- Table Description should be playing and have a GUID.
    assert(tableDescription.gameInstanceGUID, "serverGameInstance.tableDescription.gameInstanceGUID is nil")
    assert(tableDescription.gameTableState == GameTableStates.Playing, "serverGameInstance.tableDescription.gameTableState is not Playing")

    assert(serverGameInstance.sanityCheck, "serverGameInstance.sanityCheck is nil")
    assert(serverGameInstance.destroy, "serverGameInstance.destroy is nil")
    assert(serverGameInstance.playerLeftGame, "serverGameInstance.destroy is nil")
    assert(serverGameInstance.getGameSpecificGameEndDetails, "serverGameInstance.destroy is nil")
    serverGameInstance:sanityCheck()
end

function SanityChecks.sanityCheckClientGameInstance(clientGameInstance: CommonTypes.ClientGameInstance)
    assert(clientGameInstance, "clientGameInstance is nil")
    assert(clientGameInstance.sanityCheck, "clientGameInstance.sanityCheck is nil")
    assert(clientGameInstance.destroy, "clientGameInstance.destroy is nil")
    assert(clientGameInstance.onPlayerLeftTable, "clientGameInstance.destroy is nil")
    assert(clientGameInstance.notifyThatHostEndedGame, "clientGameInstance.destroy is nil")
    clientGameInstance:sanityCheck()
end


return SanityChecks
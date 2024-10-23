--[[
Interface to write and read analytics to some store.

Currently build on DataStores:

More on data stores:
https://create.roblox.com/docs/cloud-services/data-stores

Overall structure:
* One data store per game.  So if your experience has Monopoly, Checkers, and Bridge, there's 3 stores, one for each game.
* Within each store, there is one big fat record for each game instance, with key
  {gameInstanceGUID}
* To use this module:
  * When game starts, call startGameRecord
  * When add an action, call appendToGameRecord
  * When game is over, call sendGameRecordAsync
  * To get total record count for a game, call getRecordCountForGameAsync
  * To get all records for a game, call getAllRecordsForGameByHandfuls
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cryo = require(ReplicatedStorage.Cryo)

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

-- Server
local RobloxBoardGameServer = game:GetService("ServerScriptService").RobloxBoardGameServer
local WrappedDataStoreService = require(RobloxBoardGameServer.Analytics.WrappedDataStoreService)

local ServerGameAnalytics = {}

local DataStoreNameRecordCountByGameID = "RecordCountByGameID"
local DataStorePrefixEventsForGameId = "EventsForGameId"

-- We want to avoid thrashing the data store.
-- We may have a lot of records, so we:
-- 1) Fetch in handfuls.
-- 2) Add some wait between handfuls.
-- FIXME(dbanks)
-- The numbers for both handful size and wait are completely arbitrary.
local keysPerHandlful = 20
-- Also pulled out of thin air.
local artificialWaitBetweenPagesSeconds = 0.1

local dataStoreNameTwiddle = nil

local recordsByGameInstanceGUID = {} :: {[CommonTypes.GameInstanceGUID]: {CommonTypes.AnalyticsGameRecord}}

function ServerGameAnalytics.useThrowawayDataStore()
    -- We will use a temporaty data store for this run of the game.
    -- Just change the name of the store.
    dataStoreNameTwiddle = tostring(os.time())
end

function getDataStoreByName(dataStoreName: string): DataStore
    if dataStoreNameTwiddle then
        dataStoreName = dataStoreName .. "_" .. dataStoreNameTwiddle
    end
    Utils.debugPrint("Analytics", "dataStoreName = ", dataStoreName)
    local dataStore = WrappedDataStoreService.getDataStore(dataStoreName)
    return dataStore
end

function ServerGameAnalytics.getRecordCountByGameIdDataStore()
    return getDataStoreByName(DataStoreNameRecordCountByGameID)
end

-- Make (if not made) and then get the data store containing all records of all plays through a particular
-- game.
function ServerGameAnalytics.getDataStoreForGame(gameId: CommonTypes.GameId): DataStore
    assert(gameId, "gameId must be provided")
    local dataStoreName = DataStorePrefixEventsForGameId .. tostring(gameId)
    return getDataStoreByName(dataStoreName)
end

function ServerGameAnalytics.startGameRecord(tableDescription: CommonTypes.TableId)
    -- Should have a playing game.
    assert(tableDescription, "tableDescription must be provided")
    assert(tableDescription.gameInstanceGUID, "gameInstanceGUID must be provided")

    local gameDescription: CommonTypes.AnalyticsGameDescription = {
        gameId = tableDescription.gameId,
        gameInstanceGUID = tableDescription.gameInstanceGUID,
        memberUserIds = Cryo.Dictionary.keys(tableDescription.memberUserIds),
        hostUserId =  tableDescription.hostUserId,
        isPublic = tableDescription.isPublic,
        nonDefaultGameOptions = tableDescription.opt_nonDefaultGameOptions or {},
    }

    -- Should be no record for this game instance.
    assert(not recordsByGameInstanceGUID[gameDescription.gameInstanceGUID], "Already have a record for this game instance")
    local recordForGameInstance = {
        gameDescription = gameDescription,
        events = {}
    } :: CommonTypes.AnalyticsGameRecord
    recordsByGameInstanceGUID[gameDescription.gameInstanceGUID] = recordForGameInstance
end

function ServerGameAnalytics.appendToGameRecord(gameInstanceGUID: CommonTypes.GameInstanceGUID, eventType: string, details: any)
    assert(gameInstanceGUID, "gameInstanceGUID must be provided")
    assert(eventType, "eventType must be provided")
    local analyticsGameEvent = {
        eventType = eventType,
        details = details,
    }
    local recordForGameInstance = recordsByGameInstanceGUID[gameInstanceGUID]
    assert(recordForGameInstance , "No record for this game instance")
    assert(recordForGameInstance.events, "No events for this game instance")
    table.insert(recordForGameInstance.events, analyticsGameEvent)
end

function ServerGameAnalytics.sendGameRecordAsync(gameInstanceGUID: CommonTypes.GameInstanceGUID): boolean
    assert(gameInstanceGUID, "gameInstanceGUID must be provided")
    local recordForGameInstance = recordsByGameInstanceGUID[gameInstanceGUID]
    assert(recordForGameInstance, "No record for this game instance")
    assert(recordForGameInstance.gameDescription, "No gameDescription for this game instance")
    assert(recordForGameInstance.gameDescription.gameId, "No gameId for this game instance")
    local gameId = recordForGameInstance.gameDescription.gameId
    local dataStore = ServerGameAnalytics.getDataStoreForGame(gameId)
    assert(dataStore, "No data store for this game instance")
    dataStore:SetAsync(tostring(gameInstanceGUID), recordForGameInstance)
    -- increment count.
    local recordCountDataStore = ServerGameAnalytics.getRecordCountByGameIdDataStore()
    recordCountDataStore:IncrementAsync(tostring(gameId), 1)
end


function ServerGameAnalytics.getRecordCountForGameAsync(gameId: CommonTypes.GameId): number
    assert(gameId, "gameId must be provided")
    local recordCountDataStore = ServerGameAnalytics.getRecordCountByGameIdDataStore()
    local gameKey = tostring(gameId)
    local success, record = pcall(function()
        return recordCountDataStore:GetAsync(gameKey)
    end)
    if not success then
        Utils.debugPrint("Analytics", "GetAsync is gettinng throttled for recordCountDataStore = ", recordCountDataStore)
        return 0
    else
        Utils.debugPrint("Analytics", "Got record count = ", record)
        if record then
            return record
        end
    end
    return 0
end

function ServerGameAnalytics.getAllRecordsForGameByHandfuls(gameId: CommonTypes.GameId, singlePageCallback: (gameRecords: {CommonTypes.AnalyticsGameRecord}, isFinished: boolean) -> nil): nil
    assert(gameId, "gameId must be provided")
    assert(singlePageCallback, "gameId must be provided")

    -- Reading from data store is async, do it in thread.
    task.spawn(function()
        local dataStore = ServerGameAnalytics.getDataStoreForGame(gameId)
        Utils.debugPrint("Analytics", "Calling list keys async for gameId = ", gameId)
        local dataStoreKeyPages: DataStoreKeyPages = dataStore:ListKeysAsync(nil, keysPerHandlful)
        while true do
            -- Grab a handful of keys.
            local keys = dataStoreKeyPages:GetCurrentPage()
            local gameRecords = {} :: {CommonTypes.AnalyticsGameRecord}

            Utils.debugPrint("Analytics", "Getting keys = ", keys)
            local keyNames = Cryo.List.map(keys, function(key)
                return key.KeyName
            end)

            -- For each key get the records.
            for _, keyName in ipairs(keyNames) do
                Utils.debugPrint("Analytics", "Getting record with keyName = ", keyName.Name)
                local value = dataStore:GetAsync(keyName)
                Utils.debugPrint("Analytics", "Got record value = ", value)

                table.insert(gameRecords, value)
            end

            -- Hit the callback with this group.
            singlePageCallback(gameRecords, dataStoreKeyPages.IsFinished)

            -- Maybe exit, maybe keep going.
            if dataStoreKeyPages.IsFinished then
                break
            else
                dataStoreKeyPages:AdvanceToNextPageAsync()
                task.wait(artificialWaitBetweenPagesSeconds)
            end
        end
    end)
end

function ServerGameAnalytics.dumpBudget()
    local getAsyncBudget = WrappedDataStoreService.getRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
    Utils.debugPrint("Analytics", "ServerGameAnalytics.GetAsync budget = ", getAsyncBudget)
    local listAsyncBudget = WrappedDataStoreService.getRequestBudgetForRequestType(Enum.DataStoreRequestType.ListAsync)
    Utils.debugPrint("Analytics", "ServerGameAnalytics.ListAsync budget = ", listAsyncBudget)
end

return ServerGameAnalytics

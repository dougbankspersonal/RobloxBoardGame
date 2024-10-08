--[[
DataStore for game analytics.

More on data stores:
https://create.roblox.com/docs/cloud-services/data-stores

Overall structure:
* One data store per game.  So if your experience has Monopoly, Checkers, and Bridge, there's 3 stores, one for each game.
* Within each store, keys will have the following structure:
  {gameInstanceGUID}/{one or more game-specific keys}
* Values are user-defined.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cryo = require(ReplicatedStorage.Cryo)

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

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
function ServerGameAnalytics.useThrowawayDataStore()
    -- We will use a temporaty data store for this run of the game.
    -- Just change the name of the store.
    dataStoreNameTwiddle = tostring(os.time())
end

-- Make (if not made) and then get the data store containing all records of all plays through a particular
-- game.
function ServerGameAnalytics.getDataStoreForGame(gameId: CommonTypes.GameId): DataStore
    assert(gameId, "gameId must be provided")
    local dataStoreName = DataStorePrefixEventsForGameId .. tostring(gameId)
    if dataStoreNameTwiddle then
        dataStoreName = dataStoreName .. "_" .. dataStoreNameTwiddle
    end
    Utils.debugPrint("Analytics", "dataStoreName = ", dataStoreName)
    local dataStore = DataStoreService:GetDataStore(dataStoreName)
    return dataStore
end

-- For any record type, we may add multiple records of that type (e.g. recording a die roll: during a
-- game there will be many die rolls).
-- Since the store is per game (not game instance), the key must include:
-- gameInstanceGUID
-- recordType
-- some final factor to keep the keys unique: we will just use a type count.
-- So for each game instance we need to track the type counts.
export type TypeNameToCount = {
    [string]: number,
}

export type TypeNameToCountsByGameInstanceGUID = {
    [CommonTypes.GameInstanceGUID]: TypeNameToCount,
}

local typeNameToCountsByGameInstanceGUID: TypeNameToCountsByGameInstanceGUID = {}

local function getCountForRecordOfType(gameInstanceGUIID: CommonTypes.GameInstanceGUID, recordType: string)
    if typeNameToCountsByGameInstanceGUID[gameInstanceGUIID] == nil then
        typeNameToCountsByGameInstanceGUID[gameInstanceGUIID] = {}
    end

    if typeNameToCountsByGameInstanceGUID[gameInstanceGUIID][recordType] == nil then
        typeNameToCountsByGameInstanceGUID[gameInstanceGUIID][recordType] = 0
    end

    local retVal = typeNameToCountsByGameInstanceGUID[gameInstanceGUIID][recordType]
    typeNameToCountsByGameInstanceGUID[gameInstanceGUIID][recordType] = retVal + 1

    return retVal
end

local function getKeyForRecordOfType(gameInstanceGUID: CommonTypes.GameInstanceGUID, recordType: string): string
    local count = getCountForRecordOfType(gameInstanceGUID, recordType)
    local key = gameInstanceGUID .. "/" .. recordType .. "/" .. tostring(count)
    return key
end

local getRecordCountDataStore = function()
    local dataStoreName = DataStoreNameRecordCountByGameID
    if dataStoreNameTwiddle then
        dataStoreName = dataStoreName .. "_" .. dataStoreNameTwiddle
    end
    -- Keep a separate count of the number of non-count records in the store.
    local recordCountDataStore = DataStoreService:GetDataStore(dataStoreName)
    return recordCountDataStore
end

function ServerGameAnalytics.addRecordOfType(gameId: CommonTypes.GameId, gameInstanceGUID: CommonTypes.GameInstanceGUID, recordType: string, value: any): nil
    assert(gameId, "gameId must be provided")
    -- Use a thread because it's async.
    -- FIXME(dbanks)
    -- We may also want to consider batching these somehow.
    task.spawn(function()
        -- Keep a separate count of the number of non-count records in the store.
        local recordCountDataStore = getRecordCountDataStore()
        recordCountDataStore:IncrementAsync(tostring(gameId), 1)

        local dataStore = ServerGameAnalytics.getDataStoreForGame(gameId)
        local recordKey = getKeyForRecordOfType(gameInstanceGUID, recordType)
        Utils.debugPrint("Analytics", "Adding record with gameId = ", gameId)
        Utils.debugPrint("Analytics", "  recordKey = ", recordKey)
        Utils.debugPrint("Analytics", "  record with value = ", value)
        dataStore:SetAsync(recordKey, value)
    end)
end

function ServerGameAnalytics.getRecordCountForGameAsync(gameId: CommonTypes.GameId): number
    assert(gameId, "gameId must be provided")
    assert(gameId, "callback must be provided")
    local recordCountDataStore = getRecordCountDataStore()
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

function ServerGameAnalytics.dumpBudget()
    local getAsyncBudget = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
    Utils.debugPrint("Analytics", "ServerGameAnalytics.GetAsync budget = ", getAsyncBudget)
    local listAsyncBudget = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.ListAsync)
    Utils.debugPrint("Analytics", "ServerGameAnalytics.ListAsync budget = ", listAsyncBudget)
end

-- Get all records for game.
-- Note this is for the GAME, not a game INSTANCE: we are getting all records from all instances of this game.
-- Does it in handfuls to deliberately avoid any thrashing.
function ServerGameAnalytics.fetchAllAnalyticsRecordsForGameByPages(gameId: CommonTypes.GameId, singlePageCallback: (records: {CommonTypes.AnalyticsRecord}, isFinished: boolean) -> nil): nil
    assert(gameId, "gameId must be provided")
    assert(singlePageCallback, "gameId must be provided")
    -- Async, do in thread.
    task.spawn(function()
        local dataStore = ServerGameAnalytics.getDataStoreForGame(gameId)
        Utils.debugPrint("Analytics", "Calling list keys async for gameId = ", gameId)
        local dataStoreKeyPages: DataStoreKeyPages = dataStore:ListKeysAsync(nil, keysPerHandlful)
        while true do
            -- Grab a handful of keys.
            local keys = dataStoreKeyPages:GetCurrentPage()
            local analyticsRecords = {} :: {CommonTypes.AnalyticsRecord}

            Utils.debugPrint("Analytics", "Getting keys = ", keys)
            local keyNames = Cryo.List.map(keys, function(key)
                return key.KeyName
            end)

            -- For each key get the records.
            for _, keyName in ipairs(keyNames) do
                Utils.debugPrint("Analytics", "Getting record with keyName = ", keyName.Name)
                local value = dataStore:GetAsync(keyName)
                Utils.debugPrint("Analytics", "Got record value = ", value)
                local orderedKeyComponents = Utils.splitString(keyName, "/")
                -- There should be 3 components:
                -- * The gameInstanceGUID
                -- * The record type.
                -- * The count.
                -- The count we don't really care about, it's just an artifact of how we need to interact with
                -- the data store.
                assert(#orderedKeyComponents == 3, "Unexpected key format")
                local gameInstanceGUID = orderedKeyComponents[1]
                local recordType = orderedKeyComponents[2]

                local analyticsRecord = {
                    gameInstanceGUID = gameInstanceGUID,
                    recordType = recordType,
                    value = value,
                }

                table.insert(analyticsRecords, analyticsRecord)
            end

            -- Hit the callback with this group.
            singlePageCallback(analyticsRecords, dataStoreKeyPages.IsFinished)

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

return ServerGameAnalytics

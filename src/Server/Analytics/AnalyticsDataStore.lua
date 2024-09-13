--[[
DataStore for game analytics.

Overall structure:
* One data store per game.  So if your experience has Monopoly, Checkers, and Bridge, there's 3 stores, one for each game.
* Within each store, keys will have the following structure:
  {gameInstacneGUID}/{one or more user-defined keys}
* Values are user-defined.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local ServerGameAnalytics = {}

local listKeysPageSize = 20

export type GameRecord = {
    orderedKeys: {string},
    value: any,
}

-- Get the data store containing all records of all plays through a particular game.
ServerGameAnalytics.getDataStoreForGame = function(gameId: CommonTypes.GameId): DataStore
    local key = "BoardGame_" .. tostring(gameId)
    local dataStore = DataStoreService:GetDataStore(key)
    return dataStore
end

ServerGameAnalytics.addRecord = function(gameId: CommonTypes.GameId, gameInstanceGUID: CommonTypes.GameInstanceGUID, key: string, value: any): nil
    -- Use a thread because it's async.
    task.spawn(function()
        local dataStore = ServerGameAnalytics.getDataStoreForGame(gameId)
        local recordKey = gameInstanceGUID .. "/" .. key
        dataStore:SetAsync(recordKey, value)
    end)
end

-- Get records for game.
-- If there is no cursor, grab the first handful.
-- If there is a cursor, and cursor has more pages, grab next handful.
ServerGameAnalytics.fetchAllGameRecordsForGameByPages = function(gameId: CommonTypes.GameId, singlePageCallback: (records: {GameRecord}, isFinished: boolean) -> nil): nil
    -- Async, do in thread.
    task.spawn(function()
        local dataStore = ServerGameAnalytics.getDataStoreForGame(gameId)
        local dataStoreKeyPages = dataStore:ListKeysAsync(nil, listKeysPageSize)
        while true do
            -- Grab a handful of keys.
            local keys = dataStoreKeyPages:GetCurrentPage()
            local gameRecords = {}
            -- For each key get the record.
            for _, key in ipairs(keys) do
                local value = dataStore:GetAsync(key)
                local orderedKeys = Utils.splitString(key)
                local gameRecord = {
                    orderedKeys = orderedKeys,
                    value = value,
                }
                table.insert(gameRecords, gameRecord)
            end
            -- Hit the callback with this group.
            singlePageCallback(gameRecords, dataStoreKeyPages.IsFinished)
            -- Maybe exit, maybe keep going.
            if dataStoreKeyPages.IsFinished then
                break
            else
                dataStoreKeyPages:AdvanceToNextPageAsync()
            end
        end
    end)
end

return ServerGameAnalytics

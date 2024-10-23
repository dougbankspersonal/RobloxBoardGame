--[[
Wrapper around data store functions so I can test other stuff.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cryo = require(ReplicatedStorage.Cryo)

local useDebug = false

local WrappedDataStoreService = {}

local MockDataStoreKeyPages = {}
MockDataStoreKeyPages.__index = MockDataStoreKeyPages

function WrappedDataStoreService.setUseDebug(value: boolean): nil
    useDebug = value
end

function MockDataStoreKeyPages.new(keyToRecordMap: {[string]: any}, keysPerHandful: number): any
    local self = {}
    setmetatable(self, MockDataStoreKeyPages)

    self.keys = Cryo.Table.keys(keyToRecordMap)
    self.currentIndex = 1
    self.keysPerHandful = keysPerHandful
    self.IsFinished = false
    return self
end

function MockDataStoreKeyPages:GetCurrentPage()
    local retVal = {}
    local index = self.currentIndex
    for _ = 1, self.keysPerHandful do
        local key = self.keys[index]
        if key == nil then
            self.IsFinished = true
            break
        end
        table.insert(retVal, key)
        index = index + 1
    end

    return retVal
end

function MockDataStoreKeyPages:AdvanceToNextPageAsync()
    self.currentIndex = self.currentIndex + self.keysPerHandful
    task.wait(0.1)
end

local MockDataStore = {}
MockDataStore.__index = MockDataStore

function MockDataStore.new(name: string): any
    local self = {}
    setmetatable(self, MockDataStore)

    self.name = name
    self.keyToRecordMap = {}
    return self
end

function MockDataStore:SetAsync(recordKey: string, value: any): nil
    task.wait(0.1)
    self.keyToRecordMap[recordKey] = value
end

function MockDataStore:IncrementAsync(recordKey: string, increment: number): nil
    task.wait(0.1)
    local currentValue = self.keyToRecordMap[recordKey] or 0
    self.keyToRecordMap[recordKey] = currentValue + increment
end

function MockDataStore:GetAsync(recordKey: string): any
    task.wait(0.1)
    return self.keyToRecordMap[recordKey]
end

function MockDataStore:ListKeysAsync(_, keysPerHandful: number)
    task.wait(0.1)
    local dataStoreKeyPages = MockDataStoreKeyPages.new(self.keyToRecordMap, keysPerHandful)
    return dataStoreKeyPages
end

local mockDataStoresByName = {} :: {[string]: any}

function getOrMakeMockDataStore(name: string): any
    if mockDataStoresByName[name] == nil then
        mockDataStoresByName[name] = MockDataStore.new(name)
    end
    return mockDataStoresByName[name]
end

function WrappedDataStoreService.getDataStore(name:string): DataStore
    if useDebug then
        return getOrMakeMockDataStore(name)
    else
        return DataStoreService:GetDataStore(name)
    end
end

function WrappedDataStoreService.getRequestBudgetForRequestType(requestType)
    if useDebug then
        -- ???
        return "mockBudget"
    else
        return DataStoreService:GetRequestBudgetForRequestType(requestType)
    end
end

return WrappedDataStoreService

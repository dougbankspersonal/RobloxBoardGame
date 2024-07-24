--[[
Random assortment of useful functions.
Note: before adding stuff here see if it's already in Cryo:
https://roblox.github.io/cryo-internal/api-reference
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cryo = require(ReplicatedStorage.Cryo)

local Utils = {}

-- verify two tables have the same set of keys.
Utils.tablesHaveSameKeys = function(table1: {[any]: any}, table2: {[any]: any}): boolean
    for key, _ in table1 do
        if table2[key] == nil then
            return false
        end
    end
    for key, _ in table2 do
        if table1[key] == nil then
            return false
        end
    end
    return true
end

-- is a value in a number-indexed array?
Utils.arrayHasValue = function(array: {any}, value: any): boolean
    local index = Cryo.List.find(array, value)
    return index ~= nil
end

Utils.tableSize = function(table: {[any]: any}): number
    assert(table ~= nil, "tableSize: table is nil")
    local keys = Cryo.Dictionary.keys(table)
    return #keys
end

Utils.debugPrint = function(...)
    if game:GetService("RunService"):IsStudio() then
        print(...)
    end
end

return Utils

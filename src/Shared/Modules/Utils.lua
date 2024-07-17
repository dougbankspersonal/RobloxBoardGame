--[[
Random assortment of useful functions.
]]


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
    for _, v in ipairs(array) do
        if v == value then
            return true
        end
    end
    return false
end

-- remove the first instance of the given value from the array, if it's there.
-- return true iff it was removed.
Utils.removeFirstInstancevFromArray = function(array: {any}, value: any): boolean
    for i, v in ipairs(array) do
        if v == value then
            table.remove(array, i)
            return true
        end
    end
    return false
end

-- We have two maps.  Merge the second into the first, return that.
-- So if first and second both have entry with same key, the value from second wins.
Utils.mergeSecondMapIntoFirst = function(first: {[any]: any}, second: {[any]: any}): {[any]: any}
    local result = {} :: {[any]: any}
    for key, value in pairs(first) do
        result[key] = value
    end
    for key, value in pairs(second) do
        result[key] = value
    end
    return result
end

-- Given a table, get the keys as an array.
Utils.getKeys = function(table: {[any]: any}): {any}
    local result = {} :: {any}
    for key, _ in pairs(table) do
        table.insert(result, key)
    end
    return result
end


return Utils

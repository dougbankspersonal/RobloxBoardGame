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

return Utils

--[[
Storage for client-side table descriptions.
Source of truth is server.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared...
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local TableDescriptions = {
}

TableDescriptions.tableDescriptionsByTableId = {} :: CommonTypes.TableDescriptionsByTableId

TableDescriptions.setTableDescriptions = function(tableDescriptionsByTableId: CommonTypes.TableDescriptionsByTableId)
    TableDescriptions.tableDescriptionsByTableId = tableDescriptionsByTableId
end

return TableDescriptions
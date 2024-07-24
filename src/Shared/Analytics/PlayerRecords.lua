local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local Cryo = require(ReplicatedStorage.Cryo)

local playerHistory = DataStoreService:GetDataStore("PlayerHistory")

local module = {}

local historiesByPlayerId = {}

module.GetPlayerRecord = function(userId)
    local getSuccess, currentHistory = pcall(function()
        return playerHistory:GetAsync(userId)
    end)
    if getSuccess then
        Utils.debugPrint("it worked")
    else
        currentHistory = {}
    end
end

module.UpdatePlayerRecord = function(userId, values)
    local currentHistory = module.GetHistory(userId)
    local updatedHistory = Cryo.Dictionary.join(currentHistory, values)
    local setSuccess, errorMessage = pcall(function()
        playerHistory:SetAsync(userId)
    end)
    return setSuccess
end


return module
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerHistory = DataStoreService:GetDataStore("PlayerHistory")
local Cryo = ReplicatedStorage.Cryo

local module = {}

local historiesByPlayerId = {}

module.GetPlayerRecord = function(userId)
    local getSuccess, currentHistory = pcall(function()
        return playerHistory:GetAsync(userId)
    end)
    if getSuccess then
        print("it worked")
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
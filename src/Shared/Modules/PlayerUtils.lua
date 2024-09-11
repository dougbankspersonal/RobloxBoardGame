local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

local PlayerUtils = {}

local userIdToName = {} :: {[CommonTypes.UserId]: string}

PlayerUtils.getNameAsync = function(userId: CommonTypes.UserId): string
    if userIdToName[userId] then
        return userIdToName[userId]
    end

    local mappedId = Utils.debugMapUserId(userId)
    local name = Players:GetNameFromUserIdAsync(mappedId)
    userIdToName[userId] = name
    return name
end

return PlayerUtils
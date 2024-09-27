local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Cryo = require(ReplicatedStorage.Cryo)

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local ContentProvider = game:GetService("ContentProvider")

local PlayerUtils = {}

local mappedUserIdToName = {} :: {[CommonTypes.UserId]: string}
local mappedUserIdToThumbnail = {} :: {[CommonTypes.UserId]: string}

-- Call 'getXXX' only once you've primed the pump: called getAsync for the same entity.
function PlayerUtils.getName(userId: CommonTypes.UserId): string
    local mappedId = Utils.debugMapUserId(userId)

    local userName = mappedUserIdToName[mappedId]
    assert(userName, "userIdToName[userId] is nil")
    return userName
end

function PlayerUtils.getThumbnail(userId: CommonTypes.UserId): string
    local mappedId = Utils.debugMapUserId(userId)

    local thumbnail = mappedUserIdToThumbnail[mappedId]
    assert(thumbnail, "userIdToThumbnail[userId] is nil")
    return thumbnail
end

-- Call this minimally: when we are aware of a new group of users, grab all their info.
function PlayerUtils.asyncFetchPlayerInfo(userIds: {CommonTypes.UserId})
    assert(userIds, "userIds should exist")

    Utils.debugPrint("Mocks", "Doug userIds = ", userIds)

    local mappedUserIds = Cryo.List.map(userIds, function(element, _)
        return Utils.debugMapUserId(element)
    end)

    local newThumbnails = {}
    for _, mappedUserId in ipairs(mappedUserIds) do
        if not mappedUserIdToName[mappedUserId] then
            local success, name = pcall(function()
                return Players:GetNameFromUserIdAsync(mappedUserId)
            end)
            if success then
                mappedUserIdToName[mappedUserId] = name
            else
                mappedUserIdToName[mappedUserId] = "Unknown"
            end
        end
        if not mappedUserIdToThumbnail[mappedUserId] then
            local success, thumbnail = pcall(function()
                return Players:GetUserThumbnailAsync(mappedUserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
            end)
            if success then
                mappedUserIdToThumbnail[mappedUserId] = thumbnail
                table.insert(newThumbnails, thumbnail)
            else
                mappedUserIdToThumbnail[mappedUserId] = ""
            end
        end
    end

    -- Preload thumbnails as a convenience.
    -- Do this on a task though because it takes forever.
    task.spawn(function()
        ContentProvider:PreloadAsync(newThumbnails)
    end)
end

return PlayerUtils
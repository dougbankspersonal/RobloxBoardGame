local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)
local UIModes = require(RobloxBoardGameShared.Globals.UIModes)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local ClientTableDescriptions = require(RobloxBoardGameClient.Modules.ClientTableDescriptions)

local StateDigest = {}

function StateDigest.getCurrentTableDescription(): CommonTypes.TableDescription?
    local localUserId = Players.LocalPlayer.UserId
    return ClientTableDescriptions.getTableWithUserId(localUserId)
end

function StateDigest.getCurrentUIMode(): CommonTypes.UIMode
    local tableDescription = StateDigest.getCurrentTableDescription()

    -- The local player is not part of any table: we show them the "select/create table" UI.
    if not tableDescription then
        return UIModes.TableSelection
    elseif tableDescription.gameTableState == GameTableStates.WaitingForPlayers then
        return UIModes.TableWaitingForPlayers
    elseif tableDescription.gameTableState == GameTableStates.Playing then
        return UIModes.TablePlaying
    else
        assert(false, "we have a table description in an unknown state")
    end
end

return StateDigest
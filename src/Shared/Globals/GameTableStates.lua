--[[
Enumerated type for GameTableStates.
A table is always in one of 3 states:
  * Waiting for Players: players can join/leave, waiting for host to start game.
  * Playing: game is on.  No one else can join.
  ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)

local GameTableStates: CommonTypes.GameTableStates = {
    WaitingForPlayers = 0,
    Playing = 1,
} :: CommonTypes.GameTableStates

return GameTableStates
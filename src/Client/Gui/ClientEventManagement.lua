--[[
Client side event management: listening to events from the server, sending events to server.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared...
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local UIModes = require(RobloxBoardGameShared.Globals.UIModes)

local ClientEventManagement = {}

-- Every new player starts in the table selection lobby.
ClientEventManagement.uiModeFromServer = UIModes.TableSelection :: CommonTypes.UIMode

return ClientEventManagement
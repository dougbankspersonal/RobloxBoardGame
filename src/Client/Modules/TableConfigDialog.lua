--[[
We are showing a dialog to a player who has opted to create a table.
They must:
  * select a game (we skip this in cases where there's just one game).
  * select whether game is public or private.
]]

local TableConfigDialog = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)

TableConfigDialog.show = function(screenGui: ScreenGui, onTableConfigSelected: (gameId: CommonTypes.GameId, isPublic: boolean) -> nil)
    -- FIXME(dbanks)
    -- Right now there's just one experience using this library (SFBG) and one game in that experience
    -- (Nuts) so I am going to fudge this for now.
    local gameDetailsByGameId = GameDetails.getAllGameDetails()
    assert(gameDetailsByGameId, "Should have gameDetailsByGameId")
    assert(#gameDetailsByGameId == 1, "FIXME(dbanks): current use case I know we only have one game, I am coding accordingly.  Once we have mumtiple games, fix this.")

    local gameId
    for gid, _ in gameDetailsByGameId do
        gameId = gid
        break
    end
    assert(gameId ~= nil, "Should have a gameId")
    assert(type(gameId) == "number", "gameId should be a number")

    -- Put up a UI to get public or private.
    -- FIXME(dbanks): this is horrible temp hack using an array of buttons to pick from a set of two options.
    -- Implement a proper toggle switch (or radio buttons or whatever)
    local dialogConfig: CommonTypes.DialogConfig = {
        title = "Public or Private?",
        description = "Anyone in experience can join a public game.  Only invited players can join a private game.",
        dialogButtonConfigs = {
            {
                text = "Public",
                callback = function()
                    onTableConfigSelected(gameId, true)
                end
            } :: CommonTypes.DialogButtonConfig,
            {
                text = "Private",
                callback = function()
                    onTableConfigSelected(gameId, false)
                end
            } :: CommonTypes.DialogButtonConfig,
        } :: {CommonTypes.DialogConfig},
    }

    GuiUtils.makeDialog(screenGui, dialogConfig)
end

return TableConfigDialog
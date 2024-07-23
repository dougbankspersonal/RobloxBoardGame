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

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local DialogUtils = require(RobloxBoardGameStarterGui.Modules.DialogUtils)

local selectPublicOrPrivate = function(screenGui: ScreenGui, gameId: CommonTypes.GameId, onTableConfigSelected: (gameId: CommonTypes.GameId, isPublic: boolean) -> nil)
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
                    print("Doug: Public clicked")
                    onTableConfigSelected(gameId, true)
                end
            } :: CommonTypes.DialogButtonConfig,
            {
                text = "Private",
                callback = function()
                    print("Doug: Private clicked")
                    onTableConfigSelected(gameId, false)
                end
            } :: CommonTypes.DialogButtonConfig,
        } :: {CommonTypes.DialogConfig},
    }

    DialogUtils.makeDialog(screenGui, dialogConfig)
end

TableConfigDialog.promptForTableConfig = function(screenGui: ScreenGui, onTableConfigSelected: (gameId: CommonTypes.GameId, isPublic: boolean) -> nil)
    local gameDetailsByGameId = GameDetails.getAllGameDetails()
    assert(gameDetailsByGameId, "Should have gameDetailsByGameId")
    assert(#gameDetailsByGameId >= 1, "Should have at last one item in gameDetailsByGameId")

    local gameId
    if #gameDetailsByGameId == 1 then
        print("Doug: promptForTableConfig gameDetailsByGameId = ", gameDetailsByGameId)
        -- If there's only one game, we don't need to ask the player to pick a game.
        -- Just use the gameId of the one game.
        for gid, _ in gameDetailsByGameId do
            gameId = gid
            break
        end
        assert(gameId ~= nil, "Should have a gameId")
        assert(type(gameId) == "number", "gameId should be a number")
        selectPublicOrPrivate(screenGui, gameId, onTableConfigSelected)
        return
    else
        -- Throw up a game selection dialog.
        local function addCustomControls(parent: Frame)
            for gameId, gameDetails in gameDetailsByGameId do
                GuiUtils.makeGameButton(parent, gameDetails, function()
                    selectPublicOrPrivate(screenGui, gameId, onTableConfigSelected)
                end)
           end
        end

        local dialogConfig: CommonTypes.DialogConfig = {
            title = "Select a game",
            description = "Click the game you want to play",
            addCustomControls = addCustomControls,
        }

        DialogUtils.makeDialog(screenGui, dialogConfig)
    end
end

return TableConfigDialog
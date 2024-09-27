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
local Utils = require(RobloxBoardGameShared.Modules.Utils)

local Cryo = require(ReplicatedStorage.Cryo)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)
local GuiConstants = require(RobloxBoardGameClient.Modules.GuiConstants)
local GameGuiUtils = require(RobloxBoardGameClient.Modules.GameGuiUtils)

local makePublicOrPrivateDialog = function(gameId: CommonTypes.GameId, onTableConfigSelected: (gameId: CommonTypes.GameId, isPublic: boolean) -> nil)
    -- Put up a UI to get public or private.
    -- FIXME(dbanks): this is horrible temp hack using an array of buttons to pick from a set of two options.
    -- Implement a proper toggle switch (or radio buttons or whatever)
    local dialogConfig: DialogUtils.DialogConfig = {
        title = "Public or Private?",
        description = "Anyone in experience can join a public game.  Only invited players can join a private game.",
        dialogButtonConfigs = {
            {
                text = "Public",
                callback = function()
                    onTableConfigSelected(gameId, true)
                end,
            } :: DialogUtils.DialogButtonConfig,
            {
                text = "Private",
                callback = function()
                    onTableConfigSelected(gameId, false)
                end,
            } :: DialogUtils.DialogButtonConfig,
        } :: {DialogUtils.DialogConfig},
    }

    DialogUtils.makeDialog(dialogConfig)
end

-- Helper for non-standard controls in the dialog.
local function makeCustomDialogContent(parent: Frame, gameDetailsByGameId: CommonTypes.GameDetailsByGameId, onTableConfigSelected: (gameId: CommonTypes.GameId, isPublic: boolean) -> nil)
    local rowContent = GuiUtils.addRowWithItemGridAndReturnRowContent(parent, "Row_GameSelectionControls", GuiConstants.gameWidgetSize)

    local gameDetailsArray = Cryo.Dictionary.values(gameDetailsByGameId)
     table.sort(gameDetailsArray, function(a, b)
        return a.name < b.name
     end)
    for _, gameDetails in gameDetailsArray do
        GameGuiUtils.addGameButtonInContainer(rowContent, gameDetails, function()
            DialogUtils.cleanupDialog()
            makePublicOrPrivateDialog(gameDetails.gameId, onTableConfigSelected)
        end)
    end
end

TableConfigDialog.makeGameSelectionDialog = function(onTableConfigSelected: (gameId: CommonTypes.GameId, isPublic: boolean) -> nil)
    local gameDetailsByGameId = GameDetails.getAllGameDetails()
    assert(gameDetailsByGameId, "Should have gameDetailsByGameId")
    local numGames = Utils.tableSize(gameDetailsByGameId)
    assert(numGames, "Should have at last one item in gameDetailsByGameId")

    local gameId
    if numGames == 1 then
        -- If there's only one game, we don't need to ask the player to pick a game.
        -- Just use the gameId of the one game.
        for gid, _ in gameDetailsByGameId do
            gameId = gid
            break
        end
        assert(gameId ~= nil, "Should have a gameId")
        assert(type(gameId) == "number", "gameId should be a number")
        makePublicOrPrivateDialog(gameId, onTableConfigSelected)
    else
        local dialogConfig: DialogUtils.DialogConfig = {
            title = "Select a game",
            description = "Click the game you want to play",
            makeCustomDialogContent = function(parent: Frame)
                makeCustomDialogContent(parent, gameDetailsByGameId, onTableConfigSelected)
            end
        }

        DialogUtils.makeDialog(dialogConfig)
    end
end

return TableConfigDialog
--[[
User has to pick a game.
If there's just one game, no prompts or anything just pass back that game.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cryo = require(ReplicatedStorage.Cryo)

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local GameGuiUtils = require(RobloxBoardGameClient.Modules.GameGuiUtils)

local GamePicker = {}

local function makeCustomDialogContent(dialogId: number, parent: Frame, callback: (gameId: CommonTypes.GameId) -> nil)
    local gameDetailsByGameId = GameDetails.getGameDetailsByGameId()

    local gamesScrollingFrame = GuiUtils.addScrollingItemGrid(parent, "GamesScroll", GuiConstants.gameWidgetSize, 1)

    local gameDetailsArray = Cryo.Dictionary.values(gameDetailsByGameId)
     table.sort(gameDetailsArray, function(a, b)
        return a.name < b.name
     end)
    for _, gameDetails in gameDetailsArray do
        GameGuiUtils.addGameButtonInContainer(gamesScrollingFrame, gameDetails, function()
            DialogUtils.cleanupDialog(dialogId)
            callback(gameDetails.gameId)
        end)
    end

    -- Adjust dialog height to fit both content and screen.
    DialogUtils.adjustSizeForContentAndScreenFit(parent)
end

-- Pop up a dialog showing all games, when game is selected hit callback.
function GamePicker.promptToSelectGameID(title: string, description: string, callback: (CommonTypes.GameId))
    local gameDetailsByGameId = GameDetails.getGameDetailsByGameId()
    assert(gameDetailsByGameId, "Should have gameDetailsByGameId")
    local keys = Cryo.Dictionary.keys(gameDetailsByGameId)
    local numGames = #keys
    assert(numGames, "Should have at last one item in gameDetailsByGameId")

    if numGames == 1 then
        -- If there's only one game, no point in picking: it's just that one.
        local gameId = numGames[1]
        callback(gameId)
        return
    end

    -- Pop up a dialog showing all games.
    local dialogConfig: DialogUtils.DialogConfig = {
        title = title,
        description = description,
        makeCustomDialogContent = function(dialogId: number, parent: Frame)
            makeCustomDialogContent(dialogId, parent, callback)
        end,
    }

    DialogUtils.makeDialogAndReturnId(dialogConfig)
end

return GamePicker
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

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local DialogUtils = require(RobloxBoardGameStarterGui.Modules.DialogUtils)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)

local selectPublicOrPrivate = function(gameId: CommonTypes.GameId, onTableConfigSelected: (gameId: CommonTypes.GameId, isPublic: boolean) -> nil)
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

    DialogUtils.makeDialog(dialogConfig)
end

-- Helper for non-standard controls in the dialog.
local function _makeRowAndAddCustomControls(parent: Frame, gameDetailsByGameId: CommonTypes.GameDetailsByGameId, onTableConfigSelected: (gameId: CommonTypes.GameId, isPublic: boolean) -> nil)
    local rowOptions = {
        isScrolling = true,
        useGridLayout = true,
        gridCellSize = UDim2.fromOffset(GuiConstants.gameWidgetX, GuiConstants.gameWidgetY),
    }

    local rowContent = GuiUtils.addRowAndReturnRowContent(parent, "Row_Controls", rowOptions, {
        AutomaticSize = Enum.AutomaticSize.None,
        ClipsDescendants = true,
        BorderSizePixel = 0,
        BorderColor3 = Color3.new(0.5, 0.5, 0.5),
        BorderMode = Enum.BorderMode.Outline,
        BackgroundColor3 = Color3.new(0.9, 0.9, 0.9),
        BackgroundTransparency = 0,
    })

    GuiUtils.addUIGradient(rowContent, GuiConstants.scrollBackgroundGradient)
    GuiUtils.addPadding(rowContent, {
        PaddingLeft = UDim.new(0, 0),
        PaddingRight = UDim.new(0, 0),
    })

    local gridLayout = rowContent:FindFirstChildWhichIsA("UIGridLayout", true)
    assert(gridLayout, "Should have gridLayout")
    local cellHeight = gridLayout.CellSize.Y.Offset
    local totalHeight = 2 * cellHeight + 3 * GuiConstants.standardPadding
    rowContent.Size = UDim2.new(1, 0, 0, totalHeight)

    for gid, gameDetails in gameDetailsByGameId do
        GuiUtils.addGameButton(rowContent, gameDetails, function()
            DialogUtils.cleanupDialog()
            selectPublicOrPrivate(gid, onTableConfigSelected)
        end)
    end
end

TableConfigDialog.promptForTableConfig = function(onTableConfigSelected: (gameId: CommonTypes.GameId, isPublic: boolean) -> nil)
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
        selectPublicOrPrivate(gameId, onTableConfigSelected)
        return
    else
        local dialogConfig: CommonTypes.DialogConfig = {
            title = "Select a game",
            description = "Click the game you want to play",
            makeRowAndAddCustomControls = function(parent: Frame)
                _makeRowAndAddCustomControls(parent, gameDetailsByGameId, onTableConfigSelected)
            end
        }

        DialogUtils.makeDialog(dialogConfig)
    end
end

return TableConfigDialog
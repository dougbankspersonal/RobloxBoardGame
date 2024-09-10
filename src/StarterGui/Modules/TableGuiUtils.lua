--[[
Widgets for tables.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local TableDescriptions = require(RobloxBoardGameStarterGui.Modules.TableDescriptions)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)
local GameGuiUtils = require(RobloxBoardGameStarterGui.Modules.GameGuiUtils)
local UserGuiUtils = require(RobloxBoardGameStarterGui.Modules.UserGuiUtils)

local TableGuiUtils = {}

--[[
    Make a clickable button representing a game table.
]]
TableGuiUtils.addTableButtonInContainer = function(parent: Instance, tableDescription: CommonTypes.TableDescription, onButtonCiicked: () -> nil): (Frame, TextButton)
    local frame, textButton = GuiUtils.addStandardTextButtonInContainer(parent, GuiConstants.tableButtonName, {
        BackgroundColor3 = GuiConstants.tableButtonBackgroundColor,
        Size = GuiConstants.tableWidgetSize,
    })

    textButton.Activated:Connect(onButtonCiicked)

    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    assert(gameDetails, "Should have gameDetails")

    GuiUtils.addUIListLayout(textButton, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })
    GuiUtils.addPadding(textButton)

    local imageLabel = GuiUtils.addItemImage(textButton, {
        LayoutOrder = 1,
    })
    local gameTextLabel = GuiUtils.addItemTextLabel(textButton, {
        LayoutOrder = 2,
    })
    local hostTextLabel = GuiUtils.addItemTextLabel(textButton, {
        LayoutOrder = 3,
        RichText = true,
    })

    local formatString = GuiUtils.italicize("Hosted by")
    formatString = formatString .. ":"

    GameGuiUtils.configureGameImage(imageLabel, gameDetails)
    GameGuiUtils.configureGameTextLabel(gameTextLabel, gameDetails)
    UserGuiUtils.configureUserTextLabel(hostTextLabel, tableDescription.hostUserId, formatString)

    return frame, textButton
end

-- Make a widgetContainer containing a button you click to join a game.
TableGuiUtils.addTableButtonWidgetContainer = function(parent: Instance, tableId: number, onClick: () -> nil): Frame
    local tableDescription = TableDescriptions.getTableDescription(tableId)
    -- Should exist.
    assert(tableDescription, "Should have a tableDescription")

    local tableButtonContainer = GuiUtils.makeWidgetContainer(parent, "Table", tableId)

    TableGuiUtils.addTableButtonInContainer(tableButtonContainer, tableDescription, onClick)

    return tableButtonContainer
end

return TableGuiUtils
--[[
    Some constants for UI fu: names, sizes, colors, etc.
]]

local GuiConstants = {}

-- Common names
GuiConstants.layoutOrderGeneratorName = "LayoutOrderGenerator"
GuiConstants.rowContentName = "RowContent"
GuiConstants.rowUIGridLayoutName = "Row_UIGridLayout"
GuiConstants.widgetLoadingName = "WidgetLoading"

GuiConstants.mainFrameName = "MainFrame"
GuiConstants.containingScrollingFrameName = "ContainingScrollingFrame"
GuiConstants.textButtonName = "TextButton"
GuiConstants.textLabelName = "TextLabel"

GuiConstants.dialogBackgroundName = "DialogBackground"
GuiConstants.nullWidgetName = "NullWidget"
GuiConstants.deadMeatTweeningOutName = "DeadMeatTweeningOut"

GuiConstants.persistentNameStart = "Persistent_"

-- Font sizes
GuiConstants.textLabelFontSize = 14
GuiConstants.dialogTitleFontSize = 24
GuiConstants.gameTextLabelFontSize = 8
GuiConstants.userTextLabelFontSize = 8
GuiConstants.rowHeaderFontSize = 16

-- Various pixel measurements.
GuiConstants.standardCornerSize = 10

GuiConstants.rowLabelWidth = 200
GuiConstants.standardPadding = 5
GuiConstants.mainFramePadding = 20
GuiConstants.paddingBetweenRows = 14

GuiConstants.gameImageWidth = 60
GuiConstants.gameImageHeight = 60
GuiConstants.gameLabelWidth = 130
GuiConstants.gameLabelHeight = 20

GuiConstants.userImageWidth = 60
GuiConstants.userImageHeight = 60
GuiConstants.userLabelWidth = 130
GuiConstants.userLabelHeight = 20

GuiConstants.gameWidgetWidth = math.max(GuiConstants.gameImageWidth, GuiConstants.gameLabelWidth) + 2 * GuiConstants.standardPadding
GuiConstants.gameWidgetHeight = GuiConstants.gameImageHeight + GuiConstants.gameLabelHeight + 3 * GuiConstants.standardPadding

GuiConstants.userWidgetX = math.max(GuiConstants.userImageWidth, GuiConstants.userLabelWidth) + 2 * GuiConstants.standardPadding
GuiConstants.userWidgetY = GuiConstants.userImageHeight + GuiConstants.userLabelHeight + 3 * GuiConstants.standardPadding

GuiConstants.tableWidgetX = GuiConstants.userWidgetX
GuiConstants.tableWidgetY = GuiConstants.gameImageHeight + GuiConstants.gameLabelHeight + GuiConstants.userLabelHeight + 4 * GuiConstants.standardPadding

GuiConstants.redXSize = 20
GuiConstants.redXMargin = 5

GuiConstants.dialogOuterPadding = 20

-- Z indices
GuiConstants.mainFrameZIndex = 2
GuiConstants.dialogBackgroundZIndex = 3
GuiConstants.dialogInputSinkZIndex = 4
GuiConstants.dialogZIndex = 5

-- itemWidget = a widget for a user, game, or user.  Has images, text, and possible button overlays.
GuiConstants.itemWidgetImageZIndex = 2
GuiConstants.itemWidgetTextZIndex = 3
GuiConstants.itemWidgetOverlayZIndex = 4

-- Colors
GuiConstants.whiteToGrayColorSequence = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.8, 0.8, 0.8))
GuiConstants.scrollBackgroundGradient = ColorSequence.new(Color3.new(0.8, 0.8, 0.8), Color3.new(0.6, 0.6, 0.6))
GuiConstants.blueColorSequence = ColorSequence.new(Color3.new(0.5, 0.6, 0.8), Color3.new(0.2, 0.3, 0.5))

GuiConstants.disabledButtonTextColor = Color3.new(0.35, 0.35, 0.35)
GuiConstants.enabledButtonTextColor = Color3.new(0, 0, 0)

-- Times
GuiConstants.standardTweenTime = 0.25

-- Images
GuiConstants.redXImage = "http://www.roblox.com/asset/?id=171846064"

-- Debug only
GuiConstants.mockUserWaitSec = 60

return GuiConstants
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

-- Font sizes
GuiConstants.textLabelFontSize = 14
GuiConstants.dialogTitleFontSize = 24
GuiConstants.gameTextLabelFontSize = 10
GuiConstants.rowHeaderFontSize = 16

-- Various measurements.
GuiConstants.rowLabelWidth = 200
GuiConstants.standardPadding = 5
GuiConstants.mainFramePadding = 10

GuiConstants.gameImageX = 100
GuiConstants.gameImageY = 100
GuiConstants.gameLabelHeight = 20

GuiConstants.userImageX = 60
GuiConstants.userImageY = 60
GuiConstants.userLabelHeight = 20
GuiConstants.userLabelWidth = 180

GuiConstants.gameWidgetX = GuiConstants.gameImageX + 2 * GuiConstants.standardPadding
GuiConstants.gameWidgetY = GuiConstants.gameImageY + GuiConstants.gameLabelHeight + 3 * GuiConstants.standardPadding

GuiConstants.userWidgetX = GuiConstants.userLabelWidth + 2 * GuiConstants.standardPadding
GuiConstants.userWidgetY = GuiConstants.userImageY + GuiConstants.userLabelHeight + 3 * GuiConstants.standardPadding

GuiConstants.redXSize = 20
GuiConstants.redXMargin = 5

GuiConstants.dialogOuterPadding = 20

-- Z indices
GuiConstants.mainFrameZIndex = 2
GuiConstants.dialogBackgroundZIndex = 3
GuiConstants.dialogInputSinkZIndex = 4
GuiConstants.dialogZIndex = 5

GuiConstants.iotlImageZIndex = 2
GuiConstants.iotlTextZIndex = 3
GuiConstants.iotlNextZIndex = 4

-- Colors
GuiConstants.whiteToGrayColorSequence = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.8, 0.8, 0.8))
GuiConstants.scrollBackgroundGradient = ColorSequence.new(Color3.new(0.8, 0.8, 0.8), Color3.new(0.6, 0.6, 0.6))
GuiConstants.blueColorSequence = ColorSequence.new(Color3.new(0.5, 0.6, 0.8), Color3.new(0.2, 0.3, 0.5))

-- Images
GuiConstants.redXImage = "http://www.roblox.com/asset/?id=171846064"

-- Debug only
GuiConstants.mockUserWaitSec = 60

return GuiConstants
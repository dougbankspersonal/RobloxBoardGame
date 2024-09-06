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
GuiConstants.textBoxName = "TextBox"

GuiConstants.dialogBackgroundName = "DialogBackground"
GuiConstants.dialogContentFrameName = "DialogContentFrame"
GuiConstants.dialogName = "Dialog"

GuiConstants.nullWidgetName = "NullWidget"
GuiConstants.deadMeatTweeningOutName = "DeadMeatTweeningOut"

GuiConstants.persistentNameStart = "Persistent_"

GuiConstants.inactiveOverlayName = "InactiveOverlay"

GuiConstants.userButtonName = "UserButton"
GuiConstants.userWidgetName = "UserWidget"
GuiConstants.gameButtonName = "GameButton"
GuiConstants.tableButtonName = "TableButton"
GuiConstants.checkboxName = "Checkbox"

GuiConstants.checkMarkString = "✓"
GuiConstants.bulletString = "•"

-- Font sizes
GuiConstants.textBoxFontSize = 16
GuiConstants.textLabelFontSize = 16
GuiConstants.largeTextLabelFontSize = 20
GuiConstants.dialogTitleFontSize = 26
GuiConstants.gameTextLabelFontSize = 14
GuiConstants.userTextLabelFontSize = 10
GuiConstants.rowHeaderFontSize = 18

-- Various pixel measurements.
GuiConstants.standardCornerSize = 10
GuiConstants.textButtonHeight = 40

GuiConstants.rowLabelWidth = 200
GuiConstants.standardPadding = 10
GuiConstants.mainFramePadding = 20
GuiConstants.mainFrameTopPadding = 80
GuiConstants.paddingBetweenRows = 14

GuiConstants.gameImageWidth = 60
GuiConstants.gameImageHeight = 60
GuiConstants.gameLabelWidth = 130
GuiConstants.gameLabelHeight = 20

GuiConstants.userImageWidth = 60
GuiConstants.userImageHeight = 60
GuiConstants.miniUserImageWidth = 30
GuiConstants.miniUserImageHeight = 30
GuiConstants.userLabelWidth = 130
GuiConstants.userLabelHeight = 20

GuiConstants.gameWidgetWidth = math.max(GuiConstants.gameImageWidth, GuiConstants.gameLabelWidth) + 2 * GuiConstants.standardPadding
GuiConstants.gameWidgetHeight = GuiConstants.gameImageHeight + GuiConstants.gameLabelHeight + 3 * GuiConstants.standardPadding

GuiConstants.userWidgetWidth = math.max(GuiConstants.userImageWidth, GuiConstants.userLabelWidth) + 2 * GuiConstants.standardPadding
GuiConstants.userWidgetHeight = GuiConstants.userImageHeight + GuiConstants.userLabelHeight + 3 * GuiConstants.standardPadding

GuiConstants.miniUserWidgetWidth = math.max(GuiConstants.miniUserImageWidth, GuiConstants.userLabelWidth) + 2 * GuiConstants.standardPadding
GuiConstants.miniUserWidgetHeight = GuiConstants.miniUserImageHeight + GuiConstants.userLabelHeight + 3 * GuiConstants.standardPadding

GuiConstants.topBarHeight = GuiConstants.miniUserWidgetHeight + 2 * GuiConstants.standardPadding
GuiConstants.bottomBarHeight = GuiConstants.textButtonHeight + 2 * GuiConstants.standardPadding

GuiConstants.tableWidgeWidth = GuiConstants.userWidgetWidth
GuiConstants.tableWidgetHeight = GuiConstants.gameImageHeight + GuiConstants.gameLabelHeight + GuiConstants.userLabelHeight + 4 * GuiConstants.standardPadding

GuiConstants.redXSize = 20
GuiConstants.redXMargin = 5

GuiConstants.screenToDialogPadding = 50
GuiConstants.dialogToContentPadding = 20

GuiConstants.defaultUIListLayoutPadding = 5
GuiConstants.buttonsUIListLayoutPadding = 20
GuiConstants.buttonInternalSidePadding = 20

GuiConstants.checkboxSize = 30

GuiConstants.TablePlayingTopBarHeight = 50

-- Z indices
GuiConstants.mainFrameZIndex = 2
GuiConstants.dialogBackgroundZIndex = 3
GuiConstants.dialogInputSinkZIndex = 4
GuiConstants.dialogZIndex = 5


-- itemWidget = a widget for a user, game, or user.  Has images, text, and possible button overlays.
GuiConstants.itemWidgetImageZIndex = 2
GuiConstants.itemWidgetTextZIndex = 3
GuiConstants.itemWidgetRedXZIndex = 4
GuiConstants.itemWidgetOverlayZIndex = 5

-- Colors
local function softenColor(c: Color3): Color3
    local h, s, v = c:ToHSV()
    return Color3.fromHSV(h, s, v * 1.4)
end


GuiConstants.buttonTextColor = Color3.new(1, 1, 1)

GuiConstants.buttonBackgroundColor = Color3.new(0.2, 0.25, 0.5)
GuiConstants.disabledBackgroundColor = softenColor(GuiConstants.buttonBackgroundColor)

GuiConstants.tableButtonBackgroundColor = Color3.new(0.5, 0.2, 0.25)
GuiConstants.tableWidgetBackgroundColor = softenColor(GuiConstants.tableButtonBackgroundColor)

GuiConstants.gameButtonBackgroundColor = Color3.new(0.2, 0.5, 0.25)
GuiConstants.gameWidgetBackgroundColor = softenColor(GuiConstants.gameButtonBackgroundColor)

GuiConstants.userButtonBackgroundColor = Color3.new(0.5, 0.3, 0.25)
GuiConstants.userWidgetBackgroundColor = softenColor(GuiConstants.userButtonBackgroundColor)

GuiConstants.whiteToBlueColorSequence = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.6, 0.6, 0.8))
GuiConstants.scrollBackgroundGradient = ColorSequence.new(Color3.new(0.8, 0.8, 0.8), Color3.new(0.6, 0.6, 0.6))
GuiConstants.blueColorSequence = ColorSequence.new(Color3.new(0.5, 0.6, 0.8), Color3.new(0.2, 0.3, 0.5))

-- Times
GuiConstants.standardTweenTime = 0.25

-- Images
GuiConstants.redXImage = "http://www.roblox.com/asset/?id=171846064"

-- Debug only
GuiConstants.mockUserWaitSec = 60

return GuiConstants
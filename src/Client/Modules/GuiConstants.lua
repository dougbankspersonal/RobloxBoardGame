--[[
    Some constants for UI fu: names, sizes, colors, etc.
]]

local GuiConstants = {}

--[[
Common names
]]
GuiConstants.uberBackgroundName = "UberBackground"
GuiConstants.containingScrollingFrameName = "ContainingScrollingFrame"
GuiConstants.mainFrameName = "MainFrame"

GuiConstants.layoutOrderGeneratorName = "LayoutOrderGenerator"
GuiConstants.rowContentName = "RowContent"
GuiConstants.rowUIGridLayoutName = "Row_UIGridLayout"
GuiConstants.widgetLoadingName = "WidgetLoading"


GuiConstants.itemImageName = "ItemImage"
GuiConstants.itemTextName = "ItemText"

GuiConstants.nullStaticWidgetName = "NullStaticWidget"
GuiConstants.deadMeatTweeningOutName = "DeadMeatTweeningOut"

GuiConstants.persistentNameStart = "Persistent_"

GuiConstants.checkMarkString = "✓"
GuiConstants.bulletString = "•"

GuiConstants.frameContainerName = "FrameContainer"

-- Dialog namees.
GuiConstants.dialogBackgroundName = "DialogBackground"
GuiConstants.dialogContentFrameName = "DialogContentFrame"
GuiConstants.dialogName = "Dialog"
GuiConstants.inactiveOverlayName = "InactiveOverlay"

-- Generic button/widget names.
GuiConstants.checkboxName = "Checkbox"
GuiConstants.textButtonName = "TextButton"
GuiConstants.textButtonContainerName = "TextButtonContainer"
GuiConstants.textLabelName = "TextLabel"
GuiConstants.textBoxName = "TextBox"

-- Buttons and widgets for users, games, and tables.
GuiConstants.userButtonName = "UserButton"
GuiConstants.userStaticName = "UserStatic"
GuiConstants.gameButtonName = "GameButton"
GuiConstants.tableButtonName = "TableButton"

-- "Game Playing" screen.
GuiConstants.gamePlayingSideBarName = "SidebarFrame"
GuiConstants.gamePlayingControlsName = "ControlsFrame"
GuiConstants.gamePlayingTableMetadataName = "TableMetadataFrame"
GuiConstants.gamePlayingContentName = "GameContent"

--[[
Fonts
]]
GuiConstants.defaultFont = Enum.Font.Merriweather

--[[
Font sizes
]]
GuiConstants.textBoxFontSize = 16
GuiConstants.textLabelFontSize = 16
GuiConstants.largeTextLabelFontSize = 20
GuiConstants.dialogTitleFontSize = 26
GuiConstants.gameTextLabelFontSize = 14
GuiConstants.userTextLabelFontSize = 14
GuiConstants.rowHeaderFontSize = 18

GuiConstants.gamePlayingSidebarH1FontSize = 12
GuiConstants.gamePlayingSidebarH2FontSize = 11
GuiConstants.gamePlayingSidebarH3FontSize = 10
GuiConstants.gamePlayingSidebarNormalFontSize = 9

--[[
Measurements in Pixels.
]]
GuiConstants.messageLogHeight = 200


GuiConstants.dialogButtonWidth = 150
GuiConstants.dialogButtonHeight = 40

GuiConstants.standardCornerSize = 4
GuiConstants.textButtonHeight = 40

GuiConstants.rowLabelWidth = 200
GuiConstants.standardPadding = 10
GuiConstants.mainFramePadding = 20
GuiConstants.paddingBetweenRows = 14

-- User widget details.
GuiConstants.userImageWidth = 80
GuiConstants.userImageHeight = 80
GuiConstants.userLabelWidth = 130
GuiConstants.userLabelHeight = 25
GuiConstants.userWidgetWidth = math.max(GuiConstants.userImageWidth, GuiConstants.userLabelWidth) + 2 * GuiConstants.standardPadding
GuiConstants.userWidgetHeight = GuiConstants.userImageHeight + GuiConstants.userLabelHeight + 2 * GuiConstants.standardPadding
GuiConstants.redXSize = 20
GuiConstants.redXMargin = 5

-- Mini user widget details.
GuiConstants.miniUserImageWidth = 30
GuiConstants.miniUserImageHeight = 30
GuiConstants.miniUserWidgetWidth = math.max(GuiConstants.miniUserImageWidth, GuiConstants.userLabelWidth) + 2 * GuiConstants.standardPadding
GuiConstants.miniUserWidgetHeight = GuiConstants.miniUserImageHeight + GuiConstants.userLabelHeight + 2 * GuiConstants.standardPadding

-- Game widget details.
GuiConstants.gameImageWidth = 60
GuiConstants.gameImageHeight = 60
GuiConstants.gameLabelWidth = 130
GuiConstants.gameLabelHeight = 25
GuiConstants.gameWidgetWidth = math.max(GuiConstants.gameImageWidth, GuiConstants.gameLabelWidth) + 2 * GuiConstants.standardPadding
GuiConstants.gameWidgetHeight = GuiConstants.gameImageHeight + GuiConstants.gameLabelHeight + 3 * GuiConstants.standardPadding

-- Table widget details.
local userInTableWidth = GuiConstants.userLabelWidth
local gameInTableWidth = math.max(GuiConstants.gameLabelWidth, GuiConstants.gameImageWidth)
GuiConstants.tableWidgetWidth = math.max(userInTableWidth, gameInTableWidth) + 2 * GuiConstants.standardPadding
GuiConstants.tableWidgetHeight = GuiConstants.gameImageHeight + GuiConstants.gameLabelHeight + GuiConstants.userLabelHeight + 4 * GuiConstants.standardPadding

GuiConstants.gamePlayingSidebarWidth = 250
GuiConstants.gamePlayingSidebarMetadataValueIndent = 10
GuiConstants.gamePlayingSidebarH2Separation = 10
GuiConstants.gamePlayingSidebarH3Separation = 5
GuiConstants.gamePlayingSidebarControlsHeight = GuiConstants.textButtonHeight + 2 * GuiConstants.standardPadding

-- Paddings.
GuiConstants.screenToDialogPadding = 50
GuiConstants.dialogToContentPadding = 20
GuiConstants.gamePlayingTopBarPadding = 40
GuiConstants.defaultUIListLayoutPadding = 5
GuiConstants.buttonsUIListLayoutPadding = 20
GuiConstants.buttonInternalSidePadding = 20
GuiConstants.noPadding = UDim.new(0, 0)
GuiConstants.robloxTopBarBottomPadding = 10

GuiConstants.checkboxSize = 30

GuiConstants.TablePlayingTopBarHeight = 50

--[[
UDim2s
]]
GuiConstants.userWidgetSize = UDim2.fromOffset(GuiConstants.userWidgetWidth, GuiConstants.userWidgetHeight)
GuiConstants.gameWidgetSize = UDim2.fromOffset(GuiConstants.gameWidgetWidth, GuiConstants.gameWidgetHeight)
GuiConstants.tableWidgetSize = UDim2.fromOffset(GuiConstants.tableWidgetWidth, GuiConstants.tableWidgetHeight)
GuiConstants.miniUserWidgetSize = UDim2.fromOffset(GuiConstants.miniUserWidgetWidth, GuiConstants.miniUserWidgetHeight)
GuiConstants.miniUserImageSize = UDim2.fromOffset(GuiConstants.miniUserImageWidth, GuiConstants.miniUserImageHeight)

GuiConstants.gameLabelSize = UDim2.fromOffset(GuiConstants.gameLabelWidth, GuiConstants.gameLabelHeight)
GuiConstants.userLabelSize = UDim2.fromOffset(GuiConstants.userLabelWidth, GuiConstants.userLabelHeight)

--[[
Z indices
]]
GuiConstants.mainFrameZIndex = 2
GuiConstants.dialogBackgroundZIndex = 3
GuiConstants.dialogInputSinkZIndex = 4
GuiConstants.dialogZIndex = 5

-- itemWidget = a widget for a user, game, or user.  Has images, text, and possible button overlays.
GuiConstants.itemLabelImageZIndex = 2
GuiConstants.itemLabelTextZIndex = 3
GuiConstants.itemWidgetRedXZIndex = 4
GuiConstants.itemLabelOverlayZIndex = 5

--[[
-Colors
]]
local function adjustColorBrightness(c: Color3, scale: number): Color3
    local h, s, v = c:ToHSV()
    return Color3.fromHSV(h, s, v * scale)
end



GuiConstants.rowOfItemsBackgroundColor = Color3.new(0.8, 0.8, 0.9)
GuiConstants.rowOfItemsBorderColor = adjustColorBrightness(GuiConstants.rowOfItemsBackgroundColor, 0.4)

GuiConstants.imageBackgroundColor = adjustColorBrightness(GuiConstants.rowOfItemsBackgroundColor, 0.7)

GuiConstants.greenFelt = Color3.new(0.4, 0.7, 0.5)

GuiConstants.scrollBarColor = Color3.new(0, 0, 0)
GuiConstants.scrollBarTransparency = 0.3

GuiConstants.uberBackgroundColor = adjustColorBrightness(GuiConstants.greenFelt, 0.3)

GuiConstants.tableSelectionBackgroundColor = GuiConstants.greenFelt
GuiConstants.tableWaitingBackgroundColor = GuiConstants.greenFelt
GuiConstants.gamePlayingBackgroundColor = GuiConstants.greenFelt
GuiConstants.gameFinishedBackgroundColor = GuiConstants.greenFelt

GuiConstants.gamePlayingSidebarColor = adjustColorBrightness(GuiConstants.gamePlayingBackgroundColor, 0.8)
GuiConstants.gamePlayingSidebarBorderColor = adjustColorBrightness(GuiConstants.gamePlayingSidebarColor, 0.4)

GuiConstants.buttonTextColor = Color3.new(1, 1, 1)
GuiConstants.widgetTextColor = Color3.new(0.1, 0.1, 0.1)

GuiConstants.buttonBackgroundColor = Color3.new(0.2, 0.25, 0.5)
GuiConstants.disabledBackgroundColor = adjustColorBrightness(GuiConstants.buttonBackgroundColor, 1.4)

GuiConstants.userButtonBackgroundColor = adjustColorBrightness(GuiConstants.rowOfItemsBackgroundColor, 0.7)
GuiConstants.tableButtonBackgroundColor = adjustColorBrightness(GuiConstants.rowOfItemsBackgroundColor, 0.7)

GuiConstants.scrollBackgroundColor = Color3.new(0.9, 0.9, 0.9)

GuiConstants.standardMainScreenColorSequence = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.7, 0.7, 0.9))
GuiConstants.scrollBackgroundGradient = ColorSequence.new(Color3.new(0.8, 0.8, 0.8), Color3.new(0.6, 0.6, 0.6))
GuiConstants.blueColorSequence = ColorSequence.new(Color3.new(0.5, 0.6, 0.8), Color3.new(0.2, 0.3, 0.5))

--[[
Times
]]
GuiConstants.standardTweenTime = 0.25
GuiConstants.messageQueueTransparencyTweenTime = 0.25
GuiConstants.scrollingFrameSlideTweenTime = 0.25

--[[
Images
]]
GuiConstants.redXImage = "http://www.roblox.com/asset/?id=171846064"

--[[
Debug only
]]
GuiConstants.mockUserWaitSec = 60

return GuiConstants
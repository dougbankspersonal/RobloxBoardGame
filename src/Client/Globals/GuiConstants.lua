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
GuiConstants.uiGridLayoutName = "_UIGridLayout"
GuiConstants.labeledRowTextLabelName = "LabeledRowTextLabel"
GuiConstants.rightHandContentName = "RightHandContent"

-- Common widgets.
GuiConstants.itemImageName = "ItemImage"
GuiConstants.itemTextName = "ItemText"
GuiConstants.nullStaticWidgetName = "NullStaticWidget"
GuiConstants.deadMeatTweeningOutName = "DeadMeatTweeningOut"

-- Loading page.
GuiConstants.widgetLoadingName = "WidgetLoading"

-- Dialog
GuiConstants.dialogControlsName = "DialogControls"

-- Friend selection dialog.
GuiConstants.selectedFriendsName = "SelectedFriends"

-- Table selection UI.
GuiConstants.publicTablesName = "PublicTables"
GuiConstants.invitedTablesName = "InvitedTables"

-- Table waiting UI.
GuiConstants.startButtonName = "StartButton"
GuiConstants.tableWaitingControlsName = "TableWaitingControls"
GuiConstants.membersName = "Members"
GuiConstants.invitesName = "Invites"

GuiConstants.persistentNameStart = "Persistent_"

GuiConstants.checkMarkString = "✓"
GuiConstants.bulletString = "•"

GuiConstants.frameContainerName = "FrameContainer"

-- Dialog namees.
GuiConstants.dialogBackgroundName = "DialogBackground"
GuiConstants.dialogContentFrameName = "DialogContentFrame"
GuiConstants.dialogName = "Dialog"
GuiConstants.inactiveOverlayName = "InactiveOverlay"
GuiConstants.dialogDescriptionTextLabel = "DialogDescriptionTextLabel"
GuiConstants.dialogTitleTextLabel = "DialogTitleTextLabel"
GuiConstants.dialogHeadingTextLabel = "DialogHeadingTextLabel"

-- Analytics
GuiConstants.statusUpdateTextLabel = "StatusUpdateTextLabel"

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

-- Paddings.
GuiConstants.defaultUIListLayoutPaddingPx = 5
GuiConstants.buttonInternalSidePaddingPx = 20
GuiConstants.robloxTopBarBottomPaddingPx = 10
GuiConstants.labelToRightSideContentPaddingPx = 10
GuiConstants.cellPaddingPx = 5
GuiConstants.screenToDialogPaddingPx = 50
GuiConstants.dialogToContentPaddingPx = 20
GuiConstants.standardPaddingPx = 10
GuiConstants.betweenRowPaddingPx = 14

GuiConstants.mainFrameToContentPaddingPx = 20
GuiConstants.betweenButtonPaddingPx = 10


GuiConstants.betweenButtonPadding = UDim.new(0, GuiConstants.betweenButtonPaddingPx)
GuiConstants.mainFrameToContentPadding = UDim.new(0, GuiConstants.mainFrameToContentPaddingPx)
GuiConstants.defaultUIListLayoutPadding = UDim.new(0, GuiConstants.defaultUIListLayoutPaddingPx)
GuiConstants.buttonInternalSidePadding = UDim.new(0, GuiConstants.buttonInternalSidePaddingPx)
GuiConstants.standardPadding = UDim.new(0, GuiConstants.standardPaddingPx)
GuiConstants.cellPadding = UDim2.fromOffset(GuiConstants.cellPaddingPx)
GuiConstants.dialogToContentPadding = UDim.new(0, GuiConstants.dialogToContentPaddingPx)
GuiConstants.betweenRowPadding = UDim.new(0, GuiConstants.betweenRowPaddingPx)
GuiConstants.noPadding = UDim.new(0, 0)
GuiConstants.labelToRightSideContentPadding = UDim.new(0, GuiConstants.labelToRightSideContentPaddingPx)

-- Dialog stuff.
GuiConstants.dialogTitleHeight = 26
GuiConstants.dialogDescriptionHeight = 16

GuiConstants.dialogButtonWidth = 150
GuiConstants.dialogButtonHeight = 40
GuiConstants.gameConfigPickerMinWidth = 400
GuiConstants.gamePickerDialogMinWidth = 400

GuiConstants.standardCornerSize = 4
GuiConstants.textButtonHeight = 40

GuiConstants.rowLabelWidth = 200

-- User widget details.
GuiConstants.userImageWidth = 80
GuiConstants.userImageHeight = 80
GuiConstants.userLabelWidth = 130
GuiConstants.userLabelHeight = 25
GuiConstants.userWidgetWidth = math.max(GuiConstants.userImageWidth, GuiConstants.userLabelWidth) + 2 * GuiConstants.standardPaddingPx

GuiConstants.userWidgetHeight = GuiConstants.userImageHeight + GuiConstants.userLabelHeight + 2 * GuiConstants.standardPaddingPx
GuiConstants.redXSize = 20
GuiConstants.redXMargin = 5

-- Mini user widget details.
GuiConstants.miniUserImageWidth = 30
GuiConstants.miniUserImageHeight = 30
GuiConstants.miniUserWidgetWidth = math.max(GuiConstants.miniUserImageWidth, GuiConstants.userLabelWidth) + 2 * GuiConstants.standardPaddingPx
GuiConstants.miniUserWidgetHeight = GuiConstants.miniUserImageHeight + GuiConstants.userLabelHeight + 2 * GuiConstants.standardPaddingPx

-- Game widget details.
GuiConstants.gameImageWidth = 60
GuiConstants.gameImageHeight = 60
GuiConstants.gameLabelWidth = 130
GuiConstants.gameLabelHeight = 25
GuiConstants.gameWidgetWidth = math.max(GuiConstants.gameImageWidth, GuiConstants.gameLabelWidth) + 2 * GuiConstants.standardPaddingPx
GuiConstants.gameWidgetHeight = GuiConstants.gameImageHeight + GuiConstants.gameLabelHeight + 2 * GuiConstants.standardPaddingPx

-- Table widget details.
local userInTableWidth = GuiConstants.userLabelWidth
local gameInTableWidth = math.max(GuiConstants.gameLabelWidth, GuiConstants.gameImageWidth)
GuiConstants.tableWidgetWidth = math.max(userInTableWidth, gameInTableWidth) + 2 * GuiConstants.standardPaddingPx
GuiConstants.tableWidgetHeight = GuiConstants.gameImageHeight + GuiConstants.gameLabelHeight + GuiConstants.userLabelHeight + 2 * GuiConstants.standardPaddingPx

GuiConstants.gamePlayingSidebarWidth = 250
GuiConstants.gamePlayingSidebarMetadataValueIndent = 10
GuiConstants.gamePlayingSidebarH2Separation = 10
GuiConstants.gamePlayingSidebarH3Separation = 5
GuiConstants.gamePlayingSidebarControlsHeight = GuiConstants.textButtonHeight

GuiConstants.checkboxSize = 30

-- Scroll stuff
GuiConstants.scrollBarThickness = 8

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
GuiConstants.adminControlFrameZIndex = 100
GuiConstants.dialogBackgroundZIndex = GuiConstants.adminControlFrameZIndex + 10
GuiConstants.dialogInputSinkZIndex = GuiConstants.dialogBackgroundZIndex + 10
GuiConstants.dialogZIndex = GuiConstants.dialogInputSinkZIndex + 10

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
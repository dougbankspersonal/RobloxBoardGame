--[[
A collection of utils around creating widgets that represent users:
* users seated at table.
* users invited to table.
* users being offered in somme kind of friend selection widget.
--]]

local UserGuiUtils = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local PlayerUtils = require(RobloxBoardGameShared.Modules.PlayerUtils)

local Cryo = require(ReplicatedStorage.Cryo)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)

local addRedX = function(widgetContainer: Frame)
    -- Add a little x indicator on the button.
    local redXImage = Instance.new("ImageLabel")
    redXImage.Parent = widgetContainer
    redXImage.Size = UDim2.fromOffset(GuiConstants.redXSize, GuiConstants.redXSize)
    redXImage.Position = UDim2.new(1, -(GuiConstants.redXSize + GuiConstants.redXMargin), 0, GuiConstants.redXMargin)
    redXImage.Image = GuiConstants.redXImage
    redXImage.BackgroundTransparency = 1
    redXImage.ZIndex = GuiConstants.itemWidgetRedXZIndex
end

-- Standard notion of displaying a user image.
-- Start with basic "item image", tweak the size, deal with async nature of loading the image.
local configureUserImage = function(imageLabel:ImageLabel, userId: CommonTypes.UserId)
    assert(imageLabel, "Should have imageLabel")
    assert(userId, "Should have userId")

    -- Make it round.
    GuiUtils.addCorner(imageLabel, {
        CornerRadius = UDim.new(0.5, 0),
    })

    imageLabel.Size = UDim2.fromOffset(GuiConstants.userImageWidth, GuiConstants.userImageWidth)
    imageLabel.Image = ""

    -- Get and set the contents of image.
    local playerThumbnail = PlayerUtils.getThumbnail(userId)

    assert(playerThumbnail, "playerThumbnail should exist")
    imageLabel.Image = playerThumbnail
end

-- Standard notion of displaying a user name in a label.
-- Start with basic "item text", tweak the size, deal with async nature of loading the name.
function UserGuiUtils.configureUserTextLabel(textLabel:TextLabel, userId: CommonTypes.UserId, opt_formatString: string?)
    assert(textLabel, "Should have textLabel")
    assert(userId, "Should have userId")

    textLabel.Size = GuiConstants.userLabelSize
    textLabel.TextSize = GuiConstants.userTextLabelFontSize
    textLabel.Text = ""

    local playerName = PlayerUtils.getName(userId)
    assert(playerName, "playerName should exist")

    local formatString = if opt_formatString then opt_formatString else "%s"
    Utils.debugPrint("Buttons", "formatString = ", formatString)
    Utils.debugPrint("Buttons", "playerName = ", playerName)
    local formattedString = string.format(formatString, playerName)
    Utils.debugPrint("Buttons", "formattedString = ", formattedString)
    textLabel.Text = formattedString
end

local function addUserImageOverTextLabel(frame: GuiObject, userId: CommonTypes.UserId): (ImageLabel, TextLabel)
    assert(userId, "Should have gameDetails")
    assert(frame, "Should have frame")

    local imageLabel, textLabel = GuiUtils.addImageOverTextLabel(frame)

    UserGuiUtils.configureUserTextLabel(textLabel, userId)
    configureUserImage(imageLabel, userId)

    return imageLabel, textLabel
end

function UserGuiUtils.addUserButtonInContainer(parent: Instance, userId: CommonTypes.UserId, onButtonClicked: (CommonTypes.UserId) -> nil): (Frame, TextButton)
    Utils.debugPrint("Layout", "addUserButtonInContainer 001")

    local container, textButton = GuiUtils.addTextButtonInContainer(parent, GuiConstants.userButtonName, {
        Size = GuiConstants.userWidgetSize,
        BackgroundColor3 = GuiConstants.userButtonBackgroundColor,
        BackgroundTransparency = 0.5,
    })

    textButton.Activated:Connect(function()
        if not textButton.Active then
            return
        end
        onButtonClicked(userId)
    end)

    addUserImageOverTextLabel(textButton, userId)

    return container, textButton
end

function UserGuiUtils.addUserStaticInContainer(parent: Instance, userId: CommonTypes.UserId, opt_frameOptions: any?): (Frame, Frame)
    local container, frame = GuiUtils.addFrameInContainer(parent, GuiConstants.userStaticName)
    GuiUtils.applyInstanceOptions(frame, {
        Size = GuiConstants.userWidgetSize,
        BackgroundTransparency = 1,
    }, opt_frameOptions)

    addUserImageOverTextLabel(frame, userId)

    return container, frame
end

-- Make a widgetContainer containing a user (name, thumbnail, etc).
-- It's a label: no click functionality.
function UserGuiUtils.addUserStaticWidgetContainer(parent: Instance, userId: number): Frame
    local userWidgetContainer = GuiUtils.makeWidgetContainer(parent, "User", userId)
    -- We return a user label with "loading" message.
    -- We fire off a fetch to get async info.
    -- When that resolves we remove loading message and add the real info.
    -- FIXME(dbanks)
    -- Make nicer: loading message could be a swirly or whatever.
    UserGuiUtils.addUserStaticInContainer(userWidgetContainer, userId)

    return userWidgetContainer
end

-- Make a widgetContainer containing a user (name, thumbnail, etc).
-- It's button.
function UserGuiUtils.addUserButtonWidgetContainer(parent: Instance, userId: number, callback: (CommonTypes.UserId) -> nil): Frame
    -- We return a user button with "loading" message.
    -- We fire off a fetch to get async info.
    -- When that resolves we remove loading message and add the real info.
    -- FIXME(dbanks)
    -- Make nicer: loading message could be a swirly or whatever.
    local userWidgetContainer = GuiUtils.makeWidgetContainer(parent, "User", userId)

    UserGuiUtils.addUserButtonInContainer(userWidgetContainer, userId, callback)

    return userWidgetContainer
end

-- Utility:
-- We have a row of users under given frame.
-- We have a set of userIds describing the users we want in the row.
-- Compare the widgets in the row to widgets we want to have.
-- Tween in new widgets, tween out old widgets.
-- Futher complications: sometimes the widget is just a static widget, but sometimes it's a button.
-- If it's a button:
--   * Make the widget a button.
--   * Hit the callback when button is clicked
function UserGuiUtils.updateUserRowContent(rowContent: Frame, justBuilt: boolean, userIds: {CommonTypes.UserId}, isButton: (userId: CommonTypes.UserId) -> boolean,
    buttonCallback: (CommonTypes.UserId) -> nil, renderEmptyList: (Frame) -> nil, cleanupEmptyList: (Frame) -> nil)
    assert(rowContent,  "Should have a rowContent")

    local makeUserWidgetContainer = function(frame: Frame, userId: CommonTypes.UserId): Frame
        local userWidgetContainer
        -- For host, if user is not himself, this widget is a button that lets you kick person out of table.
        if isButton(userId) then
            userWidgetContainer = UserGuiUtils.addUserButtonWidgetContainer(frame, userId, buttonCallback)
            addRedX(userWidgetContainer)
        else
            userWidgetContainer = UserGuiUtils.addUserStaticWidgetContainer(frame, userId)
        end
        return userWidgetContainer
    end

    GuiUtils.updateWidgetContainerChildren(rowContent, userIds, makeUserWidgetContainer, renderEmptyList, cleanupEmptyList, justBuilt)
end

function UserGuiUtils.addMiniUserWidget(parent: Instance, userId: CommonTypes.UserId): GuiObject
    local _, widget = UserGuiUtils.addUserStaticInContainer(parent, userId)

    -- adjust sizes.
    widget.Size = GuiConstants.miniUserWidgetSize
    local image = widget:FindFirstChild(GuiConstants.itemImageName, true)
    assert(image, "Should have image")
    image.Size = GuiConstants.miniUserImageSize

    return widget
end


return UserGuiUtils

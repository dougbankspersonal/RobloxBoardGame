--[[
    GuiUtils is a collection of utility functions for creating common/consistent GUI elements.
    It is used by the client to create the UI for the game.

    FIXME(dbanks) Right now these elements are fugly/bare bones functional.  We want to go thru
    and make them nice.
    Also I expect there will be a lot of custom/shared widgets here, so we might want to split this
    into multiple files, add a subdir for "common gui elements" and dump it all in there, etc.
]]

local GuiUtils = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local TableDescriptions = require(RobloxBoardGameStarterGui.Modules.TableDescriptions)
local TweenHandling = require(RobloxBoardGameStarterGui.Modules.TweenHandling)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)

local Cryo = require(ReplicatedStorage.Cryo)

local mainScreenGui: ScreenGui = nil

local globalLayoutOrder = 0

-- An "item" is a user or a game.
-- We have a standard notion of size/style for an image for an item.
local addItemImage = function(parent: GuiObject): ImageLabel
    assert(parent, "Should have parent")
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "ItemImage"
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.BackgroundTransparency = 1
    imageLabel.Parent = parent
    imageLabel.LayoutOrder = 1
    imageLabel.ZIndex = GuiConstants.itemWidgetImageZIndex
    GuiUtils.addCorner(imageLabel)
    return imageLabel
end

-- An "item" is a user or a game.
-- We have a standard notion of size/style for a text label for an item.
local addItemTextLabel = function(parent:GuiObject): TextLabel
    local userTextLabel = GuiUtils.addTextLabel(parent, "", {
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    userTextLabel.AutomaticSize = Enum.AutomaticSize.None
    userTextLabel.LayoutOrder = 2
    userTextLabel.Name = "ItemText"
    userTextLabel.ZIndex = GuiConstants.itemWidgetTextZIndex
    return userTextLabel
end

-- Standard notion of displaying a user name in a label.
-- Start with basic "item text", tweak the size, deal with async nature of loading the name.
local configureUserTextLabel = function(textLabel:TextLabel, userId: CommonTypes.UserId, opt_formatString: string?)
    assert(textLabel, "Should have textLabel")
    assert(userId, "Should have userId")

    textLabel.Size = UDim2.new(1, 0, 0, GuiConstants.userLabelHeight)
    textLabel.TextSize = GuiConstants.userTextLabelFontSize
    textLabel.Text = ""

    -- Async get and set the contents of name
    task.spawn(function()
        local mappedId = Utils.debugMapUserId(userId)
        local playerName = Players: GetNameFromUserIdAsync(mappedId)
        assert(playerName, "playerName should exist")

        local formatString = if opt_formatString then opt_formatString else "%s"
        local formattedString = string.format(formatString, playerName)
        textLabel.Text = formattedString
    end)
end

-- Standard notion of displaying a user image.
-- Start with basic "item image", tweak the size, deal with async nature of loading the image.
local configureUserImage = function(imageLabel:ImageLabel, userId: CommonTypes.UserId)
    assert(imageLabel, "Should have imageLabel")
    assert(userId, "Should have userId")

    imageLabel.Size = UDim2.fromOffset(GuiConstants.userImageX, GuiConstants.userImageX)
    imageLabel.Image = ""

    -- Async get and set the contents of image.
    task.spawn(function()
        local mappedId = Utils.debugMapUserId(userId)

        local playerThumbnail = Players:GetUserThumbnailAsync(mappedId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)

        assert(playerThumbnail, "playerThumbnail should exist")
        imageLabel.Image = playerThumbnail
    end)
end

-- Standard notion of displaying a game name in text.
-- Start with basic "item text", tweak the size, set the name.
local configureGameTextLabel = function(textLabel:TextLabel, gameDetails: CommonTypes.GameDetails)
    assert(textLabel, "Should have textLabel")
    assert(gameDetails, "Should have gameDetails")
    textLabel.Size = UDim2.new(1, 0, 0, GuiConstants.gameLabelHeight)
    textLabel.TextSize = GuiConstants.gameTextLabelFontSize
    textLabel.Text = gameDetails.name
end

-- Standard notion of displaying a game image in text.
-- Start with basic "item image", tweak the size, set the image.
local configureGameImage = function(imageLabel: ImageLabel, gameDetails: GameDetails): ImageLabel
    assert(imageLabel, "Should have imageLabel")
    assert(gameDetails, "Should have gameDetails")
    imageLabel.Size = UDim2.fromOffset(GuiConstants.gameImageX, GuiConstants.gameImageY)
    imageLabel.Image = gameDetails.gameImage
end

GuiUtils.getMainScreenGui = function(): ScreenGui
    assert(mainScreenGui, "Should have a mainScreenGui")
    return mainScreenGui

end

GuiUtils.getMainFrame = function(): Frame?
    assert(mainScreenGui, "Should have a mainScreenGui")
    local mainFrame = mainScreenGui:FindFirstChild(GuiConstants.mainFrameName, true)
    assert(mainFrame, "Should have a mainFrame")
    return mainFrame
end

GuiUtils.getContainingScrollingFrame = function(): Frame?
    assert(mainScreenGui, "Should have a mainScreenGui")
    local containingScrollingFrameName = mainScreenGui:FindFirstChild(GuiConstants.containingScrollingFrameName)
    assert(containingScrollingFrameName, "Should have a containingScrollingFrameName")
    return containingScrollingFrameName
end

GuiUtils.italicize = function(text: string): string
    return "<i>" .. text .. "</i>"
end

GuiUtils.setMainScreenGui = function(msg: ScreenGui)
    assert(msg, "Should have a mainScreenGui")
    mainScreenGui = msg
    mainScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
end

GuiUtils.applyInstanceOptions = function(instance: Instance, opt_instanceOptions: CommonTypes.InstanceOptions?)
    if not opt_instanceOptions then
        return
    end
    for key, value in pairs(opt_instanceOptions) do
        -- Note: I could pcall this to make it not die if you use a bad property name but I'd rather things fail so
        -- you notice something is wrong.
        instance[key] = value
    end
end


GuiUtils.addPadding = function(guiObject: GuiObject, opt_instanceOptions: CommonTypes.InstanceOptions?): UIPadding
    local uiPadding = Instance.new("UIPadding")
    uiPadding.Parent = guiObject
    uiPadding.Name = "UniformPadding"
    local defaultPadding = UDim.new(0, GuiConstants.standardPadding)

    uiPadding.PaddingLeft = defaultPadding
    uiPadding.PaddingRight = defaultPadding
    uiPadding.PaddingTop = defaultPadding
    uiPadding.PaddingBottom = defaultPadding

    GuiUtils.applyInstanceOptions(uiPadding, opt_instanceOptions)

    return uiPadding
end

GuiUtils.addStandardMainFramePadding = function(frame: Frame): UIPadding
    return GuiUtils.addPadding(frame, {
        PaddingLeft = UDim.new(0, GuiConstants.mainFramePadding),
        PaddingRight = UDim.new(0, GuiConstants.mainFramePadding),
        PaddingTop = UDim.new(0, GuiConstants.mainFramePadding),
        PaddingBottom = UDim.new(0, GuiConstants.mainFramePadding),
    })
end

GuiUtils.addUIGradient = function(frame:Frame, colorSequence: ColorSequence, opt_instanceOptions: CommonTypes.InstanceOptions): UIGradient
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Parent = frame
    uiGradient.Color = colorSequence
    uiGradient.Rotation = 90

    GuiUtils.applyInstanceOptions(uiGradient, opt_instanceOptions)
end

GuiUtils.getLayoutOrder = function(parent:Instance): number
    local layoutOrder
    local nextLayourOrder = parent:FindFirstChild(GuiConstants.layoutOrderGeneratorName)
    if nextLayourOrder then
        layoutOrder = nextLayourOrder.Value
        nextLayourOrder.Value = nextLayourOrder.Value + 1
    else
        layoutOrder = globalLayoutOrder
        globalLayoutOrder = globalLayoutOrder + 1
    end
    return layoutOrder
end

GuiUtils.addLayoutOrderGenerator = function(parent:Instance)
    local layoutOrderGenerator = Instance.new("IntValue")
    layoutOrderGenerator.Parent = parent
    layoutOrderGenerator.Value = 0
    layoutOrderGenerator.Name = GuiConstants.layoutOrderGeneratorName
end

-- Make a text label, standardized look & feel.
GuiUtils.addTextLabel = function(parent: Instance, text: string, opt_instanceOptions: CommonTypes.InstanceOptions): TextLabel
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = GuiConstants.textLabelName

    textLabel.Parent = parent
    textLabel.Size = UDim2.fromOffset(0, GuiUtils.GuiConstants)
    textLabel.Position = UDim2.fromScale(0, 0)
    textLabel.AutomaticSize = Enum.AutomaticSize.XY
    textLabel.Text = text
    textLabel.TextSize = GuiConstants.textLabelFontSize
    textLabel.BorderSizePixel = 0
    textLabel.BackgroundTransparency = 1
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center

    GuiUtils.applyInstanceOptions(textLabel, opt_instanceOptions)

    return textLabel
end

-- Conveniencce for adding ui list layout.
-- Defaults to vertical fill direction, vertical align center, horizontal align left.
-- This can be overridden with options.
-- Defaults to center/center.
GuiUtils.addUIListLayout = function(frame: Frame, opt_instanceOptions: CommonTypes.InstanceOptions) : UIListLayout
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Name = "UIListLayout"
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = frame
    uiListLayout.Padding = UDim.new(0, 5)

    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    GuiUtils.applyInstanceOptions(uiListLayout, opt_instanceOptions)

    return uiListLayout
end

-- Make a row spanning the screen left to right.
-- Give it a layout order so it sorts properly with other rows.
-- If label text is given in options, add a label as first rightmost child.
-- Add "rowContent" as the second child of the row.
-- Return this "rowContent": this is where we stick the useful widgets for this row.
--
--  +---------------row--------------------------
--  |               |  row content
--  |   text label  |
--  |   with title  |  +--------+--------
--  |   of row      |  | widget | widget
--  |               |  +--------+--------
--  +--------------------------------------------
GuiUtils.addRowAndReturnRowContent = function(parent:Instance, rowName: string, opt_rowLabelText: string?, opt_rowOptions: CommonTypes.RowOptions?, opt_instanceOptions: CommonTypes.InstanceOptions?): GuiObject
    assert(parent, "Should have a parent")
    assert(rowName, "Should have a rowName")

    local rowOptions = opt_rowOptions or {}

    local row = Instance.new("Frame")
    row.Name = rowName
    row.Parent = parent
    row.Size = UDim2.fromScale(1, 0)
    row.Position = UDim2.fromScale(0, 0)
    row.BorderSizePixel = 0

    row.LayoutOrder = GuiUtils.getLayoutOrder(parent)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1.0

    local contentWidthOffset = 0

    if opt_rowLabelText then
        GuiUtils.addUIListLayout(row, {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = rowOptions.horizontalAlignment or Enum.HorizontalAlignment.Left,
        })

        local labelText = "<b>" .. opt_rowLabelText .. "</b>"
        GuiUtils.addTextLabel(row, labelText, {
            RichText = true,
            TextSize = GuiConstants.rowHeaderFontSize,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.fromOffset(GuiConstants.rowLabelWidth, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
        })
        contentWidthOffset = GuiConstants.rowLabelWidth + GuiConstants.standardPadding
    end

    local rowContent
    if rowOptions.isScrolling then
        rowContent = Instance.new("ScrollingFrame")
        rowContent.AutomaticCanvasSize = Enum.AutomaticSize.XY
        rowContent.CanvasSize = UDim2.fromScale(0, 0)
        rowContent.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        rowContent.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        rowContent.ScrollingDirection = Enum.ScrollingDirection.Y
        rowContent.ScrollBarImageColor3 = Color3.new(0.5, 0.5, 0.5)
    else
        rowContent = Instance.new("Frame")
    end
    rowContent.Parent = row
    rowContent.Size = UDim2.new(1, -contentWidthOffset, 0, 0)
    rowContent.AutomaticSize = Enum.AutomaticSize.Y
    rowContent.Position = UDim2.fromScale(0, 0)
    rowContent.Name = GuiConstants.rowContentName
    rowContent.LayoutOrder = 2
    rowContent.BackgroundTransparency = 1
    rowContent.BorderSizePixel = 0

    -- Rows usually contain ordered list of widgets, add a layout order generator.
    GuiUtils.addLayoutOrderGenerator(rowContent)

    if rowOptions.useGridLayout then
        local uiGridLayout = Instance.new("UIGridLayout")
        uiGridLayout.Parent = rowContent
        uiGridLayout.FillDirection = Enum.FillDirection.Horizontal
        uiGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        uiGridLayout.Name = GuiConstants.rowUIGridLayoutName
        uiGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        if rowOptions.gridCellSize then
            uiGridLayout.CellSize = rowOptions.gridCellSize
        end
    else
        GuiUtils.addUIListLayout(rowContent, {
            FillDirection = rowOptions.fillDirection or Enum.FillDirection.Horizontal,
            Wraps = rowOptions.wraps or false,
            HorizontalAlignment = rowOptions.horizontalAlignment or Enum.HorizontalAlignment.Center,
        })
    end

    GuiUtils.applyInstanceOptions(rowContent, opt_instanceOptions)

    return rowContent
end

GuiUtils.addCorner = function(parent: Frame): UICorner
    local uiCorner = Instance.new("UICorner")
    uiCorner.Parent = parent
    uiCorner.CornerRadius = UDim.new(0, GuiConstants.standardCornerSize)
    return uiCorner
end

-- Parent contains rows.
-- Find row with given name, return the rowContent frame for that row.
GuiUtils.getRowContent = function(parent: GuiObject, rowName: string): Frame
    local row = parent:FindFirstChild(rowName)
    assert(row, "row should exist")
    local rowContent = row:FindFirstChild(GuiConstants.rowContentName)
    assert(rowContent, "rowContent should exist")
    return rowContent
end

-- Make a button with common look & feel.
GuiUtils.addTextButton = function(parent: Instance, text: string, callback: () -> ()): Instance
    local button = Instance.new("TextButton")
    button.Name = GuiConstants.textButtonName
    button.Parent = parent
    button.Size = UDim2.fromScale(0, 0)
    button.AutomaticSize = Enum.AutomaticSize.XY
    button.Position = UDim2.fromScale(0, 0)
    button.Text = text
    button.TextSize = 14
    button.MouseButton1Click:Connect(function()
        if not button.Active then
            return
        end
        callback()
    end)

    GuiUtils.addCorner(button)

    GuiUtils.addPadding(button)

    return button
end

GuiUtils.getPlayerName = function(playerId: CommonTypes.UserId): string?
    local player = game.Players:GetPlayerByUserId(playerId)
    if player then
        return player.Name
    else
        return nil
    end
end

GuiUtils.getGameName = function(gameId: CommonTypes.GameId): string?
    local gameDetails = GameDetails.getGameDetails(gameId)
    if gameDetails then
        return gameDetails.name
    else
        return nil
    end
end

--[[
    Make a clickable button representing a game table.
]]
GuiUtils.addTableButton = function(parent: Instance, tableDescription: CommonTypes.TableDescription, onButtonCiicked: () -> nil): GuiObject
    local button = Instance.new("TextButton")
    button.Parent = parent

    button.Text = ""
    button.Name = "TableButton"
    button.Activated:Connect(onButtonCiicked)

    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    assert(gameDetails, "Should have gameDetails")

    button.Size = UDim2.fromOffset(GuiConstants.tableWidgetX, GuiConstants.tableWidgetY)

    button.BackgroundColor3 = Color3.new(1, 1, 1)

    GuiUtils.addUIGradient(button, GuiConstants.whiteToGrayColorSequence)
    GuiUtils.addCorner(button)
    GuiUtils.addUIListLayout(button, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })
    GuiUtils.addPadding(button)

    local imageLabel = addItemImage(button)

    local gameTextLabel = addItemTextLabel(button)
    local hostTextLabel = addItemTextLabel(button)
    hostTextLabel.LayoutOrder = 3
    hostTextLabel.RichText = true

    configureGameTextLabel(gameTextLabel, gameDetails)
    local formatString = "<i>Hosted by</i> %s"
    configureUserTextLabel(hostTextLabel, tableDescription.hostUserId, formatString)

    configureGameImage(imageLabel, gameDetails)

    return button

end

local addImageOverTextLabel = function(frame: GuiObject): (ImageLabel, TextLabel)
    assert(frame, "Should have parent")

    frame.BackgroundColor3 = Color3.new(1, 1, 1)

    GuiUtils.addUIGradient(frame, GuiConstants.whiteToGrayColorSequence)
    GuiUtils.addCorner(frame)
    GuiUtils.addUIListLayout(frame, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })
    GuiUtils.addPadding(frame)

    local imageLabel = addItemImage(frame)
    local textLabel = addItemTextLabel(frame)

    return imageLabel, textLabel
end

local function addUserImageOverTextLabel(frame: GuiObject, userId: CommonTypes.UserId): (ImageLabel, TextLabel)
    assert(userId, "Should have gameDetails")
    assert(frame, "Should have frame")
    frame.Size = UDim2.fromOffset(GuiConstants.userWidgetX, GuiConstants.userWidgetY)

    local imageLabel, textLabel = addImageOverTextLabel(frame)

    configureUserTextLabel(textLabel, userId)
    configureUserImage(imageLabel, userId)

    return imageLabel, textLabel
end

local function addGameImageOverTextLabel(frame: GuiObject, gameDetails: CommonTypes.GameDetails): (ImageLabel, TextLabel)
    assert(gameDetails, "Should have gameDetails")
    assert(frame, "Should have frame")
    frame.Size = UDim2.fromOffset(GuiConstants.gameWidgetX, GuiConstants.gameWidgetY)

    local imageLabel, textLabel = addImageOverTextLabel(frame)

    configureGameTextLabel(textLabel, gameDetails)
    configureGameImage(imageLabel, gameDetails)

    return imageLabel, textLabel
end

GuiUtils.addGameButton = function(parent: Instance, gameDetails: CommonTypes.GameDetails, onButtonClicked: () -> nil): GuiObject
    local button = Instance.new("TextButton")
    button.Parent = parent

    button.Text = ""
    button.Name = "GameButton"
    button.Activated:Connect(onButtonClicked)

    addGameImageOverTextLabel(button, gameDetails)

    return button
end

GuiUtils.addGameWidget = function(parent: Instance, gameDetails: CommonTypes.GameDetails): GuiObject
    -- Frame with name and image.
    -- FIXME(dbanks)
    -- Make this look cooler.
    local frame = Instance.new("Frame")
    frame.Name = "GameWidget"
    frame.Parent = parent
    addGameImageOverTextLabel(frame, gameDetails)
    return frame
end

GuiUtils.addUserWidget = function(parent: Instance, userId: CommonTypes.UserId): GuiObject
    local frame = Instance.new("Frame")
    frame.Name = "UserWidget"
    frame.Parent = parent

    addUserImageOverTextLabel(frame, userId)

    return frame
end

GuiUtils.addUserButton = function(parent: Instance, userId: CommonTypes.UserId, onButtonClicked: (userId: CommonTypes.UserId) -> nil): GuiObject
    local textButton = Instance.new("TextButton")
    textButton.Text = ""
    textButton.Name = "UserTextButton"
    textButton.Parent = parent

    textButton.Activated:Connect(function()
        onButtonClicked(userId)
    end)

    addUserImageOverTextLabel(textButton, userId)

    return textButton
end

-- We want to have the set of widgets correspond 1-1 with the given ids.
-- Which widgets need to be removed?
local function getWidgetContainersOut(widetContainers: {Instance}, itemIds: {number}): {Instance}
    local widgetContainersOut = {} :: {Instance}
    for _, widgetContainer in widetContainers do
        local widgetContainerItemIdIntValue = widgetContainer:WaitForChild("ItemId")
        assert(widgetContainerItemIdIntValue, "Should have an widgetContainerItemId")
        local widgetInItems = false
        for _, itemId in itemIds do
            if widgetContainerItemIdIntValue.Value == itemId then
                widgetInItems = true
                break
            end
        end
        if not widgetInItems then
            table.insert(widgetContainersOut, widgetContainer)
        end
    end
    return widgetContainersOut
end

-- We want to have the set of widgets correspond 1-1 with the given ids.
-- Which ids have no widgets yet?
local function getItemIdsIn(widgetContainers: {Instance}, itemIds: {number}): {number}
    local itemIdsIn = {}
    for _, itemId in itemIds do
        local itemInWidgets = false
        for _, widgetContainer in widgetContainers do
            local widgetContainerItemIdIntValue = widgetContainer:WaitForChild("ItemId")
            assert(widgetContainerItemIdIntValue, "Should have a widgetContainerItemId")
            if itemId == widgetContainerItemIdIntValue.Value then
                itemInWidgets = true
                break
            end
        end
        if not itemInWidgets then
            table.insert(itemIdsIn, itemId)
        end
    end
    return itemIdsIn
end

-- Construct the name of a widget container.  All widget containers have
-- a child "itemType" string value and a child "itemId" number value.
-- <type, id> should be globally unique.
-- Name is just "WidgetContainer_<type>_<id>
GuiUtils.constructWidgetContainerName = function(itemType: string, itemId: numbe): string
    assert(itemType, "Should have a itemType")
    assert(itemId, "Should have a itemId")
    return "WidgetContainer_" .. itemType .. "_" .. tostring(itemId)
end

-- If this thing is a proper widget container, what should it's name be?
-- WidgetContainer_<type>_<id>
-- If something is missing just return nil.
GuiUtils.getExpectedWidgetContainerName = function(widgetContainer: Instance): string?
    if not widgetContainer then
        return nil
    end
    local itemType = widgetContainer:FindFirstChild("ItemType")
    if not itemType then
        return nil
    end
    local itemId = widgetContainer:FindFirstChild("ItemId")
    if not itemId then
        return nil
    end
    return GuiUtils.constructWidgetContainerName(itemType.Value, itemId.Value)
end

-- All WidgetContainers have names of the form "WidgetContainer_ItemType_ItemId".
GuiUtils.isAWidgetContainer = function(instance: Instance): boolean
    if not instance:IsA("Frame") then
        return false
    end
    local expectedName = GuiUtils.getExpectedWidgetContainerName(instance)
    if not expectedName then
            return false
    end
    return expectedName == instance.Name
end

-- We are tweening a widgetContainer, we keep track of tween in some table.
-- We want a unique key for the tween: just use the type plus id of the
-- widgetContainer.
local function makeTweenKey(widgetContainer: Instance): string
    assert(widgetContainer, "Should have a widgetContainer")
    assert(GuiUtils.isAWidgetContainer(widgetContainer), "Should be a widgetContainer")
    local itemType = widgetContainer:WaitForChild("ItemType")
    local itemId = widgetContainer:WaitForChild("ItemId")
    return "Tween_" .. itemType.Value .. "_" .. tostring(itemId.Value)
end

local collectWidgetContainers = function(parent: GuiObjet): {GuiObject}
    assert(parent, "Should have a parent")
    local widgetContainers = {} :: {GuiObject}
    local allKids = parent:GetChildren()
    for _, kid in allKids do
        if GuiUtils.isAWidgetContainer(kid) then
            table.insert(widgetContainers, kid)
        end
    end
    return widgetContainers
end

local collectWidgetsTweeningOut = function(parent: GuiObject): {GuiObject}
    assert(parent, "Should have a parent")
    local deadMeatFrames = {} :: {GuiObject}
    local allKids = parent:GetChildren()
    for _, kid in allKids do
        if kid.Name == GuiConstants.deadMeatTweeningOutName then
            table.insert(deadMeatFrames, kid)
        end
    end
    return deadMeatFrames
end

GuiUtils.updateNilWidgetContainer = function(parentFrame: Frame, renderEmptyList: (Frame) -> nil, cleanupEmptyList: (Frame) -> nil)
    -- How many non-nil widget containers, or guys tweening out?
    assert(parentFrame, "Should have a parentFrame")
    local widgetContainers = collectWidgetContainers(parentFrame)
    local widgetsTweeningOut = collectWidgetsTweeningOut(parentFrame)

    if #widgetContainers == 0 and #widgetsTweeningOut == 0 then
        renderEmptyList(parentFrame)
    else
        cleanupEmptyList(parentFrame)
    end
end

-- Any WidgetContainer has a type (e.g. "game button") and an id, unique within the type.
-- We have a parent frame with zero or more WidgetContainer children, all the same type.
-- We have a new/updated list of itemIds within the same type.
-- We want to make sure widgets in row match new set of ids.
-- Update the parent to remove/add widgets so the widgets match the incoming list of things.
-- Return a list of any tweens we created so we can murder them later if we need to.
-- If "skipTweens" is true, just slap things in there, no tweens.
GuiUtils.updateWidgetContainerChildren = function(parentFrame:Frame,
        itemIds:{number},
        makeWidgetContainerForItem: (Instance, number) -> Instance,
        renderEmptyList: (Frame) -> nil,
        cleanupEmptyList: (Frame) -> nil,
        skipTweens: boolean)
    local tweensToKill = {} :: CommonTypes.TweensToKill
    assert(parentFrame, "parentFrame should exist")
    -- Get all the existing widgets containers.
    local widgetContainers = collectWidgetContainers(parentFrame)

    -- Figure out which widgets need to go, and what new widgets we need.
    local widgetContainersOut = getWidgetContainersOut(widgetContainers, itemIds)
    local itemIdsIn = getItemIdsIn(widgetContainers, itemIds)

    if skipTweens then
        -- Remove the old, add the new.
        for _, widgetContainer in widgetContainersOut do
            widgetContainer:Destroy()
        end
        for _, itemId in itemIdsIn do
            local itemWidgetContainer = makeWidgetContainerForItem(parentFrame, itemId)
            assert(itemWidgetContainer, "Should have widgetContainer")
            -- It is required that the widget container has an int value child with
            -- name "ItemId" and value equal to itemId.
            assert(itemWidgetContainer.ItemId, "WidgetContainer should have an ItemId")
            assert(itemWidgetContainer.ItemId.Value == itemId, "WidgetContainer.ItemId.Value should be itemId")

            local uiScale = Instance.new("UIScale")
            uiScale.Name = "UIScale"
            uiScale.Parent = itemWidgetContainer
            uiScale.Scale = 1
        end

        GuiUtils.updateNilWidgetContainer(parentFrame, renderEmptyList, cleanupEmptyList)
    else
        local tweenInfo = TweenInfo.new(GuiConstants.standardTweenTime, Enum.EasingStyle.Circular)
        -- Tween out unused widgets.
        for _, widgetContainer in widgetContainersOut do
            local uiScale = widgetContainer:FindFirstChild("UIScale")
            if not uiScale then
                uiScale = Instance.new("UIScale")
                uiScale.Name = "UIScale"
                uiScale.Parent = widgetContainer
                uiScale.Scale = 1
            end
            local tween = TweenService:Create(uiScale, tweenInfo, {Scale = 0})
            local key = makeTweenKey(widgetContainer)
            -- Cancel any existing tweens on this fool.
            TweenHandling.cancelTween(key)

            tweensToKill[key] = tween

            -- Rename them so we don't find them again and re-tween.
            widgetContainer.Name = GuiConstants.deadMeatTweeningOutName

            tween.Completed:Connect(function(_)
                widgetContainer:Destroy()
                GuiUtils.updateNilWidgetContainer(parentFrame, renderEmptyList, cleanupEmptyList)
            end)
            tween:Play()
        end

        for _, itemId in itemIdsIn do
            local itemWidgetContainer = makeWidgetContainerForItem(parentFrame, itemId)
            assert(itemWidgetContainer, "Should have widgetContainer")
            -- It is required that the widget container has an int value child with
            -- name "ItemId" and value equal to itemId.
            assert(itemWidgetContainer.ItemId, "WidgetContainer should have an ItemId")
            assert(itemWidgetContainer.ItemId.Value == itemId, "WidgetContainer.ItemId.Value should be itemId")

            local uiScale = Instance.new("UIScale")
            uiScale.Name = "UIScale"
            uiScale.Parent = itemWidgetContainer
            uiScale.Scale = 0

            local tween = TweenService:Create(itemWidgetContainer.UIScale, tweenInfo, {Scale = 1})
            local key = makeTweenKey(itemWidgetContainer)
            tweensToKill[key] = tween

            tween:Play()
        end
    end

    -- store the tweens.
    TweenHandling.saveTweens(tweensToKill)

    GuiUtils.updateNilWidgetContainer(parentFrame, renderEmptyList, cleanupEmptyList)
end

local genericIdGenerator = 0

local makeWidgetContainer = function(parent:GuiObject, widgetType: string, opt_itemId: number?): GuiObject
    assert(parent, "Should have a parent")
    assert(widgetType, "Should have a widgetType")

    local itemId
    if opt_itemId then
        itemId = opt_itemId
    else
        itemId = genericIdGenerator
        genericIdGenerator = genericIdGenerator + 1
    end

    local widgetContainer = Instance.new("Frame")
    widgetContainer.Parent = parent
    widgetContainer.Size = UDim2.fromOffset(0, 0)
    widgetContainer.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
    widgetContainer.BorderSizePixel = 0
    widgetContainer.Name = GuiUtils.constructWidgetContainerName(widgetType, itemId)
    widgetContainer.LayoutOrder = GuiUtils.getLayoutOrder(parent)
    widgetContainer.AutomaticSize = Enum.AutomaticSize.XY
    widgetContainer.BackgroundTransparency = 1

    local intValue = Instance.new("IntValue")
    intValue.Value = itemId
    intValue.Parent = widgetContainer
    intValue.Name = "ItemId"

    local stringValue = Instance.new("StringValue")
    stringValue.Value = widgetType
    stringValue.Parent = widgetContainer
    stringValue.Name = "ItemType"

    return widgetContainer
end

-- Make a widgetContainer containing a user (name, thumbnail, etc).
-- If a callback is given, make it a button, else it's just a static frame.
GuiUtils.addUserWidgetContainer = function(parent: Instance, userId: number, onClick: ((userId: CommonTypes.UserId) -> nil)?): Frame
    -- So what will happen:
    -- We return a table button container with "loading" message.
    -- We fire off a fetch to get async info.
    -- When that resolves we remove loading message and add the real info.
    -- FIXME(dbanks)
    -- Make nicer: loading message could be a swirly or whatever.
    local userWidgetContainer = makeWidgetContainer(parent, "User", userId)

    if onClick then
        GuiUtils.addUserButton(userWidgetContainer, userId, function()
            onClick(userId)
        end)

        -- The only reason we ever use this button is to kick the user out.  Put a little x indicator on the button.
        local xImage = Instance.new("ImageButton")
        xImage.Parent = userWidgetContainer
        xImage.Size = UDim2.fromOffset(GuiConstants.redXSize, GuiConstants.redXSize)
        xImage.Position = UDim2.new(1, -(GuiConstants.redXSize + GuiConstants.redXMargin), 0, GuiConstants.redXMargin)
        xImage.Image = GuiConstants.redXImage
        xImage.BackgroundTransparency = 1
        xImage.ZIndex = GuiConstants.itemWidgetOverlayZIndex
    else
        GuiUtils.addUserWidget(userWidgetContainer, userId)
    end

    return userWidgetContainer
end

GuiUtils.removeNullWidget = function(parent:Instance)
    if parent:FindFirstChild(GuiConstants.nullWidgetName) then
        parent:FindFirstChild(GuiConstants.nullWidgetName):Destroy()
    end
end

-- Make standard "nothing there" indicator.
-- Idempotent: will remove old/previous one if present.
GuiUtils.addNullWidget = function(parent: Instance, message: string, opt_instanceOptions: CommonTypes.InstanceOptions): Frame
    -- Make sure old widget is gone.
    GuiUtils.removeNullWidget(parent)
    local instanceOptions = opt_instanceOptions or {}
    instanceOptions = Cryo.Dictionary.join(instanceOptions, {
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        RichText = true,
        TextWrapped = true,
        BackgroundTransparency = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
        AutomaticSize = Enum.AutomaticSize.None,
    })
    local textLabel = GuiUtils.addTextLabel(parent, message, instanceOptions)
    GuiUtils.addUIGradient(textLabel, GuiConstants.whiteToGrayColorSequence)
    GuiUtils.addCorner(textLabel)
    GuiUtils.addPadding(textLabel)

    textLabel.Name = GuiConstants.nullWidgetName
    return textLabel
end

-- Make a widgetContainer containing a button you click to join a game.
GuiUtils.addTableButtonWidgetContainer = function(parent: Instance, tableId: number, onClick: () -> nil): Frame
    local tableDescription = TableDescriptions.getTableDescription(tableId)
    -- Should exist.
    assert(tableDescription, "Should have a tableDescription")

    local tableButtonContainer = makeWidgetContainer(parent, "Table", tableId)

    GuiUtils.addTableButton(tableButtonContainer, tableDescription, onClick)

    return tableButtonContainer
end

-- A generic text button in a widget container.
GuiUtils.addTextButtonWidgetContainer = function(parent: Instance, text: string, onClick: () -> nil): Frame
    local textButtonContainer = makeWidgetContainer(parent, "TextButtonWidgetContainer", nil)
    GuiUtils.addTextButton(textButtonContainer, text, onClick)
    return textButtonContainer
end

-- Make a widget container containing a text label.
GuiUtils.addTextLabelWidgetContainer = function(parent: Instance, text: string, opt_instanceOptions: CommonTypes.InstanceOptions): Frame
    local textLabelContainer = makeWidgetContainer(parent, "TextLabelWidgetContainer", nil)
    GuiUtils.addTextLabel(textLabelContainer, text, opt_instanceOptions)
    return textLabelContainer
end

GuiUtils.updateTextLabelWidgetContainer = function(widgetContainer: Frame, text: string): boolean
    local textLabel = widgetContainer:FindFirstChild(GuiConstants.textLabelName)
    assert(textLabel, "Should have a textLabel")
    if textLabel.Text == text then
        return false
    end
    textLabel.Text = text
    return true
end

GuiUtils.updateTextButtonEnabledInWidgetContainer = function(widgetContainer: Frame, enabled: boolean)
    assert(widgetContainer, "Should have a widgetContainer")
    local textButton = widgetContainer:FindFirstChild(GuiConstants.textButtonName)
    assert(textButton, "Should have a textButton")
    textButton.Active = enabled
end

local function getOptionValue(gameOption: CommonTypes.GameOption, nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions): string?
    -- Does this particular option have a non-default value?
    local opt_nonDefaultGameOption = nonDefaultGameOptions[gameOption.gameOptionId]
    if opt_nonDefaultGameOption then
        -- Yes it does.  How we write about the value turns on whether the option is a bool or has variants.
        if gameOption.opt_variants then
            -- This is a variant option: the value of the non-default option is an index.
            assert(typeof(opt_nonDefaultGameOption) == "number", "Should have a number")
            local variant = gameOption.opt_variants[opt_nonDefaultGameOption]
            assert(variant, "Should have a variant")
            return variant.Name
        end

        -- It's a bool.
        assert(typeof(opt_nonDefaultGameOption) == "boolean", "Should have a boolean")
        if opt_nonDefaultGameOption then
            return "Yes"
        else
            return "No"
        end
    end

    -- We are using default value.
    -- For variants, it's the first.
    if gameOption.opt_variants then
        assert(#gameOption.opt_variants > 0, "Should have at least one variant")
        local variant = gameOption.opt_variants[1]
        assert(variant, "Should have a variant")
        return variant.name
    end

    -- It's a bool, and default is "off"/"no"
    return "No"
end

GuiUtils.getSelectedGameOptionsString = function(tableDescription: CommonTypes.TableDescription): string?
    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)

    -- Game doesn't even have options: nothing to say.
    if not gameDetails.gameOptions then
        return nil
    end

    local enabledOptionsStrings = {}
    local nonDefaultGameOptions = tableDescription.opt_nonDefaultGameOptions or {}

    for _, gameOption in gameDetails.gameOptions do
        local optionName = gameOption.name
        assert(optionName, "Should have an optionName")
        local optionValue = getOptionValue(gameOption, nonDefaultGameOptions)
        assert(optionValue, "Should have an optionValue"
    )
        local optionString = optionName .. ": " .. optionValue

        table.insert(enabledOptionsStrings, optionString)
    end
    if #enabledOptionsStrings == 0 then
        return "(None)"
    end

    return table.concat(enabledOptionsStrings,"\n")
end

GuiUtils.getTableSizeString = function(gameDetails: CommonTypes.GameDetails): string
    return tostring(gameDetails.minPlayers) .. " - " .. tostring(gameDetails.maxPlayers)
end

-- A row with a text label and a row of same-size items.
-- Row is just one item high. Will add scrollbar if needed.
GuiUtils.addRowOfUniformItems = function(frame: Frame, name: string, labelText: string, itemHeight: number): Frame
    assert(frame, "Should have frame")
    assert(name, "Should have name")
    assert(labelText, "Should have labelText")
    assert(itemHeight, "Should have itemHeight")

    local instanceOptions = {
        AutomaticSize = Enum.AutomaticSize.None,
        Size = UDim2.new(1, -GuiConstants.rowLabelWidth - GuiConstants.standardPadding, 0, itemHeight + 2 * GuiConstants.standardPadding),
        ClipsDescendants = true,
        BorderSizePixel = 0,
        BorderColor3 = Color3.new(0.5, 0.5, 0.5),
        BorderMode = Enum.BorderMode.Outline,
        BackgroundColor3 = Color3.new(0.9, 0.9, 0.9),
        BackgroundTransparency = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
    }

    local rowOptions = {
        isScrolling = true,
        horizontalAlignment = Enum.HorizontalAlignment.Left,
    }

    local rowContent = GuiUtils.addRowAndReturnRowContent(frame, name, labelText, rowOptions, instanceOptions)
    GuiUtils.addPadding(rowContent, {
        PaddingTop = UDim.new(0, 0),
        PaddingBottom = UDim.new(0, 0),
    })
    return rowContent
end

return GuiUtils
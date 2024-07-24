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

local mainScreenGui: ScreenGui = nil

local globalLayoutOrder = 0

local layoutOrderGeneratorName = "LayoutOrderGenerator"
local rowContentName = "RowContent"
local rowUIGridLayoutName = "Row_UIGridLayout"
local widgetLoadingName = "WidgetLoading"

GuiUtils.mainFrameName = "MainFrame"
GuiUtils.textButtonName = "TextButton"
GuiUtils.textLabelName = "TextLabel"

-- Various measurements.
GuiUtils.textLabelHeight = 30
GuiUtils.textLabelFontSize = 14
GuiUtils.gameTextLabelFontSize = 10
GuiUtils.dialogTitleFontSize = 24
GuiUtils.standardPaddingPixels = 5
GuiUtils.minWidgetContainerHeight = 30

GuiUtils.mainFrameZIndex = 2
GuiUtils.dialogBackgroundZIndex = 3
GuiUtils.dialogInputSinkZIndex = 4
GuiUtils.dialogZIndex = 5

GuiUtils.gameWidgetX = 100
GuiUtils.gameWidgetY = 130
GuiUtils.gameLabelHeight = 20

GuiUtils.whiteToGrayColorSequence = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.8, 0.8, 0.8))
GuiUtils.scrollBackgroundGradient = ColorSequence.new(Color3.new(0.8, 0.8, 0.8), Color3.new(0.6, 0.6, 0.6))
GuiUtils.blueColorSequence = ColorSequence.new(Color3.new(0.5, 0.6, 0.8), Color3.new(0.2, 0.3, 0.5))

GuiUtils.setMainScreenGui = function(msg: ScreenGui)
    assert(msg, "Should have a mainScreenGui")
    mainScreenGui = msg
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
    local defaultPadding = UDim.new(0, GuiUtils.standardPaddingPixels)

    uiPadding.PaddingLeft = defaultPadding
    uiPadding.PaddingRight = defaultPadding
    uiPadding.PaddingTop = defaultPadding
    uiPadding.PaddingBottom = defaultPadding

    GuiUtils.applyInstanceOptions(uiPadding, opt_instanceOptions)

    return uiPadding
end
GuiUtils.addUIGradient = function(frame:Frame, colorSequence: ColorSequence, opt_instanceOptions: CommonTypes.InstanceOptions): UIGradient
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Parent = frame
    uiGradient.Color = colorSequence
    uiGradient.Rotation = 90

    GuiUtils.applyInstanceOptions(uiGradient, opt_instanceOptions)
end

GuiUtils.getMainScreenGui = function(): ScreenGui
    assert(mainScreenGui, "Should have a mainScreenGui")
    return mainScreenGui

end

GuiUtils.getMainFrame = function(): Frame?
    assert(mainScreenGui, "Should have a mainScreenGui")
    local mainFrame = mainScreenGui:FindFirstChild(GuiUtils.mainFrameName)
    assert(mainFrame, "Should have a mainFrame")
    return mainFrame
end

GuiUtils.getLayoutOrder = function(parent:Instance): number
    local layoutOrder
    local nextLayourOrder = parent:FindFirstChild(layoutOrderGeneratorName)
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
    layoutOrderGenerator.Name = layoutOrderGeneratorName
end

-- Make a text label, standardized look & feel.
GuiUtils.addTextLabel = function(parent: Instance, text: string, opt_instanceOptions: CommonTypes.InstanceOptions): TextLabel
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = GuiUtils.textLabelName

    textLabel.Parent = parent
    textLabel.Size = UDim2.fromOffset(0, GuiUtils.textLabelHeight)
    textLabel.Position = UDim2.fromScale(0, 0)
    textLabel.AutomaticSize = Enum.AutomaticSize.XY
    textLabel.Text = text
    textLabel.TextSize = GuiUtils.textLabelFontSize
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
GuiUtils.addRowAndReturnRowContent = function(parent:Instance, rowName: string, opt_rowOptions: CommonTypes.RowOptions?, opt_instanceOptions: CommonTypes.InstanceOptions?): GuiObject
    assert(parent, "Should have a parent")
    assert(rowName, "Should have a rowName")

    local rowOptions = opt_rowOptions or {}

    local row = Instance.new("Frame")
    row.Name = rowName
    row.Parent = parent
    row.Size = UDim2.new(1, -10, 0, 0)
    row.Position = UDim2.fromScale(0, 0)
    row.BorderSizePixel = 0

    row.LayoutOrder = GuiUtils.getLayoutOrder(parent)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1.0

    GuiUtils.addUIListLayout(row, {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = rowOptions.horizontalAlignment or Enum.HorizontalAlignment.Left,
    })

    if rowOptions.labelText then
        GuiUtils.addTextLabel(row, rowOptions.labelText)
    end

    local rowContent
    if rowOptions.isScrolling then
        rowContent = Instance.new("ScrollingFrame")
        rowContent.AutomaticCanvasSize = Enum.AutomaticSize.XY
        rowContent.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        rowContent.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        rowContent.ScrollingDirection = Enum.ScrollingDirection.Y
    else
        rowContent = Instance.new("Frame")
    end
    rowContent.Parent = row
    rowContent.Size = UDim2.fromScale(0, 0)
    rowContent.AutomaticSize = Enum.AutomaticSize.XY
    rowContent.Position = UDim2.fromScale(0, 0)
    rowContent.Name = rowContentName
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
        uiGridLayout.Name = rowUIGridLayoutName
        uiGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        if rowOptions.gridCellSize then
            uiGridLayout.CellSize = rowOptions.gridCellSize
        end
    else
        GuiUtils.addUIListLayout(rowContent, {
            FillDirection = Enum.FillDirection.Horizontal,
        })
    end

    GuiUtils.applyInstanceOptions(rowContent, opt_instanceOptions)

    return rowContent
end

GuiUtils.addCorner = function(parent: Frame): UICorner
    local uiCorner = Instance.new("UICorner")
    uiCorner.Parent = parent
    uiCorner.CornerRadius = UDim.new(0, 4)
    return uiCorner
end

-- Parent contains rows.
-- Find row with given name, return the rowContent frame for that row.
GuiUtils.getRowContent = function(parent: GuiObject, rowName: string): Frame
    local row = parent:FindFirstChild(rowName)
    assert(row, "row should exist")
    local rowContent = row:FindFirstChild(rowContentName)
    assert(rowContent, "rowContent should exist")
    return rowContent
end

-- Make a button with common look & feel.
GuiUtils.addTextButton = function(parent: Instance, text: string, callback: () -> ()): Instance
    local button = Instance.new("TextButton")
    button.Name = GuiUtils.textButtonName
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
    -- FIXME(dbanks)
    -- Someday a nice large button with image of game, name, host, description, etc.
    -- For now just host name and game name as a text button.
   local hostName = GuiUtils.getPlayerName(tableDescription.hostUserId)
    local gameName = GuiUtils.getGameName(tableDescription.gameId)
    assert(hostName, "No host name for " .. tableDescription.hostUserId)
    assert(gameName, "No game name for " .. tableDescription.gameId)
    local buttonText = "\"" .. gameName .. "\" hosted by " .. hostName

    return GuiUtils.addTextButton(parent, buttonText, onButtonCiicked)
end

local gameButtonOrWidgetHelper = function(frame: GuiObject, gameDetails: CommonTypes.GameDetails)
    assert(gameDetails, "Should have gameDetails")
    Utils.debugPrint("Doug: gameDetails = ", gameDetails)

    frame.Size = UDim2.fromOffset(GuiUtils.gameWidgetX, GuiUtils.gameWidgetY)
    frame.BackgroundColor3 = Color3.new(1, 1, 1)

    GuiUtils.addUIGradient(frame, GuiUtils.whiteToGrayColorSequence)
    GuiUtils.addCorner(frame)
    GuiUtils.addUIListLayout(frame, {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })
    GuiUtils.addPadding(frame)

    local textLabel = GuiUtils.addTextLabel(frame, gameDetails.name, {
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    -- Twiddle this a bit...
    textLabel.TextSize = GuiUtils.gameTextLabelFontSize
    textLabel.Size = UDim2.new(1, 0, 0, GuiUtils.gameLabelHeight)
    textLabel.AutomaticSize = Enum.AutomaticSize.None
    textLabel.LayoutOrder = 1

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "GameImage"
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.BackgroundTransparency = 1
    imageLabel.Parent = frame
    local sideLength = GuiUtils.gameWidgetY - 3 * GuiUtils.standardPaddingPixels - GuiUtils.gameLabelHeight
    imageLabel.Size = UDim2.fromOffset(sideLength, sideLength)
    imageLabel.LayoutOrder = 2
    Utils.debugPrint("Doug: gameDetails = ", gameDetails)
    imageLabel.Image = gameDetails.gameImage
    GuiUtils.addCorner(imageLabel)
end

GuiUtils.addGameButton = function(parent: Instance, gameDetails: CommonTypes.GameDetails, onButtonClicked: () -> nil): GuiObject
    local button = Instance.new("TextButton")
    button.Parent = parent

    button.Text = ""
    button.Name = "GameButton"
    button.Activated:Connect(onButtonClicked)

    gameButtonOrWidgetHelper(button, gameDetails)

    return button
end

GuiUtils.addGameWidget = function(parent: Instance, gameDetails: CommonTypes.GameDetails): GuiObject
    -- Frame with name and image.
    -- FIXME(dbanks)
    -- Make this look cooler.
    local frame = Instance.new("Frame")
    frame.Name = "GameWidget"
    frame.Parent = parent

    gameButtonOrWidgetHelper(frame, gameDetails)

    return frame
end

GuiUtils.addUserWidget = function(parent: Instance, playerName: string, playerThumbnail: string): GuiObject
    -- FIXME(dbanks)
    -- Someday a nice large widget with image of user, name, etc.
    -- For now just text label with name,
    return GuiUtils.addTextLabel(parent, playerName)
end

GuiUtils.addUserButton = function(parent: Instance, playerName: string, playerThumbnail: string, onButtonClicked: () -> nil): GuiObject
    -- FIXME(dbanks)
    -- Someday a nice large button with image of user, name, etc.
    -- For now just text button with name,
    return GuiUtils.addTextButton(parent, playerName, onButtonClicked)
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
GuiUtils.constructWidgetContainerName = function(itemType: string, itemId: number): string
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

-- Any WidgetContainer has a type (e.g. "game button") and an id, unique within the type.
-- We have a parent frame with zero or more WidgetContainer children, all the same type.
-- We have a new/updated list of itemIds within the same type.
-- We want to make sure widgets in row match new set of ids.
-- Update the parent to remove/add widgets so the widgets match the incoming list of things.
-- Return a list of any tweens we created so we can murder them later if we need to.
GuiUtils.updateWidgetContainerChildren = function(parentFrame:Frame, itemIds:{number}, makeWidgetContainerForItem: (Instance, number) -> Instance)
    local tweensToKill = {} :: CommonTypes.TweensToKill

    local allKids = parentFrame:GetChildren()

    -- Get all the existing widgets.
    local widgetContainers = {}
    for _, kid in allKids do
        if GuiUtils.isAWidgetContainer(kid) then
            table.insert(widgetContainers, kid)
        end
    end

    -- Figure out which widgets need to go, and what new widgets we need.
    local widgetContainersOut = getWidgetContainersOut(widgetContainers, itemIds)
    local itemIdsIn = getItemIdsIn(widgetContainers, itemIds)

    -- Just for giggles, instead of stuff just popping in/out, make it a nice tween.
    local tweenInfo = TweenInfo.new(0.5)

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
        tweensToKill[key] = tween

        tween.Completed:Connect(function(_)
            widgetContainer:Destroy()
        end)
        tween:Play()
    end

    -- Tween in new widgets.
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

    -- store the tweens.
    TweenHandling.saveTweens(tweensToKill)
end

local genericIdGenerator = 0

local makeWidgetContainer = function(parent:GuiObject, widgetType: string, _itemId: number?): GuiObject
    assert(parent, "Should have a parent")
    assert(widgetType, "Should have a widgetType")

    local itemId
    if _itemId then
        itemId = _itemId
    else
        itemId = genericIdGenerator
        genericIdGenerator = genericIdGenerator + 1
    end

    local widgetContainer = Instance.new("Frame")
    widgetContainer.Parent = parent
    widgetContainer.Size = UDim2.fromOffset(0, GuiUtils.minWidgetContainerHeight)
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

-- Make a widgetContainer containing a clickable button representing a table.
GuiUtils.addTableButtonWidgetContainer = function(parent: Instance, tableId: number, onClick: () -> nil): Frame
    local tableDescription = TableDescriptions.getTableDescription(tableId)
    -- Should exist.
    assert(tableDescription, "Should have a tableDescription")
    local tableButtonContainer = makeWidgetContainer(parent, "Table", tableId)

    GuiUtils.addTableButton(tableButtonContainer, tableDescription, onClick)

    return tableButtonContainer
end

-- Make a widgetContainer containing a user (name, thumbnail, etc).
-- If a callback is given, make it a button, else it's just a static frame.
GuiUtils.addUserWidgetContainer = function(parent: Instance, userId: number, onClick: ((userId) -> nil)?): Frame
    -- So what will happen:
    -- We return a table button container with "loading" message.
    -- We fire off a fetch to get async info.
    -- When that resolves we remove loading message and add the real info.
    -- FIXME(dbanks)
    -- Make nicer: loading message could be a swirly or whatever.
    local tableButtonContainer = makeWidgetContainer(parent, "User", userId)
    local waitingWidget = GuiUtils.addTextLabel(tableButtonContainer, "Loading...")
    waitingWidget.Name = widgetLoadingName


    -- get the user info.
    -- This is async so we do it inside pcall.
    pcall(function()
        local playerName = Players: GetNameFromUserIdAsync(userId)
        local playerThumbnail = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)

        -- FIXME(dbanks)
        -- Add some extra wait just for fun.
        task.wait(5)

        -- Remove the waiting widget.
        local waitingWidget = tableButtonContainer:FindFirstChild(widgetLoadingName)
        assert(waitingWidget, "Should have a waiting widget")
        waitingWidget:Destroy()

        if onClick then
            GuiUtils.addUserButton(tableButtonContainer, playerName, playerThumbnail, function()
                onClick(userId)
            end)
        else
            GuiUtils.addUserWidget(tableButtonContainer, playerName, playerThumbnail)
        end
    end)

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
    local textLabel = widgetContainer:FindFirstChild(GuiUtils.textLabelName)
    assert(textLabel, "Should have a textLabel")
    if textLabel.Text == text then
        return false
    end
    textLabel.Text = text
    return true
end

GuiUtils.updateTextButtonEnabledInWidgetContainer = function(widgetContainer: Frame, enabled: boolean)
    assert(widgetContainer, "Should have a widgetContainer")
    local textButton = widgetContainer:FindFirstChild(GuiUtils.textButtonName)
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

    return table.concat(enabledOptionsStrings,", ")
end

return GuiUtils
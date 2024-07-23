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

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local TableDescriptions = require(RobloxBoardGameStarterGui.Modules.TableDescriptions)
local TweenHandling = require(RobloxBoardGameStarterGui.Modules.TweenHandling)

local globalLayoutOrder = 0

local layoutOrderGeneratorName = "LayoutOrderGenerator"
local rowContentName = "RowContent"
local rowUIGridLayoutName = "Row_UIGridLayout"
local widgetLoadingName = "WidgetLoading"

GuiUtils.mainFrameName = "MainFrame"
GuiUtils.textButtonName = "TextButton"
GuiUtils.textLabelName = "TextLabel"

GuiUtils.textLabelHeight = 30
GuiUtils.textLabelFontSize = 14
GuiUtils.dialogTitleFontSize = 24
GuiUtils.horizontalPadding = UDim.new(0, 5)
GuiUtils.minWidgetContainerHeight = 30

GuiUtils.mainFrameZIndex = 2
GuiUtils.dialogBackgroundZIndex = 3
GuiUtils.dialogInputSinkZIndex = 4
GuiUtils.dialogZIndex = 5

GuiUtils.whiteToGrayColorSequence = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.8, 0.8, 0.8))
GuiUtils.blueColorSequence = ColorSequence.new(Color3.new(0.5, 0.6, 0.8), Color3.new(0.2, 0.3, 0.5))


GuiUtils.addUIGradient = function(frame:Frame, colorSequence: ColorSequence, opt_leftToRight: boolean?): UIGradient
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Parent = frame
    uiGradient.Color = colorSequence
    if opt_leftToRight == nil or not opt_leftToRight then
        uiGradient.Rotation = 90
    end
end

GuiUtils.getMainFrame = function(screenGui: ScreenGui): Frame?
    local mainFrame = screenGui:FindFirstChild(GuiUtils.mainFrameName)
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

GuiUtils.makeLayoutOrderGenerator = function(parent:Instance)
    local layoutOrderGenerator = Instance.new("IntValue")
    layoutOrderGenerator.Parent = parent
    layoutOrderGenerator.Value = 0
    layoutOrderGenerator.Name = layoutOrderGeneratorName
end

-- Make a row spanning the screen left to right.
-- Give it a layout order so it sorts properly with other rows.
-- If text is given, add a label widget as the first child of the row.
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
GuiUtils.makeRowWithLabelAndReturnRowContent = function(parent:Instance, rowName: string, text: string?, opt_useGridLayout: boolean?): Instance
    assert(parent, "Should have a parent")
    assert(rowName, "Should have a rowName")

    local row = Instance.new("Frame")
    row.Name = rowName
    row.Parent = parent
    row.Size = UDim2.new(1, -10, 0, 0)
    row.Position = UDim2.new(0, 0, 0, 0)
    row.BorderSizePixel = 0

    row.LayoutOrder = GuiUtils.getLayoutOrder(parent)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1.0

    if text then
        GuiUtils.makeTextLabel(row, text)
    end

    local rowContent = Instance.new("Frame")
    rowContent.Parent = row
    rowContent.Size = UDim2.new(0, 0, 0, 0)
    rowContent.AutomaticSize = Enum.AutomaticSize.XY
    rowContent.Position = UDim2.new(0, 0, 0, 0)
    rowContent.Name = rowContentName
    rowContent.LayoutOrder = 2
    rowContent.BackgroundTransparency = 1
    rowContent.BorderSizePixel = 0

    -- Rows usually contain ordered list of widgets, add a layout order generator.
    GuiUtils.makeLayoutOrderGenerator(rowContent)

    if opt_useGridLayout then
        local uiGridLayout = Instance.new("UIGridLayout")
        uiGridLayout.Parent = rowContent
        uiGridLayout.FillDirection = Enum.FillDirection.Horizontal
        uiGridLayout.Name = rowUIGridLayoutName
        uiGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        -- FIXME(dbanks)
        -- This is just junk/random value.  Should be passsed in I guess?
        uiGridLayout.CellSize = UDim2.new(0, 200, 0, 30)
    else
        GuiUtils.makeUiListLayout(rowContent, true)
    end


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

-- Make a row with no label.
GuiUtils.makeRowAndReturnRowContent = function(parent:Instance, rowName: string): Instance
    assert(parent, "Should have a parent")
    assert(rowName, "Should have a rowName")
    return GuiUtils.makeRowWithLabelAndReturnRowContent(parent, rowName, nil)
end

-- Make a button with common look & feel.
GuiUtils.makeTextButton = function(parent: Instance, text: string, callback: () -> ()): Instance
    local button = Instance.new("TextButton")
    button.Name = GuiUtils.textButtonName
    button.Parent = parent
    button.Size = UDim2.new(0, 0, 1, 0)
    button.AutomaticSize = Enum.AutomaticSize.X
    button.Position = UDim2.new(0, 0, 0, 0)
    button.Text = text
    button.TextSize = 14
    button.MouseButton1Click:Connect(function()
        if not button.Active then
            return
        end
        callback()
    end)
    button.BorderSizePixel = 3

    GuiUtils.addCorner(button)

    local uiPadding = Instance.new("UIPadding")
    uiPadding.Parent = button
    uiPadding.PaddingLeft = GuiUtils.horizontalPadding
    uiPadding.PaddingRight = GuiUtils.horizontalPadding

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

-- Make a text label, standardized look & feel.
GuiUtils.makeTextLabel = function(parent: Instance, text: string, opt_richText: boolean?): TextLabel
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = GuiUtils.textLabelName
    if opt_richText then
        textLabel.RichText = true
    end
    textLabel.Parent = parent
    textLabel.Size = UDim2.new(0, 0, 0, GuiUtils.textLabelHeight)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.AutomaticSize = Enum.AutomaticSize.XY
    textLabel.TextWrapped = true
    textLabel.Text = text
    textLabel.TextSize = GuiUtils.textLabelFontSize
    textLabel.BorderSizePixel = 0
    textLabel.BackgroundTransparency = 1
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    return textLabel
end

--[[
    Make a clickable button representing a game table.
]]
GuiUtils.makeTableButton = function(parent: Instance, tableDescription: CommonTypes.TableDescription, onButtonCiicked: () -> nil): GuiObject
    -- FIXME(dbanks)
    -- Someday a nice large button with image of game, name, host, description, etc.
    -- For now just host name and game name as a text button.
   local hostName = GuiUtils.getPlayerName(tableDescription.hostUserId)
    local gameName = GuiUtils.getGameName(tableDescription.gameId)
    assert(hostName, "No host name for " .. tableDescription.hostUserId)
    assert(gameName, "No game name for " .. tableDescription.gameId)
    local buttonText = "\"" .. gameName .. "\" hosted by " .. hostName

    return GuiUtils.makeTextButton(parent, buttonText, onButtonCiicked)
end

GuiUtils.makeUserButton = function(parent: Instance, playerName: string, playerThumbnail: string, onButtonClicked: () -> nil): GuiObject
    -- FIXME(dbanks)
    -- Someday a nice large button with image of user, name, etc.
    -- For now just text button with name,
    return GuiUtils.makeTextButton(parent, playerName, onButtonClicked)
end

GuiUtils.makeGameButton = function(parent: Instance, gameDetails: CommonTypes.GameDetails, onButtonClicked: () -> nil): GuiObject
    -- FIXME(dbanks)
    -- Someday a nice large button with image of game, description, etc.
    -- For now just text button with name,
    return GuiUtils.makeTextButton(parent, gameDetails.name, onButtonClicked)
end

GuiUtils.makeUserWidget = function(parent: Instance, playerName: string, playerThumbnail: string): GuiObject
    -- FIXME(dbanks)
    -- Someday a nice large widget with image of user, name, etc.
    -- For now just text label with name,
    return GuiUtils.makeTextLabel(parent, playerName)
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
    widgetContainer.Size = UDim2.new(0, 0, 0, GuiUtils.minWidgetContainerHeight)
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
GuiUtils.makeTableButtonWidgetContainer = function(parent: Instance, tableId: number, onClick: () -> nil): Frame
    local tableDescription = TableDescriptions.getTableDescription(tableId)
    -- Should exist.
    assert(tableDescription, "Should have a tableDescription")
    local tableButtonContainer = makeWidgetContainer(parent, "Table", tableId)

    GuiUtils.makeTableButton(tableButtonContainer, tableDescription, onClick)

    return tableButtonContainer
end

-- Make a widgetContainer containing a user (name, thumbnail, etc).
-- If a callback is given, make it a button, else it's just a static frame.
GuiUtils.makeUserWidgetContainer = function(parent: Instance, userId: number, onClick: ((userId) -> nil)?): Frame
    -- So what will happen:
    -- We return a table button container with "loading" message.
    -- We fire off a fetch to get async info.
    -- When that resolves we remove loading message and add the real info.
    -- FIXME(dbanks)
    -- Make nicer: loading message could be a swirly or whatever.
    local tableButtonContainer = makeWidgetContainer(parent, "User", userId)
    local waitingWidget = GuiUtils.makeTextLabel(tableButtonContainer, "Loading...")
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
            GuiUtils.makeUserButton(tableButtonContainer, playerName, playerThumbnail, function()
                onClick(userId)
            end)
        else
            GuiUtils.makeUserWidget(tableButtonContainer, playerName, playerThumbnail)
        end
    end)

    return tableButtonContainer
end

-- A generic text button in a widget container.
GuiUtils.makeTextButtonWidgetContainer = function(parent: Instance, text: string, onClick: () -> nil): Frame
    local textButtonContainer = makeWidgetContainer(parent, "TextButtonWidgetContainer", nil)
    GuiUtils.makeTextButton(textButtonContainer, text, onClick)
    return textButtonContainer
end

-- Make a widget container containing a text label.
GuiUtils.makeTextLabelWidgetContainer = function(parent: Instance, text: string): Frame
    local textLabelContainer = makeWidgetContainer(parent, "TextLabelWidgetContainer", nil)
    GuiUtils.makeTextLabel(textLabelContainer, text)
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

-- Conveniencce for adding vertical list layout, order based on layout order.
GuiUtils.makeUiListLayout = function(frame: Frame, opt_useHorizontal: boolean) : UIListLayout
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    if opt_useHorizontal then
        uiListLayout.FillDirection = Enum.FillDirection.Horizontal
    else
        uiListLayout.FillDirection = Enum.FillDirection.Vertical
    end
    uiListLayout.Parent = frame

    uiListLayout.Padding = UDim.new(0, 5)

    return uiListLayout
end

GuiUtils.getSelectedOptionsString = function(tableDescription: CommonTypes.TableDescription): string
    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)

    if not gameDetails.configOptions then
        return
    end

    local enabledOptionsStrings = {}
    for _, optionId in tableDescription.enabledGameOptions do
        local optionName
        for _, gameOption in gameDetails.gameOptions do
            if gameOption.id == optionId then
                optionName = gameOption.name
                break
            end
        end
        assert(optionId, "Should have an optionId")
        table.insert(enabledOptionsStrings, optionName)
    end
    if #enabledOptionsStrings == 0 then
        return "(None)"
    end

    return table.concat(enabledOptionsStrings,", ")
end

return GuiUtils
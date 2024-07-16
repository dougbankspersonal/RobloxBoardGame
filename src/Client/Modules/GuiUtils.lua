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
local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local TableDescriptions = require(RobloxBoardGameClient.Modules.TableDescriptions)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)

local globalLayoutOrder = 0

GuiUtils.getLayoutOrder = function(parent:Instance, opt_layoutOrder: number?): number
    local layoutOrder
    if opt_layoutOrder then
        layoutOrder = opt_layoutOrder
    else
        local nextLayourOrder = parent:FindFirstChild("NextLayoutOrder")
        if nextLayourOrder then
            layoutOrder = nextLayourOrder.Value
            nextLayourOrder.Value = nextLayourOrder.Value + 1
        else
            layoutOrder = globalLayoutOrder
            globalLayoutOrder = globalLayoutOrder + 1
        end
    end
    return layoutOrder
end

GuiUtils.addLayoutOrderTracking = function(parent:Instance)
    local nextLayoutOrder = Instance.new("IntValue")
    nextLayoutOrder.Parent = parent
    nextLayoutOrder.Value = 0
    nextLayoutOrder.Name = "NextLayoutOrder"
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
GuiUtils.addRowWithLabelAndReturnRowContent = function(parent:Instance, rowName: string, text: string?, opt_layoutOrder: number?): Instance
    assert(parent, "Should have a parent")
    assert(rowName, "Should have a rowName")

    local row = Instance.new("Frame")
    row.Name = rowName
    row.Parent = parent
    row.Size = UDim2.new(1, 0, 0, 0)
    row.Position = UDim2.new(0, 0, 0, 0)
    row.BorderSizePixel = 0

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Parent = row
    uiListLayout.FillDirection = Enum.FillDirection.Horizontal
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    uiListLayout.Padding = UDim.new(5, 5)
    if opt_layoutOrder then
        row.LayoutOrder = GuiUtils.getLayoutOrder(parent, opt_layoutOrder)
    end

    row.AutomaticSize = Enum.AutomaticSize.Y
    local bgColor
    if row.LayoutOrder%2 == 0 then
        bgColor = Color3.fromHex("f0f0f0")
    else
        bgColor = Color3.fromHex("e0e0e0")
    end
    row.BackgroundColor3 = bgColor

    if text then
        local label = Instance.new("TextLabel")
        label.Name = "LabelInRow"
        label.Parent = row
        label.Size = UDim2.new(0, 0, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.XY
        label.Position = UDim2.new(0, 0, 0, 0)
        label.Text = text
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.LayoutOrder = 1
    end

    local rowContent = Instance.new("Frame")
    rowContent.Parent = row
    rowContent.Size = UDim2.new(0, 0, 0, 0)
    rowContent.AutomaticSize = Enum.AutomaticSize.XY
    rowContent.Position = UDim2.new(0, 0, 0, 0)
    rowContent.Name = "RowContent"
    rowContent.LayoutOrder = 2
    rowContent.BackgroundTransparency = 1
    rowContent.BorderSizePixel = 0

    local uiGridLayout = Instance.new("UIGridLayout")
    uiGridLayout.Parent = rowContent
    uiGridLayout.FillDirection = Enum.FillDirection.Horizontal
    uiGridLayout.Name = "uiGridLayout"
    uiGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiGridLayout.CellSize = UDim2.new(0, 200, 0, 30)

    GuiUtils.addLayoutOrderTracking(rowContent)

    return rowContent
end

-- Parent contains rows.
-- Find row with given name, return the rowContent frame for that row.
GuiUtils.getRowContent = function(parent: GuiObject, rowName: string): Frame
    local row = parent:FindFirstChild(rowName)
    assert(row, "row should exist")
    local rowContent = row:FindFirstChild("RowContent")
    assert(rowContent, "rowContent should exist")
    return rowContent
end

-- Make a row with no label.
GuiUtils.addRowAndReturnRowContent = function(parent:Instance, rowName: string, opt_layoutOrder: number?): Instance
    assert(parent, "Should have a parent")
    assert(rowName, "Should have a rowName")
    return GuiUtils.addRowWithLabelAndReturnRowContent(parent, rowName, nil, opt_layoutOrder)
end

GuiUtils.addButton = function(parent: Instance, text: string, callback: () -> (), opt_layoutOrder: number?): Instance
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = UDim2.new(0, 0, 1, 0)
    button.AutomaticSize = Enum.AutomaticSize.X
    button.Position = UDim2.new(0, 0, 0, 0)
    button.Text = text
    button.TextSize = 14
    button.LayoutOrder = GuiUtils.getLayoutOrder(parent, opt_layoutOrder)
    parent.NextLayoutOrder.Value = parent.NextLayoutOrder.Value + 1
    button.Activated:Connect(function()
        callback()
    end)
    button.BorderSizePixel = 3

    local uiCorner = Instance.new("UICorner")
    uiCorner.Parent = button
    uiCorner.CornerRadius = UDim.new(0, 4)

    return button
end

-- Throw up a dialog using the given config.
-- Clicking any button in the config will kill the dialog and hit the associated callback.
GuiUtils.makeDialog = function(screenGui: ScreenGui, dialogConfig: CommonTypes.DialogConfig)
    -- FIXME(dbanks)
    -- One way to make this nicer, add some kinda cool tweening effect for dialog
    -- going up/down.
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0.5, 0, 0.5, 0)
    dialog.Position = UDim2.new(0.25, 0, 0.25, 0)
    dialog.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    dialog.Parent = screenGui

    GuiUtils.addRowWithLabelAndReturnRowContent(dialog, "Row_Title", dialogConfig.title)
    GuiUtils.addRowWithLabelAndReturnRowContent(dialog, "Row_Description", dialogConfig.description)
    local rowContent = GuiUtils.addRowAndReturnRowContent(dialog, "Row_Controls")
    for _, buttonConfig in ipairs(dialogConfig.buttons) do
        GuiUtils.addButton(rowContent, buttonConfig.text, function()
            dialog.Parent = nil
            buttonConfig.callback()
        end)
    end

    return dialog
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
GuiUtils.makeTextLabel = function(parent: Instance, text: string): TextLabel
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = parent
    textLabel.Size = UDim2.new(0, 0, 0, 0)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.AutomaticSize = Enum.AutomaticSize.XY
    textLabel.Text = text
    textLabel.TextSize = 14
    textLabel.BorderSizePixel = 0
    return textLabel
end

--[[
    Make a clickable button representing a game table.
]]
GuiUtils.makeTableButton = function(tableButtonContainer: Instance, tableDescription: CommonTypes.TableDescription, onButtonCiicked: () -> nil)
    local tableButton = Instance.new("TextButton")
    tableButton.Parent = tableButtonContainer
    tableButton.Size = UDim2.new(1, 0, 1, 0)
    tableButton.Position = UDim2.new(0, 0, 0, 0)

    -- FIXME(dbanks)
    -- Add a nice image of the game, the host, other metadata.
    -- FOr now just host name and game name.
    local hostName = GuiUtils.getPlayerName(tableDescription.hostUserId)
    local gameName = GuiUtils.getGameName(tableDescription.gameId)
    assert(hostName, "No host name for " .. tableDescription.hostUserId)
    assert(gameName, "No game name for " .. tableDescription.gameId)

    tableButton.Text = "\"" .. gameName .. "\" hosted by " .. hostName
    tableButton.TextSize = 14
    tableButton.BorderSizePixel = 0
    tableButton.Activated:Connect(onButtonCiicked)
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
GuiUtils.updateWidgetContainerChildren = function(parentFrame:Frame, itemIds:{number}, _makeWidgetContainer: (Instance, number) -> Instance): CommonTypes.TweensToKill
    local retVal = {} :: CommonTypes.TweensToKill

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
        retVal[key] = tween

        tween.Completed:Connect(function(_)
            retVal[key] = nil
            widgetContainer:Destroy()
        end)
        tween:Play()
    end

    -- Tween in new widgets.
    for _, itemId in itemIdsIn do
        local widgetContainer = _makeWidgetContainer(parentFrame, itemId)
        -- It is required that the widget container has an int value child with
        -- name "ItemId" and value equal to itemId.
        assert(widgetContainer.ItemId, "WidgetContainer should have an ItemId")
        assert(widgetContainer.ItemId.Value == itemId, "WidgetContainer.ItemId.Value should be itemId")

        local uiScale = Instance.new("UIScale")
        uiScale.Name = "UIScale"
        uiScale.Parent = widgetContainer
        uiScale.Scale = 0

        local tween = TweenService:Create(widgetContainer.UIScale, tweenInfo, {Scale = 1})
        local key = makeTweenKey(widgetContainer)
        retVal[key] = tween

        tween.Completed:Connect(function(_)
            retVal[key] = nil
        end)
        tween:Play()
    end

    return retVal
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

    local container = Instance.new("Frame")
    container.Parent = parent
    container.Size = UDim2.new(0, 200, 0, 30)
    container.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
    container.BorderSizePixel = 0
    container.Name = GuiUtils.constructWidgetContainerName(widgetType, itemId)

    local intValue = Instance.new("IntValue")
    intValue.Value = itemId
    intValue.Parent = container
    intValue.Name = "ItemId"

    local stringValue = Instance.new("StringValue")
    stringValue.Value = widgetType
    stringValue.Parent = container
    stringValue.Name = "ItemType"

    return container
end

-- Make a widgetContainer containing a clickable button representing a table.
-- Clicking button joins the table.
GuiUtils.makeTableButtonWidgetContainer = function(parent: Instance, tableId: number): Frame
    local tableDescription = TableDescriptions.getTableDescription(tableId)
    -- Should exist.
    assert(tableDescription, "Should have a tableDescription")
    local tableButtonContainer = makeWidgetContainer(parent, "table", tableId)

    GuiUtils.makeTableButton(tableButtonContainer, tableDescription, function()
        ClientEventManagement.joinTable(tableId)
    end)

    return tableButtonContainer
end

-- Make a widget container containing a text label.
GuiUtils.makeTextLabelWidgetContainer = function(parent: Instance, text: string): Frame
    local textLabelContainer = makeWidgetContainer(parent, "TextLabel", nil)
    GuiUtils.makeTextLabel(textLabelContainer, text)
    return textLabelContainer
end


GuiUtils.updateTextLabelWidgetContainer = function(widgetContainer: Frame, text: string): boolean
    local textLabel = widgetContainer:FindFirstChild("TextLabel")
    assert(textLabel, "Should have a textLabel")
    if textLabel.Text == text then
        return false
    end
    textLabel.Text = text
    return true
end

GuiUtils.selectFriend = function(screenGui, onFriendSelected: (userId: CommonTypes.UserId?)
    -> nil)
    -- FIXME(dbanks)
    -- Pure hackery for test purposes only.
    -- What we really need is some widget that:
    -- * shows all friends.
    -- * search widget to filter.
    -- * can select one or more friends.
    -- * reports back set of selected friends.
    -- I have to believe this exists somewhere, can't find it.
    -- Bonus if it also invites said friends to the experience.
    local localPlayerId = game.Players.LocalPlayer.UserId
    local dialogButtonConfigs = {} :: {CommonTypes.DialogConfigButton}

    -- FIXME(dbanks)
    -- Add the ids of the non-local players you get when you run in Studio.

    table.insert(dialogButtonConfigs, {
        {
            text = "Cancel",
            callback = function()
                onFriendSelected()
            end,
        })

    local dialogConfig = {
        title = "Select a friend",
        description = "Select a friend to invite to the table.",
        buttons = dialogButtonConfigs,
    } :: CommonTypes.DialogConfig
    GuiUtils.makeDialog(screenGui, dialogConfig)
end

-- Conveniencce for adding vertical list layout, order based on layout order.
GuiUtils.addUiListLayout = function(frame: Frame) : UIListLayout
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = frame
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
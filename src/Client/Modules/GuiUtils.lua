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

GuiUtils.addRowWithLabel = function(parent:Instance, text: string?, opt_layoutOrder: number?): Instance
    local row = Instance.new("Frame")
    row.Parent = parent
    row.Size = UDim2.new(1, 0, 0, 0)
    row.Position = UDim2.new(0, 0, 0, 0)
    row.BorderSizePixel = 0

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Parent = row
    uiListLayout.FillDirection = Enum.FillDirection.Horizontal
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(5, 5)
    row.LayoutOrder = GuiUtils.getLayoutOrder(parent, opt_layoutOrder)
    row.Name = "Row" .. tostring(row.LayoutOrder)
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

GuiUtils.addRow = function(parent:Instance, opt_layoutOrder: number?): Instance
    return GuiUtils.addRowWithLabel(parent, nil, opt_layoutOrder)
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
    button.MouseButton1Click:Connect(function()
        if not button.Active then
            return
        end
        callback()
    end)
    button.BorderSizePixel = 3

    local uiCorner = Instance.new("UICorner")
    uiCorner.Parent = button
    uiCorner.CornerRadius = UDim.new(0, 4)

    return button
end

GuiUtils.makeDialog = function(screenGui: ScreenGui, dialogConfig: CommonTypes.DialogConfig)
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0.5, 0, 0.5, 0)
    dialog.Position = UDim2.new(0.25, 0, 0.25, 0)
    dialog.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    dialog.Parent = screenGui

    GuiUtils.addRowWithLabel(dialog, dialogConfig.title)
    GuiUtils.addRowWithLabel(dialog, dialogConfig.description)
    local row = GuiUtils.addRow(dialog)

    for _, buttonConfig in ipairs(dialogConfig.buttons) do
        GuiUtils.addButton(row, buttonConfig.text, buttonConfig.callback)
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
    tableButton.MouseButton1Click:Connect(onButtonCiicked)
end

-- Which table buttons have no description?
local function getWidgetContainersOut(widetContainers: {Instance}, itemIds: {number}): {Instance}
    local widgetContainersOut = {} :: {Instance}
    for _, widetContainer in widetContainers do
        local widgetItemId = widetContainer.ItemId.Value
        local widgetInItems = false
        for _, itemId in itemIds do
            if widgetItemId == itemId then
                widgetInItems = true
                break
            end
        end
        if not widgetInItems then
            table.insert(widgetContainersOut, widetContainer)
        end
    end
    return widgetContainersOut
end

-- Which table descriptions have no buttons?
local function getItemIdsIn(widetContainers: {Instance}, itemIds: {number}): {number}
    local itemIdsIn = {}
    for _, itemId in itemIds do
        local itemInWidgets = false
        for _, widetContainer in widetContainers do
            if itemId == widetContainer.ItemId.Value then
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

-- we have a row which is a frame containing one widget for each of a list of things (tables,
-- users, whatever).
-- These things all have some unique id, call it itemId (a number).
-- We have a new/updated list of these things which may or may not match the existing list of
-- widgets.
-- Make update the row to remove/add widgets so the widgets match the incoming list of things.
GuiUtils.updateRowOfWidgets = function(row:Instance, itemIds:{number}, makeWidgetContainer: (Instance, number) -> Instance): nil
    local allKids = row:GetChildren()

    -- Get all the existing widgets.
    local widgetContainers = {}
    for _, kid in allKids do
        if kid.Name == "WidgetContainer" then
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
        tween.Completed:Connect(function(_)
            widgetContainer:Destroy()
        end)
        tween:Play()
    end

    -- Tween in new widgets.
    for _, itemId in itemIdsIn do
        local widgetContainer = makeWidgetContainer(row, itemId)
        -- It is required that the widget container has an int value child with
        -- name "ItemId" and value equal to itemId.
        assert(widgetContainer.ItemId, "WidgetContainer should have an ItemId")
        assert(widgetContainer.ItemId.Value == itemId, "WidgetContainer.ItemId.Value should be itemId")

        local uiScale = Instance.new("UIScale")
        uiScale.Name = "UIScale"
        uiScale.Parent = widgetContainer
        uiScale.Scale = 0

        local tween = TweenService:Create(widgetContainer.UIScale, tweenInfo, {Scale = 1})
        tween:Play()
    end
end

-- Make a button describing a table.
-- When button is clicked, user joins this table.
GuiUtils.makeTableButtonContainer = function(parent: Instance, tableId: number): Instance
    local tableDescription = TableDescriptions.getTableDescription(tableId)
    -- Should exist.
    assert(tableDescription, "Should have a tableDescription"
)
    local tableButtonContainer = Instance.new("Frame")
    tableButtonContainer.Parent = parent
    tableButtonContainer.Size = UDim2.new(0, 200, 0, 30)
    tableButtonContainer.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
    tableButtonContainer.BorderSizePixel = 0
    tableButtonContainer.Name = "WidgetContainer"

    local intValue = Instance.new("IntValue")
    intValue.Value = tableId
    intValue.Parent = tableButtonContainer
    intValue.Name = "ItemId"

    GuiUtils.makeTableButton(tableButtonContainer, tableDescription, function()
        ClientEventManagement.joinTable(tableId)
    end)

    return tableButtonContainer
end

-- Function to check whether the player can send an invite
local function canSendGameInvite(sendingPlayer)
	local success, canSend = pcall(function()
		return SocialService:CanSendGameInviteAsync(sendingPlayer)
	end)
	return success and canSend
end

GuiUtils.selectFriend = function(screenGui, onFriendSelected: (userId: CommonTypes.UserId)
    -> nil)
    local player = Players.LocalPlayer
    local canInvite = canSendGameInvite(player)

    -- Before we put up the prompt, hook into the "all done" function.


    if canInvite then
        SocialService:PromptGameInvite(player)
    end
end

return GuiUtils
--[[
Generic widget for selecting a friend or set of friends.
Pass in:
    * dialog title
    * dialog description.
    * bool: is this multi or single select?
    * array of userIds: if multi-select, these are the pre-selected friends.
    * callback: function to call when user hits OK.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

local Cryo = require(ReplicatedStorage.Cryo)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local DialogUtils = require(RobloxBoardGameStarterGui.Modules.DialogUtils)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)
local UserGuiUtils = require(RobloxBoardGameStarterGui.Modules.UserGuiUtils)

local FriendSelectionDialog = {}

-- SnackFort: few friends.
-- local mockUserId = 5845980262
-- TheGamer101: many friends.
local mockUserId = 2231221

local selectedUserIds: {CommonTypes.UserId} = {}

local selectedFriendsRowContent
local gridRowContent
local filterWidgetContent

export type FriendSelectionDialogConfig = {
    title: string,
    description: string,
    isMultiSelect: boolean?,
    preselectedUserIds: {CommonTypes.UserId}?,
    callback: (userIds: {CommonTypes.UserId}?) -> nil,
}

export type FriendFromFriendPages = {
    DisplayName	: string,
    Id: number,
    IsOnline: boolean,
    Username: string,
}

local updateSelectedFriendsRowContent
updateSelectedFriendsRowContent = function(justBuilt: boolean?)
    assert(selectedFriendsRowContent, "Should have a rowContent")
    assert(selectedFriendsRowContent.Parent.Name == "Row_SelectedFriends", "Should have a rowContent with parent Row_SelectedFriends")

    local function canDeselectFriend(): boolean
        return true
    end

    local function deselectFriendCallback(userId: CommonTypes.UserId)
        selectedUserIds = Cryo.List.removeValue(selectedUserIds, userId)
        updateSelectedFriendsRowContent(false)
    end

    local function addNullUserStaticWidget(_parent: Frame)
        GuiUtils.addStaticWidget(_parent, GuiUtils.italicize("No friends selected."), {
            Size = GuiConstants.userWidgetSize,
        })
    end

    UserGuiUtils.updateUserRowContent(selectedFriendsRowContent, justBuilt == true, selectedUserIds, canDeselectFriend, deselectFriendCallback, addNullUserStaticWidget, GuiUtils.removeNullStaticWidget)

    -- Anyone in grid not in selectedUserIds should be enabled.
    -- Anyone in grid in selectedUserIds should be disabled.
    local widgetCotainerNamesForSelectedUsers = {}
    for _, selectedUserId in selectedUserIds do
        local widgetContainerName = GuiUtils.constructWidgetContainerName("User", selectedUserId)
        widgetCotainerNamesForSelectedUsers[widgetContainerName] = true
    end

    local childWidgetContainers = gridRowContent:GetChildren()
    for _, childWidgetContainer in childWidgetContainers do
        if GuiUtils.isAWidgetContainer(childWidgetContainer) then
            local button = childWidgetContainer:FindFirstChild(GuiConstants.userButtonName)
            assert(button, "Should have a button")
            if widgetCotainerNamesForSelectedUsers[childWidgetContainer.Name] then
                button.Active = false
            else
                button.Active = true
            end
        end
    end
end

local function appendFriendsToGrid(friendsFromFriendPages: {FriendFromFriendPages}, config: FriendSelectionDialogConfig)
    for _, friendFromFriendPages in friendsFromFriendPages do
        local userId = friendFromFriendPages.Id

        local onFriendSelected = function()
            if config.isMultiSelect then
                -- Just some sanity checks: if already selected this is a no op.
                if Cryo.List.find(selectedUserIds, userId) then
                    return
                end
                table.insert(selectedUserIds, userId)
                updateSelectedFriendsRowContent(false)
            else
                config.callback({userId})
            end
        end

        local userWidgetContainer = UserGuiUtils.addUserButtonWidgetContainer(gridRowContent, userId, onFriendSelected)

        if config.isMultiSelect then
            -- If this is multi-select, we want to disable the button if it's already selected.
            if Cryo.List.find(selectedUserIds, userId) then
                local button = userWidgetContainer:FindFirstChild("Button")
                assert(button, "Should have a button")
                button.Active = false
            end
        end
    end
end

local function asyncFetchAllFriends(userId: number, callback: ({FriendFromFriendPages}))
    task.spawn(function()
        local friendPages = Players:GetFriendsAsync(userId)
        local finalFriendsFromFriendPages: {FriendFromFriendPages} = {}
        while true do
            local friendsFromFriendPagesHandful = friendPages:GetCurrentPage()
            finalFriendsFromFriendPages = Cryo.List.join(finalFriendsFromFriendPages, friendsFromFriendPagesHandful)
            if friendPages.IsFinished then
                break
            else
                friendPages:AdvanceToNextPageAsync()
            end
        end
        callback(finalFriendsFromFriendPages)
    end)
end

local function fillGridInRowContentWithFriends(config: FriendSelectionDialogConfig)
    -- Grab handfuls. If we scroll down grab more handfuls.
    local userId = Players.LocalPlayer.UserId
    if RunService:IsStudio() then
        -- Pretend, this account has lots of friends.
        userId = mockUserId
    end

    -- Async so do in a task spawn.
    asyncFetchAllFriends(userId, function(friendsFromFriendPages: {FriendFromFriendPages})
        Utils.debugPrint("Friends", "Doug: friendsFromFriendPages = ", friendsFromFriendPages)
        appendFriendsToGrid(friendsFromFriendPages, config)
    end)
end

local filterMatchesUserName = function(filterText: string?, userName: string): boolean
    if not filterText or filterText == "" then
        return true
    end

    return string.find(string.lower(userName), string.lower(filterText), 1, true) ~= nil
end

local addFilterTextBox = function(rowContent:Frame): Frame
    local textBox = GuiUtils.addTextBox(rowContent, {
        PlaceholderText = "Filter friends by name...",
        Size = UDim2.fromScale(0.75, 0),
        Text = "",
    })

    -- When the text box changes we are going to filter the grid.
    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        local filterText = textBox.Text
        local childWidgetContainers = gridRowContent:GetChildren()
        for _, childWidgetContainer in childWidgetContainers do
            if GuiUtils.isAWidgetContainer(childWidgetContainer) then
                local userName = GuiUtils.getNameFromUserWidgetContainer(childWidgetContainer)

                if filterMatchesUserName(filterText, userName) then
                    childWidgetContainer.Visible = true
                else
                    childWidgetContainer.Visible = false
                end
            end
        end
    end)
end


local function _makeCustomDialogContent(parent:Frame, config: FriendSelectionDialogConfig): GuiObject
    -- If this is multi-select, we want a row to show all currently selected friends.
    if config.isMultiSelect then
        selectedFriendsRowContent = GuiUtils.addRowOfUniformItemsAndReturnRowContent(parent, "Row_SelectedFriends", "Selected Friends: ", GuiConstants.userLabelHeight)
    end

    -- Add the filter widget.
    filterWidgetContent = GuiUtils.addRowAndReturnRowContent(parent, "Row_Filter")
    addFilterTextBox(filterWidgetContent)

    -- Grid of friends.
    Utils.debugPrint("User", "Doug: _makeCustomDialogContent 001 GuiConstants.userWidgetSize = ", GuiConstants.userWidgetSize)
    gridRowContent = GuiUtils.addRowWithItemGridAndReturnRowContent(parent, "Row_AvailableFriends", GuiConstants.userWidgetSize)
    fillGridInRowContentWithFriends(config)

    if config.isMultiSelect then
        updateSelectedFriendsRowContent(true)
    end
end

FriendSelectionDialog.selectFriends = function(config: FriendSelectionDialogConfig): Frame?
    Utils.debugPrint("Friends", "Doug: config = ", config)

    assert(config, "config must be provided")
    assert(config.title, "config.title must be provided")
    assert(config.description, "config.description must be provided")
    assert(config.callback, "config.callback must be provided")

    selectedUserIds = config.preselectedUserIds or {}
    Utils.debugPrint("Friends", "Doug: selectedUserIds = ", selectedUserIds)

    local dialogConfig: DialogUtils.DialogConfig = {
        title = config.title,
        description = config.description,
        dialogButtonConfigs = {
            {
                text = "OK",
                callback = function()
                    config.callback(selectedUserIds)
                end
            } :: DialogUtils.DialogButtonConfig,
        } :: {DialogUtils.DialogConfig},
        makeCustomDialogContent = function(parent: Frame)
            _makeCustomDialogContent(parent, config)
        end,
    }

    return DialogUtils.makeDialog(dialogConfig)
end

return FriendSelectionDialog
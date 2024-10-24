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
local PlayerUtils = require(RobloxBoardGameShared.Modules.PlayerUtils)

local Cryo = require(ReplicatedStorage.Cryo)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)
local UserGuiUtils = require(RobloxBoardGameClient.Modules.UserGuiUtils)

local FriendSelectionDialog = {}

-- For testing purposes it helps to have lots of friends in here.
-- My account has few friends.
-- TheGamer101 has many friends.
-- If in Studio, when we do stuff related to friends, pretend we are that account.
local mockUserId = 2231221

local selectedUserIds: {CommonTypes.UserId} = {}

local selectedFriendsRowContent
local friendsScrollingFrame
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

local setChildButtonActive = function(widgetContainer: Frame, active: boolean)
    local button = widgetContainer:FindFirstChild(GuiConstants.userButtonName, true)
    assert(button, "Should have a button")
    button.Active = active
end

local updateSelectedFriendsRowContent
updateSelectedFriendsRowContent = function(justBuilt: boolean?)
    assert(selectedFriendsRowContent, "Should have a rowContent")
    assert(selectedFriendsRowContent.Parent.Name == GuiConstants.selectedFriendsName, "Should have a rowContent with parent " .. GuiConstants.selectedFriendsName)

    local function canDeselectFriend(): boolean
        return true
    end

    local function deselectFriendCallback(userId: CommonTypes.UserId)
        selectedUserIds = Cryo.List.removeValue(selectedUserIds, userId)
        updateSelectedFriendsRowContent(false)
    end

    local function addNullUserStaticWidget(_parent: Frame)
        GuiUtils.addNullStaticWidget(_parent, GuiUtils.italicize("No friends selected."), {
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

    Utils.debugPrint("InviteToTable", "gridRowContent = ", friendsScrollingFrame)
    local childWidgetContainers = friendsScrollingFrame:GetChildren()
    Utils.debugPrint("InviteToTable", "childWidgetContainers = ", childWidgetContainers)
    for _, childWidgetContainer in childWidgetContainers do
        Utils.debugPrint("InviteToTable", "childWidgetContainer = ", childWidgetContainer)
        if GuiUtils.isAWidgetContainer(childWidgetContainer) then
            setChildButtonActive(childWidgetContainer, not widgetCotainerNamesForSelectedUsers[childWidgetContainer.Name])
        end
    end
end

local function appendFriendsToGrid(friendsFromFriendPages: {FriendFromFriendPages}, config: FriendSelectionDialogConfig)
    for _, friendFromFriendPages in friendsFromFriendPages do
        task.spawn(function()
            local userId = friendFromFriendPages.Id

            PlayerUtils.asyncFetchPlayerInfo({userId})

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

            local userWidgetContainer = UserGuiUtils.addUserButtonWidgetContainer(friendsScrollingFrame, userId, onFriendSelected)

            if config.isMultiSelect then
                -- If this is multi-select, we want to disable the button if it's already selected.
                setChildButtonActive(userWidgetContainer, not Cryo.List.find(selectedUserIds, userId))
            end
        end)
    end
end

local function asyncFetchAllFriends(userId: number, callback: ({FriendFromFriendPages}))
    task.spawn(function()
        local friendPages = Players:GetFriendsAsync(userId)
        local finalFriendsFromFriendPages: {FriendFromFriendPages} = {}
        while true do
            local friendsFromFriendPagesHandful = friendPages:GetCurrentPage()
            -- Prime the pump for all these guys' player info.
            -- Warning: trying to do these all in one handful creates a huge lag.  Just do them one at a time later as we try to create the buttons.
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

local function fillFriendsScrollingFrametWithFriends(config: FriendSelectionDialogConfig)
    -- Grab handfuls. If we scroll down grab more handfuls.
    local userId = Players.LocalPlayer.UserId
    if RunService:IsStudio() then
        -- Pretend, this account has lots of friends.
        userId = mockUserId
    end

    -- Async so do in a task spawn.
    asyncFetchAllFriends(userId, function(friendsFromFriendPages: {FriendFromFriendPages})
        Utils.debugPrint("Friends", "friendsFromFriendPages = ", friendsFromFriendPages)
        appendFriendsToGrid(friendsFromFriendPages, config)
    end)
end

local filterMatchesUserName = function(filterText: string?, userName: string): boolean
    if not filterText or filterText == "" then
        return true
    end

    return string.find(string.lower(userName), string.lower(filterText), 1, true) ~= nil
end

local addFilterTextBox = function(parent:Frame): Frame
    local textBox = GuiUtils.addTextBox(parent, {
        PlaceholderText = "Filter friends by name...",
        Size = UDim2.fromScale(0.75, 0),
        Text = "",
    })

    -- When the text box changes we are going to filter the grid.
    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        local filterText = textBox.Text
        local childWidgetContainers = friendsScrollingFrame:GetChildren()
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


local function makeCustomDialogContent(parent:Frame, config: FriendSelectionDialogConfig): GuiObject
    -- If this is multi-select, we want a row to show all currently selected friends.
    if config.isMultiSelect then
        local function rightHandContentMaker(_parent: Frame)
            local itemGrid = GuiUtils.addScrollingItemGrid(_parent, GuiConstants.rightHandContentName, GuiConstants.userWidgetSize, 1)
            return itemGrid
        end
        GuiUtils.addLabeledRow(parent, GuiConstants.SelectedFriendsName, "Selected Friends: ",rightHandContentMaker)
    end

    -- Add the filter widget.
    addFilterTextBox(parent)

    -- Grid of friends.
    Utils.debugPrint("User", "makeCustomDialogContent 001 GuiConstants.userWidgetSize = ", GuiConstants.userWidgetSize)
    friendsScrollingFrame = GuiUtils.addScrollingItemGrid(parent, "AvailableFriendsScroll", GuiConstants.userWidgetSize, 3)
    fillFriendsScrollingFrametWithFriends(config)

    if config.isMultiSelect then
        updateSelectedFriendsRowContent(true)
    end
end

function FriendSelectionDialog.selectFriends(config: FriendSelectionDialogConfig)
    Utils.debugPrint("Friends", "config = ", config)

    assert(config, "config must be provided")
    assert(config.title, "config.title must be provided")
    assert(config.description, "config.description must be provided")
    assert(config.callback, "config.callback must be provided")

    selectedUserIds = config.preselectedUserIds or {}
    Utils.debugPrint("Friends", "selectedUserIds = ", selectedUserIds)

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
        makeCustomDialogContent = function(_: number, parent: Frame)
            makeCustomDialogContent(parent, config)
        end,
    }

    DialogUtils.makeDialogAndReturnId(dialogConfig)
end

return FriendSelectionDialog
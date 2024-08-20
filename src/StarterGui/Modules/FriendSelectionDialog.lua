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

local selectedUserIds: {CommonTypes.UserId} = {}

export type FriendSelectionDialogConfig = {
    title: string,
    description: string,
    isMultiSelect: boolean?,
    preselectedUserIds: {CommonTypes.UserId}?,
    callback: (userIds: {CommonTypes.UserId}?) -> nil,
}

local updateSelectedFriendsRow
updateSelectedFriendsRow = function(parent: Frame, opt_justBuilt: boolean?)
    local function canDeselectFriend(): boolean
        return true
    end

    local function deselectFriendCallback(userId: CommonTypes.UserId)
        Cryo.List.removeValue(selectedUserIds, userId)
        updateSelectedFriendsRow(parent)
    end

    local function makeNullWidget(_parent: Frame)
        GuiUtils.addNullWidget(_parent, "<i>No friends selected.</i>", {
            Size = UDim2.fromOffset(GuiConstants.userWidgetX, GuiConstants.userWidgetY)
        })
    end

    UserGuiUtils.updateUserRow(parent, "Row_SelectedFriends", opt_justBuilt == true, selectedUserIds, canDeselectFriend, deselectFriendCallback, makeNullWidget, GuiUtils.removeNullWidget)
end

local function appendFriendsToGrid(rowContent: Frame, friendsFromFriendPages: {CommonTypes.FriendFromFriendPages}, config: FriendSelectionDialogConfig)
    for _, friendFromFriendPages in friendsFromFriendPages do
        local userId = friendFromFriendPages.Id

        local button = GuiUtils.addUserButton(rowContent, userId, function()
            if config.isMultiSelect then
                -- Just some sanity checcks: if already selected this is a no op.
                if Cryo.List.find(selectedUserIds, userId) then
                    return
                end
                table.insert(selectedUserIds, userId)
                updateSelectedFriendsRow(rowContent)
            else
                config.callback({userId})
            end
        end)

        if Cryo.List.find(selectedUserIds, userId) then
            button.Active = false
        end
    end
end

local function asyncFetchAllFriends(userId: number, callback: ({CommonTypes.FriendFromFriendPages}))
    task.spawn(function()
            local friendPages = Players:GetFriendsAsync(userId)
        local finalFriendsFromFriendPages: {CommonTypes.FriendFromFriendPages} = {}
        while friendPages.IsFinished == false do
            local friendsFromFriendPagesHandful = friendPages:GetCurrentPage()
            finalFriendsFromFriendPages = Cryo.List.join(finalFriendsFromFriendPages, friendsFromFriendPagesHandful)
            friendPages:AdvanceToNextPageAsync()
        end
        callback(finalFriendsFromFriendPages)
    end)
end

local function fillGridInRowContentWithFriends(rowContent: Frame, config: FriendSelectionDialogConfig)
    -- Grab handfuls. If we scroll down grab more handfuls.
    local userId = Players.LocalPlayer.UserId
    if RunService:IsStudio() then
        -- Pretend, this account has lots of friends.
        userId = 2231221
    end

    -- Async so do in a task spawn.
    asyncFetchAllFriends(userId, function(friendsFromFriendPages: {CommonTypes.FriendFromFriendPages})
        appendFriendsToGrid(rowContent, friendsFromFriendPages, config)
    end)
end


local function _makeCustomDialogContent(parent:Frame, config: FriendSelectionDialogConfig): GuiObject
    -- If this is multi-select, we want a row to show all currently selected friends.
    if config.isMultiSelect then
        GuiUtils.addRowOfUniformItems(parent, "Row_SelectedFriends", "Selected Friends: ", GuiConstants.userWidgetY)
        updateSelectedFriendsRow(parent, true)
    end

    -- FIXME(dbanks)
    -- Add the filter widget.

    -- Grid of friends.
    local rowContent = GuiUtils.addRowWithItemGridAndReturnRowContent(parent, "Row_AvailableFriends", GuiConstants.userWidgetWidth, GuiConstants.userWidgetY)
    fillGridInRowContentWithFriends(rowContent, config)
end

FriendSelectionDialog.selectFriends = function(config: FriendSelectionDialogConfig): Frame?
    Utils.debugPrint("Friends", "Doug: config = ", config)

    assert(config, "config must be provided")
    assert(config.title, "config.title must be provided")
    assert(config.description, "config.description must be provided")
    assert(config.callback, "config.callback must be provided")

    selectedUserIds = config.preselectedUserIds or {}

    local dialogConfig: CommonTypes.DialogConfig = {
        title = config.title,
        description = config.description,
        dialogButtonConfigs = {
            {
                text = "OK",
                callback = function()
                    config.callback(selectedUserIds)
                end
            } :: CommonTypes.DialogButtonConfig,
        } :: {CommonTypes.DialogConfig},
        makeCustomDialogContent = function(parent: Frame)
            _makeCustomDialogContent(parent, config)
        end,
    }

    return DialogUtils.makeDialog(dialogConfig)
end

return FriendSelectionDialog
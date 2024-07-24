--[[
UIMode is TableWaitingForPlayers.
Local player belongs to exactly one table (as host or guest) and
that table is in GameTableStates.WaitingForPlayers.
UI Shows:
    * metadata about game, including currently set gameOptions.
    * metadata about host.
    * row of members. Host can click to remove.
    * row of outstanding invites.  Host can click to uninvite.
    * (Host only): if game has gameOptions (e.g. optional rules, expanstions) a control to set gameOptions.
    * (Host only): a control to start the game.
    * (Host only): a control to destroy the table.
    * ( only): a control to leave the table.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local Cryo = require(ReplicatedStorage.Cryo)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local ClientEventManagement = require(RobloxBoardGameStarterGui.Modules.ClientEventManagement)
local DialogUtils = require(RobloxBoardGameStarterGui.Modules.DialogUtils)

local TableWaitingUI = {}

local startButtonWidgetContainerName: string
local gameOptionsWidgetContainerName: string

-- Called when first building the UI.
-- Game and host info don't change so we can fill that in.
-- Config options will change so that gets filled in in update, but we can create space for it now.
local addGameAndHostInfo = function(frame: Frame, gameDetails: CommonTypes.GameDetails, currentTableDescription: CommonTypes.TableDescription)
    -- Game info and host info will not change, might as well fill them in now.
    local rowContent = GuiUtils.addRowAndReturnRowContent(frame, "Row_Game", {
        labelText = "Game",

    })

    GuiUtils.addGameWidget(rowContent, gameDetails, true)

    -- If there are gameOptions, add a widget to contain that info.
    -- It will be filled in later.
    Utils.debugPrint("Doug: addGameAndHostInfo gameDetails = ", gameDetails)
    Utils.debugPrint("Doug: addGameAndHostInfo gameDetails.gameOptions = ", gameDetails.gameOptions)
    if gameDetails.gameOptions and #gameDetails.gameOptions > 0 then
        rowContent = GuiUtils.addRowAndReturnRowContent(frame, "Row_GameOptions", {
            labelText = "Game Options",
        })
        Utils.debugPrint("Doug: addGameAndHostInfo currentTableDescription = ", currentTableDescription)
        local selectedOptionsString = GuiUtils.getSelectedGameOptionsString(currentTableDescription)
        assert(selectedOptionsString, "selectedOptionsString should exist")
        local gameOptionsLabelWidgetContainer = GuiUtils.addTextLabelWidgetContainer(rowContent, selectedOptionsString,
            {
                TextWrapped = true,
            })
        assert(gameOptionsLabelWidgetContainer, "Should have gameOptionsLabelWidgetContainer")
        gameOptionsWidgetContainerName = gameOptionsLabelWidgetContainer.Name
    end

    rowContent  = GuiUtils.addRowAndReturnRowContent(frame, "Row_Host", {
        labelText = "Host",
    })
    GuiUtils.addPlayerWidget(rowContent, currentTableDescription.hostUserId)
end

local selectFriend = function(onFriendSelected: (userId: CommonTypes.UserId?)
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
    local dialogButtonConfigs = {} :: {CommonTypes.DialogButtonConfig}

    -- FIXME(dbanks)
    -- Add the ids of the non-local players you get when you run in Studio.

    table.insert(dialogButtonConfigs, {
        {
            text = "Cancel",
            callback = function()
                onFriendSelected()
            end,
        }
    })

    local dialogConfig = {
        title = "Select a friend",
        description = "Select a friend to invite to the table.",
        dialogButtonConfigs = dialogButtonConfigs,
    } :: CommonTypes.DialogConfig
    DialogUtils.makeDialog(dialogConfig)
end

local onAddInviteClicked = function(tableId: CommonTypes.TableId)
    assert(tableId, "Should have a tableId")
    selectFriend(function (userId: CommonTypes.UserId?)
        if userId then
            ClientEventManagement.invitePlayerToTable(tableId, userId)
        end
    end)
end

local addTableControls = function (frame: Frame, currentTableDescription: CommonTypes.TableDescription, isHost: boolean)
    -- Make a row for controls.
    local rowContent = GuiUtils.addRowAndReturnRowContent(frame, "Row_Controls")

    -- If we are the host, we can start the game.
    if isHost then
        -- Host can:
        -- * start game
        -- * destroy table
        -- * add invites (for non-public)
        -- * configure game (for game with gameOptions).
        --
        -- Keep track of the id for the start game button: we need to update it later.
        local startButtonWidgetContainer = GuiUtils.addTextButtonWidgetContainer(rowContent, "Start Game", function()
            ClientEventManagement.startGame(currentTableDescription.tableId)
        end)
        assert(startButtonWidgetContainer, "Should have startButtonWidgetContainer")
        startButtonWidgetContainerName = startButtonWidgetContainer.Name

        GuiUtils.addTextButtonWidgetContainer(rowContent, "Destroy Table", function()
            ClientEventManagement.destroyTable(currentTableDescription.tableId)
        end)
        if not currentTableDescription.isPublic then
            GuiUtils.addTextButtonWidgetContainer(rowContent, "Add Invites", function()
                onAddInviteClicked(currentTableDescription.tableId)
            end)
        end
        local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
        assert(gameDetails, "Should have gameDetails")
        if gameDetails.gameOptions and #gameDetails.gameOptions > 0 then
            GuiUtils.addTextButtonWidgetContainer(rowContent, "Configure Game", function()
                -- FIXME(dbanks)
                -- Put up a dialog to configure game.
            end)
        end
    else
        -- Guests can leave table.
        GuiUtils.addTextButtonWidgetContainer(rowContent, "Leave Table", function()
            ClientEventManagement.leaveTable(currentTableDescription.tableId)
        end)
    end
end

-- Create barebones structure for this UI,
-- Do not bother filling in anything that might change over time: this comes with update.
TableWaitingUI.build = function(currentTableDescription: CommonTypes.TableDescription)
    -- Sanity check arguments, get all the other stuff we need.
    assert(currentTableDescription, "Should have a currentTableDescription")

    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local isHost = localUserId == currentTableDescription.hostUserId

    local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
    assert(gameDetails, "Should have a gameDetails")

    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "MainFrame not found")

    GuiUtils.addUIListLayout(mainFrame)

    addGameAndHostInfo(mainFrame, gameDetails, currentTableDescription)

    -- Make a row for members (players who have joined), invites (players invited who have not yet joined)
    -- but do not fill in as this info will change: we set this in update function.
    GuiUtils.addRowAndReturnRowContent(mainFrame, "Row_Members", {
        labelText = "Members",
    })
    GuiUtils.addRowAndReturnRowContent(mainFrame, "Row_Invites", {
        labelText = "Invites",
    })

    addTableControls(mainFrame, currentTableDescription, isHost)
end

-- Parent frame of whole UI and table we're seated at.
-- Update the UI to show the current game configs.
-- May not need updating.
local updateGameOptions = function(parentOfRow: Frame, currentTableDescription: CommonTypes.TableDescription)
    assert(parentOfRow, "Should have a frame")
    assert(currentTableDescription, "Should have a currentTableDescription")

    local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
    if not gameDetails.gameOptions or #gameDetails.gameOptions == 0 then
        return
    end

    local configsRowContent = GuiUtils.getRowContent(parentOfRow, "Row_GameOptions")
    assert(configsRowContent, "Should have a configsRowContent")
    assert(gameOptionsWidgetContainerName, "Should have getOptionsLabelWidgetContainerName")

    local gameOptionsContainerWidget = configsRowContent:FindFirstChild(gameOptionsWidgetContainerName)
    assert(gameOptionsContainerWidget, "Should have gameConfigLabelWidgetContainerName")

    local selectedOptionsString = GuiUtils.getSelectedGameOptionsString(currentTableDescription)
    GuiUtils.updateTextLabelWidgetContainer(gameOptionsContainerWidget, selectedOptionsString)
end

-- Utility:
-- Our UI has a row of users under given frame.
-- We have a set of userIds describing the users we want in the row.
-- Compare the widgets in the row to widgets we want to have.
-- Tween in new widgets, tween out old widgets.
-- Futher complications: sometimes the widget is just a static widget, but sometimes it's a button.
-- If it's a button:
--   * Make the widget a button.
--   * Hit the callback when button is clicked
-- Return a list of any tweens generated.
local updateUserRow = function(parentOfRow: Frame, rowName: string, userIds: {CommonTypes.UserId}, isButton: (userId: CommonTypes.UserId) -> boolean,
        buttonCallback: (CommonTypes.UserId) -> nil)
    local rowContent = GuiUtils.getRowContent(parentOfRow, rowName)
    assert(rowContent, "Should have a rowContent")

    local makeUserWidgetContainer = function(frame: Frame, userId: CommonTypes.UserId): Frame
        local userWidgetContainer
        -- For host, if user is not himself, this widget is a button that lets you kick person out of table.
        if isButton() then
            userWidgetContainer = GuiUtils.addUserWidgetContainer(frame, userId, buttonCallback)
        else
            userWidgetContainer = GuiUtils.addUserWidgetContainer(frame, userId)
        end
        return userWidgetContainer
    end

    GuiUtils.updateWidgetContainerChildren(rowContent, userIds, makeUserWidgetContainer)
end

local updateGuests = function(parentOfRow: Frame, isHost: boolean, localUserId: CommonTypes.UserId, currentTableDescription: CommonTypes.TableDescription)
    assert(parentOfRow, "Should have a parentOfRow")
    assert(localUserId, "Should have a localUserId")
    assert(currentTableDescription, "Should have a currentTableDescription")

    -- Some functions used as args below.
    local function canRemoveGuest(userId: CommonTypes.UserId): boolean
        if isHost and userId ~= localUserId then
            return true
        else
            return false
        end
    end

    local function removeGuestCallback(userId: CommonTypes.UserId)
        DialogUtils.showConfirmationDialog("Remove Player?",
            "Please confirm you want to remove this player from the table.", function()
                ClientEventManagement.removeGuestFromTable(currentTableDescription.tableId, userId)
            end)
    end

    updateUserRow(parentOfRow, "Row_Members", Cryo.Dictionary.keys(currentTableDescription.memberUserIds), canRemoveGuest, removeGuestCallback)
end

local updateInvites = function(parentOfRow: Frame, isHost: boolean, currentTableDescription: CommonTypes.TableDescription)
    assert(parentOfRow, "Should have a mainFrame")
    assert(currentTableDescription, "Should have a currentTableDescription")

    -- Some functions used as args below.
    local function canRemoveInvite(userId: CommonTypes.UserId): boolean
        if isHost then
            return true
        else
            return false
        end
    end

    local function removeInviteCallback(userId: CommonTypes.UserId)
        DialogUtils.showConfirmationDialog("Remove Invitation?",
            "Please confirm you want to remove this player''s invitation to the table.", function()
                ClientEventManagement.removeInviteForTable(currentTableDescription.tableId, userId)
            end)
    end

    -- Update guests.
    updateUserRow(parentOfRow, "Row_Invites", Cryo.Dictionary.keys(currentTableDescription.memberUserIds), canRemoveInvite, removeInviteCallback)
end

local updateTableControls = function(parentOfRow: Frame, currentTableDescription: CommonTypes.TableDescription, isHost: boolean)
    assert(parentOfRow, "Should have a mainFrame")
    assert(currentTableDescription, "Should have a currentTableDescription")

    -- Non-host controls never change.
    if not isHost then
        return
    end

    -- The only control that changes is start game: we can't start if we don't have enough players.
    local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
    local numMembers = Utils.tableSize(currentTableDescription.memberUserIds)

    -- Sanity: we should never have too many.
    assert(gameDetails.minPlayers, "Should have minPlayers")
    assert(gameDetails.maxPlayers, "Should have maxPlayers")
    assert(gameDetails.maxPlayers >= numMembers, "Somehow we have too many members")

    local startEnabled = numMembers >= gameDetails.minPlayers

    assert(startButtonWidgetContainerName, "Should have startButtonWidgetContainerName")

    local controlsRowContent = GuiUtils.getRowContent(parentOfRow, "Row_Controls")

    local startButtonWidgetContainer = controlsRowContent:FindFirstChild(startButtonWidgetContainerName)
    assert(startButtonWidgetContainer, "Should have startButtonWidgetContainer")

    GuiUtils.updateTextButtonEnabledInWidgetContainer(startButtonWidgetContainer, startEnabled)

end

TableWaitingUI.update = function(currentTableDescription: CommonTypes.TableDescription)
    -- Make sure we have all the stuff we need.
    assert(currentTableDescription, "Should have a currentTableDescription")
    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "Should have a mainFrame")

    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")
    local isHost = localUserId == currentTableDescription.hostUserId

    -- Keep game options up to date.
    updateGameOptions(mainFrame, currentTableDescription)

    -- Keep guests up to date.
    updateGuests(mainFrame, isHost, localUserId, currentTableDescription)

    -- Keep invites up to date.
    updateInvites(mainFrame, isHost, currentTableDescription)

    -- Keep controls up to date.
    updateTableControls(mainFrame, currentTableDescription, isHost)
end

return TableWaitingUI
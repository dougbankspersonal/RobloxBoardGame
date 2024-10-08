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
local PlayerUtils = require(RobloxBoardGameShared.Modules.PlayerUtils)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)
local ClientTableDescriptions = require(RobloxBoardGameClient.Modules.ClientTableDescriptions)
local FriendSelectionDialog = require(RobloxBoardGameClient.Modules.FriendSelectionDialog)
local GameConfigSelectionUI = require(RobloxBoardGameClient.Modules.GameConfigSelectionUI)
local UserGuiUtils = require(RobloxBoardGameClient.Modules.UserGuiUtils)

local TableWaitingUI = {}

local startButtonWidgetContainerName: string
local gameOptionsTextLabel: string

local membersRowContent: Frame?
local invitesRowContent: Frame?
local controlsRowContent: Frame?

TableWaitingUI.justBuilt = false

local startButton

-- Called when first building the UI.
-- Game and host info don't change so we can fill that in.
-- Config options will change so that gets filled in in update, but we can create space for it now.
local addGameAndHostInfo = function(frame: Frame, gameDetails: CommonTypes.GameDetails, tableDescription: CommonTypes.TableDescription)
    -- Game info and host info will not change, might as well fill them in now.
    local rowContent = GuiUtils.addRowAndReturnRowContent(frame, "Row_Metadata1")

    local topTextLabel = GuiUtils.addTextLabel(rowContent, "", {
        RichText = true,
        TextSize = GuiConstants.largeTextLabelFontSize,
    })

    local gameNameString =  GuiUtils.bold(gameDetails.name)
    local gameHostString = GuiUtils.bold(PlayerUtils.getName(tableDescription.hostUserId))
    local metadataString1 = string.format("%s, hosted by %s", gameNameString, gameHostString)
    assert(topTextLabel, "Should have topTextLabel")
    topTextLabel.Text = metadataString1

    rowContent = GuiUtils.addRowAndReturnRowContent(frame, "Row_Metadata1")
    local tableSizeString = GuiUtils.getTableSizeString(gameDetails)
    local publicOrPrivateString = tableDescription.isPublic and "Public" or "Private"
    local formatString = GuiUtils.italicize("%s, %s")
    local metadataString2 = string.format(formatString, tableSizeString, publicOrPrivateString)
    GuiUtils.addTextLabel(rowContent, metadataString2, {
        RichText = true,
    })

    local rowOptions
    -- If there are gameOptions, add a widget to contain that info.
    -- It will be filled in later.
    if gameDetails.gameOptions and #gameDetails.gameOptions > 0 then
        rowOptions = {
            horizontalAlignment = Enum.HorizontalAlignment.Left,
            labelText = "Game Options:",
        }

        rowContent = GuiUtils.addRowAndReturnRowContent(frame, "Row_GameOptions", rowOptions)

        local selectedOptionsString = GuiUtils.getGameOptionsString(tableDescription.gameId, tableDescription.opt_nonDefaultGameOptions, "\n")
        assert(selectedOptionsString, "selectedOptionsString should exist")
        selectedOptionsString = GuiUtils.italicize(selectedOptionsString)

        gameOptionsTextLabel = GuiUtils.addTextLabel(rowContent, selectedOptionsString,
            {
                TextWrapped = true,
                RichText = true,
            })
        assert(gameOptionsTextLabel, "Should have gameOptionsTextLabel")
    end
end

local onManageInvitesClicked = function(tableId: CommonTypes.TableId)
    assert(tableId, "Should have a tableId")
    Utils.debugPrint("Friends", "tableId = ", tableId)

    local tableDescription = ClientTableDescriptions.getTableDescription(tableId)
    local inviteeIds = Cryo.Dictionary.keys(tableDescription.invitedUserIds)

    Utils.debugPrint("Friends", "inviteeIds = ", inviteeIds)

    local friendSelectionDialogConfig: FriendSelectionDialog.FriendSelectionDialogConfig = {
        title = "Select Friends",
        description = "Select friends to invite to the table.",
        isMultiSelect = true,
        preselectedUserIds = inviteeIds,
        callback = function(userIds: {CommonTypes.UserId})
            ClientEventManagement.setTableInvites(tableId, userIds)
        end
    }

    Utils.debugPrint("Friends", "friendSelectionDialogConfig = ", friendSelectionDialogConfig)

    FriendSelectionDialog.selectFriends(friendSelectionDialogConfig)
end

local onConfigureGameClicked = function(tableId: CommonTypes.TableId)
    assert(tableId, "Should have a tableId")

    local tableDescription = ClientTableDescriptions.getTableDescription(tableId)

    GameConfigSelectionUI.promptToSelectGameConfig(tableDescription, function(nonDefaultGameOptions: CommonTypes.NonDefaultGameOptions)
        ClientEventManagement.setTableGameOptions(tableId, nonDefaultGameOptions)
    end)
end

local addTableControls = function (frame: Frame, tableDescription: CommonTypes.TableDescription, isHost: boolean)
    -- Make a row for controls.
    local rowOptions : GuiUtils.RowOptions = {
        horizontalAlignment = Enum.HorizontalAlignment.Center,
        uiListLayoutPadding = UDim.new(0, GuiConstants.buttonsUIListLayoutPadding),
    }
    controlsRowContent = GuiUtils.addRowAndReturnRowContent(frame, "Row_TableWaitingControls",rowOptions)

    local tableId = tableDescription.tableId

    -- If we are the host, we can start the game.
    if isHost then
        -- Host can:
        -- * start game
        -- * destroy table
        -- * add invites (for non-public)
        -- * configure game (for game with gameOptions).
        --
        -- Keep track of the id for the start game button: we need to update it later.
        local _, _startButton = GuiUtils.addStandardTextButtonInContainer(controlsRowContent, "Start Game", function()
            ClientEventManagement.startGame(tableId)
        end)
        startButton = _startButton
        assert(startButton, "Should have startButton")
        startButtonWidgetContainerName = startButton.Name

        GuiUtils.addStandardTextButtonInContainer(controlsRowContent, "Destroy Table", function()
            DialogUtils.showConfirmationDialog("Destroy Table?", "Please confirm you want to destroy this table.", function()
                ClientEventManagement.destroyTable(tableId)
            end)
        end)

        if not tableDescription.isPublic then
            GuiUtils.addStandardTextButtonInContainer(controlsRowContent, "Manage Invites", function()
                Utils.debugPrint("Friends", "Manage Invites clicked")
                onManageInvitesClicked(tableId)
            end)
        end

        local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
        assert(gameDetails, "Should have gameDetails")
        if gameDetails.gameOptions and #gameDetails.gameOptions > 0 then
            GuiUtils.addStandardTextButtonInContainer(controlsRowContent, "Configure Game", function()
                onConfigureGameClicked(tableId)
            end)
        end
    else
        -- Guests can leave table.
        GuiUtils.addStandardTextButtonInContainer(controlsRowContent, "Leave Table", function()
            ClientEventManagement.leaveTable(tableId)
        end)
    end
end

-- Create barebones structure for this UI,
-- Do not bother filling in anything that might change over time: this comes with update.
TableWaitingUI.build = function(tableId: CommonTypes.TableId)
    -- Sanity check arguments, get all the other stuff we need.
    assert(tableId, "Should have a tableId")

    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local tableDescription = ClientTableDescriptions.getTableDescription(tableId)
    assert(tableDescription, "Should have a tableDescription")
    local isHost = localUserId == tableDescription.hostUserId

    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    assert(gameDetails, "Should have a gameDetails")

    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "MainFrame not found")

    mainFrame.BackgroundColor3 = GuiConstants.tableWaitingBackgroundColor
    GuiUtils.addUIGradient(mainFrame, GuiConstants.standardMainScreenColorSequence)

    GuiUtils.addStandardMainFramePadding(mainFrame)
    GuiUtils.addLayoutOrderGenerator(mainFrame)
    GuiUtils.addUIListLayout(mainFrame, {
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, GuiConstants.paddingBetweenRows),
    })

    addGameAndHostInfo(mainFrame, gameDetails, tableDescription)

    -- Make a row for members (players who have joined), invites (players invited who have not yet joined)
    -- but do not fill in as this info will change: we set this in update function.
    membersRowContent = GuiUtils.addRowOfUniformItemsAndReturnRowContent(mainFrame, "Row_Members", "Members: ", GuiConstants.userWidgetHeight)

    if not tableDescription.isPublic then
        invitesRowContent = GuiUtils.addRowOfUniformItemsAndReturnRowContent(mainFrame, "Row_Invites", "Invites: ", GuiConstants.userWidgetHeight)
    end

    addTableControls(mainFrame, tableDescription, isHost)
    TableWaitingUI.justBuilt = true
end

-- Parent frame of whole UI and table we're seated at.
-- Update the UI to show the current game configs.
-- May not need updating.
local updateGameOptions = function(parentOfRow: Frame, tableDescription: CommonTypes.TableDescription)
    assert(parentOfRow, "Should have a frame")
    assert(tableDescription, "Should have a tableDescription")

    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    if not gameDetails.gameOptions or #gameDetails.gameOptions == 0 then
        return
    end

    local configsRowContent = GuiUtils.getRowContent(parentOfRow, "Row_GameOptions")
    assert(configsRowContent, "Should have a configsRowContent")
    assert(gameOptionsTextLabel, "Should have gameOptionsTextLabel")

    assert(gameOptionsTextLabel, "Should have gameOptionsTextLabel")

    local selectedOptionsString = GuiUtils.getGameOptionsString(tableDescription.gameId, tableDescription.opt_nonDefaultGameOptions, "\n")
    assert(selectedOptionsString, "selectedOptionsString should exist")
    selectedOptionsString = GuiUtils.italicize(selectedOptionsString)
    GuiUtils.updateTextLabel(gameOptionsTextLabel, selectedOptionsString)
end

local addMemberUserNullStaticWidget = function(parent: Frame)
    print("addMemberUserNullStaticWidget GuiConstants.userWidgetSize = ", GuiConstants.userWidgetSize)
    return GuiUtils.addNullStaticWidget(parent, GuiUtils.italicize("No players have joined yet."), {
        Size = GuiConstants.userWidgetSize,
    })
end

local updateMembers = function(isHost: boolean, localUserId: CommonTypes.UserId, tableDescription: CommonTypes.TableDescription)
    assert(membersRowContent, "Should have a rowContent")
    assert(localUserId, "Should have a localUserId")
    assert(tableDescription, "Should have a tableDescription")

    local tableId = tableDescription.tableId

    -- Some functions used as args below.
    local function canRemoveGuest(userId: CommonTypes.UserId): boolean
        assert(userId, "Should have a userId")
        if isHost and userId ~= localUserId then
            return true
        else
            return false
        end
    end

    local function removeGuestCallback(userId: CommonTypes.UserId)
        assert(userId, "Should have a userId")
        local playerName = PlayerUtils.getName(userId)
        local title = string.format("Remove %s?", playerName)
        local desc = string.format("Please confirm you want to remove %s from the table.", playerName)
        DialogUtils.showConfirmationDialog(title, desc, function()
                ClientEventManagement.removeGuestFromTable(tableId, userId)
            end)
    end

    -- We don't want to display the host as a member, remove him.
    local memberUserIds = Cryo.Dictionary.keys(tableDescription.memberUserIds)
    -- Host should always be first.
    memberUserIds = Cryo.List.removeValue(memberUserIds, tableDescription.hostUserId)
    table.insert(memberUserIds, 1, tableDescription.hostUserId)

    UserGuiUtils.updateUserRowContent(membersRowContent, TableWaitingUI.justBuilt, memberUserIds, canRemoveGuest,
        removeGuestCallback, addMemberUserNullStaticWidget, GuiUtils.removeNullStaticWidget)
end

local function addInvitedUserNullStaticWidget (parent)
    return GuiUtils.addNullStaticWidget(parent, GuiUtils.italicize("No outstanding invitations."), {
        Size = GuiConstants.userWidgetSize,
    })
end

local updateInvites = function(isHost: boolean, tableDescription: CommonTypes.TableDescription)
    assert(invitesRowContent, "Should have a rowContent")
    assert(tableDescription, "Should have a tableDescription")

    local tableId = tableDescription.tableId

    Utils.debugPrint("Friends", "updateInvites tableDescription = ", tableDescription)

    -- Some functions used as args below.
    local function canRemoveInvite(_: CommonTypes.UserId): boolean
        if isHost then
            return true
        else
            return false
        end
    end

    local function removeInviteCallback(userId: CommonTypes.UserId)
        local playerName = PlayerUtils.getName(userId)
        local title = string.format("Disinvite %s?", playerName)
        local desc = string.format("Please confirm you want to remove %s's invitation to the table.", playerName)

        DialogUtils.showConfirmationDialog(title, desc, function()
                ClientEventManagement.removeInviteForTable(tableId, userId)
            end)
    end

    UserGuiUtils.updateUserRowContent(invitesRowContent, TableWaitingUI.justBuilt, Cryo.Dictionary.keys(tableDescription.invitedUserIds),
        canRemoveInvite, removeInviteCallback, addInvitedUserNullStaticWidget, GuiUtils.removeNullStaticWidget)
end

local updateTableControls = function(tableDescription: CommonTypes.TableDescription, isHost: boolean)
    assert(controlsRowContent, "Should have a controlsRowContent")
    assert(tableDescription, "Should have a tableDescription")

    -- Non-host controls never change.
    if not isHost then
        return
    end

    -- The only control that changes is start game: we can't start if we don't have enough players.
    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    local numMembers = Utils.tableSize(tableDescription.memberUserIds)

    -- Sanity: we should never have too many.
    assert(gameDetails.minPlayers, "Should have minPlayers")
    assert(gameDetails.maxPlayers, "Should have maxPlayers")
    assert(gameDetails.maxPlayers >= numMembers, "Somehow we have too many members")

    local startEnabled = numMembers >= gameDetails.minPlayers

    assert(startButtonWidgetContainerName, "Should have startButtonWidgetContainerName")

    assert(startButton, "Should have startButton")
    startButton.Active = startEnabled
end

TableWaitingUI.update = function()
    local tableDescription = ClientTableDescriptions.getTableWithUserId(game.Players.LocalPlayer.UserId)
    -- Make sure we have all the stuff we need.
    assert(tableDescription, "Should have a tableDescription")
    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "Should have a mainFrame")

    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")
    local isHost = localUserId == tableDescription.hostUserId

    -- Keep game options up to date.
    updateGameOptions(mainFrame, tableDescription)

    -- Keep members up to date.
    updateMembers(isHost, localUserId, tableDescription)

    -- Keep invites up to date.
    if not tableDescription.isPublic then
        updateInvites(isHost, tableDescription)
    end

    -- Keep controls up to date.
    updateTableControls(tableDescription, isHost)
    -- This is not longer "just built".
    TableWaitingUI.justBuilt = false
end

return TableWaitingUI
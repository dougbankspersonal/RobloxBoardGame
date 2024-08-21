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
local Players = game:GetService("Players")

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
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)
local TableDescriptions = require(RobloxBoardGameStarterGui.Modules.TableDescriptions)
local FriendSelectionDialog = require(RobloxBoardGameStarterGui.Modules.FriendSelectionDialog)
local UserGuiUtils = require(RobloxBoardGameStarterGui.Modules.UserGuiUtils)

local TableWaitingUI = {}

local startButtonWidgetContainerName: string
local gameOptionsWidgetContainerName: string

TableWaitingUI.justBuilt = false

-- Called when first building the UI.
-- Game and host info don't change so we can fill that in.
-- Config options will change so that gets filled in in update, but we can create space for it now.
local addGameAndHostInfo = function(frame: Frame, gameDetails: CommonTypes.GameDetails, currentTableDescription: CommonTypes.TableDescription)
    -- Game info and host info will not change, might as well fill them in now.
    local rowContent = GuiUtils.addRowAndReturnRowContent(frame, "Row_Metadata1")
    local gameNameString = gameDetails.name
    local gameHostString = Players:GetNameFromUserIdAsync(Utils.debugMapUserId(currentTableDescription.hostUserId))
    local metadataString1 = string.format("<b>%s</b>, hosted by <b>%s</b>", gameNameString, gameHostString)

    GuiUtils.addTextLabelWidgetContainer(rowContent, metadataString1, {
        RichText = true,
        TextSize = GuiConstants.largeTextLabelFontSize,
    })

    rowContent = GuiUtils.addRowAndReturnRowContent(frame, "Row_Metadata1")
    local tableSizeString = GuiUtils.getTableSizeString(gameDetails)
    local publicOrPrivateString = currentTableDescription.isPublic and "Public" or "Private"
    local metadataString2 = string.format("<i>%s, %s</i>", tableSizeString, publicOrPrivateString)
    GuiUtils.addTextLabelWidgetContainer(rowContent, metadataString2, {
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

        local selectedOptionsString = GuiUtils.getSelectedGameOptionsString(currentTableDescription)
        assert(selectedOptionsString, "selectedOptionsString should exist")
        selectedOptionsString = GuiUtils.italicize(selectedOptionsString)

        local gameOptionsLabelWidgetContainer = GuiUtils.addTextLabelWidgetContainer(rowContent, selectedOptionsString,
            {
                TextWrapped = true,
                RichText = true,
            })
        assert(gameOptionsLabelWidgetContainer, "Should have gameOptionsLabelWidgetContainer")
        gameOptionsWidgetContainerName = gameOptionsLabelWidgetContainer.Name
    end
end

local onAddInviteClicked = function(currentTableDescription: CommonTypes.TableDescription)
    assert(currentTableDescription, "Should have a currentTableDescription")
    local inviteeIds = Cryo.Dictionary.keys(currentTableDescription.invitedUserIds)
    local friendSelectionDialogConfig: FriendSelectionDialog.FriendSelectionDialogConfig = {
        title = "Select friends",
        description = "Select friends to invite to the table.",
        isMultiSelect = true,
        preselectedUserIds = inviteeIds,
        callback = function(userIds: {CommonTypes.UserId})
            ClientEventManagement.invitePlayersToTable(currentTableDescription.tableId, userIds)
        end
    }
    FriendSelectionDialog.selectFriends(friendSelectionDialogConfig)
end

local addTableControls = function (frame: Frame, currentTableDescription: CommonTypes.TableDescription, isHost: boolean)
    -- Make a row for controls.
    local rowContent = GuiUtils.addRowAndReturnRowContent(frame, "Row_Controls", {
        horizontalAlignment = Enum.HorizontalAlignment.Center,
    })

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
            DialogUtils.showConfirmationDialog("Destroy Table?", "Please confirm you want to destroy this table.", function()
                ClientEventManagement.destroyTable(currentTableDescription.tableId)
            end)
        end)

        if not currentTableDescription.isPublic then
            GuiUtils.addTextButtonWidgetContainer(rowContent, "Add Invites", function()
                onAddInviteClicked(currentTableDescription)
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

    GuiUtils.addUIGradient(mainFrame, GuiConstants.whiteToGrayColorSequence)
    GuiUtils.addStandardMainFramePadding(mainFrame)
    GuiUtils.addLayoutOrderGenerator(mainFrame)
    GuiUtils.addUIListLayout(mainFrame, {
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, GuiConstants.paddingBetweenRows),
    })

    addGameAndHostInfo(mainFrame, gameDetails, currentTableDescription)

    -- Make a row for members (players who have joined), invites (players invited who have not yet joined)
    -- but do not fill in as this info will change: we set this in update function.
    GuiUtils.addRowOfUniformItems(mainFrame, "Row_Members", "Members: ", GuiConstants.userWidgetY)

    if not currentTableDescription.isPublic then
        GuiUtils.addRowOfUniformItems(mainFrame, "Row_Invites", "Invites: ", GuiConstants.userWidgetY)
    end

    addTableControls(mainFrame, currentTableDescription, isHost)
    TableWaitingUI.justBuilt = true
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
    assert(selectedOptionsString, "selectedOptionsString should exist")
    selectedOptionsString = GuiUtils.italicize(selectedOptionsString)
    GuiUtils.updateTextLabelWidgetContainer(gameOptionsContainerWidget, selectedOptionsString)
end

local updateMembers = function(parentOfRow: Frame, isHost: boolean, localUserId: CommonTypes.UserId, currentTableDescription: CommonTypes.TableDescription)
    assert(parentOfRow, "Should have a parentOfRow")
    assert(localUserId, "Should have a localUserId")
    assert(currentTableDescription, "Should have a currentTableDescription")

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
        local mappedId = Utils.debugMapUserId(userId)
        local playerName = Players: GetNameFromUserIdAsync(mappedId)

        local title = string.format("Remove %s?", playerName)
        local desc = string.format("Please confirm you want to remove %s from the table.", playerName)
        DialogUtils.showConfirmationDialog(title, desc, function()
                ClientEventManagement.removeGuestFromTable(currentTableDescription.tableId, userId)
            end)
    end

    -- We don't want to display the host as a member, remove him.
    Utils.debugPrint("GameMetadata", "Doug: currentTableDescription.memberUserIds = ", currentTableDescription.memberUserIds)
    local memberUserIds = Cryo.Dictionary.keys(currentTableDescription.memberUserIds)
    Utils.debugPrint("GameMetadata", "Doug: pristine memberUserIds = ", memberUserIds)
    Utils.debugPrint("GameMetadata", "Doug: currentTableDescription.hostUserId = ", currentTableDescription.hostUserId)
    Utils.debugPrint("GameMetadata", "Doug: typeof(currentTableDescription.hostUserId) = ", typeof(currentTableDescription.hostUserId))
    Utils.debugPrint("GameMetadata", "Doug: typeof(memberUserIds[1]) = ", typeof(memberUserIds[1]))
    -- Host should always be first.
    memberUserIds = Cryo.List.removeValue(memberUserIds, currentTableDescription.hostUserId)
    Utils.debugPrint("GameMetadata", "Doug: removed host memberUserIds = ", memberUserIds)
    table.insert(memberUserIds, 1, currentTableDescription.hostUserId)
    Utils.debugPrint("GameMetadata", "Doug: restored host memberUserIds = ", memberUserIds)

    UserGuiUtils.updateUserRow(parentOfRow, "Row_Members", TableWaitingUI.justBuilt, memberUserIds, canRemoveGuest,
        removeGuestCallback, function(parent)
            GuiUtils.addNullWidget(parent, "<i>No players have joined yet.</i>", {
                Size = UDim2.fromOffset(GuiConstants.userWidgetX, GuiConstants.userWidgetY)
            })
        end, GuiUtils.removeNullWidget)
end

local updateInvites = function(parentOfRow: Frame, isHost: boolean, currentTableDescription: CommonTypes.TableDescription)
    assert(parentOfRow, "Should have a mainFrame")
    assert(currentTableDescription, "Should have a currentTableDescription")

    -- Some functions used as args below.
    local function canRemoveInvite(_: CommonTypes.UserId): boolean
        if isHost then
            return true
        else
            return false
        end
    end

    local function removeInviteCallback(userId: CommonTypes.UserId)
        Utils.debugPrint("RemoveInvite", "Doug: removeInviteCallback 001 userId = ", userId)
        DialogUtils.showConfirmationDialog("Remove Invitation?",
            "Please confirm you want to remove this player''s invitation to the table.", function()
                Utils.debugPrint("RemoveInvite", "Doug: removeInviteCallback 002 userId = ", userId)
                ClientEventManagement.removeInviteForTable(currentTableDescription.tableId, userId)
            end)
    end

    UserGuiUtils.updateUserRow(parentOfRow, "Row_Invites", TableWaitingUI.justBuilt, Cryo.Dictionary.keys(currentTableDescription.invitedUserIds),
        canRemoveInvite, removeInviteCallback, function(parent)
            GuiUtils.addNullWidget(parent, "<i>No outstanding invitations.</i>", {
                Size = UDim2.fromOffset(GuiConstants.userWidgetX, GuiConstants.userWidgetY)
            })
        end, GuiUtils.removeNullWidget)
end

local updateTableControls = function(parentOfRow: Frame, currentTableDescription: CommonTypes.TableDescription, isHost: boolean)
    assert(parentOfRow, "Should have a mainFrame")
    assert(currentTableDescription, "Should have a currentTableDescription")
    Utils.debugPrint("TableUpdated", "Doug: updateTableControls 001")

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
    Utils.debugPrint("TableUpdated", "Doug: updateTableControls startEnabled = ", startEnabled)

    assert(startButtonWidgetContainerName, "Should have startButtonWidgetContainerName")

    local controlsRowContent = GuiUtils.getRowContent(parentOfRow, "Row_Controls")

    local startButtonWidgetContainer = controlsRowContent:FindFirstChild(startButtonWidgetContainerName)
    assert(startButtonWidgetContainer, "Should have startButtonWidgetContainer")

    GuiUtils.updateTextButtonEnabledInWidgetContainer(startButtonWidgetContainer, startEnabled)

end

TableWaitingUI.update = function()
    local currentTableDescription = TableDescriptions.getTableWithUserId(game.Players.LocalPlayer.UserId)
    -- Make sure we have all the stuff we need.
    assert(currentTableDescription, "Should have a currentTableDescription")
    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "Should have a mainFrame")

    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")
    local isHost = localUserId == currentTableDescription.hostUserId

    -- Keep game options up to date.
    updateGameOptions(mainFrame, currentTableDescription)

    -- Keep members up to date.
    updateMembers(mainFrame, isHost, localUserId, currentTableDescription)

    -- Keep invites up to date.
    if not currentTableDescription.isPublic then
        updateInvites(mainFrame, isHost, currentTableDescription)
    end

    -- Keep controls up to date.
    updateTableControls(mainFrame, currentTableDescription, isHost)
    -- This is not longer "just built".
    TableWaitingUI.justBuilt = false
end

return TableWaitingUI
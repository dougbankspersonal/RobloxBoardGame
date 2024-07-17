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

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local TableDescriptions = require(RobloxBoardGameClient.Modules.TableDescriptions)

local TableWaitingUI = {}

local getOptionsLabelWidgetContainerName = nil

local tweensToKill = {} :: CommonTypes.TweensToKill

-- Called when first building the UI.
-- Game and host info don't change so we can fill that in.
-- Config options will change so that gets filled in in update, but we can create space for it now.
local addGameAndHostInfo = function(frame: Frame, gameDetails: CommonTypes.GameDetails, currentTableDescription: CommonTypes.TableDescription)
    -- Game info and host info will not change, might as well fill them in now.
    local rowContent = GuiUtils.addRowWithLabelAndReturnRowContent(frame, "Row_Game, Game")
    GuiUtils.addGameWidget(rowContent, currentTableDescription, true)
    -- If there are gameOptions, add a widget to contain that info.
    -- It will be filled in later.
    if gameDetails.configOptions and #gameDetails.configOptions > 0 then
        rowContent = GuiUtils.addRowWithLabelAndReturnRowContent(frame, "Row_GameOptions", "Game Options")
        local selectedOptionsString = GuiUtils.getSelectedOptionsString(currentTableDescription)
        assert(selectedOptionsString, "selectedOptionsString should exist")
        local gameOptionsLabelWidgetContainer = GuiUtils.makeTextLabelWidgetContainer(rowContent, selectedOptionsString)
        assert(gameOptionsLabelWidgetContainer, "Should have gameOptionsLabelWidgetContainer")
        getOptionsLabelWidgetContainerName = gameOptionsLabelWidgetContainer.Name
    end

    rowContent  = GuiUtils.addRowWithLabelAndReturnRowContent(frame, "Row_Host", "Host")
    GuiUtils.addPlayerWidget(rowContent, currentTableDescription.hostUserId)
end

local onAddInviteClicked = function(screenGui: ScreenGui, tableId: CommonTypes.TableId)
    assert(tableId, "Should have a tableId")
    GuiUtils.selectFriend(screenGui, function (userId: CommonTypes.UserId?)
        if userId then
            ClientEventManagement.invitePlayerToTable(tableId, userId)
        end
    end)
end

local addTableControls = function (screenGui: ScreenGui, frame: Frame, currentTableDescription: CommonTypes.TableDescription, isHost: boolean)
    -- If we are the host, we can start the game.
    if isHost then
        -- Host can start gamem destroy table, add invites (for non-public), configure game (for game with gameOptions).
        GuiUtils.addButton(frame, "Start Game", function()
            ClientEventManagement.startGame(currentTableDescription.tableId)
        end)
        GuiUtils.addButton(frame, "Destroy Table", function()
            ClientEventManagement.destroyTable(currentTableDescription.tableId)
        end)
        if not currentTableDescription.isPublic then
            GuiUtils.addButton(frame, "Add Invites", function()
                onAddInviteClicked(screenGui, currentTableDescription.tableId)
            end)
        end
        local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
        assert(gameDetails, "Should have gameDetails")
        if gameDetails.gameOptions and #gameDetails.gameOptions > 0 then
            GuiUtils.addButton(frame, "Configure Game", function()
                -- FIXME(dbanks)
                -- Put up a dialog to configure game.
            end)
        end
    else
        -- Guests can leave table.
        GuiUtils.addButton(frame, "Leave Table", function()
            ClientEventManagement.leaveTable(currentTableDescription.tableId)
        end)
    end
end

-- Create barebones structure for this UI,
-- Do not bother filling in anything that might change over time: this comes with update.
TableWaitingUI.build = function(screenGui: ScreenGui, currentTableDescription: CommonTypes.TableDescription)
    -- Sanity check arguments, get all the other stuff we need.
    assert(screenGui, "Should have a screenGui")
    assert(currentTableDescription, "Should have a currentTableDescription")

    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local isHost = localUserId == currentTableDescription.hostUserId

    local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
    assert(gameDetails, "Should have a gameDetails")

    local mainFrame = screenGui:WaitForChild("MainFrame")
    assert(mainFrame, "MainFrame not found")

    GuiUtils.addUiListLayout(mainFrame)

    addGameAndHostInfo(mainFrame, gameDetails, currentTableDescription)

    -- Make a row for members (players who have joined), invites (players invited who have not yet joined)
    -- but do not fill in as this info will change: we set this in update function.
    GuiUtils.addRowWithLabelAndReturnRowContent(mainFrame, "Row_Members", "Members")
    GuiUtils.addRowWithLabelAndReturnRowContent(mainFrame, "Row_Invites", "Invites")

    addTableControls(screenGui, mainFrame, currentTableDescription, isHost)
end

-- Parent frame of whole UI and table we're seated at.
-- Update the UI to show the current game configs.
-- May not need updating.
local updateGameOptions = function(frame: Frame, currentTableDescription: CommonTypes.TableDescription)
    assert(frame, "Should have a frame")
    assert(currentTableDescription, "Should have a currentTableDescription")

    local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
    if not gameDetails.gameOptions or #gameDetails.gameOptions == 0 then
        return
    end

    local configsRowContent = GuiUtils.getRowContent(frame, "Row_GameOptions")
    assert(configsRowContent, "Should have a configsRowContent")
    assert(getOptionsLabelWidgetContainerName, "Should have getOptionsLabelWidgetContainerName")

    local gameOptionsContainerWidget = configsRowContent:FindFirstChild(getOptionsLabelWidgetContainerName)
    assert(gameOptionsContainerWidget, "Should have gameConfigLabelWidgetContainerName")

    local selectedOptionsString = GuiUtils.getSelectedOptionsString(currentTableDescription)
    GuiUtils.updateTextLabelWidgetContainer(gameOptionsContainerWidget, selectedOptionsString)
end

TableWaitingUI.update = function(screenGui: ScreenGui, currentTableDescription: CommonTypes.TableDescription)
    -- Make sure we have all the stuff we need.
    assert(currentTableDescription, "Should have a currentTableDescription")
    assert(screenGui, "Should have a screenGui")
    local mainFrame = screenGui:WaitForChild("MainFrame")
    assert(mainFrame, "Should have a screenGui")

    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")
    local isHost = localUserId == currentTableDescription.hostUserId

    -- Keep game options up to date.
    updateGameOptions(mainFrame, currentTableDescription)

    -- Keep members up to date.
    local guestsRowContent = GuiUtils.getRowContent(mainFrame, "Row_Members")
    -- memberUserIds in currentTableDescription is s set mapping (id -> true: we need an array.
    local memberUserIdsAsArray = Utils.getKeys(currentTableDescription.memberUserIds)
    local newTweensToKill = GuiUtils.updateWidgetContainerChildren(guestsRowContent, memberUserIdsAsArray, function(frame: Frame, userId: CommonTypes.UserId): Frame
        local widgetContainer
        -- For host, if user is not himself, this widget is a button that lets you kick person out of table.
        if isHost and userId ~= localUserId then
            widgetContainer = GuiUtils.makeUserWidgetContainer(frame, userId, function()
                GuiUtils.showConfirmationDialog("Remove Player?", "Please confirm you want to remove this player from the table.", function()
                    ClientEventManagement.removePlayerFromTable(currentTableDescription.tableId, userId)
                end)
            end)
        else
            widgetContainer = GuiUtils.makeUserWidgetContainer(frame, userId)
        end
        return widgetContainer
    end)
    tweensToKill = Utils.mergeSecondMapIntoFirst(tweensToKill, newTweensToKill)

    -- Keep invitees up to date.
    local invitesRowContent = GuiUtils.getRowContent(mainFrame, "Row_Invites")
    -- invitedUserIds in currentTableDescription is s set mapping (id -> true: we need an array.
    local invitedUserIdsAsArray = Utils.getKeys(currentTableDescription.invitedUserIds)
    local newTweensToKill = GuiUtils.updateWidgetContainerChildren(invitesRowContent, invitedUserIdsAsArray, function(frame: Frame, userId: CommonTypes.UserId)
        local widgetContainer
        -- For host, this widget is a button that lets you disinvite someone.
        if isHost then
            widgetContainer = GuiUtils.makeUserWidgetContainer(frame, userId, function()
                GuiUtils.showConfirmationDialog("Remove Invitation?", "Please confirm you want to this player's invitation to join the table.", function()
                    ClientEventManagement.removePlayerFromTable(currentTableDescription.tableId, userId)
                end)
            end)
        else
            widgetContainer = GuiUtils.makeUserWidgetContainer(frame, userId)
        end
        return widgetContainer
    end)
    tweensToKill = Utils.mergeSecondMapIntoFirst(tweensToKill, newTweensToKill)


    -- Update controls.
end





    for memberPlayerId, _ in currentTableDescription.memberUserIds do
        GuiUtils.addPlayerWidget(row, memberPlayerId)
    end

    if localUserId == currentTableDescription.hostUserId then
        if not hasEnoughPlayers() then
            GuiUtils.addLabel(row, "Waiting for more minimum number of players to join.")
        elseif roomForMorePlayers() then
            GuiUtils.addLabel(row, "Press start when ready, or wait for more players to join.")
        else
            GuiUtils.addLabel(row, "Press start when ready.")
        end
    else
        GuiUtils.addLabel(row, "Waiting for game to start")
    end


end

return TableWaitingUI
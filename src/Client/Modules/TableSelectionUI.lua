--[[
UIMode is TableSelection.
Local player can create a new table or join an existing table.
UI Shows:
  * Control to make a new table.
  * Row of tables to which local user is invited.
  * Row of public tables.

  FIXME(dbanks)
  Perhaps add other chrome/crap like a title, welcome text, help buttons, etc.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local TableDescriptions = require(RobloxBoardGameClient.Modules.TableDescriptions)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local TableConfigDialog = require(RobloxBoardGameClient.Modules.TableConfigDialog)

local TableSelectionUI = {}

local function updateInvitedTables(mainFrame: GuiObject)
    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local invitedRowContent = GuiUtils.getRowContent(mainFrame, "Row_InvitedTables")
    assert(invitedRowContent, "Should have an invitedRowContent")
    local tableIdsForInvitedWaitingTables = TableDescriptions.getTableIdsForInvitedWaitingTables(localUserId)

    GuiUtils.updateWidgetContainerChildren(invitedRowContent, tableIdsForInvitedWaitingTables, function(parent: Frame, tableId: CommonTypes.TableId)
        GuiUtils.makeTableButtonWidgetContainer(parent, tableId, function()
            ClientEventManagement.joinTable(tableId)
        end)
    end)
end

local function updatePublicTables(mainFrame: GuiObject)
    local publicRowContent = GuiUtils.getRowContent(mainFrame, "Row_PublicTables")
    assert(publicRowContent, "Should have an publicRowContent")
    local tableIdsForPublicWaitingTables = TableDescriptions.getTableIdsForPublicWaitingTables()

    GuiUtils.updateWidgetContainerChildren(publicRowContent, tableIdsForPublicWaitingTables, function(parent: Frame, tableId: CommonTypes.TableId)
        GuiUtils.makeTableButtonWidgetContainer(parent, tableId, function()
            ClientEventManagement.joinTable(tableId)
        end)
    end)
end



--[[
    Build ui elements for the table creation/selection ui.
    Note this is just the framework for this UI: any specifics related
    to what the tables are, we deal with in updateTableSelectionUI.

    Returns a list of any special cleanup functions.
    "Special" because we have generic cleanup function that just kills
    everything under mainFrame.

    We do create some tweens in this UI: we use the special cleanup function
    to kill those tweens.
]]
TableSelectionUI.build = function(screenGui: ScreenGui)
    local mainFrame = screenGui:WaitForChild("MainFrame")
    assert(mainFrame, "MainFrame not found")

    GuiUtils.makeUiListLayout(mainFrame)

    -- Row to add a new table.
    local rowContent = GuiUtils.makeRowAndReturnRowContent(mainFrame, "Row_CreateTable")
    GuiUtils.makeTextButtonWidgetContainer(rowContent, "Host a new Table", function()
        -- user must select a game and whether it is public or invite-only.
        TableConfigDialog.show(screenGui, function(gameId, isPublic)
            -- Send all this along to the server.
            ClientEventManagement.createTable(gameId, isPublic)
        end)
    end)

    -- Row to show tables you are invited to.
    GuiUtils.makeRowWithLabelAndReturnRowContent(mainFrame, "Row_InvitedTables", "Your invitations")
    -- Row to show public tables.
    GuiUtils.makeRowWithLabelAndReturnRowContent(mainFrame, "Row_PublicTables", "Public Tables")
end

-- update ui elements for the table creation/selection ui.
TableSelectionUI.update = function(screenGui: ScreenGui)
    local mainFrame = screenGui:WaitForChild("MainFrame")
    assert(mainFrame, "MainFrame not found")

    updateInvitedTables(mainFrame)
    updatePublicTables(mainFrame)
end

return TableSelectionUI
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

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local TableDescriptions = require(RobloxBoardGameStarterGui.Modules.TableDescriptions)
local ClientEventManagement = require(RobloxBoardGameStarterGui.Modules.ClientEventManagement)
local TableConfigDialog = require(RobloxBoardGameStarterGui.Modules.TableConfigDialog)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)

local TableSelectionUI = {}

local makeWidgetContainerForTable = function(parent: Frame, tableId: CommonTypes.TableId): Frame
    return GuiUtils.addTableButtonWidgetContainer(parent, tableId, function()
        ClientEventManagement.joinTable(tableId)
    end)
end

local function updateInvitedTables(mainFrame: GuiObject)
    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local invitedRowContent = GuiUtils.getRowContent(mainFrame, "Row_InvitedTables")
    assert(invitedRowContent, "Should have an invitedRowContent")
    local tableIdsForInvitedWaitingTables = TableDescriptions.getTableIdsForInvitedWaitingTables(localUserId)

    GuiUtils.updateWidgetContainerChildren(invitedRowContent, tableIdsForInvitedWaitingTables, makeWidgetContainerForTable, function(parent)
        GuiUtils.addNullWidget(parent, "<i>Sorry, no table invites right now.</i>", {
            Size = UDim2.fromOffset(GuiConstants.tableWidgetX, GuiConstants.tableWidgetY)
        })
    end, GuiUtils.removeNullWidget)
end

local function updatePublicTables(mainFrame: GuiObject)
    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local publicRowContent = GuiUtils.getRowContent(mainFrame, "Row_PublicTables")
    assert(publicRowContent, "Should have an publicRowContent")
    local tableIdsForPublicWaitingTables = TableDescriptions.getTableIdsForPublicWaitingTables(localUserId)

    GuiUtils.updateWidgetContainerChildren(publicRowContent, tableIdsForPublicWaitingTables, makeWidgetContainerForTable, function(parent)
        GuiUtils.addNullWidget(parent, "<i>Sorry, no public tables to join right now.</i>", {
            Size = UDim2.fromOffset(GuiConstants.tableWidgetX, GuiConstants.tableWidgetY)
        })
    end, GuiUtils.removeNullWidget)
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
TableSelectionUI.build = function()
    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "MainFrame not found")

    GuiUtils.addUIGradient(mainFrame, GuiConstants.whiteToGrayColorSequence)
    GuiUtils.addStandardMainFramePadding(mainFrame)
    GuiUtils.addLayoutOrderGenerator(mainFrame)

    GuiUtils.addUIListLayout(mainFrame, {
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, GuiConstants.paddingBetweenRows),
    })

    -- Row to add a new table.
    local rowContent = GuiUtils.addRowAndReturnRowContent(mainFrame, "Row_CreateTable", {
        horizontalAlignment = Enum.HorizontalAlignment.Center,
    })
    GuiUtils.addTextButtonWidgetContainer(rowContent, "Host a new Table", function()
        -- user must select a game and whether it is public or invite-only.
        TableConfigDialog.makeGameSelectionDialog(function(gameId, isPublic)
            -- Send all this along to the server.
            ClientEventManagement.createTable(gameId, isPublic)
        end)
    end)

    GuiUtils.addRowOfUniformItems(mainFrame, "Row_InvitedTables", "Open Invitations:", GuiConstants.tableWidgetY)
    GuiUtils.addRowOfUniformItems(mainFrame, "Row_PublicTables", "Public Tables:", GuiConstants.tableWidgetY)
end

-- update ui elements for the table creation/selection ui.
TableSelectionUI.update = function()
    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "MainFrame not found")

    updateInvitedTables(mainFrame)
    updatePublicTables(mainFrame)
end

return TableSelectionUI
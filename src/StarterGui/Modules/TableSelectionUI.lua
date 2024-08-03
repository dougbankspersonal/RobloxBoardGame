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

local function updateInvitedTables(mainFrame: GuiObject)
    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local invitedRowContent = GuiUtils.getRowContent(mainFrame, "Row_InvitedTables")
    assert(invitedRowContent, "Should have an invitedRowContent")
    local tableIdsForInvitedWaitingTables = TableDescriptions.getTableIdsForInvitedWaitingTables(localUserId)

    GuiUtils.updateWidgetContainerChildren(invitedRowContent, tableIdsForInvitedWaitingTables, function(parent: Frame, tableId: CommonTypes.TableId)
        GuiUtils.addTableButtonWidgetContainer(parent, tableId, function()
            ClientEventManagement.joinTable(tableId)
        end)
    end, GuiUtils.italicize("No open invitations"))
end

local function updatePublicTables(mainFrame: GuiObject)
    local publicRowContent = GuiUtils.getRowContent(mainFrame, "Row_PublicTables")
    assert(publicRowContent, "Should have an publicRowContent")
    local tableIdsForPublicWaitingTables = TableDescriptions.getTableIdsForPublicWaitingTables()

    GuiUtils.updateWidgetContainerChildren(publicRowContent, tableIdsForPublicWaitingTables, function(parent: Frame, tableId: CommonTypes.TableId)
        GuiUtils.addTableButtonWidgetContainer(parent, tableId, function()
            ClientEventManagement.joinTable(tableId)
        end)
    end, GuiUtils.italicize("No public tables"))
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
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    })

    -- Row to add a new table.
    local rowContent = GuiUtils.addRowAndReturnRowContent(mainFrame, "Row_CreateTable", {
        horizontalAlignment = Enum.HorizontalAlignment.Center,
    })
    GuiUtils.addTextButtonWidgetContainer(rowContent, "Host a new Table", function()
        -- user must select a game and whether it is public or invite-only.
        TableConfigDialog.promptForTableConfig(function(gameId, isPublic)
            -- Send all this along to the server.
            ClientEventManagement.createTable(gameId, isPublic)
        end)
    end)

    -- Row to show tables you are invited to.
    GuiUtils.addRowAndReturnRowContent(mainFrame, "Row_InvitedTables", {
        isScrolling = true,
        useGridLayout = true,
        labelText = "Open Invitations:",
    })
    -- Row to show public tables.
    GuiUtils.addRowAndReturnRowContent(mainFrame, "Row_PublicTables", {
        isScrolling = true,
        useGridLayout = true,
        labelText = "Public Tables:",
    })
end

-- update ui elements for the table creation/selection ui.
TableSelectionUI.update = function()
    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "MainFrame not found")

    updateInvitedTables(mainFrame)
    updatePublicTables(mainFrame)
end

return TableSelectionUI
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

    local invitedTablesRow = mainFrame:FindFirstChild("InvitedTablesRow", true)
    assert(invitedTablesRow, "Should have an invitedTablesRow")
    local sortedInvitedWaitingTablesForUser = TableDescriptions.getSortedInvitedWaitingTablesForUser(localUserId)
    GuiUtils.updateRowOfWidgets(invitedTablesRow, sortedInvitedWaitingTablesForUser, GuiUtils.makeTableButtonContainer)
end

local function updatePublicTables(mainFrame: GuiObject)
    local publicTablesRow = mainFrame:FindFirstChild("PublicTablesRow", true)
    assert(publicTablesRow, "Should have an publicTablesRow")
    local sortedPublicWaitingTables = TableDescriptions.getSortedPublicWaitingTables()
    GuiUtils.updateRowOfWidgets(publicTablesRow, sortedPublicWaitingTables, GuiUtils.makeTableButtonContainer)
end

--[[
    Build ui elements for the table creation/selection ui.
    Note this is just the framework for this UI: any specifics related
    to what the tables are, we deal with in updateTableSelectionUI.
]]
TableSelectionUI.build = function(screenGui: ScreenGui)
    local mainFrame = screenGui:WaitForChild("MainFrame")
    assert(mainFrame, "MainFrame not found")

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = mainFrame

    -- Row to add a new table.
    local makeTableRow = GuiUtils.addRow(mainFrame)
    makeTableRow.Name = "MakeTablesRow"
    GuiUtils.addButton(makeTableRow, "Host a new Table", function()
        -- user must select a game and whether it is public or invite-only.
        TableConfigDialog.show(screenGui, function(gameId, isPublic)
            -- Send all this along to the server.
            ClientEventManagement.createTable(gameId, isPublic)
        end)
    end)

    -- Row to show tables you are invited to.
    local invitedTablesRow = GuiUtils.addRowWithLabel(mainFrame, "Your invitations")
    invitedTablesRow.Name = "InvitedTablesRow"

    -- Row to show public tables.
    local publicTablesRow = GuiUtils.addRowWithLabel(mainFrame, "Public Tables")
    publicTablesRow.Name = "PublicTablesRow"
end

-- update ui elements for the table creation/selection ui.
TableSelectionUI.update = function(screenGui: ScreenGui)
    local mainFrame = screenGui:WaitForChild("MainFrame")
    assert(mainFrame, "MainFrame not found")

    updateInvitedTables(mainFrame)
    updatePublicTables(mainFrame)
end

return TableSelectionUI
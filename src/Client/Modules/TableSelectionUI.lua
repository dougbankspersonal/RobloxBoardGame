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

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local ClientTableDescriptions = require(RobloxBoardGameClient.Modules.ClientTableDescriptions)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)
local TableGuiUtils= require(RobloxBoardGameClient.Modules.TableGuiUtils)
local GameSelectionUI = require(RobloxBoardGameClient.Modules.GameSelectionUI)
local PrivacySelectionUI = require(RobloxBoardGameClient.Modules.PrivacySelectionUI)

local TableSelectionUI = {}

local makeWidgetContainerForTable = function(parent: Frame, tableId: CommonTypes.TableId): Frame
    return TableGuiUtils.addTableButtonWidgetContainer(parent, tableId, function()
        ClientEventManagement.joinTable(tableId)
    end)
end

local function addInviteTableNullStaticWidget(parent: Frame)
    return GuiUtils.addNullStaticWidget(parent, GuiUtils.italicize("No table invites"), {
        Size = GuiConstants.tableWidgetSize,
    })
end

local function addPublicTableNullStaticWidget(parent: Frame)
    return GuiUtils.addNullStaticWidget(parent, GuiUtils.italicize("No public tables"), {
        Size = GuiConstants.tableWidgetSize,
    })
end

local function updateInvitedTables(mainFrame: GuiObject)
    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local invitedRowContent = GuiUtils.getRowContent(mainFrame, "Row_InvitedTables")
    assert(invitedRowContent, "Should have an invitedRowContent")
    local tableIdsForInvitedWaitingTables = ClientTableDescriptions.getTableIdsForInvitedWaitingTables(localUserId)

    GuiUtils.updateWidgetContainerChildren(invitedRowContent, tableIdsForInvitedWaitingTables, makeWidgetContainerForTable, addInviteTableNullStaticWidget, GuiUtils.removeNullStaticWidget)
end

local function updatePublicTables(mainFrame: GuiObject)
    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local publicRowContent = GuiUtils.getRowContent(mainFrame, "Row_PublicTables")
    assert(publicRowContent, "Should have an publicRowContent")
    local tableIdsForPublicWaitingTables = ClientTableDescriptions.getTableIdsForPublicWaitingTables(localUserId)

    GuiUtils.updateWidgetContainerChildren(publicRowContent, tableIdsForPublicWaitingTables, makeWidgetContainerForTable, addPublicTableNullStaticWidget, GuiUtils.removeNullStaticWidget)
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
function TableSelectionUI.build()
    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "MainFrame not found")

    mainFrame.BackgroundColor3 = GuiConstants.tableSelectionBackgroundColor
    GuiUtils.addUIGradient(mainFrame, GuiConstants.standardMainScreenColorSequence)

    GuiUtils.addStandardMainFramePadding(mainFrame)
    GuiUtils.addLayoutOrderGenerator(mainFrame)

    GuiUtils.addUIListLayout(mainFrame, {
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, GuiConstants.paddingBetweenRows),
    })

    -- Row to add a new table.
    local rowOptions : GuiUtils.RowOptions = {
        horizontalAlignment = Enum.HorizontalAlignment.Center,
        uiListLayoutPadding = UDim.new(0, GuiConstants.buttonsUIListLayoutPadding),
    }
    local rowContent = GuiUtils.addRowAndReturnRowContent(mainFrame, "Row_TableSelectionControls", rowOptions)
    GuiUtils.addStandardTextButtonInContainer(rowContent, "Host a new Table", function()
        -- Prompt to select a game.
        GameSelectionUI.promptToSelectGameID("Select a game", "Click on the game you want to play.", function(gameId: CommonTypes.GameId)
            -- Prompt to select public or private.
            PrivacySelectionUI.promptToSelectPrivacy("Public or Private?",
                "Anyone in the experience can join a Public game.  Only invited players can join a Private game.",
                function(isPublic: boolean)
                    -- Send all this along to the server.
                    ClientEventManagement.createTable(gameId, isPublic)
                end)
        end)
    end)

    GuiUtils.addRowOfUniformItemsAndReturnRowContent(mainFrame, "Row_InvitedTables", "Private Tables:", GuiConstants.tableWidgetHeight)
    GuiUtils.addRowOfUniformItemsAndReturnRowContent(mainFrame, "Row_PublicTables", "Public Tables:", GuiConstants.tableWidgetHeight)
end

-- update ui elements for the table creation/selection ui.
function TableSelectionUI.update()
    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "MainFrame not found")

    updateInvitedTables(mainFrame)
    updatePublicTables(mainFrame)
end

return TableSelectionUI
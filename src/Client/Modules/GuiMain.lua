--[[
    GuiMain.lua
    The top level functions for building user interface.
]]

local GuiMain = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local UIModes = require(RobloxBoardGameShared.Globals.UIModes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local GameUIs = require(RobloxBoardGameClient.Globals.GameUIs)
local LoadingUI = require(RobloxBoardGameClient.Modules.LoadingUI)
local TableSelectionUI = require(RobloxBoardGameClient.Modules.TableSelectionUI)
local TableWaitingUI = require(RobloxBoardGameClient.Modules.TableWaitingUI)
local TableDescriptions = require(RobloxBoardGameClient.Modules.TableDescriptions)

-- Globals
local localUserId = Players.LocalPlayer.UserId
assert(localUserId, "Should have a localUserId")

local mainFrame: Frame?
local screenGui: ScreenGui?

local currentUIMode: CommonTypes.UIMode = UIModes.None
local cleanupFunctionsForCurrentUIMode = {}:: {() -> nil}

-- Based on the local player id and the latest set of table descriptions from the
-- servre we can determine the overall UI mode.
local uiModeBasedOnTableDescriptions: CommonTypes.UIMode = UIModes.Loading
-- Iff local user is at a table (either waiting, playing, or finished), this describes that table.
local currentTableDescription: CommonTypes.TableDescription? = nil

--[[
    makeMainFrame
    Creates the main frame for the user interface.
    @param _screenGui: ScreenGui
    @returns: nil
]]
GuiMain.makeMainFrame = function(_screenGui: ScreenGui)
    screenGui = _screenGui
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.458823, 0.509803, 0.733333)
    mainFrame.Parent = screenGui
    mainFrame.ZIndex = 1
    mainFrame.Name = "main"
    mainFrame.BorderSizePixel= 0

    GuiUtils.addLayoutOrderTracking(mainFrame)
end

local function hasEnoughPlayers() : boolean
    assert(currentTableDescription, "Should have a currentTableDescription")
    local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
    return #currentTableDescription.memberUserIds >= gameDetails.minPlayers
end

local function roomForMorePlayers() : boolean
    assert(currentTableDescription, "Should have a currentTableDescription")
    local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
    assert(gameDetails.maxPlayers, "GameDetails should have a maxPlayers")
    assert(gameDetails.maxPlayers > 0, "GameDetails should have non-zero maxPlayers")
    assert(gameDetails.maxPlayers >= #currentTableDescription.memberUserIds, "GameDetails.maxPlayers should be >= #currentTableDescription.memberUserIds")
    return #currentTableDescription.memberUserIds < gameDetails.maxPlayers
end

local function buildTablePlayingUI(): nil
    assert(currentTableDescription, "Should have a currentTableDescription")
    assert(currentTableDescription.gameId, "Should have a currentTableDescription.gameId")

    local gameUI = GameUIs.getGameUI(currentTableDescription.gameId)
    assert(gameUI, "Should have a gameUI")
    gameUI.buildUI(mainFrame, currentTableDescription)
end

-- update ui elements for the "in a table and waiting for game to start"
-- UI.
local updateTableWaitingUI = function()
    assert(currentTableDescription, "Should have a currentTableDescription")
    local row

    local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
    -- If there are game options, add details about that to the UI.
    if gameDetails.configOptions then
        row = mainFrame:FindFirstChild("Game")
        assert(row, "Should have a row for game details")
        local gameUI = GameUIs.getGameUI(currentTableDescription.gameId)
        gameUI.addSummaryOfGameOptions(row, currentTableDescription)
    end

    -- Update the guests and invites.
    local invitedTablesRow = mainFrame:FindFirstChild("InvitedTablesRow", true)
    assert(invitedTablesRow, "Should have an invitedTablesRow")
    local sortedInvitedWaitingTablesForUser = TableDescriptions.getSortedInvitedWaitingTablesForUser(localUserId)
    updateRowOfWidgets(invitedTablesRow, sortedInvitedWaitingTablesForUser, makeTableButtonContainer)


    -- Add controls.
    row = GuiUtils.addRowWithLabel(mainFrame, "Controls")
    if localUserId == currentTableDescription.hostUserId then
        GuiUtils.addButton(row, "Start Game", function()
            print("FIXME: start game")
        end)
        GuiUtils.addButton(row, "Destroy Table", function()
            print("FIXME: destroy game")
        end)
        if currentTableDescription.isPublic then
            GuiUtils.addButton(row, "Add Invites", function()
                print("FIXME: add invites")
            end)
        end
        local gameDetails = GameDetails.getGameDetails(currentTableDescription.gameId)
        if gameDetails.configOptions then
            GuiUtils.addButton(row, "Configure Game", function()
                print("FIXME: configure game")
            end)
        end
    else
        GuiUtils.addButton(row, "Leave Table", function()
            print("FIXME: leave table")
        end)
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

-- update ui elements for the "in a table and game is playing" UI.
local updateTablePlayingUI = function()
    assert(false, "FIXME(dbanks) updateTablePlayingUI")
end


local function setCurrentTableAndUIMode()
    currentTableDescription = TableDescriptions.getTableWithUserId(localUserId)

    -- The local player is not part of any table: we show them the "select/create table" UI.
    if not currentTableDescription then
        uiModeBasedOnTableDescriptions = UIModes.TableSelection
    elseif currentTableDescription.gameTableState == GameTableStates.WaitingForPlayers then
        uiModeBasedOnTableDescriptions = UIModes.TableWaitingForPlayers
    elseif currentTableDescription.gameTableState == GameTableStates.Playing then
        uiModeBasedOnTableDescriptions = UIModes.TablePlaying
    elseif currentTableDescription.gameTableState == GameTableStates.Finished then
        uiModeBasedOnTableDescriptions = UIModes.TableFinished
    else
        assert(false, "we have a table description in an unknown state")
    end
end

--[[
    Remove all ui elements from mainFrame.
]]
local cleanupCurrentUI = function()
    -- Cancel anything that needs cancelling.
    for _, cleanupFunction in cleanupFunctionsForCurrentUIMode do
        cleanupFunction()
    end
    cleanupFunctionsForCurrentUIMode = {}

    -- Remove all the ui elements.
    local children = mainFrame:GetChildren()
    for _, child in children do
        child:Destroy()
    end
end

--[[
    When we receieve updates from the server, this function is called.
    Updates UI to reflect current state.
]]
GuiMain.updateUI = function()
    -- Figure out which, if any, table we're at, and from that we know what ui mode we are in.
    setCurrentTableAndUIMode()

    -- If this causes a change in UIMode, destroy the old UI and build a new one.
    if currentUIMode ~= uiModeBasedOnTableDescriptions then
        cleanupCurrentUI()
        currentUIMode = uiModeBasedOnTableDescriptions
        local additionalCleanupFunctions = {}
        if currentUIMode == UIModes.Loading then
            additionalCleanupFunctions = LoadingUI.build(screenGui)
        elseif currentUIMode == UIModes.TableSelection then
            additionalCleanupFunctions = TableSelectionUI.build(screenGui)
        elseif currentUIMode == UIModes.TableWaitingForPlayers then
            additionalCleanupFunctions = TableWaitingUI.build(screenGui, currentTableDescription)
        elseif currentUIMode == UIModes.TablePlaying then
            additionalCleanupFunctions = buildTablePlayingUI(screenGui)
        end

        for _, cleanupFunction in additionalCleanupFunctions do
            table.insert(cleanupFunctionsForCurrentUIMode, cleanupFunction)
        end
    end

    -- Update the existing UI based on what we know about tables.
    if currentUIMode == UIModes.TableSelection then
        TableSelectionUI.update(screenGui)
    elseif currentUIMode == UIModes.TableWaitingForPlayers then
        TableWaitingUI.update(screenGui)
    elseif currentUIMode == UIModes.TablePlaying then
        updateTablePlayingUI(screenGui)
    end
end

GuiMain.onTableCreated = function(tableDescription: CommonTypes.TableDescription)
    TableDescriptions.addTableDescription(tableDescription)
    GuiMain.updateUI()
end

GuiMain.onTableDestroyed = function(tableId: CommonTypes.TableId)
    TableDescriptions.removeTableDescription(tableId)
    GuiMain.updateUI()
end

GuiMain.onTableUpdated = function(tableDescription: CommonTypes.TableDescription)
    TableDescriptions.updateTableDescription(tableDescription)
    GuiMain.updateUI()
end

return GuiMain
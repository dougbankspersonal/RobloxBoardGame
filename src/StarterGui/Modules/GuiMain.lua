--[[
    GuiMain.lua
    The top level functions for building user interface.
]]

local GuiMain = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local UIModes = require(RobloxBoardGameShared.Globals.UIModes)
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local LoadingUI = require(RobloxBoardGameStarterGui.Modules.LoadingUI)
local TableSelectionUI = require(RobloxBoardGameStarterGui.Modules.TableSelectionUI)
local TableWaitingUI = require(RobloxBoardGameStarterGui.Modules.TableWaitingUI)
local TablePlayingUI = require(RobloxBoardGameStarterGui.Modules.TablePlayingUI)
local TableDescriptions = require(RobloxBoardGameStarterGui.Modules.TableDescriptions)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)
local DialogUtils = require(RobloxBoardGameStarterGui.Modules.DialogUtils)
local ClientEventManagement= require(RobloxBoardGameStarterGui.Modules.ClientEventManagement)
local GameUIs = require(RobloxBoardGameStarterGui.Globals.GameUIs)

-- Globals
local localUserId = Players.LocalPlayer.UserId
assert(localUserId, "Should have a localUserId")

local currentUIMode: CommonTypes.UIMode = UIModes.None
local cleanupFunctionsForCurrentUIMode = {}:: {() -> nil}

-- Based on the local player id and the latest set of table descriptions from the
-- servre we can determine the overall UI mode.
local uiModeBasedOnTableDescriptions: CommonTypes.UIMode = UIModes.Loading
-- Iff local user is at a table (either waiting, playing, or finished), this describes that table.
local currentTableDescription: CommonTypes.TableDescription? = nil

local summonMocksDialog = function(): Frame?
    local dialogButtonConfigs = {
        {
            text = "Mock Public Table (not joined)",
            callback = function()
                ClientEventManagement.mockTable(true, false)
            end,
        } :: DialogUtils.DialogButtonConfig,
        {
            text = "Mock Private Table (not joined)",
            callback = function()
                ClientEventManagement.mockTable(false, false)
            end,
        } :: DialogUtils.DialogButtonConfig,
        {
            text = "Mock Public Table (joined)",
            callback = function()
                ClientEventManagement.mockTable(true, true)
            end,
        } :: DialogUtils.DialogButtonConfig,
        {
            text = "Mock Private Table (joined)",
            callback = function()
                ClientEventManagement.mockTable(false, true)
            end,
        } :: DialogUtils.DialogButtonConfig,
        {
            text = "Destroy Mock Tables",
            callback = function()
                ClientEventManagement.destroyAllMockTables(false)
            end,
        } :: DialogUtils.DialogButtonConfig,
    } :: {DialogUtils.DialogButtonConfig}

    -- Mocks for waiting at a table.
    if currentTableDescription and currentUIMode == UIModes.TableWaitingForPlayers then
        local tableId = currentTableDescription.tableId
        assert(tableId, "Should have a tableId")

        if currentTableDescription.isPublic then
            table.insert(dialogButtonConfigs, {
                text = "Add Mock Member",
                callback = function()
                    ClientEventManagement.addMockMember(tableId)
                end,
            } :: DialogUtils.DialogButtonConfig)
        else
            table.insert(dialogButtonConfigs, {
                text = "Add Mock Invite",
                callback = function()
                    ClientEventManagement.addMockInvite(tableId)
                end,
            } :: DialogUtils.DialogButtonConfig)
            table.insert(dialogButtonConfigs, {
                text = "Mock Invite Acceptance",
                callback = function()
                    ClientEventManagement.mockInviteAcceptance(tableId)
                end,
            } :: DialogUtils.DialogButtonConfig)
        end

        if currentTableDescription.hostUserId ~= localUserId then
            table.insert(dialogButtonConfigs, {
                text = "Start Mock Game",
                callback = function()
                    ClientEventManagement.mockStartGame(tableId)
                end,
            } :: DialogUtils.DialogButtonConfig)
        end
    end

    local dialogConfig: DialogUtils.DialogConfig = {
        title = "Mocks",
        description = "Various debug options.",
        dialogButtonConfigs = dialogButtonConfigs,
    }
    return DialogUtils.makeDialog(dialogConfig)
end

GuiMain.makeContaintingScrollingFrame = function()
    local mainScreenGui = GuiUtils.getMainScreenGui()
    assert(mainScreenGui, "Should have a mainScreenGui")

    local containingScrollingFrame = Instance.new("ScrollingFrame")
    containingScrollingFrame.Size = UDim2.fromScale(1, 1)
    containingScrollingFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    containingScrollingFrame.Parent = mainScreenGui
    containingScrollingFrame.Name = GuiConstants.containingScrollingFrameName
    containingScrollingFrame.BorderSizePixel= 0
    containingScrollingFrame.CanvasSize = UDim2.fromScale(1, 0)
    containingScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    containingScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    containingScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0.5, 0.5, 0.5)

    return containingScrollingFrame
end

--[[
    makeMainFrame
    Creates the main frame for the user interface.
    @param _screenGui: ScreenGui
    @returns: nil
]]
GuiMain.makeMainFrame = function(): Frame
    local containingScrollingFrame = GuiUtils.getContainingScrollingFrame()
    assert(containingScrollingFrame, "Should have a containingScrollingFrame")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.fromScale(1, 1)
    mainFrame.BackgroundTransparency = 0
    mainFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    mainFrame.Parent = containingScrollingFrame
    mainFrame.Name = GuiConstants.mainFrameName
    mainFrame.BorderSizePixel= 0
    mainFrame.AutomaticSize = Enum.AutomaticSize.Y

    return mainFrame
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
    local mainFrame = GuiUtils.getMainFrame()
    local children = mainFrame:GetChildren()
    for _, child in children do
        -- Skip persistent children.
        if Utils.stringStartsWith(child.Name, GuiConstants.persistentNameStart) then
            continue
        end
        child:Destroy()
    end
end

GuiMain.showLoadingUI = function()
    LoadingUI.build()
end

--[[
    When we receieve updates from the server, this function is called.
    Updates UI to reflect current state.
]]
GuiMain.updateUI = function()
    Utils.debugPrint("TablePlaying", "Doug: updateUI 001")
    -- Figure out which, if any, table we're at, and from that we know what ui mode we are in.
    setCurrentTableAndUIMode()

    -- Should never call this if we are still loading.
    assert(uiModeBasedOnTableDescriptions ~= UIModes.Loading, "Should not call updateUI while loading")

    Utils.debugPrint("TablePlaying", "Doug: updateUI 002 uiModeBasedOnTableDescriptions = " .. tostring(uiModeBasedOnTableDescriptions))
    Utils.debugPrint("TablePlaying", "Doug: updateUI 002 currentUIMode = " .. tostring(currentUIMode))

    -- If this causes a change in UIMode, destroy the old UI and build a new one.
    if currentUIMode ~= uiModeBasedOnTableDescriptions then
        Utils.debugPrint("TablePlaying", "Doug: updateUI 003")
        cleanupCurrentUI()
        currentUIMode = uiModeBasedOnTableDescriptions
        if currentUIMode == UIModes.TableSelection then
            Utils.debugPrint("TablePlaying", "Doug: updateUI 004")
            TableSelectionUI.build()
        elseif currentUIMode == UIModes.TableWaitingForPlayers then
            Utils.debugPrint("TablePlaying", "Doug: updateUI 005")
            assert(currentTableDescription, "Should have a currentTableDescription")
            TableWaitingUI.build(currentTableDescription.tableId)
        elseif currentUIMode == UIModes.TablePlaying then
            Utils.debugPrint("TablePlaying", "Doug: updateUI 006")
            assert(currentTableDescription, "Should have a currentTableDescription")
            TablePlayingUI.build(currentTableDescription.tableId)
        else
            -- ???
            assert(false, "Unknown UI Mode")
        end
    end

    -- Update the existing UI based on what we know about tables.
    if currentUIMode == UIModes.TableSelection then
        Utils.debugPrint("TablePlaying", "Doug: updateUI 007")
        TableSelectionUI.update()
    elseif currentUIMode == UIModes.TableWaitingForPlayers then
        Utils.debugPrint("TablePlaying", "Doug: updateUI 008")
        TableWaitingUI.update()
    elseif currentUIMode == UIModes.TablePlaying then
        Utils.debugPrint("TablePlaying", "Doug: updateUI 009")
        TablePlayingUI.update()
    else
        -- ???
        assert(false, "Unknown UI Mode")
    end
end

GuiMain.onTableCreated = function(tableDescription: CommonTypes.TableDescription)
    assert(tableDescription, "tableDescription must be provided")
    assert(typeof(tableDescription) == "table", "tableDescription must be a table")

    -- Sending table description from server to client messes with some types. Fix it.
    tableDescription = TableDescriptions.cleanUpTypes(tableDescription)
    TableDescriptions.addTableDescription(tableDescription)
    GuiMain.updateUI()
end

GuiMain.onTableDestroyed = function(tableId: CommonTypes.TableId)
    if TableDescriptions.localPlayerIsAtTable(tableId) then
        -- If this was your table, throw up a dialog.
        -- Not if you are the host (if you're the host you did this yourself, already know).
        local tableDescription = TableDescriptions.getTableDescription(tableId)
        assert(tableDescription, "Should have a tableDescription")
        if tableDescription.hostUserId ~= localUserId then
            DialogUtils.showAckDialog("Table Destroyed", "The table you were at has been destroyed.")
        end
    end
    TableDescriptions.removeTableDescription(tableId)
    GuiMain.updateUI()
end

-- Doesn't change state: just an opportunity for to update users on what happened.
-- Host may be prompted to do something about it.
GuiMain.onPlayerLeftTable = function(tableId: CommonTypes.TableId, userId: CommonTypes.UserId)
    -- Non-table members don't care.
    if not TableDescriptions.localPlayerIsAtTable(tableId) then
        return
    end

    -- We only really care if the game is playing.
    local tableDescription = TableDescriptions.getTableDescription(tableId)
    if tableDescription.gameTableState ~= GameTableStates.Playing then
        return
    end

    if tableDescription.hostUserId == localUserId then
        -- Host is given an opportunity to do something about it in game-logic land.
        local gameUIs = GameUIs.getGameUIs(tableDescription.gameId)
        assert(gameUIs, "Should have gameUIs")
        gameUIs.onPlayerLeftTable(userId)
    else
        if localUserId ~= userId then
            -- Non-host, non-leavers just get a notification.
            local playerName = Players:GetNameFromUserIdAsync(userId)
            local title = "Player \"" .. playerName .. "\" Left"
            local description = "Player \"" .. playerName .. "\" has left the table.  The host may need a moment to decide how to handle this: please be patient."
            DialogUtils.showAckDialog(title, description)
        end
    end
end

-- Doesn't change state: just an opportunity for to update users on what happened.
GuiMain.onHostAbortedGame = function(tableId: CommonTypes.TableId)
    -- Non-table members don't care.
    if not TableDescriptions.localPlayerIsAtTable(tableId) then
        return
    end
    -- If this was your table, throw up a dialog.
    -- Not if you are the host (if you're the host you did this yourself, already know).
    local tableDescription = TableDescriptions.getTableDescription(tableId)
    assert(tableDescription, "Should have a tableDescription")
    if tableDescription.hostUserId ~= localUserId then
        -- If you were at the table, throw up a dialog.
        DialogUtils.showAckDialog("Game Ended Early", "The game was ended early by the host.")
    end
end

GuiMain.onTableUpdated = function(tableDescription: CommonTypes.TableDescription)
    -- Sending table description from server to client messes with some types. Fix it.
    tableDescription = TableDescriptions.cleanUpTypes(tableDescription)

    TableDescriptions.updateTableDescription(tableDescription)
    GuiMain.updateUI()
end

GuiMain.addMocksButton = function(screenGui: ScreenGui)
    -- Throw on a button with a very high z index to summon mocks.
    if RunService:IsStudio() then
        GuiUtils.addTextButtonInContainer(screenGui, "Mocks", summonMocksDialog, {
            Name = "MocksButton",
        }, {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -10, 1, -10),
            ZIndex = 1000,
        })
    end
end

return GuiMain
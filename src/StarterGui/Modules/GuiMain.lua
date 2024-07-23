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
local GameTableStates = require(RobloxBoardGameShared.Globals.GameTableStates)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local GameUIs = require(RobloxBoardGameStarterGui.Globals.GameUIs)
local LoadingUI = require(RobloxBoardGameStarterGui.Modules.LoadingUI)
local TableSelectionUI = require(RobloxBoardGameStarterGui.Modules.TableSelectionUI)
local TableWaitingUI = require(RobloxBoardGameStarterGui.Modules.TableWaitingUI)
local TableDescriptions = require(RobloxBoardGameStarterGui.Modules.TableDescriptions)

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
GuiMain.makeMainFrame = function(_screenGui: ScreenGui): Frame
    screenGui = _screenGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    mainFrame.Parent = screenGui
    mainFrame.ZIndex = GuiUtils.mainFrameZIndex
    mainFrame.Name = GuiUtils.mainFrameName
    mainFrame.BorderSizePixel= 0

    GuiUtils.addUIGradient(mainFrame, GuiUtils.whiteToGrayColorSequence)

    GuiUtils.makeLayoutOrderGenerator(mainFrame)
    return mainFrame
end

local function buildTablePlayingUI(): nil
    assert(currentTableDescription, "Should have a currentTableDescription")
    assert(currentTableDescription.gameId, "Should have a currentTableDescription.gameId")

    local gameUI = GameUIs.getGameUI(currentTableDescription.gameId)
    assert(gameUI, "Should have a gameUI")
    gameUI.buildUI(mainFrame, currentTableDescription)
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

GuiMain.showLoadingUI = function()
    LoadingUI.build(screenGui)
end

--[[
    When we receieve updates from the server, this function is called.
    Updates UI to reflect current state.
]]
GuiMain.updateUI = function()
    -- Figure out which, if any, table we're at, and from that we know what ui mode we are in.
    setCurrentTableAndUIMode()

    -- Should never call this if we are still loading.
    assert(uiModeBasedOnTableDescriptions ~= UIModes.Loading, "Should not call updateUI while loading")

    -- If this causes a change in UIMode, destroy the old UI and build a new one.
    if currentUIMode ~= uiModeBasedOnTableDescriptions then
        cleanupCurrentUI()
        currentUIMode = uiModeBasedOnTableDescriptions
        if currentUIMode == UIModes.TableSelection then
            TableSelectionUI.build(screenGui)
        elseif currentUIMode == UIModes.TableWaitingForPlayers then
            assert(currentTableDescription, "Should have a currentTableDescription")
            TableWaitingUI.build(screenGui, currentTableDescription)
        elseif currentUIMode == UIModes.TablePlaying then
            assert(currentTableDescription, "Should have a currentTableDescription")
            buildTablePlayingUI(screenGui)
        else
            -- ???
            assert(false, "Unknown UI Mode")
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
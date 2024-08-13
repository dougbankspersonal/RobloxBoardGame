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
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local GameUIs = require(RobloxBoardGameStarterGui.Globals.GameUIs)
local LoadingUI = require(RobloxBoardGameStarterGui.Modules.LoadingUI)
local TableSelectionUI = require(RobloxBoardGameStarterGui.Modules.TableSelectionUI)
local TableWaitingUI = require(RobloxBoardGameStarterGui.Modules.TableWaitingUI)
local TableDescriptions = require(RobloxBoardGameStarterGui.Modules.TableDescriptions)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)
local DialogUtils = require(RobloxBoardGameStarterGui.Modules.DialogUtils)
local ClientEventManagement= require(RobloxBoardGameStarterGui.Modules.ClientEventManagement)

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

local summonMocksDialog = function()
    local dialogButtonConfigs = {
        {
            text = "Create Mock Public Table",
            callback = function()
                ClientEventManagement.mockTable(true)
            end
        } :: CommonTypes.DialogButtonConfig,
        {
            text = "Create Mock Private Table",
            callback = function()
                ClientEventManagement.mockTable(false)
            end
        } :: CommonTypes.DialogButtonConfig,
        {
            text = "Destroy Mock Tables",
            callback = function()
                ClientEventManagement.destroyAllMockTables(false)
            end
        } :: CommonTypes.DialogButtonConfig,
    } :: {CommonTypes.DialogConfig}

    -- Mocks to add/remove invites and members while waiting.
    if currentTableDescription and currentUIMode == UIModes.TableWaitingForPlayers then
        local tableId = currentTableDescription.tableId
        assert(tableId, "Should have a tableId")

        if currentTableDescription.isPublic then
            table.insert(dialogButtonConfigs, {
                text = "Add Mock Member",
                callback = function()
                    ClientEventManagement.addMockMember(tableId)
                end
            } :: CommonTypes.DialogButtonConfig)
        else
            table.insert(dialogButtonConfigs, {
                text = "Add Mock Invite",
                callback = function()
                    ClientEventManagement.addMockInvite(tableId)
                end
            } :: CommonTypes.DialogButtonConfig)
            table.insert(dialogButtonConfigs, {
                text = "Mock Invite Acceptance",
                callback = function()
                    ClientEventManagement.mockInviteAcceptance(tableId)
                end
            } :: CommonTypes.DialogButtonConfig)
        end
    end

    local dialogConfig: CommonTypes.DialogConfig = {
        title = "Mocks",
        description = "Various debug options.",
        dialogButtonConfigs = dialogButtonConfigs,
    }
    DialogUtils.makeDialog(dialogConfig)
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
    containingScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    containingScrollingFrame.CanvasSize = UDim2.fromScale(1, 0)
    containingScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
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
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = containingScrollingFrame
    mainFrame.Name = GuiConstants.mainFrameName
    mainFrame.BorderSizePixel= 0
    mainFrame.AutomaticSize = Enum.AutomaticSize.Y

    return mainFrame
end

local function buildTablePlayingUI(): nil
    assert(currentTableDescription, "Should have a currentTableDescription")
    assert(currentTableDescription.gameId, "Should have a currentTableDescription.gameId")

    local gameUI = GameUIs.getGameUI(currentTableDescription.gameId)
    assert(gameUI, "Should have a gameUI")
    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "Should have a mainFrame")

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
    -- Figure out which, if any, table we're at, and from that we know what ui mode we are in.
    setCurrentTableAndUIMode()

    -- Should never call this if we are still loading.
    assert(uiModeBasedOnTableDescriptions ~= UIModes.Loading, "Should not call updateUI while loading")

    -- If this causes a change in UIMode, destroy the old UI and build a new one.
    if currentUIMode ~= uiModeBasedOnTableDescriptions then
        cleanupCurrentUI()
        currentUIMode = uiModeBasedOnTableDescriptions
        if currentUIMode == UIModes.TableSelection then
            TableSelectionUI.build()
        elseif currentUIMode == UIModes.TableWaitingForPlayers then
            assert(currentTableDescription, "Should have a currentTableDescription")
            TableWaitingUI.build(currentTableDescription)
        elseif currentUIMode == UIModes.TablePlaying then
            assert(currentTableDescription, "Should have a currentTableDescription")
            buildTablePlayingUI()
        else
            -- ???
            assert(false, "Unknown UI Mode")
        end
    end

    -- Update the existing UI based on what we know about tables.
    if currentUIMode == UIModes.TableSelection then
        TableSelectionUI.update()
    elseif currentUIMode == UIModes.TableWaitingForPlayers then
        TableWaitingUI.update()
    elseif currentUIMode == UIModes.TablePlaying then
        updateTablePlayingUI()
    end
end

GuiMain.onTableCreated = function(tableDescription: CommonTypes.TableDescription)
    print("Doug: broadcasting new table: client")
    assert(tableDescription, "tableDescription must be provided")
    assert(typeof(tableDescription) == "table", "tableDescription must be a table")

    -- Sending table description from server to client messes with some types. Fix it.
    tableDescription = TableDescriptions.cleanUpTypes(tableDescription)
    TableDescriptions.addTableDescription(tableDescription)
    GuiMain.updateUI()
end

GuiMain.onTableDestroyed = function(tableId: CommonTypes.TableId)
    -- If this was your table, throw up a dialog.
    if TableDescriptions.localPlayerIsAtTable(tableId) then
        local dialogConfig: CommonTypes.DialogConfig = {
            title = "Table Destroyed",
            description = "The table at which you were seated has been destroyed.",
            dialogButtonConfigs = {
                {
                    text = "OK",
                    callback = function()
                    end
                } :: CommonTypes.DialogButtonConfig,
            } :: {CommonTypes.DialogConfig},
        }
        DialogUtils.makeDialog(dialogConfig)
    end
    TableDescriptions.removeTableDescription(tableId)
    GuiMain.updateUI()
end

GuiMain.onTableUpdated = function(tableDescription: CommonTypes.TableDescription)
    -- Sending table description from server to client messes with some types. Fix it.
    tableDescription = TableDescriptions.cleanUpTypes(tableDescription)

    TableDescriptions.updateTableDescription(tableDescription)
    GuiMain.updateUI()
end

GuiMain.addMocksButton = function(screenGui: ScreenGui)
    -- Throw on a button with a very high z index to summon mocks.
    if game:GetService("RunService"):IsStudio() then
        local textButton = GuiUtils.addTextButton(screenGui, "Mocks", summonMocksDialog)
        textButton.Name = GuiConstants.persistentNameStart .. "MocksButton"
        textButton.AnchorPoint = Vector2.new(1, 1)
        textButton.Position = UDim2.new(1, -10, 1, -10)
        textButton.ZIndex = 1000
        textButton.BackgroundColor3 = Color3.new(0.5, 0.9, 0.5)
    end
end

return GuiMain
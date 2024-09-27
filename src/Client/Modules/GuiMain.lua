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

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local LoadingUI = require(RobloxBoardGameClient.Modules.LoadingUI)
local TableSelectionUI = require(RobloxBoardGameClient.Modules.TableSelectionUI)
local TableWaitingUI = require(RobloxBoardGameClient.Modules.TableWaitingUI)
local TablePlayingUI = require(RobloxBoardGameClient.Modules.TablePlayingUI)
local ClientTableDescriptions = require(RobloxBoardGameClient.Modules.ClientTableDescriptions)
local GuiConstants = require(RobloxBoardGameClient.Modules.GuiConstants)
local DialogUtils = require(RobloxBoardGameClient.Modules.DialogUtils)
local ClientEventManagement= require(RobloxBoardGameClient.Modules.ClientEventManagement)
local ClientGameInstanceFunctions = require(RobloxBoardGameClient.Globals.ClientGameInstanceFunctions)
local StateDigest = require(RobloxBoardGameClient.Modules.StateDigest)

-- Globals
local localUserId = Players.LocalPlayer.UserId
assert(localUserId, "Should have a localUserId")

local cleanupFunctionsForCurrentUIMode = {}:: {() -> nil}

GuiMain.makeUberBackground = function(parent: Instance)
    local backgroundScreenGui = Instance.new("ScreenGui")
    backgroundScreenGui.Name = "BackgroundScreenGui"
    backgroundScreenGui.Parent = parent
    backgroundScreenGui.DisplayOrder = 0
    backgroundScreenGui.IgnoreGuiInset = true

    local uberBackground = Instance.new("Frame")
    uberBackground.Name = "UberBackground"
    uberBackground.Parent = backgroundScreenGui
    uberBackground.Size = UDim2.new(1, 0, 1, 0)
    uberBackground.BackgroundColor3 = GuiConstants.uberBackgroundColor
end

GuiMain.makeContainingScrollingFrame = function()
    local mainScreenGui = GuiUtils.getMainScreenGui()
    assert(mainScreenGui, "Should have a mainScreenGui")

    local containingScrollingFrame = Instance.new("ScrollingFrame")
    containingScrollingFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    containingScrollingFrame.Parent = mainScreenGui
    containingScrollingFrame.Name = GuiConstants.containingScrollingFrameName
    containingScrollingFrame.BorderSizePixel= 0
    containingScrollingFrame.CanvasSize = UDim2.fromScale(1, 0)
    containingScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    containingScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    containingScrollingFrame.Position = UDim2.fromOffset(0, GuiConstants.robloxTopBarBottomPadding)
    containingScrollingFrame.Size = UDim2.new(1, 0, 1, -GuiConstants.robloxTopBarBottomPadding)
    GuiUtils.setScrollingFrameColors(containingScrollingFrame)

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

--[[
    Remove all ui elements from mainFrame.
]]
local cleanupCurrentUI = function()
    local currentUIMode = StateDigest.getCurrentUIMode()

    -- If we are in a game and leaving it, stop listening for game-centric events.
    if currentUIMode == UIModes.TablePlaying then
        local currentTableDescription = StateDigest.getCurrentTableDescription()
        assert(currentTableDescription, "Should have a currentTableDescription")
        assert(currentTableDescription.gameInstanceGUID, "Should have a gameInstanceGUID")
        ClientEventManagement.cancelServerEventsForActiveGame(currentTableDescription.gameInstanceGUID)
    end

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

local onPlayerLeftTable = function(userId: CommonTypes.UserId)
    local currentTableDescription = StateDigest.getCurrentTableDescription()

    -- If the custom game instance wants to consume this fine, otherwise put up a generic "player left" dialog.
    assert(currentTableDescription, "Should have a currentTableDescription")
    assert(currentTableDescription.gameId, "Should have a gameId")
    assert(currentTableDescription.gameInstanceGUID, "Should have a gameInstanceGUID")
    local clientGameInstanceFunctions = ClientGameInstanceFunctions.getClientGameInstanceFunctions(currentTableDescription.gameId)
    assert(clientGameInstanceFunctions, "Should have clientGameInstanceFunctions")
    assert(clientGameInstanceFunctions.getClientGameInstance, "Should have clientGameInstanceFunctions.new")

    local clientGameInstance = clientGameInstanceFunctions.getClientGameInstance()
    assert(clientGameInstance, "Should have clientGameInstance")
    assert(clientGameInstance.tableDescription.gameInstanceGUID == currentTableDescription.gameInstanceGUID, "Should have the right gameInstanceGUID")

    if clientGameInstance.onPlayerLeftTable(userId) then
        return
    else
        assert(ClientTableDescriptions.localPlayerIsAtTable(currentTableDescription.tableId), "Should be a table member")
        assert(currentTableDescription.gameTableState == GameTableStates.Playing, "Should be playing")

        -- Don't notify the guy who left, he already knows.
        if localUserId ~= userId then
            task.spawn(function()
                -- Non-host, non-leavers just get a notification.
                local playerName = Players:GetNameFromUserIdAsync(userId)
                local title = "Player \"" .. playerName .. "\" Left"
                local description = "Player \"" .. playerName .. "\" has left the table.  The host may need a moment to decide how to handle this: please be patient."
                DialogUtils.showAckDialog(title, description)
            end)
        end
    end
end

--[[
    When we receieve updates from the server, this function is called.
    Updates UI to reflect current state.
]]
local previousUIMode = UIModes.None
GuiMain.updateUI = function()
    Utils.debugPrint("TablePlaying", "Doug: updateUI 001")

    local currentUIMode = StateDigest.getCurrentUIMode()

    Utils.debugPrint("TablePlaying", "Doug: updateUI 002 previousUIMode = " .. tostring(previousUIMode))
    Utils.debugPrint("TablePlaying", "Doug: updateUI 002 currentUIMode = " .. tostring(currentUIMode))

    local currentTableDescription = StateDigest.getCurrentTableDescription()

    -- If this causes a change in UIMode, destroy the old UI and build a new one.
    if currentUIMode ~= previousUIMode then
        Utils.debugPrint("TablePlaying", "Doug: updateUI 003")
        cleanupCurrentUI()
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
            -- Start listening for game-centric events.
            ClientEventManagement.listenToServerEventsForActiveGame(currentTableDescription.gameInstanceGUID, onPlayerLeftTable)
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

    previousUIMode = currentUIMode
end

GuiMain.onTableCreated = function(tableDescription: CommonTypes.TableDescription)
    assert(tableDescription, "tableDescription must be provided")
    assert(typeof(tableDescription) == "table", "tableDescription must be a table")
    task.spawn(function()
        ClientTableDescriptions.addTableDescriptionAsync(tableDescription)
        GuiMain.updateUI()
    end)
end

GuiMain.onTableDestroyed = function(tableId: CommonTypes.TableId)
    if ClientTableDescriptions.localPlayerIsAtTable(tableId) then
        -- If this was your table, throw up a dialog.
        -- Not if you are the host (if you're the host you did this yourself, already know).
        local tableDescription = ClientTableDescriptions.getTableDescription(tableId)
        assert(tableDescription, "Should have a tableDescription")
        if tableDescription.hostUserId ~= localUserId then
            DialogUtils.showAckDialog("Table Destroyed", "The table you were at has been destroyed.")
        end
    end
    ClientTableDescriptions.removeTableDescription(tableId)
    GuiMain.updateUI()
end

-- Doesn't change state: just an opportunity for to update users on what happened.
GuiMain.onHostAbortedGame = function(tableId: CommonTypes.TableId)
    -- Non-table members don't care.
    if not ClientTableDescriptions.localPlayerIsAtTable(tableId) then
        return
    end
    -- If this was your table, throw up a dialog.
    -- Not if you are the host (if you're the host you did this yourself, already know).
    local tableDescription = ClientTableDescriptions.getTableDescription(tableId)
    assert(tableDescription, "Should have a tableDescription")
    if tableDescription.hostUserId ~= localUserId then
        -- If you were at the table, throw up a dialog.
        DialogUtils.showAckDialog("Game Ended Early", "The game was ended early by the host.")
    end
end

GuiMain.onTableUpdated = function(tableDescription: CommonTypes.TableDescription)
    ClientTableDescriptions.updateTableDescriptionAsync(tableDescription)
    GuiMain.updateUI()
end

return GuiMain
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
local SanityChecks = require(RobloxBoardGameShared.Modules.SanityChecks)

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
local ClientEventUtils = require(RobloxBoardGameClient.Modules.ClientEventUtils)

-- Globals
local localUserId = Players.LocalPlayer.UserId
assert(localUserId, "Should have a localUserId")

local cleanupFunctionsForCurrentUIMode = {}:: {() -> nil}

function GuiMain.makeUberBackground(parent: Instance)
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

function GuiMain.makeContainingScrollingFrame()
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
function GuiMain.makeMainFrame(): Frame
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
local function cleanupCurrentUI()
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

function GuiMain.showLoadingUI()
    LoadingUI.build()
end

-- Called when we receive a notification that a game has ended.
-- (Game can only end because of some action from the host).
-- Handling this message is purely about communication with the user explaining what's happening:
-- all cleanup of state, ui elements, etc happens when the updated not-playing-anymore table
-- state is broadcast.
local function notifyThatHostEndedGame(gameInstanceGUID: CommonTypes.GameInstanceGUID, gameEndDetails: CommonTypes.GameEndDetails)
    local currentTableDescription = StateDigest.getCurrentTableDescription()

    -- If the custom game instance wants to consume this fine, otherwise put up a generic "game ended" dialog.
    assert(currentTableDescription, "Should have a currentTableDescription")
    assert(currentTableDescription.gameId, "Should have a gameId")
    assert(currentTableDescription.gameInstanceGUID, "Should have a gameInstanceGUID")
    assert(currentTableDescription.gameInstanceGUID == gameInstanceGUID, "Should have the right gameInstanceGUID")
    local clientGameInstanceFunctions = ClientGameInstanceFunctions.getClientGameInstanceFunctions(currentTableDescription.gameId)
    assert(clientGameInstanceFunctions, "Should have clientGameInstanceFunctions")
    assert(clientGameInstanceFunctions.getClientGameInstance, "Should have clientGameInstanceFunctions.new")

    local clientGameInstance = clientGameInstanceFunctions.getClientGameInstance()
    assert(clientGameInstance, "Should have clientGameInstance")
    assert(clientGameInstance.tableDescription.gameInstanceGUID == currentTableDescription.gameInstanceGUID, "Should have the right gameInstanceGUID")

    -- We want to message the users about this.
    -- Prefer more specific messages to less.
    -- First give the game instance a chance to say anything it wants.
    -- If it handles the messaging for this scenario, then we're done.
    local success = clientGameInstance:notifyThatHostEndedGame(gameEndDetails)
    -- Should still be sane.
    SanityChecks.sanityCheckClientGameInstance(clientGameInstance)

    if success then
        return
    end

    -- Game-specific instance had nothing specific to say about this.
    -- So we fall back to system-level messaging.
    if gameEndDetails.tableDestroyed then
        task.spawn(function()
            DialogUtils.showAckDialog("Game Ended", "The host has taken down the game table, so the game is over.")
        end)
        return
    end

    if gameEndDetails.hostEndedGame then
        task.spawn(function()
            DialogUtils.showAckDialog("Game Ended", "The host has ended the game.")
        end)
        return
    end

    -- How did we get here?
    assert(false, "Unexpected game end details.")
end

local function onPlayerLeftTable(gameInstanceGUID: CommonTypes.GameInstanceGUID, userId: CommonTypes.UserId)
    local currentTableDescription = StateDigest.getCurrentTableDescription()

    -- We should only be getting this if we are sitting at the table with the game in question.
    assert(currentTableDescription, "Should have a currentTableDescription")
    assert(currentTableDescription.gameId, "Should have a gameId")
    assert(currentTableDescription.gameInstanceGUID, "Should have a gameInstanceGUID")
    assert(currentTableDescription.gameInstanceGUID == gameInstanceGUID, "Should have the right gameInstanceGUID")
    assert(currentTableDescription.gameTableState == GameTableStates.Playing, "Should be playing")
    assert(ClientTableDescriptions.localPlayerIsAtTable(currentTableDescription.tableId), "Should be a table member")

    local clientGameInstanceFunctions = ClientGameInstanceFunctions.getClientGameInstanceFunctions(currentTableDescription.gameId)

    assert(clientGameInstanceFunctions, "Should have clientGameInstanceFunctions")
    assert(clientGameInstanceFunctions.getClientGameInstance, "Should have clientGameInstanceFunctions.new")

    local clientGameInstance = clientGameInstanceFunctions.getClientGameInstance()
    assert(clientGameInstance, "Should have clientGameInstance")
    assert(clientGameInstance.tableDescription.gameInstanceGUID == currentTableDescription.gameInstanceGUID, "Should have the right gameInstanceGUID")

    local customUIHandling = clientGameInstance:onPlayerLeftTable(userId)
    -- Things should still be sane.
    SanityChecks.sanityCheckClientGameInstance(clientGameInstance)

    if not customUIHandling then
        -- Don't notify the guy who left, he already knows.
        if localUserId ~= userId then
            task.spawn(function()
                --Non-leavers just get a notification.
                local playerName = Players:GetNameFromUserIdAsync(userId)
                local title = "Player \"" .. playerName .. "\" Left"
                local description = "Player \"" .. playerName .. "\" has left the game."
                DialogUtils.showAckDialog(title, description)
            end)
        end
    end
end

local function cleanupTablePlayingUI()
    -- When we're done playing, we can ditch events listening for server details about the game, and we can
    -- ditch the client game instance.
    local currentUIMode = StateDigest.getCurrentUIMode()
    assert(currentUIMode == UIModes.TablePlaying, "Should be in TablePlaying mode")
    local currentTableDescription = StateDigest.getCurrentTableDescription()
    assert(currentTableDescription, "Should have a currentTableDescription")
    assert(currentTableDescription.gameInstanceGUID, "Should have a gameInstanceGUID")
    ClientEventUtils.removeGameEventConnections(currentTableDescription.gameInstanceGUID)
    local clientGameInstanceFunctions = ClientGameInstanceFunctions.getClientGameInstanceFunctions(currentTableDescription.gameId)
    assert(clientGameInstanceFunctions, "Should have clientGameInstanceFunctions")
    local clientGameInstance = clientGameInstanceFunctions.getClientGameInstance()
    assert(clientGameInstance,    "Should have gameInstance")
    clientGameInstance:destroy()
end

--[[
    When we receieve updates from the server, this function is called.
    Updates UI to reflect current state.
]]
local previousUIMode = UIModes.None
function GuiMain.updateUI()
    Utils.debugPrint("TablePlaying", "Doug: updateUI 001")

    local currentUIMode = StateDigest.getCurrentUIMode()

    Utils.debugPrint("TablePlaying", "Doug: updateUI 002 previousUIMode = " .. tostring(previousUIMode))
    Utils.debugPrint("TablePlaying", "Doug: updateUI 002 currentUIMode = " .. tostring(currentUIMode))

    local currentTableDescription = StateDigest.getCurrentTableDescription()

    -- If this causes a change in UIMode, destroy the old UI and build a new one.
    if currentUIMode ~= previousUIMode then
        Utils.debugPrint("TablePlaying", "Doug: updateUI 003")
        cleanupCurrentUI()
        cleanupFunctionsForCurrentUIMode = {}
        if currentUIMode == UIModes.TableSelection then
            Utils.debugPrint("TablePlaying", "Doug: updateUI 004")
            TableSelectionUI.build()
        elseif currentUIMode == UIModes.TableWaitingForPlayers then
            Utils.debugPrint("TablePlaying", "Doug: updateUI 005")
            assert(currentTableDescription, "Should have a currentTableDescription")
            TableWaitingUI.build(currentTableDescription.tableId)
        elseif currentUIMode == UIModes.TablePlaying then
            cleanupFunctionsForCurrentUIMode = {
                cleanupTablePlayingUI,
            }
            Utils.debugPrint("TablePlaying", "Doug: updateUI 006")
            assert(currentTableDescription, "Should have a currentTableDescription")
            -- Start listening for game-centric events.
            ClientEventManagement.listenToServerEventsForActiveGame(currentTableDescription.gameInstanceGUID,
                onPlayerLeftTable,
                notifyThatHostEndedGame)
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

function GuiMain.onTableCreated(tableDescription: CommonTypes.TableDescription)
    assert(tableDescription, "tableDescription must be provided")
    assert(typeof(tableDescription) == "table", "tableDescription must be a table")
    task.spawn(function()
        ClientTableDescriptions.addTableDescriptionAsync(tableDescription)
        GuiMain.updateUI()
    end)
end

function GuiMain.onTableDestroyed(tableId: CommonTypes.TableId)
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

function GuiMain.onTableUpdated(tableDescription: CommonTypes.TableDescription)
    ClientTableDescriptions.updateTableDescriptionAsync(tableDescription)
    GuiMain.updateUI()
end

return GuiMain
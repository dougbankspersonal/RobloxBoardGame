--[[
    GuiMain.lua
    The top level functions for building user interface.
]]

local GuiMain = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Cryo = require(ReplicatedStorage.Cryo)

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
    We have transitioned to a new ui mode.
    Clean up whatever belongs to old mode:
      * UI elements.
      * allocated instances
      * connections
]]
local function cleanupPreviousUI(previousUIMode: CommonTypes.UIMode, opt_previousTableDescription: CommonTypes.TableDescription?)
    if previousUIMode == UIModes.TablePlaying then
        -- There must have been  a prior table description.
        assert(opt_previousTableDescription, "Should have a previous table description")
        local previousTableDescription = opt_previousTableDescription
        -- Should have been playing.
        local gameInstanceGUID = previousTableDescription.gameInstanceGUID
        assert(previousTableDescription.gameTableState == GameTableStates.Playing, "Should have been playing")
        assert(gameInstanceGUID, "Should have a gameInstanceGUID")
        -- No longer listening for game-centric events.
        ClientEventUtils.removeGameEventConnections(gameInstanceGUID)
        -- Clean up the game instance itself.
        local clientGameInstanceFunctions = ClientGameInstanceFunctions.getClientGameInstanceFunctions(previousTableDescription.gameId)
        local clientGameInstance = clientGameInstanceFunctions.getClientGameInstance()
        clientGameInstance:destroy()
    end

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

    Utils.debugPrint("GamePlay", "GuiMain notifyThatHostEndedGame: gameEndDetails = ", gameEndDetails)

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
    assert(false, "Unexpected gameEndDetails")
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

--[[
    When we receieve updates from the server, this function is called.
    Updates UI to reflect current state.
]]
local previousUIMode = UIModes.None
function GuiMain.updateUI(opt_previousTableDescription: CommonTypes.TableDescription?)
    Utils.debugPrint("GamePlay", "GuiMain.onTableUpdated calling GuiMain.updateUI")

    local currentUIMode = StateDigest.getCurrentUIMode()

    local currentTableDescription = StateDigest.getCurrentTableDescription()

    -- If this causes a change in UIMode, destroy the old UI and build a new one.
    if currentUIMode ~= previousUIMode then
        cleanupPreviousUI(previousUIMode, opt_previousTableDescription)
        if currentUIMode == UIModes.TableSelection then
            TableSelectionUI.build()
        elseif currentUIMode == UIModes.TableWaitingForPlayers then
            assert(currentTableDescription, "Should have a currentTableDescription")
            TableWaitingUI.build(currentTableDescription.tableId)
        elseif currentUIMode == UIModes.TablePlaying then
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
        TableSelectionUI.update()
    elseif currentUIMode == UIModes.TableWaitingForPlayers then
        TableWaitingUI.update()
    elseif currentUIMode == UIModes.TablePlaying then
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
    Utils.debugPrint("GamePlay", "GuiMain.onTableUpdated tableDescription = ", tableDescription)
    Utils.debugPrint("GamePlay", "GuiMain.onTableUpdated calling ClientTableDescriptions.updateTableDescriptionAsync")
    local tableId = tableDescription.tableId
    local previousTableDescription = ClientTableDescriptions.getTableDescription(tableId)
    -- Copy it just to be safe.
    previousTableDescription = Cryo.Dictionary.join({}, previousTableDescription)

    ClientTableDescriptions.updateTableDescriptionAsync(tableDescription)
    Utils.debugPrint("GamePlay", "GuiMain.onTableUpdated called ClientTableDescriptions.updateTableDescriptionAsync")
    Utils.debugPrint("GamePlay", "GuiMain.onTableUpdated calling GuiMain.updateUI")
    GuiMain.updateUI(previousTableDescription)
end

return GuiMain
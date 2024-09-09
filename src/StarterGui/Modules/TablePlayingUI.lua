--[[
UIMode is TablePlaying.
Local player belongs to exactly one table (as host or guest) and
that table is in GameTableStates.Playing.
UI Shows:
    * a frame with data and controls common to all games (name, host, players, controls, etc).
    * an area for game-specific UI.
]]

local TablePlayingUI = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local Utils = require(RobloxBoardGameShared.Modules.Utils)

-- StarterGui
local RobloxBoardGameStarterGui = script.Parent.Parent
local TableDescriptions = require(RobloxBoardGameStarterGui.Modules.TableDescriptions)
local GuiUtils = require(RobloxBoardGameStarterGui.Modules.GuiUtils)
local GuiConstants = require(RobloxBoardGameStarterGui.Modules.GuiConstants)
local DialogUtils = require(RobloxBoardGameStarterGui.Modules.DialogUtils)
local ClientEventManagement = require(RobloxBoardGameStarterGui.Modules.ClientEventManagement)
local GameUIs = require(RobloxBoardGameStarterGui.Globals.GameUIs)

local topBarContent
local bottomBarContent
local gameSpecificContainer

local addTopBar = function(mainFrame: GuiObject, tableDescription: CommonTypes.TableDescription, gameDetails: CommonTypes.GameDetails): Frame
    local content = GuiUtils.addRowAndReturnRowContent(mainFrame, "TopBar", nil, {
        AutomaticSize = Enum.AutomaticSize.None,
        Size = UDim2.new(1, 0, 0, GuiConstants.topBarHeight),
    })

    GuiUtils.addTextLabel(content, "<b>" .. gameDetails.name .. "</b>", {
        RichText = true,
        FontSize = Enum.FontSize.Size24,
    })
    GuiUtils.addTextLabel(content, "Host:")
    GuiUtils.addMiniUserLabel(content, tableDescription.hostUserId)
    GuiUtils.addTextLabel(content, "Players:")
    Utils.debugPrint("TablePlaying", "Doug: addTopBar tableDescription.memberUserIds = ", tableDescription.memberUserIds)
    for userId, _  in tableDescription.memberUserIds do
        Utils.debugPrint("TablePlaying", "Doug: addTopBar 001 userId = ", userId)
        if userId ~= tableDescription.hostUserId then
            Utils.debugPrint("TablePlaying", "Doug: addTopBar 002 userId = ", userId)
            Utils.debugPrint("TablePlaying", "Doug: addTopBar 002 typeof(userId) = ", typeof(userId))
            GuiUtils.addMiniUserLabel(content, userId)
        end
    end

    Utils.debugPrint("TablePlaying", "Doug: 003")
    return content
end

local addBottomBar = function(mainFrame: GuiObject, tableId: CommonTypes.TableId, isHost: boolean): Frame
    local content = GuiUtils.addRowAndReturnRowContent(mainFrame, "BottomBar", nil, {
        AutomaticSize = Enum.AutomaticSize.None,
        Size = UDim2.new(1, 0, 0, GuiConstants.bottomBarHeight),
    })
    content.Parent.Position = UDim2.new(0, 0, 1, -GuiConstants.bottomBarHeight)

    if isHost then
        GuiUtils.addTextButtonInContainer(content, "End Game Immediately", function()
            DialogUtils.showConfirmationDialog("End the game early?", "Please confirm you want to end this game immediately.", function()
                ClientEventManagement.endGameEarly(tableId)
            end)
        end)
    else
        GuiUtils.addTextButtonInContainer(content, "Leave Game", function()
            DialogUtils.showConfirmationDialog("Leave the game early?", "Please confirm you want to leave this game immediately.", function()
                ClientEventManagement.leaveTable(tableId)
            end)
        end)
    end

    return content
end

local addGameSpecificContainer = function(mainFrame: GuiObject, tableDescription: CommonTypes.TableDescription, gameDetails: CommonTypes.GameDetails): Frame
    local content = GuiUtils.addRowAndReturnRowContent(mainFrame, "GameSpecificContainer", nil, {
        AutomaticSize = Enum.AutomaticSize.None,
        Size = UDim2.new(1, 0, 1, -GuiConstants.topBarHeight - GuiConstants.bottomBarHeight),
    })
    content.Parent.Position = UDim2.new(0, 0, 0, GuiConstants.topBarHeight)

    Utils.debugPrint("TablePlaying", "Doug: gameDetails.gameId = ", gameDetails.gameId)
    local gameUIs = GameUIs.getGameUIs(gameDetails.gameId)
    assert(gameUIs, "Should have a gameUIs")

    gameUIs.build(content, tableDescription)

    return content
end

-- Create barebones structure for this UI,
-- Do not bother filling in anything that might change over time: this comes with update.
TablePlayingUI.build = function(tableId: CommonTypes.TableId)
    -- Sanity check arguments, get all the other stuff we need.
    assert(tableId, "Should have a tableId")

    local localUserId = game.Players.LocalPlayer.UserId
    assert(localUserId, "Should have a localUserId")

    local tableDescription = TableDescriptions.getTableDescription(tableId)
    assert(tableDescription, "Should have a tableDescription")
    local isHost = localUserId == tableDescription.hostUserId

    local gameDetails = GameDetails.getGameDetails(tableDescription.gameId)
    assert(gameDetails, "Should have a gameDetails")

    local mainFrame = GuiUtils.getMainFrame()
    assert(mainFrame, "MainFrame not found")

    GuiUtils.addUIGradient(mainFrame, GuiConstants.whiteToBlueColorSequence)
    GuiUtils.addStandardMainFramePadding(mainFrame)
    GuiUtils.addLayoutOrderGenerator(mainFrame)

    topBarContent = addTopBar(mainFrame, tableDescription, gameDetails)
    gameSpecificContainer = addGameSpecificContainer(mainFrame, tableDescription, gameDetails)
    bottomBarContent = addBottomBar(mainFrame, tableId, isHost)
end

TablePlayingUI.update = function()
    Utils.debugPrint("TablePlaying", "Doug: in TablePlayingUI.update")
end

return TablePlayingUI
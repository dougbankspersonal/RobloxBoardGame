-- Shared
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxBoardGameShared = ReplicatedStorage.RobloxBoardGameShared
local CommonTypes = require(RobloxBoardGameShared.Types.CommonTypes)
local GameDetails = require(RobloxBoardGameShared.Globals.GameDetails)
local Utils = require(RobloxBoardGameShared.Modules.Utils)
local SanityChecks = require(RobloxBoardGameShared.Modules.SanityChecks)

-- Client
local RobloxBoardGameClient = script.Parent.Parent
local GuiMain = require(RobloxBoardGameClient.Modules.GuiMain)
local ClientEventManagement = require(RobloxBoardGameClient.Modules.ClientEventManagement)
local ClientGameInstanceFunctions = require(RobloxBoardGameClient.Globals.ClientGameInstanceFunctions)
local ClientTableDescriptions = require(RobloxBoardGameClient.Modules.ClientTableDescriptions)
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)
local Mocks = require(RobloxBoardGameClient.Modules.Mocks)
local AnalyticsView = require(RobloxBoardGameClient.Modules.AnalyticsView)
local GuiConstants = require(RobloxBoardGameClient.Globals.GuiConstants)

-- 3d avatar is irrelevant for this game.
local function turnOffPlayerControls()
    local localPlayer = game.Players.LocalPlayer
    assert(localPlayer, "localPlayer not found")
    local controls = require(localPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
    assert(controls, "controls not found")
    controls:Disable()
end

-- Most Roblox experiences are 3d spaces with avatar running around.
-- This is a 2s board game, no avatar, no 3d space.
-- This has some implications for how we configure the game.
local function configureForBoardGames()
    -- Player can't move or jump.
    turnOffPlayerControls()
    -- We don't need/want local chat: people can use voice chat, and the chat widget gets in the way of
    -- the 2d interface.
    game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    -- We don't want 3d sound.
    local soundService = game:GetService("SoundService")
    soundService.DistanceFactor = 0

end

local ClientStartUp = {}

local function sanityCheckClientGameInstanceFunctionsByGameId(clientGameInstanceFunctionsByGameId: CommonTypes.ClientGameInstanceFunctionsByGameId)
    for gameId, clientGameInstanceFunctions in pairs(clientGameInstanceFunctionsByGameId) do
      assert(gameId, "gameId must be provided")
      assert(clientGameInstanceFunctions, "clientGameInstanceFunctions must be provided")
      assert(clientGameInstanceFunctions.makeClientGameInstanceAsync, "makeClientGameInstanceAsync must be provided")
      assert(clientGameInstanceFunctions.getClientGameInstance, "getClientGameInstance must be provided")
    end
  end


function ClientStartUp.ClientStartUp(screenGui: ScreenGui, gameDetailsByGameId: CommonTypes.GameDetailsByGameId, clientGameInstanceFunctionsByGameId: CommonTypes.ClientGameInstanceFunctionsByGameId)
    -- Sanity check on tables coming in from client of RobloxBoardGame library.
    SanityChecks.sanityCheckGameDetailsByGameId(gameDetailsByGameId)
    sanityCheckClientGameInstanceFunctionsByGameId(clientGameInstanceFunctionsByGameId)

    -- must be at least one.
    local numGames = Utils.tableSize(gameDetailsByGameId)
    assert(numGames > 0, "Should have at least one game")
    assert(Utils.tablesHaveSameKeys(gameDetailsByGameId, clientGameInstanceFunctionsByGameId), "tables should have same keys")

    -- Set up globals.
    GameDetails.setAllGameDetails(gameDetailsByGameId)
    ClientGameInstanceFunctions.setAllClientGameInstanceFunctions(clientGameInstanceFunctionsByGameId)


    -- make a background screenGui to hide the 3d world.
    GuiMain.makeUberBackground(screenGui.Parent)

    screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    screenGui.DisplayOrder = 1
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    configureForBoardGames()

    local adminControlsFrame = Instance.new("Frame")
    adminControlsFrame.Name = "AdminControlsFrame"
    adminControlsFrame.AnchorPoint = Vector2.new(1, 1)
    adminControlsFrame.Position = UDim2.fromScale(1, 1)
    adminControlsFrame.Size = UDim2.fromScale(0, 0)
    adminControlsFrame.BackgroundTransparency = 1
    adminControlsFrame.Parent = screenGui
    adminControlsFrame.ZIndex = GuiConstants.adminControlFrameZIndex
    adminControlsFrame.AutomaticSize = Enum.AutomaticSize.XY

    GuiUtils.addUIPadding(adminControlsFrame)
    GuiUtils.addUIListLayout(adminControlsFrame)

    Mocks.addMocksButton(adminControlsFrame, 1)
    AnalyticsView.addAnalyticsButton(adminControlsFrame, 2)

    GuiMain.makeContainingScrollingFrame()
    GuiMain.makeMainFrame()

    -- Show a loading screen while we fetch data from backend.
    GuiMain.showLoadingUI()

    -- Do this before we fetch all tables (just so there's no squirreliness where:
    -- a) we ask for all tables
    -- b) server replies
    -- c) server updates tables and broadcasts updates
    -- d) we get the updates
    ClientEventManagement.listenToServerEvents(GuiMain.onTableCreated,
        GuiMain.onTableDestroyed,
        GuiMain.onTableUpdated)

    task.spawn(function()
        local tableDescriptionsByTableId = ClientEventManagement.fetchTableDescriptionsByTableIdAsync()
        task.spawn(function()
            ClientTableDescriptions.setTableDescriptionsAsync(tableDescriptionsByTableId)
            GuiMain.updateUI()
        end)
    end)
end

return ClientStartUp